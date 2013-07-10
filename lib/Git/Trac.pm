package Git::Trac;

use 5.010;
use Moose;
use autodie ':all';
use namespace::autoclean;
use Carp;
use Term::EditorEdit;

use aliased 'Git::Repository';

use aliased 'Git::Trac::Configuration';
use aliased 'Git::Trac::Task';
use aliased 'Git::Trac::Ticket::List' => 'TicketList';
use aliased 'Git::Trac::Task::List'   => 'TaskList';

our $VERSION = '0.01';

has 'configuration' => (
    is      => 'ro',
    isa     => Configuration,
    builder => '_build_configuration',
);
sub _build_configuration { Configuration->new }

has 'ticket_cache' => (
    is      => 'ro',
    isa     => 'Str',
    default => '.git_trac_ticket_cache',
);
has 'ticket_list' => (
    is            => 'ro',
    isa           => TicketList,
    lazy          => 1,
    builder       => '_build_ticket_list',
    documentation => 'List class of Trac tickets',
);

sub _build_ticket_list {
    my $self  = shift;
    my $cache = $self->ticket_cache;

    if ( !$self->refresh && -f $cache ) {
        my $ticket_list = TicketList->load($cache);
        $ticket_list->_set_configuration( $self->configuration );
        return $ticket_list;
    }
    else {
        return TicketList->new(
            cache         => $cache,
            configuration => $self->configuration,
        );
    }
}

has 'task_cache' => (
    is      => 'ro',
    isa     => 'Str',
    default => '.git_trac_task_cache',
);
has 'task_list' => (
    is            => 'ro',
    isa           => TaskList,
    lazy          => 1,
    builder       => '_build_task_list',
    documentation => 'List class of Trac tasks',
);
sub _build_task_list {
    my $self  = shift;
    my $cache = $self->task_cache;

    if ( -f $cache ) {
        my $task_list = TaskList->load($cache);
        $task_list->_set_ticket_list($self->ticket_list);
        return $task_list;
    }
    else {
        return TaskList->new(
            cache       => $cache,
            ticket_list => $self->ticket_list,
        );
    }
}

has '_git' => (
    is      => 'ro',
    isa     => Repository,
    builder => '_build_git',
);
sub _build_git { Repository->new }

has 'refresh' => (
    is  => 'ro',
    isa => 'Bool',
);

sub tickets_to_string {
    my $self   = shift;
    my $string = '';

    if ( $self->ticket_list->is_empty ) {
        say "No tickets found. Perhaps refresh? (git trac --refresh)";
        return;
    }

    foreach my $ticket ( @{ $self->ticket_list->tickets } ) {
        my ( $id, $summary, $created, $status )
          = map { $ticket->$_ } qw/id summary created status/;
        $string .= sprintf "%7d - %s - %-12s - $summary\n" => $id,
          $created, $status;
    }
    return $string;
}

sub tasks_to_string {
    my $self   = shift;
    my $string = '';

    if ( $self->task_list->is_empty ) {
        say "No tasks found. (git trac start \$ticket task name)";
        return;
    }

    foreach my $task ( @{ $self->task_list->tasks } ) {
        my ( $id, $summary, $is_current, $branch )
          = map { $task->$_ } qw/id summary is_current branch/;
        $is_current = $is_current ? '*' : '';
        $string .= sprintf "%2s - %7d - $branch ($summary)\n" => $is_current, $id;
    }
    return $string;
}

sub start_task {
    my ( $self, $id, @name ) = @_;

    unless (@name) {
        croak("Starting a task requires a branch name");
    }
    if ( my $dirty = $self->_branch_is_dirty ) {
        warn "Refusing to start task with dirty branch\n$dirty";
        return;
    }
    my $ticket = $self->ticket_list->by_id($id)
      or croak "No ticket found for id ($id)";

    if ( $self->task_list->by_id($id) ) {
        warn "Task $id already started\n";
        return;
    }
    my $branch = join '_' => @name;
    $branch =~ s/\W/_/g;
    unless ( $branch =~ /\b$id\b/ ) {
        $branch = "ticket_$id\_$branch";
    }

    my $task = Task->new(
        branch     => $branch,
        ticket     => $ticket,
        is_current => 1,
    );

    my $integration_branch = $self->configuration->integration_branch;
    my $git                = $self->_git;

    # XXX requires git 1.6.3 or newer
    my $current_branch = $git->run(qw/rev-parse --abbrev-ref HEAD/);
    unless ( $current_branch eq $integration_branch ) {
        $git->run( checkout => $integration_branch );
    }
    $git->run( 'checkout', '-b', $branch );

    $ticket->update_status(
        connection => $self->configuration->connection,
        status     => 'accepted', # currently a no-op
        comment    => "Work started in branch $branch",
    );

    $self->task_list->add_task($task);
}

sub switch_task {
    my ( $self, $id ) = @_;
    my $task = $self->task_list->by_id($id)
        or croak("No such task '$id'");

    if ( my $dirty = $self->_branch_is_dirty ) {
        warn "Refusing to switch tasks with dirty branch\n$dirty";
        return;
    }

    $self->_git->run( checkout => $task->branch );
    $self->task_list->set_current($task);
    return $self->tasks_to_string;
}

sub delete {
    my ( $self, $id ) = @_;
    my $task = $self->task_list->by_id($id)
      or croak("No such task '$id'");
    if ( my $dirty = $self->_branch_is_dirty ) {
        warn "Refusing to delete task with dirty branch\n$dirty";
        return;
    }
    $self->task_list->delete($task);
}

sub commit {
    my ( $self, @args ) = @_;

    my $task = $self->task_list->current_task;

    unless ($task) {
        warn "No current task found. Skipping commit";
    }

    unless ( grep {/^-m$/} @args ) {
        my $id      = $task->id;
        my $branch  = $task->branch;
        my $message = Term::EditorEdit->edit( document => <<"END");
(#$id) Enter you commit message here

Description

# Please enter the commit message for your changes. Lines starting
# with '#' will be ignored, and an empty message aborts the commit.
# On branch $branch
END
        unless ($message) {
            die "Aborting commit due to empty commit message";
        }
        $message = join "\n" => grep { !/^\s*#/ } split /\n/ => $message;
        push @args => ( '-m', $message );
    }


    my $git = $self->_git;
    $git->run( commit => @args );
    my $message = $git->run('log', '-n1');

    my $ticket = $self->ticket_list->by_id( $task->id );
    $ticket->update_status(
        connection => $self->configuration->connection,
        comment    => $message,
    );
}

sub _branch_is_dirty {
    my $self = shift;
    return $self->_git->run('diff', '--shortstat');
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=head1 NAME

Git::Trac - Interact with git and trac

=head1 VERSION

Version 0.01

=cut

=head1 SYNOPSIS


=head1 METHODS

=cut


=head1 AUTHOR

Curtis "Ovid" Poe, C<< <ovid at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-git-trac at rt.cpan.org>,
or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Git-Trac>.  I will be
notified, and then you'll automatically be notified of progress on your bug as
I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Git::Trac
You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Git-Trac>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Git-Trac>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Git-Trac>

=item * Search CPAN

L<http://search.cpan.org/dist/Git-Trac/>

=back

=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2013 Curtis "Ovid" Poe.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

=cut

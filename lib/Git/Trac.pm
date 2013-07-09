package Git::Trac;

use 5.010;
use Moose;
use Git::Trac::Authentication;
use Net::Trac;

our $VERSION = '0.01';

has '_auth' => (
    is      => 'ro',
    isa     => 'Git::Trac::Authentication',
    builder => '_build_auth',
);
sub _build_auth { Git::Trac::Authentication->new }

has 'connection' => (
    is      => 'ro',
    isa     => "Net::Trac::Connection",
    lazy    => 1,
    builder => '_build_connection',
);
sub _build_connection { shift->_auth->connect; }

sub get_open_tickets {
    my ( $self, $user ) = @_;
    $user //= $self->_auth->user;

    my $search
      = Net::Trac::TicketSearch->new( connection => $self->connection );

    return $search->query(
        owner  => $user,
        status => { 'not' => [qw(closed)] },
    );
}

sub tickets_to_string {
    my $self    = shift;
    my $tickets = $self->get_open_tickets;
    my $string  = '';
    foreach my $ticket (@$tickets) {
        my ( $id, $summary, $created )
          = map { $ticket->$_ } qw/id summary created/;
        $string .= sprintf "%7d - %s - $summary\n" => $id, $created->ymd;
    }
    return $string;
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

1; # End of Git::Trac

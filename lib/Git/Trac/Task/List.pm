package Git::Trac::Task::List;

use Moose;
use MooseX::Storage;
use aliased 'Git::Trac::Task';
use namespace::autoclean;
use Carp;

with Storage( 'format' => 'JSON', 'io' => 'File' );

has 'cache' => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

has 'tasks' => (
    traits  => [ 'Array', 'DoNotSerialize' ],
    is      => 'rw',
    isa     => 'ArrayRef[Git::Trac::Task]',
    lazy    => 1,
    builder => '_build_tasks',
    handles => {
        is_empty  => 'is_empty',
        _add_task => 'push',
    },
);
sub _build_tasks {
    my $self = shift;

    my $tasks = $self->_tasks // [];

    my $ticket_list = $self->ticket_list or return $tasks;

    my @tasks;
    foreach my $task (@$tasks) {
        push @tasks => Task->new(
            ticket     => $ticket_list->by_id( $task->{id} ),
            branch     => $task->{branch},
            is_current => $task->{is_current},
        );
    }
    return \@tasks;
}
        
has 'ticket_list' => (
    traits => ['DoNotSerialize'],
    is     => 'rw',
    writer => '_set_ticket_list',                # trusted method, not private
    isa    => 'Maybe[Git::Trac::Ticket::List]',
);

has '_tasks' => (
    traits  => ['Array'],
    is      => 'rw',
    isa     => 'ArrayRef[HashRef]',
    handles => {
        _add_task_ref => 'push',
    },
    default       => sub { [] },
    documentation => 'This is an internal hashref of tasks',
);

sub add_task {
    my ( $self, $task ) = @_;

    my $id           = $task->id;
    my $is_current   = $task->is_current;
    my %task_as_hash = (
        id         => $id,
        branch     => $task->branch,
        is_current => $is_current,
    );

    if ( $task->is_current ) {
        foreach my $task ( @{ $self->_tasks } ) {
            $task->{is_current} = 0;
        }
        foreach my $task ( @{ $self->tasks } ) {
            $task->_is_current(0);
        }
    }
    $self->_add_task_ref( \%task_as_hash );
    $self->_add_task($task);
}

sub delete {
    my ( $self, $task ) = @_;

    my $id = $task->id;
    my @tasks = grep { $_->id ne $id } @{ $self->tasks };
    $self->tasks( \@tasks );
    @tasks = grep { $_->{id} ne $id } @{ $self->_tasks };
    $self->_tasks( \@tasks );
}

sub set_current {
    my ( $self, $current_task ) = @_;
    foreach my $task ( @{ $self->_tasks } ) {
        next if $task->{id} == $current_task->id;
        $task->{is_current} = 0;
    }
    foreach my $task ( @{ $self->tasks } ) {
        $task->_is_current(0);
    }
    $current_task->_is_current(1);
}

sub by_id {
    my ( $self, $id ) = @_;
    return if $self->is_empty;
    my %tasks = map { $_->id => $_ } @{ $self->tasks };
    return $tasks{$id};
}

sub current_task {
    my $self = shift;
    return if $self->is_empty;
    my $tasks = $self->tasks;
    my @current = grep { $_->is_current } @$tasks;
    if ( @current > 1 ) {
        croak("PANIC: More than one current task found");
    }
    return $current[0];
}

sub DEMOLISH {
    my $self = shift;
    $self->store( $self->cache );
}
1;

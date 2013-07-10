package Git::Trac::Task;

use Moose;
use MooseX::Storage;
use aliased 'Git::Trac::Ticket';
with Storage( 'format' => 'JSON', 'io' => 'File' );
use namespace::autoclean;

has 'is_current' => (
    is     => 'rw',
    writer => '_is_current',
    isa    => 'Bool',
);

has 'branch' => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

has 'ticket' => (
    is       => 'ro',
    isa      => Ticket,
    required => 1,
    handles  => {
        id             => 'id',
        summary        => 'summary',
        status         => 'status',
        ticket_created => 'create',
    },
);

__PACKAGE__->meta->make_immutable;

1;

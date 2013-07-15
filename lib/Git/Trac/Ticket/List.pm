package Git::Trac::Ticket::List;

use 5.010;
use Moose;
use MooseX::Storage;
use autodie ':all';
use namespace::autoclean;
use Net::Trac;

use aliased 'Git::Trac::Ticket';
with Storage( 'format' => 'JSON', 'io' => 'File' );

our $VERSION = '0.02';

has 'cache' => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

has 'configuration' => (
    traits => ['DoNotSerialize'],
    is     => 'rw',
    writer => '_set_configuration',       # trusted method, not private method
    isa    => 'Git::Trac::Configuration',
);

has 'connection' => (
    traits  => ['DoNotSerialize'],
    is      => 'ro',
    isa     => "Net::Trac::Connection",
    lazy    => 1,
    builder => '_build_connection',
);
sub _build_connection { shift->configuration->connection; }

has '_tickets' => (
    is      => 'rw',
    lazy    => 1,
    builder => '_build_tickets',
);

sub _build_tickets {
    my ($self) = @_;
    my $user = $self->configuration->user;

    my $search
      = Net::Trac::TicketSearch->new( connection => $self->connection );

    my $tickets = $search->query(
        owner  => $user,
        status => { 'not' => [qw(closed)] },
    );

    my @tickets;
    foreach my $ticket (@$tickets) {
        my %ticket_data = map { my $attr = $_->name; $attr => $ticket->$attr }
          Ticket->meta->get_all_attributes;
        $ticket_data{created} .= '';    # coerce DateTime or we can't cache it
        push @tickets => \%ticket_data;
    }
    return \@tickets;
}

sub by_id {
    my ( $self, $id ) = @_;
    state $ticket_for = { map { $_->id => $_ } @{ $self->tickets } };
    return $ticket_for->{$id};
}

sub is_empty {
    my $self = shift;
    return scalar !scalar @{ $self->_tickets };
}

sub tickets {
    my $self    = shift;
    my $tickets = $self->_tickets;
    return [ map { Ticket->new($_) } @$tickets ];
}

sub DEMOLISH {
    my $self = shift;
    $self->store( $self->cache );
}

__PACKAGE__->meta->make_immutable;

1;

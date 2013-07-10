package Git::Trac::Cache;

use Moose;
use MooseX::Storage;
use autodie ':all';
use namespace::autoclean;
use Net::Trac;

use Git::Trac::Authentication;
use aliased 'Git::Trac::Ticket';
with Storage( 'format' => 'JSON', 'io' => 'File' );

our $VERSION = '0.01';

has 'cache_file' => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

has '_auth' => (
    traits  => ['DoNotSerialize'],
    is      => 'ro',
    isa     => 'Git::Trac::Authentication',
    builder => '_build_auth',
);
sub _build_auth { Git::Trac::Authentication->new }

has 'connection' => (
    traits  => ['DoNotSerialize'],
    is      => 'ro',
    isa     => "Net::Trac::Connection",
    lazy    => 1,
    builder => '_build_connection',
);
sub _build_connection { shift->_auth->connect; }

has '_tickets' => (
    is => 'rw',

    #    isa     => 'ArrayRef[Net::Track::Tickets]',
    lazy    => 1,
    builder => '_build_tickets',
);

sub _build_tickets {
    my ( $self, $user ) = @_;
    $user //= $self->_auth->user;

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

sub tickets {
    my $self    = shift;
    my $tickets = $self->_tickets;
    return [ map { Ticket->new($_) } @$tickets ];
}

sub DEMOLISH {
    my $self = shift;
    $self->store( $self->cache_file );
}

__PACKAGE__->meta->make_immutable;

    1;

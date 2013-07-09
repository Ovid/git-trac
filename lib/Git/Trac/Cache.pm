package Git::Trac::Cache;

use Moose;
use MooseX::Storage;
use autodie ':all';
use namespace::autoclean;
use Net::Trac;

use Git::Trac::Authentication;
use Git::Trac::Ticket;
with Storage( 'format' => 'JSON', 'io' => 'File' );

our $VERSION = '0.01';

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
        push @tickets => {
            id      => $ticket->id,
            summary => $ticket->summary,
            created => $ticket->created->ymd, # can't freeze a DateTime
        };
    }
    return \@tickets;
}

sub tickets {
    my $self = shift;
    my $tickets = $self->_tickets;
    return [ map { Git::Trac::Ticket->new($_) } @$tickets ];
}

__PACKAGE__->meta->make_immutable;

1;

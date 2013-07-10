package Git::Trac::Ticket;

use Moose;
use autodie ':all';
use namespace::autoclean;
use MooseX::Types::DateTime::MoreCoercions qw(DateTime);
use DateTime::Format::Strptime;
use Net::Trac::Ticket;

our $VERSION = '0.01';

has [qw/id summary status/] => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);
has 'created' => (
    is       => 'ro',
    isa      => DateTime,
    required => 1,
    coerce   => 1,
);

sub BUILD {
    my $self = shift;

    my $YYYY_MM_DD = DateTime::Format::Strptime->new( pattern => '%F' );
    $self->created->set_formatter($YYYY_MM_DD);
}

sub update_status {
    my ( $self, $connection, $status ) = @_;
    return if $self->status eq $status;
    my $ticket = Net::Trac::Ticket->new( connection => $connection );
    $ticket->load($self->id);
    $ticket->update( status => $status );
}

__PACKAGE__->meta->make_immutable;

1;

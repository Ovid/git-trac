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
    my ( $self, %arg_for ) = @_;

    my ( $connection, $status, $comment )
      = @arg_for{qw/connection status comment/};
    my $ticket = Net::Trac::Ticket->new( connection => $connection );
    $ticket->load( $self->id );

    if ( $self->status ne $status ) {
        $ticket->update( status => $status )
          or warn "Failed to update status: $status";
    }
    $ticket->comment($comment) or warn "Failed to add comment: $comment";
}

__PACKAGE__->meta->make_immutable;

1;

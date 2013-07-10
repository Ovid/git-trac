package Git::Trac::Ticket;

use Moose;
use autodie ':all';
use namespace::autoclean;
use MooseX::Types::DateTime::MoreCoercions qw(DateTime);
use DateTime::Format::Strptime;

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

__PACKAGE__->meta->make_immutable;

1;

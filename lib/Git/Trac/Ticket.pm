package Git::Trac::Ticket;

use Moose;
use autodie ':all';
use namespace::autoclean;

use Git::Trac::Authentication;

our $VERSION = '0.01';

has [qw/id summary created/] => (
    is       => 'ro',
    isa      => 'Str',    # we stringify the data so it can be serialized :(
    required => 1,
);

__PACKAGE__->meta->make_immutable;

1;

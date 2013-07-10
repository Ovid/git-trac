package Git::Trac::Ticket;

use Moose;
use autodie ':all';
use namespace::autoclean;
use MooseX::Types::DateTime::MoreCoercions qw(DateTime);

use Git::Trac::Authentication;

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

sub string_attributes {
    my @attributes
      = map { $_->name }
      grep  { !$_->should_coerce } Git::Trac::Ticket->meta->get_all_attributes;
    return @attributes;
}

sub datetime_attributes {
    my @attributes
      = map { $_->name }
      grep  { $_->should_coerce } Git::Trac::Ticket->meta->get_all_attributes;
    return @attributes;
}

__PACKAGE__->meta->make_immutable;

1;

package Git::Trac::Configuration;

use 5.010;
use Moose;
use MooseX::Configuration;
use Net::Trac::Connection;
use File::stat;    # not File::Stat
use Carp;
use namespace::autoclean;

our $VERSION = '0.01';

has 'user' => (
    is            => 'ro',
    isa           => 'Str',
    section       => 'authentication',
    key           => 'user',
    documentation => 'Your Trac login name',
);

has 'password' => (
    is            => 'ro',
    isa           => 'Str',
    section       => 'authentication',
    key           => 'password',
    documentation => 'Your Trac password',
);

has 'url' => (
    is            => 'ro',
    isa           => 'Str',
    section       => 'authentication',
    key           => 'url',
    documentation => 'Your Trac url',
);

has 'config_file' => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
    default  => sub { $ENV{GIT_TRAC_CONFIG} // "$ENV{HOME}/.git-trac.ini" },
);

sub BUILD {
    my $self = shift;

    my $config_file = $self->config_file;
    unless ( -f $config_file ) {
        die $self->_usage;
    }
    my $mode        = 0777 & stat($config_file)->mode;

    unless ( ( $mode & 0600 ) == 0600 ) {
        croak("Permisions on '$config_file' must be 0600");
    }
}

sub connect {
    my $self   = shift;
    my @fields = qw/url user password/;
    return Net::Trac::Connection->new( map { $_ => $self->$_ } @fields );
}

sub _usage {
    my $self = shift;
    my $config_file = $self->config_file;

    print STDERR <<"END";
You must create a file named '$config_file', with permissions of 0600. The
file should be an ini-style with the following data:

    [authentication]
    ; Your Trac login name
    user     = your username

    ; Your Trac password
    password = your password

    ; Your Trac url
    url      = https://dev.drugdev.org/trac/drugdev.dev
END
}

__PACKAGE__->meta->make_immutable;

1;

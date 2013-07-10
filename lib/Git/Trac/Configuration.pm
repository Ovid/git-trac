package Git::Trac::Configuration;

use 5.010;
use Moose;
use MooseX::Configuration;
use File::stat;    # not File::Stat
use Carp;
use namespace::autoclean;
use aliased 'Net::Trac::Connection';

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

has 'integration_branch' => (
    is            => 'ro',
    isa           => 'Str',
    section       => 'git',
    key           => 'integration_branch',
    documentation => 'The primary branch you will branch from',
    default       => 'master',
);

has 'config_file' => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
    default  => sub { $ENV{GIT_TRAC_CONFIG} // "$ENV{HOME}/.git-trac.ini" },
);

has 'connection' => (
    is      => 'ro',
    isa     => Connection,
    lazy    => 1,
    builder => '_build_connection',
);

sub _build_connection {
    my $self   = shift;
    my @fields = qw/url user password/;
    return Connection->new( map { $_ => $self->$_ } @fields );
}


sub BUILD {
    my $self = shift;

    my $config_file = $self->config_file;
    unless ( -f $config_file ) {
        die $self->_usage;
    }
    my $mode = 0777 & stat($config_file)->mode;

    unless ( ( $mode & 0600 ) == 0600 ) {
        croak("Permisions on '$config_file' must be 0600");
    }
}

sub _usage {
    my $self        = shift;
    my $config_file = $self->config_file;

    print STDERR <<"END";
You must create a file named '$config_file', with permissions of 0600. The
file should be an ini-style with the following data:

    [authentication]
    ; Your Trac login name
    user     = your username

    ; Your Trac password
    password = your password

    ; Your base Trac url
    url      = https://example.com/trac/company.dev

    [git]

    ; This is the main branch you will branch from. For personal projects, this is
    ; often 'master'. For a work environment, you often branch from 'devel' or
    ; 'integration', so use that branch name. When you switch to a new branch, git
    ; will check out your integration_branch and branch from there. Obviously this
    ; will fail if you have a dirty working tree
    integration_branch = integration
END
}

__PACKAGE__->meta->make_immutable;

1;

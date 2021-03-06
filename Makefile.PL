use 5.010;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME               => 'Git::Trac',
    AUTHOR             => q{Curtis "Ovid" Poe <ovid@cpan.org>},
    VERSION_FROM       => 'lib/Git/Trac.pm',
    ABSTRACT_FROM      => 'lib/Git/Trac.pm',
    LICENSE            => 'Artistic_2_0',
    PL_FILES           => {},
    MIN_PERL_VERSION   => 5.010,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'Test::More' => 0,
    },
    EXE_FILES => ["bin/git-trac"],
    PREREQ_PM => {
        'Moose'                                  => '2.0',
        'MooseX::Storage'                        => '0.34',
        'autodie'                                => '2.17',
        'namespace::autoclean'                   => '0.13',
        'MooseX::Configuration'                  => '0.02',
        'Net::Trac'                              => '0.16',
        'MooseX::Types::DateTime::MoreCoercions' => 0,
        'aliased'                                => 0,
        'Git::Repository'                        => 0,
        'Term::EditorEdit'                       => 0,
        'Pod::Usage'                             => 0,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES    => 'Git-Trac-*' },
);

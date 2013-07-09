#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Git::Trac' ) || print "Bail out!\n";
}

diag( "Testing Git::Trac $Git::Trac::VERSION, Perl $], $^X" );

#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'WWW::RMDown' ) || print "Bail out!\n";
}

diag( "Testing WWW::RMDown $WWW::RMDown::VERSION, Perl $], $^X" );

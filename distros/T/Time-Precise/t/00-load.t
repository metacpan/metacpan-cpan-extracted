#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More tests => 1;
use lib 'lib';

BEGIN {
    use_ok( 'Time::Precise' ) || print "Bail out!\n";
}

diag( "Testing Time::Precise $Time::Precise::VERSION, Perl $], $^X" );

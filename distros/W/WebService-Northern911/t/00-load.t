#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'WebService::Northern911' ) || print "Bail out!\n";
}

diag( "Testing WebService::Northern911 $WebService::Northern911::VERSION, Perl $], $^X" );

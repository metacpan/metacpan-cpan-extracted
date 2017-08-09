#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'WebService::ThreatStack' ) || print "Bail out!\n";
}

diag( "Testing WebService::ThreatStack $WebService::ThreatStack::VERSION, Perl $], $^X" );

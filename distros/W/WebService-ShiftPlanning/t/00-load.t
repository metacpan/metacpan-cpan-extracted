#!perl -T
use 5.10.1;
use strict;
use warnings FATAL => 'all';
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'WebService::ShiftPlanning' ) || print "Bail out!\n";
}

diag( "Testing WebService::ShiftPlanning $WebService::ShiftPlanning::VERSION, Perl $], $^X" );

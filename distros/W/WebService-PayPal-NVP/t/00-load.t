#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'WebService::PayPal::NVP' ) || print "Bail out!\n";
}

diag( "Testing WebService::PayPal::NVP $WebService::PayPal::NVP::VERSION, Perl $], $^X" );

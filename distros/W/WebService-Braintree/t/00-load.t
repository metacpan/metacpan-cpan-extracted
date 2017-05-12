#!/usr/bin/env perl

use Test::More tests => 1;

BEGIN {
    use_ok( 'WebService::Braintree' ) || print "Bail out!\n";
}

diag( "Testing WebService::Braintree $WebService::Braintree::VERSION, Perl $], $^X" );

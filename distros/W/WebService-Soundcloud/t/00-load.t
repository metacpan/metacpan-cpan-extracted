#!/usr/bin/perl

use Test::More tests => 1;

BEGIN {
    use_ok( 'WebService::Soundcloud' ) || print "Bail out!\n";
}

diag( "Testing WebService::Soundcloud $WebService::Soundcloud::VERSION, Perl $], $^X" );

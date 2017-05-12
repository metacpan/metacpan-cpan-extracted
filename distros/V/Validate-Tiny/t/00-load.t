#!/usr/bin/perl

use Test::More tests => 1;

BEGIN {
    use_ok( 'Validate::Tiny' ) || print "Bail out!\n";
}

diag( "Testing Validate::Tiny $Validate::Tiny::VERSION, Perl $], $^X" );

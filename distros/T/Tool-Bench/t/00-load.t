#!/usr/bin/perl 

use Test::More tests => 1;

BEGIN {
    use_ok( 'Tool::Bench' );
}

diag( "Testing Tool::Bench $Tool::Bench::VERSION, Perl $], $^X" );

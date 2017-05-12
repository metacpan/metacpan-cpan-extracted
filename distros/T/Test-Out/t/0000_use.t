#!/usr/bin/env perl

use Test::More tests => 1;

BEGIN {
    use_ok( 'Test::Out' );
}

diag( "Testing Test::Out $Test::Out::VERSION" );

#!perl -T
use strict;
use Test::More tests => 1;

BEGIN {
    use_ok( 'warnings' );
}

diag( "Testing warnings $warnings::VERSION, Perl $], $^X" );

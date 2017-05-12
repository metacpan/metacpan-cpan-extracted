#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'TheEye' );
}

diag( "Testing TheEye $TheEye::VERSION, Perl $], $^X" );

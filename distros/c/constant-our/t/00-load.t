#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'constant::our' );
}

diag( "Testing constant::our $constant::our::VERSION, Perl $], $^X" );

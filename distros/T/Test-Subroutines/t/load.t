#!perl -Tw

use Test::More tests => 1;

# Test for successful module load

BEGIN {
    use_ok( 'Test::Subroutines' );
}

diag( "Testing Test::Subroutines $Test::Subroutines::VERSION, Perl $], $^X" );

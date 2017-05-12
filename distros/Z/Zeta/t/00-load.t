#!perl

use Test::More;

BEGIN {
    use_ok( 'Zeta')       || BAIL_OUT('Failed to use Zeta');
    use_ok( 'Zeta::Util') || BAIL_OUT('Failed to use Zeta::Util');
}

diag( "Testing Zeta $Zeta::VERSION, Perl $], $^X" );
diag( "Testing Zeta::Util $Zeta::Util::VERSION, Perl $], $^X" );

done_testing();

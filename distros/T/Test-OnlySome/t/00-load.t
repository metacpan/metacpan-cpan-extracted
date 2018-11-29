#!perl
use rlib 'lib';
use DTest;

plan tests => 1;

BEGIN {
    use_ok( 'Test::OnlySome' ) || print "Bail out!\n";
}

diag( "Testing Test::OnlySome $Test::OnlySome::VERSION, Perl $], $^X" );

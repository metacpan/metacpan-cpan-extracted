#!perl -T

use Test::More tests => 3;

BEGIN {
    use_ok( 'Validator::Var' ) || print "Bail out!\n";
    use_ok( 'Validator::Group' ) || print "Bail out!\n";
    use_ok( 'Validator::Checker::MostWanted' ) || print "Bail out!\n";
}

diag( "Testing Validator::Var $Validator::Var::VERSION, Perl $], $^X" );

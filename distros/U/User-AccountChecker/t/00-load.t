#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'User::AccountChecker' ) || print "Bail out!
";
}

diag( "Testing User::AccountChecker $User::AccountChecker::VERSION, Perl $], $^X" );

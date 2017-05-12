#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Wikileaks::AfWD' ) || print "Bail out!
";
}

diag( "Testing Wikileaks::AfWD $Wikileaks::AfWD::VERSION, Perl $], $^X" );

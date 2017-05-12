#!perl -T

use Test::More tests => 2;

BEGIN {
    use_ok( 'here' ) || print "Bail out!
";
    use_ok( 'here::declare' ) || print "Bail out!
";
}

diag( "Testing here $here::VERSION, Perl $], $^X" );

#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Test::Structure' ) || print "Bail out!
";
}

diag( "Testing Test::Structure $Test::Structure::VERSION, Perl $], $^X" );

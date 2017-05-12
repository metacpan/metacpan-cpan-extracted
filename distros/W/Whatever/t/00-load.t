#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Whatever' ) || print "Bail out!
";
}

diag( "Testing Whatever $Whatever::VERSION, Perl $], $^X" );

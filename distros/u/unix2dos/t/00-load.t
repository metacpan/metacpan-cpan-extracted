#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'unix2dos' ) || print "Bail out!
";
}

diag( "Testing unix2dos $unix2dos::VERSION, Perl $], $^X" );

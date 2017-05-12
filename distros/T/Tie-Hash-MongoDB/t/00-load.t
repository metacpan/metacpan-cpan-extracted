#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Tie::Hash::MongoDB' ) || print "Bail out!
";
}

diag( "Testing Tie::Hash::MongoDB $Tie::Hash::MongoDB::VERSION, Perl $], $^X" );

#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Tie::Hash::Identity' ) || print "Bail out!
";
}

diag( "Testing Tie::Hash::Identity $Tie::Hash::Identity::VERSION, Perl $], $^X" );

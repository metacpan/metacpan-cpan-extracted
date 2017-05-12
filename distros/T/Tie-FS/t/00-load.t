#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Tie::FS' ) || print "Bail out!\n";
}

diag( "Testing Tie::FS $Tie::FS::VERSION, Perl $], $^X" );

#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'WWW::EFA' ) || print "Bail out!\n";
}

diag( "Testing WWW::EFA $WWW::EFA::VERSION, Perl $], $^X" );

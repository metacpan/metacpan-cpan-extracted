#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'WWW::SubDB' ) || print "Bail out!\n";
}

diag( "Testing WWW::SubDB $WWW::SubDB::VERSION, Perl $], $^X" );

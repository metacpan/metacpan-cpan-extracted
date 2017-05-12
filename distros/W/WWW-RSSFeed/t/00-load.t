#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'WWW::RSSFeed' ) || print "Bail out!\n";
}

diag( "Testing WWW::RSSFeed $WWW::RSSFeed::VERSION, Perl $], $^X" );

#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'WWW::Mechanize::Query' ) || print "Bail out!\n";
}

diag( "Testing WWW::Mechanize::Query $WWW::Mechanize::Query::VERSION, Perl $], $^X" );

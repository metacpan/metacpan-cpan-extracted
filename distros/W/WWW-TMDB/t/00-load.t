#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'WWW::TMDB::API' ) || print "Bail out!\n";
}

diag( "Testing WWW::TMDB::API $WWW::TMDB::API::VERSION, Perl $], $^X" );

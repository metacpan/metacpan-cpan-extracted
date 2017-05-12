#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'WWW::Wunderground::API' ) || print "Bail out!\n";
}

diag( "Testing WWW::Wunderground::API $WWW::Wunderground::API::VERSION, Perl $], $^X" );

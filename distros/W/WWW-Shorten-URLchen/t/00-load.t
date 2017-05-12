#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'WWW::Shorten::URLchen' ) || print "Bail out!\n";
}

diag( "Testing WWW::Shorten::URLchen $WWW::Shorten::URLchen::VERSION, Perl $], $^X" );

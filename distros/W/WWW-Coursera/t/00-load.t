#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'WWW::Coursera' ) || print "Bail out!\n";
}

diag( "Testing WWW::Coursera $WWW::Coursera::VERSION, Perl $], $^X" );

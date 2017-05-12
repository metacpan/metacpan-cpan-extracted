#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'WWW::Socrata' ) || print "Bail out!\n";
}

diag( "Testing WWW::Socrata $WWW::Socrata::VERSION, Perl $], $^X" );

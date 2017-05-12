#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'WWW::Billomat' ) || print "Bail out!\n";
}

diag( "Testing WWW::Billomat $WWW::Billomat::VERSION, Perl $], $^X" );

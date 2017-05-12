#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'WWW::LibraryThing::Covers' ) || print "Bail out!\n";
}

diag( "Testing WWW::LibraryThing::Covers $WWW::LibraryThing::Covers::VERSION, Perl $], $^X" );

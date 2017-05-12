#!perl

use Test::More tests => 1;

BEGIN {
    use_ok( 'WWW::Wikipedia::Links' ) || print "Bail out!\n";
}

diag( "Testing WWW::Wikipedia::Links $WWW::Wikipedia::Links::VERSION, Perl $], $^X" );

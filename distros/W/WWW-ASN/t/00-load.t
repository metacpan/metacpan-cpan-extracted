#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'WWW::ASN' ) || print "Bail out!\n";
}

diag( "Testing WWW::ASN $WWW::ASN::VERSION, Perl $], $^X" );

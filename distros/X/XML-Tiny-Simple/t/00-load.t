#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'XML::Tiny::Simple' ) || print "Bail out!\n";
}

diag( "Testing XML::Tiny::Simple $XML::Tiny::Simple::VERSION, Perl $], $^X" );

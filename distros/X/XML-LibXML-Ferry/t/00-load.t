#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'XML::LibXML::Ferry' ) || print "Bail out!\n";
}

diag( "Testing XML::LibXML::Ferry $XML::LibXML::Ferry::VERSION, Perl $], $^X" );

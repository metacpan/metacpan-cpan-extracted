#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'XML::LibXML::Proxy' ) || print "Bail out!\n";
}

diag( "Testing XML::LibXML::Proxy $XML::LibXML::Proxy::VERSION, Perl $], $^X" );

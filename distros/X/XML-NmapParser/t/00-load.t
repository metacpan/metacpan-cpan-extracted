#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'XML::NmapParser' ) || print "Bail out!\n";
}

diag( "Testing XML::NmapParser $XML::NmapParser::VERSION, Perl $], $^X" );

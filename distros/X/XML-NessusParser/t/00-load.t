#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'XML::NessusParser' ) || print "Bail out!\n";
}

diag( "Testing XML::NessusParser $XML::NessusParser::VERSION, Perl $], $^X" );

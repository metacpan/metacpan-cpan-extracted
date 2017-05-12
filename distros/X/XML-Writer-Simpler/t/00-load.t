#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'XML::Writer::Simpler' ) || print "Bail out!\n";
}

diag( "Testing XML::Writer::Simpler $XML::Writer::Simpler::VERSION, Perl $], $^X" );

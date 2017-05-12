#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'XML::Printer::ESCPOS' ) || print "Bail out!\n";
}

diag( "Testing XML::Printer::ESCPOS $XML::Printer::ESCPOS::VERSION, Perl $], $^X" );

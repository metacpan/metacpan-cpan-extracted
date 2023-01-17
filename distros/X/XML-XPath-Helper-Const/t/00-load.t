#!perl
use 5.010;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'XML::XPath::Helper::Const' ) || print "Bail out!\n";
}

diag( "Testing XML::XPath::Helper::Const $XML::XPath::Helper::Const::VERSION, Perl $], $^X" );

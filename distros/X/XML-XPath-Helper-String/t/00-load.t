#!perl
use 5.008;
use strict;
use warnings;
use Test::More tests => 1;

BEGIN {
    use_ok( 'XML::XPath::Helper::String' ) || print "Bail out!\n";
}

diag( "Testing XML::XPath::Helper::String $XML::XPath::Helper::String::VERSION, Perl $], $^X" );

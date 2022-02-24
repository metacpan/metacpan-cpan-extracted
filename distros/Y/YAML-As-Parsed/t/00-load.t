#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'YAML::As::Parsed' ) || print "Bail out!\n";
}

diag( "Testing YAML::As::Parsed $YAML::As::Parsed::VERSION, Perl $], $^X" );

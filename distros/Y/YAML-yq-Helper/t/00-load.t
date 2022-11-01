#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'YAML::yq::Helper' ) || print "Bail out!\n";
}

diag( "Testing YAML::yq::Helper $YAML::yq::Helper::VERSION, Perl $], $^X" );

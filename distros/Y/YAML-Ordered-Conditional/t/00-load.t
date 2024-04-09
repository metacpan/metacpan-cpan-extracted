#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'YAML::Ordered::Conditional' ) || print "Bail out!\n";
}

diag( "Testing YAML::Ordered::Conditional $YAML::Ordered::Conditional::VERSION, Perl $], $^X" );

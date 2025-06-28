#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'WebService::TogetherWeRemember' ) || print "Bail out!\n";
}

diag( "Testing WebService::TogetherWeRemember $WebService::TogetherWeRemember::VERSION, Perl $], $^X" );

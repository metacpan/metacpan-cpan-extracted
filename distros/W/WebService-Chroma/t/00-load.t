#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'WebService::Chroma' ) || print "Bail out!\n";
}

diag( "Testing WebService::Chroma $WebService::Chroma::VERSION, Perl $], $^X" );

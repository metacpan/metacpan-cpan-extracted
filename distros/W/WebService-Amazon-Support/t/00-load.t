#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'WebService::Amazon::Support' ) || print "Bail out!\n";
}

diag( "Testing WebService::Amazon::Support $WebService::Amazon::Support::VERSION, Perl $], $^X" );

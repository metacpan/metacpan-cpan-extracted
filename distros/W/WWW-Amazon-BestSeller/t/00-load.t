#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'WWW::Amazon::BestSeller' ) || print "Bail out!\n";
}

diag( "Testing WWW::Amazon::BestSeller $WWW::Amazon::BestSeller::VERSION, Perl $], $^X" );

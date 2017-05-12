#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Uninets::Check::Modules::MongoDB' ) || print "Bail out!\n";
}

diag( "Testing Uninets::Check::Modules::MongoDB $Uninets::Check::Modules::MongoDB::VERSION, Perl $], $^X" );

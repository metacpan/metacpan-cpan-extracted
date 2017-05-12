#!perl -T
use v5.10;
use strict;
use warnings FATAL => 'all';
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Test::HTML::Spelling' ) || print "Bail out!\n";
}

diag( "Testing Test::HTML::Spelling $Test::HTML::Spelling::VERSION, Perl $], $^X" );

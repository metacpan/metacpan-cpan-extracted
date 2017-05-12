#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Text::Tokenize::Indented' ) || print "Bail out!\n";
}

diag( "Testing Text::Tokenize::Indented $Text::Tokenize::Indented::VERSION, Perl $], $^X" );

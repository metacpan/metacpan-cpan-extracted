#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Unicode::Homoglyph::Replace' ) || print "Bail out!\n";
}

diag( "Testing Unicode::Homoglyph::Replace $Unicode::Homoglyph::Replace::VERSION, Perl $], $^X" );

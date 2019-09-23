#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Text::Trim' ) or BAIL_OUT( 'use failed. No point continuing.' );
}

diag( "Testing Text::Trim $Text::Trim::VERSION, Perl $], $^X" );

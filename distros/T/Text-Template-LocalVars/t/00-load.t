#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Text::Template::LocalVars' ) || print "Bail out!\n";
}

diag( "Testing Text::Template::LocalVars $Text::Template::LocalVars::VERSION, Perl $], $^X" );

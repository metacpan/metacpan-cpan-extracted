#!perl -T
use 5.006001;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Text::Distill' ) || print "Bail out!\n";
}

diag( "Testing Text::Distill $Text::Distill::VERSION, Perl $], $^X" );

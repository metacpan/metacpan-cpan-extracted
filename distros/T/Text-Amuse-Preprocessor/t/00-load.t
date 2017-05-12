#!perl -T
use strict;
use warnings FATAL => 'all';
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Text::Amuse::Preprocessor' ) || print "Bail out!\n";
}

diag( "Testing Text::Amuse::Preprocessor $Text::Amuse::Preprocessor::VERSION, Perl $], $^X" );

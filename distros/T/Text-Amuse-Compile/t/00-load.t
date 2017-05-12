#!perl -T
use strict;
use warnings FATAL => 'all';
use Test::More;

plan tests => 3;

BEGIN {
    use_ok( 'Text::Amuse::Compile' ) || print "Bail out!\n";
    use_ok( 'Text::Amuse::Compile::Templates' ) || print "Bail out!\n";
    use_ok( 'Text::Amuse::Compile::File' ) || print "Bail out!\n";
}

diag( "Testing Text::Amuse::Compile $Text::Amuse::Compile::VERSION, Perl $], $^X" );

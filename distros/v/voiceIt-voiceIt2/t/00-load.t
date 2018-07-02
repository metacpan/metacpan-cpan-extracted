#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'voiceIt::voiceIt2' ) || print "Bail out!\n";
}

diag( "Testing voiceIt::voiceIt2 $voiceIt::voiceIt2::VERSION, Perl $], $^X" );

#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Tunein::Streams' ) || print "Bail out!\n";
}

diag( "Testing Tunein::Streams $Tunein::Streams::VERSION, Perl $], $^X" );

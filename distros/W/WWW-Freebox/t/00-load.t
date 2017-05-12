#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'WWW::Freebox' ) || print "Bail out!\n";
}

diag( "Testing WWW::Freebox $WWW::Freebox::VERSION, Perl $], $^X" );

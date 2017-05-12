#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'yEd::Document' ) || print "Bail out!\n";
}

diag( "Testing yEd::Document $yEd::Document::VERSION, Perl $], $^X" );


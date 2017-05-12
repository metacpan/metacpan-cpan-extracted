#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'WWW::Challonge' ) || print "Bail out!\n";
}

diag( "Testing WWW::Challonge $WWW::Challonge::VERSION, Perl $], $^X" );

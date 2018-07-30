#!perl -T
use 5.010001;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'WordPress::DBIC::Schema' ) || print "Bail out!\n";
}

diag( "Testing WordPress::DBIC::Schema $WordPress::DBIC::Schema::VERSION, Perl $], $^X" );

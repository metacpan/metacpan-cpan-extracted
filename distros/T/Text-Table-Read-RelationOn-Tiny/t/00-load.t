#!perl
use 5.010_001;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Text::Table::Read::RelationOn::Tiny' ) || print "Bail out!\n";
  }

diag( "Testing Text::Table::Read::RelationOn::Tiny $Text::Table::Read::RelationOn::Tiny::VERSION, Perl $], $^X" );



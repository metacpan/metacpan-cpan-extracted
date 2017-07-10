#!perl -T

use Test::More tests => 2;

BEGIN {
  use_ok( 'Text::Transliterator' )           || print "Bail out!\n";
  use_ok( 'Text::Transliterator::Unaccent' ) || print "Bail out!\n";
}

diag( "Testing Text::Transliterator $Text::Transliterator::VERSION, Perl $], $^X" );

#!perl -T

use Test::More tests => 3;

BEGIN {
    # TEST
    use_ok( 'XML::Grammar::Fortune::Synd' );
    # TEST
    use_ok( 'XML::Grammar::Fortune::Synd::Heap::Elem' );
    # TEST
    use_ok( 'XML::Grammar::Fortune::Synd::App' );
}

diag( "Testing XML::Grammar::Fortune::Synd $XML::Grammar::Fortune::Synd::VERSION, Perl $], $^X" );

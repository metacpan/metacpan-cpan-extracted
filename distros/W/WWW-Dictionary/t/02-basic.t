#!perl -T

use Test::More tests => 12;

BEGIN {
	use_ok( 'WWW::Dictionary' );
}

my  $dictionary = WWW::Dictionary->new();

is( $dictionary->get_expression, '' );

is( $dictionary->set_expression( 'new_expression' ), 'new_expression' );
is( $dictionary->get_expression, 'new_expression' );

    $dictionary = WWW::Dictionary->new( 'some_expression' );

is( $dictionary->get_expression, 'some_expression' );

is_deeply( $dictionary->get_dictionary, {} );

    $dictionary->reset_dictionary;

is_deeply( $dictionary->get_dictionary, {} );

is( $dictionary->set_meaning( ), undef );
is( $dictionary->set_meaning( 'a' ), undef );
is( $dictionary->set_meaning( 'a', 'b' ), 'b' );

is_deeply( $dictionary->get_dictionary, { 'a' => 'b' } );
 
    $dictionary->reset_dictionary;

is_deeply( $dictionary->get_dictionary, {} );

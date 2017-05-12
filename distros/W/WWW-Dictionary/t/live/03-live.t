#!perl -T

use Test::More tests => 6;

BEGIN {
	use_ok( 'WWW::Dictionary' );
}

my  $dictionary = WWW::Dictionary->new();

my $take = 'take in charge
v : accept as a charge [syn: undertake ]';

my $not_found = 'Entry not found';

is( $dictionary->set_expression( 'take in charge' ), 'take in charge' );

is( $dictionary->get_meaning, $take );

is( $dictionary->set_expression( 'module2' ), 'module2' );

is( $dictionary->get_meaning, $not_found );

is_deeply( $dictionary->get_dictionary, { 'take in charge' => $take, 'module2' => $not_found });



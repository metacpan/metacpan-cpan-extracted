#!perl -T

use Test::More tests => 7;

BEGIN {
	use_ok( 'WWW::Dictionary' );
}

my $dictionary = WWW::Dictionary->new();

isa_ok( $dictionary, WWW::Dictionary    );

can_ok( $dictionary, 'set_expression'   );
can_ok( $dictionary, 'get_expression'   );
can_ok( $dictionary, 'get_meaning'      );
can_ok( $dictionary, 'get_dictionary'   );
can_ok( $dictionary, 'reset_dictionary' );

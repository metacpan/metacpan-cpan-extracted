#!perl -T

use Test::More tests => 7;

BEGIN {
	use_ok( 'URI::crid' );
}

my $c = URI->new("crid://bbc.co.uk/b0074fly");

#scheme
is($c->scheme, 'crid');

#get
is($c->authority, 'bbc.co.uk');
is($c->data, 'b0074fly');

#set
is($c->authority('example.com'), 'example.com');
is($c->data('123'), '123');
is("$c", 'crid://example.com/123');


#!/usr/bin/env perl
use Test::Most;
use Test::Mock::Object::Chain qw(create_method_chain);

my $chain = create_method_chain( [ qw/foo bar baz/, 42 ] );
is $chain->foo->bar->baz, 42, 'We should be able to create method chains';

throws_ok { $chain->unknown }
qr/Unknown method 'unknown' called in method chain defined in Test::Mock::Object::Chain/,
  '... but our AUTOLOAD does not create unknown methods';

throws_ok { $chain->foo->baz->bar }
qr/Unknown method 'baz' called in method chain defined in Test::Mock::Object::Chain/,
  '... no matter how far down the chain it is';

$chain = create_method_chain( [ [ $chain, 'bar' ], 'this', 23 ] );
is $chain->bar->this, 23,
  'We should be able to add new links to an existing chain';

done_testing;

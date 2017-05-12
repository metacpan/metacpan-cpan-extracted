# -*- perl -*-

# t/003_store.t - unique functionality for references, custom function

use Test::More tests => 27;

BEGIN { use_ok( 'Tie::Hash::MultiValue' ); }

my $hash = {};

sub compare {
  $^W = 0;  # Forced conversion of non-numerics causes a warning; ignore it
  my ($foo, $bar) = @_;
  $foo == $bar;
}

my $object = tie %$hash, 'Tie::Hash::MultiValue', 'unique' => \&compare;
isa_ok($object, 'Tie::Hash::MultiValue');

my @keys;
@keys = keys %$hash;
is(scalar @keys, 0, 'empty hash has no keys');

$hash->{'foo'} = 1;
@keys = keys %$hash;
is(scalar @keys, 1, 'one item, one key');
is_deeply(\@keys, ['foo'], 'keys are as expected');

$hash->{'bar'} = 0;
@keys = keys %$hash;
is(scalar @keys, 2, 'two items, two keys');
@keys = sort @keys;
is_deeply(\@keys, ['bar','foo'], 'keys are still as expected');

$hash->{'foo'} = 3;
@keys = keys %$hash;
is(scalar @keys, 2, 'two items (one multiple), two keys');
@keys = sort @keys;
is_deeply(\@keys, ['bar','foo'], 'keys are still as expected');
is_deeply($hash->{'foo'}, [1,3], 'multivalue is as expected');
is_deeply($hash->{'bar'}, [0], 'single value as expected');
is($hash->{'baz'}, undef, 'empty hash element as expected');

delete $hash->{'foo'};
@keys = keys %$hash;
is(scalar @keys, 1, 'one item, one key again');
is_deeply(\@keys, ['bar'], 'keys are as expected');
is($hash->{'foo'}, undef, 'deleted item is as expected');
is_deeply($hash->{'bar'}, [0], 'single value as expected');
is($hash->{'baz'}, undef, 'empty hash element as expected');

$hash->{'bar'} = 2;
@keys = keys %$hash;
is(scalar @keys, 1, 'one item, one key again');
is_deeply(\@keys, ['bar'], 'keys are as expected');
is($hash->{'foo'}, undef, 'deleted item is as expected');
is_deeply($hash->{'bar'}, [0,2], 'two values as expected');
is($hash->{'baz'}, undef, 'empty hash element as expected');

$hash->{'bar'} = 'foo'; # numerically equal to zero, so won't be stored
@keys = keys %$hash;
is(scalar @keys, 1, 'one item, one key again');
is_deeply(\@keys, ['bar'], 'keys are as expected');
is($hash->{'foo'}, undef, 'deleted item is as expected');
is_deeply($hash->{'bar'}, [0,2], 'two values as expected');
is($hash->{'baz'}, undef, 'empty hash element as expected');




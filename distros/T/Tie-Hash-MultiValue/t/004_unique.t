# -*- perl -*-

# t/003_store.t - unique functionality for references, default function

use Test::More tests => 22;

BEGIN { use_ok( 'Tie::Hash::MultiValue' ); }

my $hash = {};

my $object = tie %$hash, 'Tie::Hash::MultiValue', 'unique';
isa_ok($object, 'Tie::Hash::MultiValue');

my @keys;
@keys = keys %$hash;
is(scalar @keys, 0, 'empty hash has no keys');

$hash->{'foo'} = 1;
@keys = keys %$hash;
is(scalar @keys, 1, 'one item, one key');
is_deeply(\@keys, ['foo'], 'keys are as expected');

$hash->{'bar'} = 2;
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
is_deeply($hash->{'bar'}, [2], 'single value as expected');
is($hash->{'baz'}, undef, 'empty hash element as expected');

delete $hash->{'foo'};
@keys = keys %$hash;
is(scalar @keys, 1, 'one item, one key again');
is_deeply(\@keys, ['bar'], 'keys are as expected');
is($hash->{'foo'}, undef, 'deleted item is as expected');
is_deeply($hash->{'bar'}, [2], 'single value as expected');
is($hash->{'baz'}, undef, 'empty hash element as expected');

$hash->{'bar'} = 2;
@keys = keys %$hash;
is(scalar @keys, 1, 'one item, one key again');
is_deeply(\@keys, ['bar'], 'keys are as expected');
is($hash->{'foo'}, undef, 'deleted item is as expected');
is_deeply($hash->{'bar'}, [2], 'still single value as expected');
is($hash->{'baz'}, undef, 'empty hash element as expected');


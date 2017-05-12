# -*- perl -*-

# t/006_listmode.t - 'iterators' functionality of multivalue hashes

use Test::More tests => 22;

BEGIN { use_ok( 'Tie::Hash::MultiValue' ); }

my $object = tie %hash, 'Tie::Hash::MultiValue';
isa_ok($object, 'Tie::Hash::MultiValue');
$object->iterators;
is $object->mode, 'iterators', 'in iterators mode';


my @keys;
@keys = keys %hash;
is(scalar @keys, 0, 'empty hash has no keys');

is_deeply $object->[1]->{iterators}, {}, 'no iterators yet';

$hash{'foo'} = 1;
@keys = keys %hash;
is(scalar @keys, 1, 'one item, one key');
is_deeply(\@keys, ['foo'], 'keys are as expected');

$hash{'bar'} = 2;
@keys = keys %hash;
is(scalar @keys, 2, 'two items, two keys');
@keys = sort @keys;
is_deeply(\@keys, ['bar','foo'], 'keys are still as expected');

$hash{'foo'} = 3;
@keys = keys %hash;
is(scalar @keys, 2, 'two items (one multiple), two keys');
@keys = sort @keys;
is_deeply(\@keys, ['bar','foo'], 'keys are still as expected');

is($hash{'foo'}, 1, 'first multivalue is as expected');
is($hash{'foo'}, 3, 'last multivalue is as expected');
is($hash{'foo'}, undef, 'no more multivalues is as expected');
is($hash{'bar'}, 2, 'single value as expected');
is($hash{'bar'}, undef, 'no more multivalues is as expected');
is($hash{'baz'}, undef, 'empty hash element as expected');

delete $hash{'foo'};
@keys = keys %hash;
is(scalar @keys, 1, 'one item, one key again');
is_deeply(\@keys, ['bar'], 'keys are as expected');
is($hash{'foo'}, undef, 'deleted item is as expected');
is($hash{'bar'}, 2, 'single value as expected');
is($hash{'bar'}, undef, 'out of values as expected');


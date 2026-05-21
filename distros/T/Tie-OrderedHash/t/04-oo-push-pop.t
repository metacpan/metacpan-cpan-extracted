#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use Tie::OrderedHash;

# OO interface: new / Push / Pop / Shift / Unshift round-trip.

my $oh = Tie::OrderedHash->new;
isa_ok($oh, 'Tie::OrderedHash');
is($oh->Length, 0, 'fresh oh is empty');

# Push.
is($oh->Push(a => 1, b => 2),         2, 'Push two pairs returns 2');
is($oh->Push(c => 3),                 3, 'Push one more returns 3');
is_deeply([$oh->Keys],   [qw(a b c)], 'Push: keys in source order');
is_deeply([$oh->Values], [1, 2, 3],   'Push: values match');

# Pop returns last (key, value), shrinks by one.
my @popped = $oh->Pop;
is_deeply(\@popped, ['c', 3], 'Pop returns (key, value) of last pair');
is($oh->Length, 2, 'Pop shrank by one');
is_deeply([$oh->Keys], [qw(a b)], 'Pop preserved remaining order');

# Shift returns first (key, value), shrinks by one.
my @shifted = $oh->Shift;
is_deeply(\@shifted, ['a', 1], 'Shift returns (key, value) of first pair');
is($oh->Length, 1, 'Shift shrank by one');
is_deeply([$oh->Keys], ['b'], 'Shift left only the trailing key');

# Pop / Shift on empty return empty list.
$oh->Shift;             # empty now
is_deeply([$oh->Pop],   [], 'Pop on empty: empty list');
is_deeply([$oh->Shift], [], 'Shift on empty: empty list');

# Unshift prepends, source order preserved.
$oh->Push(    last  => 'L');
$oh->Unshift(first  => 'F', second => 'S');
is_deeply([$oh->Keys], [qw(first second last)],
          'Unshift: prepended keys in source order');
is_deeply([$oh->Values], ['F', 'S', 'L'],
          'Unshift: prepended values match');

# Unshift of an existing key updates value, keeps position.
$oh->Unshift(last => 'OVERWRITTEN');
is_deeply([$oh->Keys], [qw(first second last)],
          'Unshift on existing key: position preserved');
is(($oh->Values)[2], 'OVERWRITTEN', 'Unshift on existing: value updated');

# Push of an existing key updates value, keeps position.
$oh->Push(first => 'CHANGED');
is_deeply([$oh->Keys], [qw(first second last)],
          'Push on existing key: position preserved');
is(($oh->Values)[0], 'CHANGED', 'Push on existing: value updated');

done_testing;

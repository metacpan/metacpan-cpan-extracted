#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use Tie::OrderedHash;

# Keys / Values: no-arg returns the full list; with indices, returns
# items at those positions.  Negative indices count from the end.

my $oh = Tie::OrderedHash->new(
    a => 1, b => 2, c => 3, d => 4, e => 5,
);

# No-arg.
is_deeply([$oh->Keys],   [qw(a b c d e)],     'Keys() no-arg');
is_deeply([$oh->Values], [1, 2, 3, 4, 5],     'Values() no-arg');

# Positive indices.
is_deeply([$oh->Keys(0, 2)],   ['a', 'c'],    'Keys(0, 2)');
is_deeply([$oh->Values(0, 2)], [1, 3],        'Values(0, 2)');

# Negative indices.
is(($oh->Keys(-1))[0],   'e', 'Keys(-1) is last');
is(($oh->Values(-1))[0], 5,   'Values(-1) is last');
is_deeply([$oh->Keys(-2, -1)],   ['d', 'e'],  'Keys(-2, -1)');
is_deeply([$oh->Values(-2, -1)], [4, 5],      'Values(-2, -1)');

# Out-of-range index returns undef.
is(($oh->Keys(99))[0],   undef, 'Keys(99) out of range');
is(($oh->Values(-99))[0], undef, 'Values(-99) out of range');

# Length matches scalar keys.
is($oh->Length, 5, 'Length: 5');

# Length on empty.
my $empty = Tie::OrderedHash->new;
is($empty->Length, 0, 'Length on empty: 0');

done_testing;

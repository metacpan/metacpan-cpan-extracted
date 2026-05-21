use strict;
use warnings;
use Test::More;
use Tie::OrderedHash;

# Keys(...) and Values(...) accept indices: positive, negative, mixed.
# Out-of-range indices return undef; the call doesn't croak.

my $obj = tie my %h, 'Tie::OrderedHash',
    one => 1, two => 2, three => 3, four => 4, five => 5;

# ---- positive indices ---------------------------------------------
is_deeply([$obj->Keys(0)],   ['one'],       'Keys(0) -> first key');
is_deeply([$obj->Keys(2)],   ['three'],     'Keys(2) -> middle key');
is_deeply([$obj->Keys(4)],   ['five'],      'Keys(4) -> last key');

is_deeply([$obj->Values(0)], [1],           'Values(0) -> first value');
is_deeply([$obj->Values(2)], [3],           'Values(2) -> middle value');
is_deeply([$obj->Values(4)], [5],           'Values(4) -> last value');

# ---- negative indices --------------------------------------------
is_deeply([$obj->Keys(-1)], ['five'],       'Keys(-1) -> last key');
is_deeply([$obj->Keys(-2)], ['four'],       'Keys(-2) -> penultimate');
is_deeply([$obj->Keys(-5)], ['one'],        'Keys(-5) -> first');

is_deeply([$obj->Values(-1)], [5],          'Values(-1) -> last');
is_deeply([$obj->Values(-2)], [4],          'Values(-2) -> penultimate');
is_deeply([$obj->Values(-5)], [1],          'Values(-5) -> first');

# ---- mixed positive + negative ----------------------------------
is_deeply([$obj->Keys(0, -1, 2, -2)],
          ['one', 'five', 'three', 'four'],
          'Keys() mixed pos+neg in argument order');
is_deeply([$obj->Values(0, -1, 2, -2)],
          [1, 5, 3, 4],
          'Values() mixed pos+neg in argument order');

# ---- out-of-range returns undef (does not croak) ----------------
is_deeply([$obj->Keys(99)],     [undef],    'Keys(99) -> undef (positive OOB)');
is_deeply([$obj->Keys(-99)],    [undef],    'Keys(-99) -> undef (negative OOB)');
is_deeply([$obj->Keys(5)],      [undef],    'Keys(5) -> undef (just past end)');
is_deeply([$obj->Keys(-6)],     [undef],    'Keys(-6) -> undef (just before start)');

is_deeply([$obj->Values(99)],   [undef],    'Values(99) -> undef');
is_deeply([$obj->Values(-99)],  [undef],    'Values(-99) -> undef');

# ---- mixed valid + OOB returns aligned slot per arg -------------
is_deeply([$obj->Keys(0, 99, -1, -99)],
          ['one', undef, 'five', undef],
          'mixed valid + OOB: per-arg alignment preserved');

# ---- repeated indices -------------------------------------------
is_deeply([$obj->Keys(2, 2, 2)],
          ['three', 'three', 'three'],
          'repeated index returns repeated key');

# ---- no-arg returns full list in order ---------------------------
is_deeply([$obj->Keys],   [qw(one two three four five)],
          'Keys() with no args returns full list');
is_deeply([$obj->Values], [1, 2, 3, 4, 5],
          'Values() with no args returns full list');

# ---- count reflects pre-call state -------------------------------
is($obj->Length, 5,    'Length unchanged by Keys/Values calls');

# ---- after a Pop the negative indices shift ---------------------
$obj->Pop;     # removes 'five'
is($obj->Length, 4, 'Length after Pop = 4');
is_deeply([$obj->Keys(-1)], ['four'],
          'Keys(-1) tracks the new tail after Pop');
is_deeply([$obj->Keys(4)],  [undef],
          'Old positive index (4) is now OOB after Pop');

done_testing;

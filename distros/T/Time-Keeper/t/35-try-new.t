#!perl
use 5.010;
use strict;
use warnings;
use Test::More;

use Time::Keeper;

my $K = 'Time::Keeper';

$@ = 'left as it was';
my $t = $K->try_new(year => 2026, month => 2, day => 30);
ok(!defined $t, 'try_new gives undef where new would die');
is($@, 'left as it was', 'and leaves $@ alone');
is($K->try_new(year => 2026, month => 2, day => 28) . '', '2026-02-28T00:00:00Z', 'and the value where new would give one');
is($K->try_new(year => 2026, month => 10, day => 15, hour => 9, zone => 'Asia/Tokyo')->zone_name, 'Asia/Tokyo', 'with every argument new takes');
ok(!defined $K->try_new(year => 2026, month => 3, day => 8, hour => 2, minute => 30, zone => 'America/New_York'), 'a time in a gap');
is($K->try_new(year => 2026, month => 3, day => 8, hour => 2, minute => 30, zone => 'America/New_York', gap => 'forward') . '',
   '2026-03-08T03:30:00-04:00', 'unless told what to do');
ok(!defined $K->try_new(month => 1), 'no year');
ok(!defined $K->try_new(year => 2026, colour => 'red'), 'an argument new does not know');
ok(!defined $K->try_new(year => 2026, 'odd'), 'an odd number of arguments');
is($@, 'left as it was', '$@ still as it was after all that');

my $v = $K->new(year => 2026, month => 1, day => 31, hour => 9);
ok(!defined $v->try_with(month => 2), 'try_with gives undef where with would die: 31 February');
is($v->try_with(month => 2, day => 'last') . '', '2026-02-28T09:00:00Z', 'and the value where with would give one');
is($v->try_with(hour => 12) . '', '2026-01-31T12:00:00Z', 'a plain change');
ok(!defined $v->try_with(hour => 25), 'an hour out of range');
ok(!defined $v->try_with(zone => 'UTC'), 'an argument with does not take');
is($@, 'left as it was', '$@ untouched by try_with');

# An error inside is caught, not just ours.
ok(!defined $K->try_new(year => []), 'a reference for a year');
is($@, 'left as it was', 'and $@ is still untouched');

done_testing;

#!perl
use 5.010;
use strict;
use warnings;
use Test::More;

use Time::Keeper;

sub civil { [Time::Keeper::_civil_from_instant(@_)] }

is_deeply(civil(0, 0), [1970, 1, 1, 0, 0, 0, 0, 4, 1], 'second 0 is the start of 1970');
is_deeply(civil(-1, 0), [1969, 12, 31, 23, 59, 59, 0, 3, 365], 'second -1 is the last of 1969');
is_deeply(civil(-1, 500_000_000), [1969, 12, 31, 23, 59, 59, 500_000_000, 3, 365],
          'half a second before 1970 is second -1 and half a second');
is_deeply(civil(-86400, 0), [1969, 12, 31, 0, 0, 0, 0, 3, 365], 'a whole day before is midnight');
is_deeply(civil(-86401, 0), [1969, 12, 30, 23, 59, 59, 0, 2, 364], 'and one second more is the day before');
is_deeply(civil(951_782_400, 0), [2000, 2, 29, 0, 0, 0, 0, 2, 60], '2000-02-29');
is_deeply(civil(2_147_483_647, 0), [2038, 1, 19, 3, 14, 7, 0, 2, 19], 'the last second a 32-bit time_t holds');
is_deeply(civil(2_147_483_648, 0), [2038, 1, 19, 3, 14, 8, 0, 2, 19], 'and the one after it');
is_deeply(civil('4102444800', 999_999_999), [2100, 1, 1, 0, 0, 0, 999_999_999, 5, 1],
          'seconds given as a string');
is_deeply(civil('-62135596800', 0), [1, 1, 1, 0, 0, 0, 0, 1, 1], '0001-01-01');
is_deeply(civil('-62167219200', 0), [0, 1, 1, 0, 0, 0, 0, 6, 1], '0000-01-01, a Saturday');

my (undef, undef, $smin, $smax) = Time::Keeper::_range();
is($smax, '31556889832780799', 'the last second of the range');
is($smin, '-31557014135596800', 'the first');
is_deeply(civil($smax, 999_999_999), [999_999_999, 12, 31, 23, 59, 59, 999_999_999, 5, 365],
          'the last nanosecond is the end of the last year');
is_deeply(civil($smin, 0), [-999_999_999, 1, 1, 0, 0, 0, 0, 1, 1], 'the first is the start of the first');
ok(!eval { civil('31556889832780800', 0); 1 }, 'one second past the end is refused');
like($@, qr/^instant out of range/, 'by name');
ok(!eval { civil('-31557014135596801', 0); 1 }, 'as is one before the start');
ok(!eval { civil(0, -1); 1 }, 'a negative nanosecond is refused');
ok(!eval { civil(0, 1_000_000_000); 1 }, 'as is a whole second of them');
ok(!eval { civil(0, -1_000_000_000); 1 }, 'and minus a whole second');
ok(!eval { civil(0, 4_294_967_296); 1 }, 'and a count of them past 32 bits');
ok(!eval { civil('9223372036854775808', 0); 1 }, 'a number past 64 bits is refused');
like($@, qr/^seconds is not an integer/, 'as not an integer');
ok(!eval { civil(1.5, 0); 1 }, 'as is a fraction');

sub instant { [Time::Keeper::_instant_from_civil(@_)] }

is_deeply(instant(1970, 1, 1, 0, 0, 0, 0), [0, 0], 'the start of 1970 is second 0');
is_deeply(instant(1969, 12, 31, 23, 59, 59, 500_000_000), [-1, 500_000_000], 'and back');
is_deeply(instant(2038, 1, 19, 3, 14, 8, 0), [2_147_483_648, 0], 'past 2038');
is_deeply(instant(999_999_999, 12, 31, 23, 59, 59, 999_999_999), [$smax, 999_999_999], 'the last moment');
ok(!eval { instant(2026, 10, 15, 24, 0, 0, 0); 1 }, 'hour 24 is refused');
ok(!eval { instant(2026, 10, 15, 0, 60, 0, 0); 1 }, 'minute 60');
ok(!eval { instant(2026, 10, 15, 0, 0, 60, 0); 1 }, 'second 60 on a day with no leap second');
ok(!eval { instant(2026, 2, 29, 0, 0, 0, 0); 1 }, 'a day that does not exist');

# Against perl's own gmtime, which has worked out dates on its own since 5.12.
SKIP: {
    skip 'perl\'s gmtime is the system\'s before 5.12', 2 if $] < 5.012;
    srand(20261015);
    my ($bad, $badback) = (0, 0);
    for (1 .. 20_000) {
        my $s = int(rand(2 * 200_000_000_000)) - 200_000_000_000;
        my @g = gmtime($s);
        my $want = join ',', $g[5] + 1900, $g[4] + 1, @g[3, 2, 1, 0], 0, ($g[6] || 7), $g[7] + 1;
        my $got = join ',', Time::Keeper::_civil_from_instant($s, 0);
        my $back = (Time::Keeper::_instant_from_civil($g[5] + 1900, $g[4] + 1, @g[3, 2, 1, 0], 0))[0];
        if ($got ne $want) {
            diag("$s: got $got, gmtime says $want") if $bad < 5;
            $bad++;
        }
        if ($back ne $s) {
            diag("$s: came back as $back") if $badback < 5;
            $badback++;
        }
    }
    is($bad, 0, '20,000 random instants across 12,000 years agree with gmtime');
    is($badback, 0, 'and come back to the same second');
}

{
    my @c;
    @c = Time::Keeper::_day_numbers(0, 0);
    is_deeply([@c[0 .. 2]], [719163, 0, 0], 'Rata Die of 1970-01-01');
    is_deeply([@c[3, 5]], [2440587, 40587], 'its Julian Day and Modified Julian Day');
    is($c[4], 0.5, 'midnight is half way through a Julian Day');
    is($c[6], 0, 'and the start of an MJD');

    @c = Time::Keeper::_day_numbers(946_728_000, 0);
    is($c[3] + $c[4], 2451545, '2000-01-01T12:00:00 is JD 2451545.0, the J2000 epoch');

    @c = Time::Keeper::_day_numbers('-3506716800', 0);
    is($c[5] + $c[6], 0, '1858-11-17 is MJD 0');

    @c = Time::Keeper::_day_numbers('-62135596800', 0);
    is($c[0], 1, '0001-01-01 is Rata Die 1');

    @c = Time::Keeper::_day_numbers(-1, 500_000_000);
    is_deeply([@c[0 .. 2]], [719162, 86399, 500_000_000], 'Rata Die before 1970 counts into the day');

    @c = Time::Keeper::_day_numbers(43_200, 0);
    is_deeply([$c[3], $c[4]], [2440588, 0], 'noon starts a new Julian Day');
}

done_testing;

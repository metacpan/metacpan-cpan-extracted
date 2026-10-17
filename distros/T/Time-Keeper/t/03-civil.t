#!perl
use 5.010;
use strict;
use warnings;
use Test::More;

use Time::Keeper;

my ($ymin, $ymax) = Time::Keeper::_range();
is($ymin, -999_999_999, 'the first year');
is($ymax,  999_999_999, 'the last year');

is(Time::Keeper::_days_from_civil(1970, 1, 1), 0, '1970-01-01 is day 0');
is(Time::Keeper::_days_from_civil(1970, 1, 2), 1, 'and the day after is day 1');
is(Time::Keeper::_days_from_civil(1969, 12, 31), -1, 'and the day before is day -1');
is(Time::Keeper::_days_from_civil(2000, 3, 1), 11017, '2000-03-01');
is(Time::Keeper::_days_from_civil(1, 1, 1), -719162, '0001-01-01');
is(Time::Keeper::_days_from_civil(0, 3, 1), -719468, '0000-03-01, the start of the algorithm\'s eras');
is(Time::Keeper::_days_from_civil(-1, 12, 31), -719529, '-0001-12-31, the day before 0000-01-01');

is_deeply([Time::Keeper::_civil_from_days(0)], [1970, 1, 1, 4, 1], 'day 0 is Thursday 1 January 1970, day 1 of its year');
is_deeply([Time::Keeper::_civil_from_days(-1)], [1969, 12, 31, 3, 365], 'day -1 is Wednesday 31 December 1969');
is_deeply([Time::Keeper::_civil_from_days(-719468)], [0, 3, 1, 3, 61], '0000-03-01: year 0 is a leap year');

for my $c ([2000, 1], [2024, 1], [1600, 1], [0, 1], [-4, 1], [-400, 1],
           [1900, 0], [2100, 0], [2023, 0], [-1, 0], [-100, 0]) {
    my ($y, $leap) = @$c;
    is(Time::Keeper::_is_leap_year($y), $leap, "$y is " . ($leap ? '' : 'not ') . 'a leap year');
}

is(Time::Keeper::_days_in_month(2000, 2), 29, 'February 2000 has 29 days');
is(Time::Keeper::_days_in_month(1900, 2), 28, 'February 1900 has 28');
is(Time::Keeper::_days_in_month(2026, $_), 31, "month $_ has 31") for 1, 3, 5, 7, 8, 10, 12;
is(Time::Keeper::_days_in_month(2026, $_), 30, "month $_ has 30") for 4, 6, 9, 11;

ok(eval { Time::Keeper::_days_from_civil(2000, 2, 29); 1 }, '2000-02-29 exists');
ok(!eval { Time::Keeper::_days_from_civil(1900, 2, 29); 1 }, '1900-02-29 does not');
like($@, qr/^no such date/, 'and says so');
ok(!eval { Time::Keeper::_days_from_civil(2026, 13, 1); 1 }, 'month 13 does not');
ok(!eval { Time::Keeper::_days_from_civil(2026, 0, 1); 1 }, 'month 0 does not');
ok(!eval { Time::Keeper::_days_from_civil(2026, 4, 31); 1 }, '31 April does not');
ok(!eval { Time::Keeper::_days_from_civil(2026, 4, 0); 1 }, 'day 0 does not');
ok(!eval { Time::Keeper::_days_from_civil(1_000_000_000, 1, 1); 1 }, 'a year past the last does not');
ok(!eval { Time::Keeper::_days_from_civil(-1_000_000_000, 1, 1); 1 }, 'nor a year before the first');
ok(!eval { Time::Keeper::_days_from_civil(2026.5, 1, 1); 1 }, 'a fractional year is refused');
like($@, qr/^year is not an integer/, 'by name');

{
    my ($n, $bad) = Time::Keeper::_civil_sweep(-4800, 4800);
    is($n, 3_506_694, 'every day from -4800-01-01 to 4800-12-31 walked');
    is($bad, 0, 'and every one converts both ways and has its weekday');
}
{
    my ($n, $bad) = Time::Keeper::_civil_sweep(999_999_000, 999_999_999);
    is($bad, 0, 'the last thousand years too');
    ($n, $bad) = Time::Keeper::_civil_sweep(-999_999_999, -999_999_000);
    is($bad, 0, 'and the first thousand');
}

my $last = Time::Keeper::_days_from_civil(999_999_999, 12, 31);
is_deeply([(Time::Keeper::_civil_from_days($last))[0 .. 2]], [999_999_999, 12, 31], 'the last day round-trips');
ok(!eval { Time::Keeper::_civil_from_days($last + 1); 1 }, 'and the day after it is refused');
my $first = Time::Keeper::_days_from_civil(-999_999_999, 1, 1);
ok(!eval { Time::Keeper::_civil_from_days($first - 1); 1 }, 'as is the day before the first');

{
    my $days = Time::Keeper::_days_from_civil(1, 1, 1);
    my @c = Time::Keeper::_civil_from_days($days);
    is($c[3], 1, '0001-01-01 was a Monday, proleptically');
}

done_testing;

#!perl
use 5.010;
use strict;
use warnings;
use Test::More;

use Time::Keeper;

my $K = 'Time::Keeper';

# Values made without a named zone do not load the zones.
{
    my $t = $K->now;
    my $u = $K->new(year => 2026, zone => '+05:30');
    my $f = $K->new(year => 2026, zone => 'floating');
    my $g = $K->from_epoch(0, zone => 'GMT');
    my $x = $t->in_zone('Z')->with(day => 2);
    ok(!$INC{'Time/Keeper/Zone.pm'}, 'UTC, fixed offsets and floating time never load the zones');
}

isa_ok($K->now, $K);
is($K->now->zone_name, 'UTC', 'now is in UTC when no zone is given');
cmp_ok(abs($K->now->epoch - time), '<=', 1, 'now is now');

{
    my $t = $K->new(year => 2026);
    is("$t", '2026-01-01T00:00:00Z', 'new with only a year is midnight on 1 January, UTC');
    $t = $K->new(year => 2026, month => 10, day => 15, hour => 9, minute => 30, second => 15, nanosecond => 250_000_000);
    is("$t", '2026-10-15T09:30:15.250Z', 'every field');
    is($K->new(year => -44, month => 3, day => 15)->year, -44, 'a year before Christ');
    is($K->new(year => 0, month => 2, day => 29)->day, 29, 'year 0 is a leap year');
}

sub dies_like {
    my ($code, $re, $name) = @_;
    my $ok = eval { $code->(); 1 };
    ok(!$ok && $@ =~ $re, $name) or diag($ok ? 'it did not die' : "died with: $@");
}

dies_like(sub { $K->new }, qr/^Time::Keeper->new: year is required/, 'new without a year');
dies_like(sub { $K->new(year => 2026, month => 13) }, qr/^Time::Keeper->new: month 13 is out of range/, 'month 13');
dies_like(sub { $K->new(year => 2026, month => 0) }, qr/month 0 is out of range/, 'month 0');
dies_like(sub { $K->new(year => 2026, month => 2, day => 29) }, qr/2026-02 has no day 29/, '29 February in a common year');
dies_like(sub { $K->new(year => 2026, month => 4, day => 31) }, qr/2026-04 has no day 31/, '31 April');
dies_like(sub { $K->new(year => 2026, hour => 24) }, qr/hour 24 is out of range/, 'hour 24');
dies_like(sub { $K->new(year => 2026, minute => 60) }, qr/minute 60 is out of range/, 'minute 60');
dies_like(sub { $K->new(year => 2026, second => 61) }, qr/second 61 is out of range/, 'second 61');
dies_like(sub { $K->new(year => 2026, nanosecond => 1_000_000_000) }, qr/nanosecond 1000000000 is out of range/, 'a whole second of nanoseconds');
dies_like(sub { $K->new(year => 1_000_000_000) }, qr/year 1000000000 is out of range/, 'a year past the last');
dies_like(sub { $K->new(year => 2026.5) }, qr/year is not an integer/, 'a fractional year');
dies_like(sub { $K->new(year => 2026, colour => 'red') }, qr/unknown argument 'colour'/, 'an argument it does not know');
dies_like(sub { $K->new(year => 2026, year => 2027) }, qr/year given twice/, 'an argument given twice');
dies_like(sub { $K->new(year => 2026, 'month') }, qr/name => value pairs/, 'an odd number of arguments');
dies_like(sub { $K->new(year => 2026, day_of_year => 3) }, qr/unknown argument 'day_of_year'/, 'another constructor\'s argument');
dies_like(sub { $K->now(year => 2026) }, qr/^Time::Keeper->now: unknown argument 'year'/, 'now takes only a zone');

is($K->last_day_of_month(year => 2028, month => 2)->day, 29, 'last_day_of_month in a leap February');
is($K->last_day_of_month(year => 2100, month => 2)->day, 28, 'and in 2100');
is($K->last_day_of_month(year => 2026, month => 12, hour => 23)->hour, 23, 'with a time');
dies_like(sub { $K->last_day_of_month(year => 2026) }, qr/month is required/, 'last_day_of_month needs a month');
dies_like(sub { $K->last_day_of_month(year => 2026, month => 1, day => 3) }, qr/unknown argument 'day'/, 'and takes no day');

is("" . $K->from_day_of_year(year => 2026, day_of_year => 288), '2026-10-15T00:00:00Z', 'from_day_of_year');
is($K->from_day_of_year(year => 2024, day_of_year => 366)->day, 31, 'day 366 of a leap year');
dies_like(sub { $K->from_day_of_year(year => 2026, day_of_year => 366) }, qr/2026 has no day 366/, 'and not of a common one');
dies_like(sub { $K->from_day_of_year(year => 2026) }, qr/day_of_year is required/, 'from_day_of_year needs the day');

is("" . $K->from_iso_week(year => 2026, week => 42, day => 4), '2026-10-15T00:00:00Z', 'from_iso_week');
is("" . $K->from_iso_week(year => 2026, week => 1), '2025-12-29T00:00:00Z', 'week 1 of 2026 starts in 2025');
is("" . $K->from_iso_week(year => 2026, week => 53, day => 7), '2027-01-03T00:00:00Z', '2026 has a week 53, ending in 2027');
dies_like(sub { $K->from_iso_week(year => 2025, week => 53) }, qr/2025 has 52 ISO weeks, not 53/, '2025 does not');
dies_like(sub { $K->from_iso_week(year => 2026, week => 1, day => 8) }, qr/day 8 is out of range/, 'day 8 of a week');

is($K->from_epoch(0)->iso8601, '1970-01-01T00:00:00Z', 'from_epoch 0');
is($K->from_epoch(-1)->iso8601, '1969-12-31T23:59:59Z', 'from_epoch -1');
is($K->from_epoch('1760000000.123456789')->nanosecond, 123_456_789, 'a string epoch is exact to the nanosecond');
is($K->from_epoch('-0.25')->iso8601, '1969-12-31T23:59:59.750Z', 'a negative fraction in a string');
is($K->from_epoch(1760000000.123456789)->nanosecond, 123_457_000, 'a number is rounded to the microsecond');
is($K->from_epoch(-0.5)->iso8601, '1969-12-31T23:59:59.500Z', 'a negative number');
is($K->from_epoch(1.9999996)->iso8601, '1970-01-01T00:00:02Z', 'rounding up carries into the second');
dies_like(sub { $K->from_epoch('1.1234567891') }, qr/at most nine decimal places/, 'ten decimal places');
dies_like(sub { $K->from_epoch('12abc') }, qr/'12abc' is not a number/, 'not a number');
dies_like(sub { $K->from_epoch('9223372036854775807') }, qr/out of range/, 'past the range');
dies_like(sub { $K->from_epoch(9**9**9) }, qr/out of range/, 'infinity');

is($K->new(year => 2026, nanosecond => 100_000)->iso8601, '2026-01-01T00:00:00.000100Z', 'a fraction in six digits');
is($K->new(year => 2026, nanosecond => 100)->iso8601, '2026-01-01T00:00:00.000000100Z', 'and in nine');
is($K->new(year => 12026)->iso8601, '+012026-01-01T00:00:00Z', 'a five-digit year in the expanded form');
is($K->new(year => -1)->iso8601, '-000001-01-01T00:00:00Z', 'and a year before 0');
is($K->new(year => 9999)->iso8601, '9999-01-01T00:00:00Z', 'but 9999 in four');
is($K->new(year => 2026, zone => '+05:45:30')->iso8601, '2026-01-01T00:00:00+05:45:30', 'an offset with seconds keeps them');
for my $s ('', '-', '.', '-.') {
    ok(!eval { $K->from_epoch($s); 1 }, "from_epoch('$s') is refused");
}
is($K->new(year => 2016, month => 12, day => 31, hour => 23, minute => 59, second => 60, nanosecond => 5)->epoch,
   1483228800, 'the epoch of a leap second is the midnight after it');

is($K->max->iso8601, '+999999999-12-31T23:59:59.999999999Z', 'max');
is($K->min->iso8601, '-999999999-01-01T00:00:00Z', 'min');
ok($K->min < $K->max, 'and min is before max');

done_testing;

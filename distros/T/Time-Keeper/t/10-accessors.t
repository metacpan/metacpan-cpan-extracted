#!perl
use 5.010;
use strict;
use warnings;
use Test::More;

use Time::Keeper;

my $K = 'Time::Keeper';
my $t = $K->new(year => 2026, month => 10, day => 15, hour => 9, minute => 30, second => 15,
                nanosecond => 123_456_789);

my %want = (
    year => 2026, month => 10, day => 15, hour => 9, minute => 30, second => 15,
    nanosecond => 123_456_789, microsecond => 123_456, millisecond => 123,
    day_of_week => 4, day_of_year => 288, quarter => 4, day_of_quarter => 15,
    week => 42, week_year => 2026, week_of_month => 3, is_leap_year => 0,
    days_in_month => 31, offset => 0, is_dst => 0, is_utc => 1, is_floating => 0,
);
is($t->$_, $want{$_}, "$_ is $want{$_}") for sort keys %want;

is($t->zone_name, 'UTC', 'zone_name');
is($t->zone_abbr, 'UTC', 'zone_abbr');
is($t->locale, 'en', 'locale');
is($t->epoch, 1792056615, 'epoch');
is($t->epoch_string, '1792056615.123456789', 'epoch_string, exact');
cmp_ok(abs($t->hires_epoch - 1792056615.123456789), '<', 1e-6, 'hires_epoch');
cmp_ok(abs($t->julian_day - (2461328.5 + (9 * 3600 + 30 * 60 + 15.123456789) / 86400)), '<', 1e-8, 'julian_day');
cmp_ok(abs($t->mjd - $t->julian_day + 2400000.5), '<', 1e-8, 'mjd is the Julian Day less 2400000.5');
is($t->tai_offset, 37, 'tai_offset');

is($K->from_epoch(0)->epoch_string, '0', 'epoch_string of 0');
is($K->from_epoch('-0.5')->epoch_string, '-0.5', 'epoch_string of half a second before 1970');
is($K->from_epoch('-1.25')->epoch_string, '-1.25', 'and a second and a quarter');
is($K->from_epoch('-2')->epoch_string, '-2', 'and two whole seconds');
{
    srand(6);
    my $bad = 0;
    for (1 .. 2000) {
        my $s = (rand() < .5 ? '-' : '') . int(rand(1e11)) . (rand() < .8 ? '.' . int(rand(1e9)) : '');
        my $back = $K->from_epoch($K->from_epoch($s)->epoch_string);
        $bad++ unless $back == $K->from_epoch($s);
    }
    is($bad, 0, 'epoch_string reads back as the same instant, for 2,000 random epochs either side of 1970');
}
is($K->from_epoch('12.5')->epoch_string, '12.5', 'trailing zeros dropped');
is($K->from_epoch('-62135596800')->year, 1, 'year 1');

{
    my $u = $K->new(year => 2027, month => 1, day => 1);
    is_deeply([$u->week_year, $u->week], [2026, 53], '1 January 2027 is in week 53 of 2026');
    is($K->new(year => 2024, month => 2, day => 29)->is_leap_year, 1, '2024 is a leap year');
    is($K->new(year => 2024, month => 2)->days_in_month, 29, 'with 29 days in February');
}

# The date fields are worked out when first read, and kept.
{
    my $v = $K->from_epoch(1792056615);
    is(Time::Keeper::_flags($v) & 1, 0, 'a new value has not worked out its date');
    my $e = $v->epoch;
    is(Time::Keeper::_flags($v) & 1, 0, 'nor after epoch, which does not need it');
    my $y = $v->year;
    is(Time::Keeper::_flags($v) & 1, 1, 'it has after year');
    is($v->month, 10, 'and the other fields come from what was kept');
}

ok(!eval { Time::Keeper::year('not a value'); 1 }, 'an accessor on something that is not a value');
like($@, qr/not a Time::Keeper value/, 'says so');

done_testing;

#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use Time::Keeper;

# The calendar's fields are computed once and kept in the value (R14a, ruled
# 18 Oct 2026). What must still hold: a copy that reads another calendar,
# another zone or another instant answers for itself, not from the copied
# cache; a read before and after any other read agrees with a fresh value;
# the struct grew by one packed block only.

my $K = 'Time::Keeper';
my @layout = Time::Keeper::_value_layout();
is(scalar @layout, 6, 'the layout door reports the cache offset and the size');
cmp_ok($layout[5], '<=', 72, 'a value is at most 72 bytes') or diag("size $layout[5]");
cmp_ok($layout[4], '>', $layout[3], 'the cache follows the civil fields');

my $t = $K->new(year => 2026, month => 10, day => 15, hour => 23, minute => 30, zone => 'UTC');
my $h = $t->in_calendar('hebrew');
is($h->month, 2, 'Heshvan, the first read fills the cache');
is($h->day, 4, 'the second read is from it');
my $c = $h->in_calendar('chinese');
is($c->month . ' ' . $c->day, '9 6', 'in_calendar after a read: the new calendar\'s fields, not the cached Hebrew ones');
is($c->in_calendar('hebrew')->day, 4, 'and back');
is($h->in_calendar('gregory')->month, 10, 'back to the Gregorian');
my $tokyo = $h->in_zone('Asia/Tokyo');
is($tokyo->day, 5, 'in_zone after a read: 23:30 UTC is the next day in Tokyo, read afresh');
is($h->day, 4, 'the original is untouched');
is($h->in_locale('he')->month, 2, 'in_locale keeps the fields, which do not depend on the locale');
is($h->in_locale('th-u-ca-buddhist')->year, 2569, 'in_locale with an extension reads the new calendar');
is($h->plus(days => 30)->month, 3, 'arithmetic from a read value gives a fresh one');
is($h->with(day => 1)->day, 1, 'with too');
is($h->truncate(to => 'month')->day, 1, 'truncate too');
my $u = $K->new(year => 2026, month => 10, day => 15, hour => 23, minute => 30, zone => 'UTC')->in_calendar('hebrew');
for my $m (qw(year month day era era_year month_code is_leap_month months_in_year days_in_month days_in_year day_of_year is_leap_year related_year quarter)) {
    is($h->$m, $u->$m, "$m agrees between a read value and a fresh one");
}
is($h->format('G y M d, D F'), $u->format('G y M d, D F'), 'formatting agrees');
is($h->strftime('%Y-%m-%d %j'), $u->strftime('%Y-%m-%d %j'), 'strftime agrees');

# the leap flags and the thirteenth month survive the packing
my $leap = $K->new(year => 2024, month => 3, day => 11, zone => 'UTC')->in_calendar('hebrew');
is($leap->month_code . ' ' . $leap->is_leap_year . ' ' . $leap->months_in_year . ' ' . $leap->days_in_year, 'M06 1 13 383', 'Adar II 5784 from the cache');
my $cl = $K->new(year => 2025, month => 7, day => 25, zone => 'UTC')->in_calendar('chinese');
is($cl->month_code . ' ' . $cl->is_leap_month . ' ' . $cl->month, 'M06L 1 7', 'the Chinese leap month from the cache');
is($cl->in_calendar('dangi')->month_code, 'M06L', 'dangi too');

# the serialisers carry the instant, not the cache
my $thawed = $K->THAW('any', $h->FREEZE('any'));
is($thawed->month . ' ' . $thawed->day, '2 4', 'a thawed value reads afresh');
is($thawed->in_calendar('chinese')->day, 6, 'and converts');

# the far end of the years still fits the packed cache: a date read there
# makes the same instant again (the calendars drift from the Gregorian by
# thousands of years over a thousand million, so no number is pinned)
for my $y (999_000_000, -999_000_000) {
    my $far = $K->new(year => $y, month => 6, day => 15, zone => 'UTC');
    for my $cal (qw(buddhist japanese coptic hebrew persian indian)) {
        my $r = $far->in_calendar($cal);
        my $back = $K->new(year => $r->year, month => $r->month, day => $r->day, calendar => $cal, zone => 'UTC');
        is($back->epoch, $far->epoch, "$cal in the year $y: the cached fields make the day again");
        cmp_ok(abs($r->year - $y), '<', 30_000_000, "and the year is of the right size") if $cal ne 'japanese';
    }
}

done_testing;

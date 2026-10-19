#!perl
use 5.010;
use strict;
use warnings;
use Test::More;

use Time::Keeper;
use Time::Keeper::Business;

my $C = 'Time::Keeper::Business';
my $R = 'Time::Keeper::Business::Rule';
sub d { Time::Keeper::Date->parse($_[0]) }
sub ds { [map { "$_" } @_] }

my $uk  = $C->new(holidays => $R->uk, weekend => 'en-GB', name => 'uk');
my $lit = $C->new(holidays => { '2026-12-25' => 'Christmas Day', '2026-12-28' => 'Boxing Day', '2027-01-01' => "New Year's Day" });
my $plain = $C->new;

for my $b ($uk, $lit) {
    is($b->plus_business_days(d('2026-12-18'), 10) . '', '2027-01-06', "ten business days from Friday 18 December 2026 is Wednesday 6 January ($b)");
    is($b->next_business_day(d('2026-12-24')) . '', '2026-12-29', '  the next after Christmas Eve is the 29th');
    is($b->previous_business_day(d('2026-12-29')) . '', '2026-12-24', '  and back');
    is($b->business_days_between(d('2026-12-18'), d('2027-01-06')), 10, '  between counts ten, half-open');
    is($b->business_days_between(d('2026-12-18'), d('2027-01-06'), include_end => 1), 11, '  eleven with the end');
}

# roll from a closed day, n of zero, negatives
is($plain->plus_business_days(d('2026-12-19'), 1) . '', '2026-12-22', 'from a Saturday, one business day on is Tuesday: Monday first, then one');
is($plain->plus_business_days(d('2026-12-19'), 0) . '', '2026-12-21', 'n of zero is the roll');
is($plain->plus_business_days(d('2026-12-19'), -1) . '', '2026-12-17', 'from a Saturday, one back is Thursday: Friday first, then one');
is($plain->plus_business_days(d('2026-12-19'), 0, roll => 'preceding') . '', '2026-12-18', 'roll names the start');
is($plain->plus_business_days(d('2026-12-19'), 2, roll => 'preceding') . '', '2026-12-22', '  so two on from a Saturday by preceding is Tuesday');
is($plain->minus_business_days(d('2026-12-22'), 2) . '', '2026-12-18', 'minus is plus of the negative');
is($plain->plus_business_days(d('2026-12-21'), -1) . '', '2026-12-18', 'back over a weekend');
is($plain->plus_business_days(d('2026-12-21'), 5) . '', '2026-12-28', 'a week on is the Monday after');
is($plain->plus_business_days(d('2026-12-21'), 260) . '', '2027-12-20', '260 business days is 52 weeks');
is($plain->plus_business_days(d('2026-12-21'), -260) . '', '2025-12-22', '  either way');
is($plain->plus_business_days(d('2026-12-21'), 2600) . '', '2036-12-08', 'ten years of business days: 520 weeks is 3,640 days');
ok(!eval { $plain->plus_business_days(d('2026-12-21'), 'x'); 1 }, 'a count that is not a number is refused');
like($@, qr/^Time::Keeper::Business->plus_business_days: the number of days is not a whole number/, '  by name');
ok(!eval { $plain->plus_business_days(d('2026-12-21'), 1, foo => 1); 1 }, 'an unknown option is refused');
like($@, qr/unknown argument 'foo'/, '  by name');
ok(!eval { $plain->plus_business_days(d('2026-12-21'), 1, roll => 'sideways'); 1 }, 'an unknown convention is refused');
like($@, qr/the convention is following, preceding, modified_following, modified_preceding, nearest or none, not 'sideways'/, '  by name');

# every convention on the last Saturday of October 2026 and the Sunday after it
my $sat = d('2026-10-31');
my $sun = d('2026-11-01');
my %want = (
    following          => ['2026-11-02', '2026-11-02'],
    preceding          => ['2026-10-30', '2026-10-30'],
    modified_following => ['2026-10-30', '2026-11-02'],
    modified_preceding => ['2026-10-30', '2026-11-02'],
    nearest            => ['2026-10-30', '2026-11-02'],
);
for my $conv (sort keys %want) {
    is($plain->roll($sat, convention => $conv) . '', $want{$conv}[0], "$conv on Saturday 31 October");
    is($plain->roll($sun, convention => $conv) . '', $want{$conv}[1], "$conv on Sunday 1 November");
}
is($plain->roll($sat) . '', '2026-11-02', 'following is the default');
is($C->new(weekend => [5, 6, 7])->roll($sat, convention => 'nearest') . '', '2026-11-02', 'nearest on a tie (Saturday in a three-day weekend: Thursday and Monday both two away) goes forward');
is($plain->roll(d('2026-10-30')) . '', '2026-10-30', 'a business day rolls to itself');
is($plain->roll(d('2026-10-30'), convention => 'none') . '', '2026-10-30', '  under none too');
ok(!eval { $plain->roll($sat, convention => 'none'); 1 }, 'none dies on a closed day');
like($@, qr/^Time::Keeper::Business->roll: 2026-10-31 is not a business day/, '  by name');
is($uk->roll(d('2026-12-26'), convention => 'nearest') . '', '2026-12-24', 'nearest over a holiday: Saturday the 26th, the 25th closed, is Thursday the 24th (two back) over Tuesday the 29th (three on)');
is($uk->roll(d('2026-12-27'), convention => 'nearest') . '', '2026-12-29', '  Sunday the 27th: the 28th closed, Tuesday the 29th (two on) over the 24th (three back)');

# between
is($plain->business_days_between(d('2026-10-12'), d('2026-10-19')), 5, 'Monday to the next Monday is five');
is($plain->business_days_between(d('2026-10-12'), d('2026-10-12')), 0, 'a day to itself is none');
is($plain->business_days_between(d('2026-10-19'), d('2026-10-12')), -5, 'reversed is negative');
is($plain->business_days_between(d('2026-10-12'), d('2026-10-16'), include_end => 1), 5, 'Monday to Friday with the end is five');
is($plain->business_days_between(d('2026-10-12'), d('2026-10-17'), include_end => 1), 5, '  and to Saturday with the end still five');
is($plain->business_days_between(d('2026-10-16'), d('2026-10-12'), include_end => 1), -5, '  reversed with the end counts the end the other way');
is($plain->business_days_between(d('2026-10-17'), d('2026-10-18')), 0, 'Saturday to Sunday is none');
is($plain->business_days_between(d('2026-01-01'), d('2027-01-01')), 261, '2026 has 261 weekdays');
is($uk->business_days_between(d('2026-01-01'), d('2027-01-01')), 253, '  and 253 business days in England');
is($plain->business_days_between(d('2000-01-01'), d('2100-01-01')), 26089, 'a century of weekdays: 36,525 days');
{
    my $calls = 0;
    my $lazy = $C->new(holidays => sub { $calls++; ("$_[0]-07-04") });
    is($lazy->business_days_between(d('2026-01-01'), d('2031-01-01')), 1305 - 4, 'between across the materialisation boundary: five years less the weekday Fourths');
    is($calls, 7, '  asked 2025 to 2031 once each');
}

# business_days
is_deeply(ds($plain->business_days(d('2026-10-12'), d('2026-10-18'))), [qw(2026-10-12 2026-10-13 2026-10-14 2026-10-15 2026-10-16)], 'the business days of a week');
is_deeply(ds($plain->business_days(d('2026-10-18'), d('2026-10-12'))), [qw(2026-10-12 2026-10-13 2026-10-14 2026-10-15 2026-10-16)], '  either way round');
is_deeply(ds($plain->business_days(d('2026-10-17'), d('2026-10-18'))), [], 'a weekend has none');
is_deeply(ds($uk->business_days(d('2026-12-24'), d('2026-12-29'))), [qw(2026-12-24 2026-12-29)], 'the holidays are skipped');
is(ref(($plain->business_days(d('2026-10-12'), d('2026-10-13')))[0]), 'Time::Keeper::Date', 'a Date in gives Dates');

# nth and last
is($plain->nth_business_day(Time::Keeper::YearMonth->new(year => 2026, month => 10), 1) . '', '2026-10-01', 'the first business day of October 2026');
is($plain->nth_business_day(d('2026-10-15'), 3) . '', '2026-10-05', 'the third, from a date in the month');
is($plain->nth_business_day(d('2026-10-15'), -1) . '', '2026-10-30', 'the last by -1');
is($plain->last_business_day(Time::Keeper::YearMonth->new(year => 2026, month => 10)) . '', '2026-10-30', 'last_business_day');
is($plain->nth_business_day(d('2026-10-15'), 22) . '', '2026-10-30', 'the 22nd is the last');
is($plain->nth_business_day(d('2026-10-15'), -22) . '', '2026-10-01', 'and -22 the first');
is($uk->last_business_day(Time::Keeper::YearMonth->new(year => 2026, month => 12)) . '', '2026-12-31', 'the last of December in England');
is($uk->nth_business_day(Time::Keeper::YearMonth->new(year => 2026, month => 12), -2) . '', '2026-12-30', '  and the second last');
ok(!eval { $plain->nth_business_day(d('2026-10-15'), 23); 1 }, 'a 23rd is refused');
like($@, qr/^Time::Keeper::Business->nth_business_day: October 2026 has 22 business days, not 23/, '  with the count');
ok(!eval { $plain->nth_business_day(d('2026-10-15'), 0); 1 }, 'n of 0 is refused');
ok(!eval { $plain->nth_business_day(d('2026-10-15'), -23); 1 }, '-23 is refused');
is(ref $plain->nth_business_day(Time::Keeper::YearMonth->new(year => 2026, month => 10), 1), 'Time::Keeper::Date', 'a YearMonth gives a Date');
ok(!eval { $plain->next_business_day(Time::Keeper::YearMonth->new(year => 2026, month => 10)); 1 }, 'a YearMonth to a day method is refused');
like($@, qr/^Time::Keeper::Business->next_business_day: a month is not a day/, '  by name');

# values keep what they had
{
    my $t = Time::Keeper->new(year => 2026, month => 12, day => 18, hour => 9, minute => 30, zone => 'Asia/Tokyo', locale => 'ja');
    my $m = $uk->plus_business_days($t, 10);
    is("$m", '2027-01-06T09:30:00+09:00', 'a Time::Keeper keeps its clock and zone');
    is($m->locale, 'ja', '  and locale');
    is(ref $m, 'Time::Keeper', '  and class');
    my $h = $uk->next_business_day($t->in_calendar('hebrew'));
    is($h->calendar, 'hebrew', 'a Hebrew-calendar value keeps its calendar');
    is($h->epoch, $uk->next_business_day($t)->epoch, '  and moves by the Gregorian day');
    is($plain->next_business_day(Time::Keeper->new(year => 2026, month => 10, day => 17, zone => 'floating')) . '', '2026-10-19T00:00:00', 'a floating value works');
    my $ny = Time::Keeper->new(year => 2026, month => 3, day => 7, hour => 2, minute => 30, zone => 'America/New_York');
    is($C->new(weekend => [])->next_business_day($ny) . '', '2026-03-08T03:30:00-04:00', 'a clock the landing day skipped is carried forward');
    is($uk->next_business_day($t)->to_date . '', '2026-12-21', 'the day is read in the value\'s own zone');
    my $utc_sun = Time::Keeper->new(year => 2026, month => 10, day => 18, hour => 23, zone => 'UTC');
    is($plain->next_business_day($utc_sun) . '', '2026-10-19T23:00:00Z', '23:00 UTC on Sunday: Monday');
    is($plain->next_business_day($utc_sun->in_zone('Asia/Tokyo'))->to_date . '', '2026-10-20', '  but it is already Monday in Tokyo, so Tuesday there');
    is($plain->next_business_day($utc_sun->in_zone('Asia/Tokyo'))->in_zone('UTC') . '', '2026-10-19T23:00:00Z', '  which is Monday 23:00 in UTC: the same string the UTC value gave, a day later in its own zone');
}

# edges
{
    my $never = $C->new(weekend => [1 .. 7]);
    ok(!eval { $never->next_business_day(d('2026-10-18')); 1 }, 'a schedule closed every day: next dies after a year');
    like($@, qr/^Time::Keeper::Business->next_business_day: no business day within a year of 2026-10-18/, '  by name');
    ok(!eval { $never->plus_business_days(d('2026-10-18'), 3); 1 }, '  plus dies');
    ok(!eval { $never->roll(d('2026-10-18')); 1 }, '  roll dies');
    is($never->business_days_between(d('2026-01-01'), d('2027-01-01')), 0, '  between is zero');
    my $sats = $C->new(working => ['2026-12-19']);
    is($sats->business_days_between(d('2026-12-14'), d('2026-12-21')), 6, 'a worked Saturday counts');
    is($sats->plus_business_days(d('2026-12-18'), 1) . '', '2026-12-19', '  and is landed on');
    is($sats->next_business_day(d('2026-12-19')) . '', '2026-12-21', '  and stepped off');
    my $weds = $C->new(holidays => [ map { d('2026-01-07')->plus(weeks => $_) } 0 .. 51 ]);
    is($weds->business_days_between(d('2026-01-05'), d('2027-01-04')), 260 - 52, 'fifty-two Wednesday holidays');
    is($weds->plus_business_days(d('2026-01-05'), 4) . '', '2026-01-12', '  four on from Monday skips the Wednesday');
    {
        my $dd = d('2026-01-05');
        my $n = 0;
        while ($n < 200) { $dd = $dd->plus(days => 1); $n++ if $weds->is_business_day($dd) }
        is($weds->plus_business_days(d('2026-01-05'), 200) . '', "$dd", '  two hundred on agrees with a walk');
    }
    my $open_only = $C->new(weekend => [1 .. 7], working => [ map { d('2026-10-18')->plus(days => $_) } 1 .. 3 ]);
    is($open_only->plus_business_days(d('2026-10-18'), 2) . '', '2026-10-21', 'a schedule with worked days only still counts them: the roll takes the first, two on is the third');
    is($open_only->business_days_between(d('2026-10-18'), d('2026-10-25')), 3, '  three in the week');
    ok(!eval { $open_only->plus_business_days(d('2026-10-18'), 3); 1 }, '  and three on runs out');
    like($@, qr/^Time::Keeper::Business->plus_business_days: there are not 3 business days within 4 years of 2026-10-19/, '  by name, from the rolled start');
}

# the formula against the walk
{
    srand(5);
    my $bad = 0;
    for my $b ($plain, $uk, $C->new(weekend => 'ar-EG', working => ['2026-10-10'], holidays => ['2026-10-06'])) {
        for (1 .. 300) {
            my $a = d('2026-01-01')->epoch_days + int(rand(800)) - 100;
            my $len = int(rand(400));
            $bad++ unless $b->business_days_between(Time::Keeper::Date->from_epoch_days($a), Time::Keeper::Date->from_epoch_days($a + $len))
                       == Time::Keeper::Business::_between_slow($b, $a, $a + $len);
        }
    }
    is($bad, 0, 'between agrees with a day-at-a-time count on 900 spans');
}

done_testing;

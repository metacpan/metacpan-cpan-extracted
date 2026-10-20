#!perl
use 5.010;
use strict;
use warnings;
use Config;
BEGIN { if ($Config{useithreads}) { require threads; threads->import } }
use Test::More;
use Storable qw(dclone freeze thaw);

use Time::Keeper;
use Time::Keeper::Business;

my $C = 'Time::Keeper::Business';
sub d { Time::Keeper::Date->parse($_[0]) }

# The civil arithmetic agrees with the core's.
{
    is(Time::Keeper::Business::_days_from_civil(1970, 1, 1), 0, 'day 0 is 1 January 1970');
    is(Time::Keeper::Business::_days_from_civil(2026, 10, 18), d('2026-10-18')->epoch_days, 'a day agrees with Date->epoch_days');
    is_deeply([Time::Keeper::Business::_civil_from_days(d('2026-10-18')->epoch_days)], [2026, 10, 18, 7], 'and back, with the weekday: 18 October 2026 is a Sunday');
    srand(42);
    my $bad = 0;
    for (1 .. 10_000) {
        my $days = int(rand(2_000_000)) - 1_000_000;
        my $date = Time::Keeper::Date->from_epoch_days($days);
        my ($y, $m, $dd, $dow) = Time::Keeper::Business::_civil_from_days($days);
        $bad++ unless $y == $date->year && $m == $date->month && $dd == $date->day && $dow == $date->day_of_week
                   && Time::Keeper::Business::_days_from_civil($y, $m, $dd) == $days;
    }
    is($bad, 0, '10,000 random days round-trip and agree with the core');
}

# Construction.
my $b = $C->new;
isa_ok($b, $C);
is_deeply([$b->weekend], [6, 7], 'the weekend is Saturday and Sunday by default');
is("$b", 'Time::Keeper::Business', 'a schedule stringifies to its class');
ok($b, 'and is true');
is($b->zone, undef, 'no zone');
is($b->name, undef, 'no name');
is($b->hours, undef, 'no hours');

my $named = $C->new(name => 'london', zone => 'Europe/London', hours => ['09:00-17:00']);
is("$named", 'Time::Keeper::Business(london)', 'a named schedule says its name');
is($named->zone, 'Europe/London', 'the zone as given');
is($named->name, 'london', 'the name as given');
is_deeply($named->hours, ['09:00-17:00'], 'the hours as given');

is_deeply([$C->new(weekend => [5, 6])->weekend], [5, 6], 'a weekend as a list');
is_deeply([$C->new(weekend => [7, 1])->weekend], [1, 7], 'in any order, given back in order');
is_deeply([$C->new(weekend => [])->weekend], [], 'an empty weekend');
is_deeply([$C->new(weekend => 'ar-EG')->weekend], [5, 6], 'the locale\'s weekend: Friday and Saturday in Egypt');
is_deeply([$C->new(weekend => 'fa-AF')->weekend], [4, 5], 'Thursday and Friday in Afghanistan');
is_deeply([$C->new(weekend => 'hi-IN')->weekend], [7], 'Sunday alone in India');
is_deeply([$C->new(weekend => 'en-GB')->weekend], [6, 7], 'Saturday and Sunday in Britain');
is_deeply([$C->new(weekend => undef)->weekend], [6, 7], 'undef is the default');

# Every refusal by name.
my @refused = (
    [[weekend => [8]],                      qr/^Time::Keeper::Business->new: a weekend day is 1 \(Monday\) to 7 \(Sunday\)/, 'a weekend day of 8'],
    [[weekend => [0]],                      qr/a weekend day is 1 \(Monday\) to 7/, 'a weekend day of 0'],
    [[weekend => ['x']],                    qr/a weekend day is 1 \(Monday\) to 7/, 'a weekend day that is not a number'],
    [[weekend => [6, 6]],                   qr/^Time::Keeper::Business->new: weekend day 6 is given twice/, 'a weekend day twice'],
    [[weekend => 'zz-ZZ'],                  qr/there is no locale 'zz-ZZ'/, 'a weekend locale that does not exist'],
    [[weekend => {}],                       qr/weekend is a list of days or a locale code/, 'a weekend that is a hash'],
    [[foo => 1],                            qr/^Time::Keeper::Business->new: unknown argument 'foo'/, 'an unknown key'],
    [['weekend'],                           qr/^Time::Keeper::Business->new: needs key\/value pairs/, 'an odd argument list'],
    [[holidays => ['2026-12-25'], working => ['2026-12-25']], qr/^Time::Keeper::Business->new: 2026-12-25 is both a holiday and a working day/, 'a holiday that is also a working day'],
    [[holidays => ['not a date']],          qr/Time::Keeper::Date->parse/, 'a holiday that is not a date, with the core\'s reason'],
    [[holidays => [undef]],                 qr/a holiday source is undef/, 'an undef holiday'],
    [[holidays => [\"x"]],                  qr/a holiday source is a date, a name map, a code ref, an object with a holidays method or a list of them/, 'a scalar ref'],
    [[holidays => [Time::Keeper::YearMonth->new(year => 2026, month => 12)]], qr/a month is not a day/, 'a month as a holiday'],
    [[holidays => [bless {}, 'Something']], qr/an object with no holidays method is not a holiday source/, 'an object without a holidays method'],
    [[working => [{}]],                     qr/a date is a string or a Time::Keeper::Date, not a reference/, 'a working day that is a hash'],
    [[zone => 'Nowhere/Here'],              qr/^Time::Keeper::Business->new: unknown zone 'Nowhere\/Here'/, 'an unknown zone'],
    [[zone => 'floating'],                  qr/^Time::Keeper::Business->new: a schedule's zone cannot be floating/, 'a floating zone'],
);
for my $r (@refused) {
    my ($args, $re, $why) = @$r;
    ok(!eval { $C->new(@$args); 1 }, "refused: $why");
    like($@, $re, "  with the message");
}

# A week of October 2026: Monday the 12th to Sunday the 18th.
my @week = map { d("2026-10-$_") } 12 .. 18;
is_deeply([map { $b->is_business_day($_) } @week], [1, 1, 1, 1, 1, 0, 0], 'the default weekend: Monday to Friday work');
is_deeply([map { $b->is_weekend_day($_) } @week], [0, 0, 0, 0, 0, 1, 1], 'Saturday and Sunday are the weekend');
is_deeply([map { $C->new(weekend => 'ar-EG')->is_business_day($_) } @week], [1, 1, 1, 1, 0, 0, 1], 'ar-EG: Friday and Saturday off');
is_deeply([map { $C->new(weekend => 'fa-AF')->is_business_day($_) } @week], [1, 1, 1, 0, 0, 1, 1], 'fa-AF: Thursday and Friday off');
is_deeply([map { $C->new(weekend => 'hi-IN')->is_business_day($_) } @week], [1, 1, 1, 1, 1, 1, 0], 'hi-IN: Sunday off');
is_deeply([map { $C->new(weekend => [])->is_business_day($_) } @week], [1, 1, 1, 1, 1, 1, 1], 'a seven-day week');
is_deeply([map { $C->new(weekend => [1 .. 7])->is_business_day($_) } @week], [0, 0, 0, 0, 0, 0, 0], 'a week with no business day');

# Holidays, worked days and names.
my $xmas = $C->new(
    holidays => [ '2026-12-25', { '2026-12-28' => 'Boxing Day (substitute)', '2026-12-26' => 'Boxing Day', '2027-01-01' => undef },
                  d('2027-01-04'), Time::Keeper->new(year => 2026, month => 12, day => 31, hour => 23, zone => 'Pacific/Auckland') ],
    working  => [ '2026-12-19', '2026-12-21' ],
);
is($xmas->is_business_day(d('2026-12-25')), 0, 'a holiday on a Friday is not a business day');
is($xmas->is_holiday(d('2026-12-25')), 1, 'and is a holiday without a name: 1');
is($xmas->is_holiday(d('2026-12-28')), 'Boxing Day (substitute)', 'a named holiday gives its name');
is($xmas->is_business_day(d('2026-12-26')), 0, 'a holiday on a Saturday is not a business day');
is($xmas->is_holiday(d('2026-12-26')), 'Boxing Day', 'and is still a holiday by name');
is($xmas->is_holiday(d('2026-12-27')), undef, 'a plain Sunday is not a holiday');
is($xmas->is_business_day(d('2026-12-27')), 0, 'though it is not a business day');
is($xmas->is_holiday(d('2027-01-01')), 1, 'a name of undef is a holiday without a name');
is($xmas->is_holiday(d('2027-01-04')), 1, 'a Date as a source');
is($xmas->is_holiday(d('2026-12-31')), 1, 'a Time::Keeper as a source is the date its own zone shows (31 December in Auckland)');
is($xmas->is_holiday(d('2026-12-30')), undef, 'not the UTC date');
is($xmas->is_business_day(d('2026-12-19')), 1, 'a worked Saturday is a business day');
is($xmas->is_weekend_day(d('2026-12-19')), 1, 'and still a weekend day');
is($xmas->is_business_day(d('2026-12-21')), 1, 'a working day on a Monday changes nothing');
is_deeply([Time::Keeper::Business::_counts($xmas)], [5, 1, 6, 5], '5 closed weekdays, 1 worked weekend day, 6 holidays, 5 days a week');
is_deeply([Time::Keeper::Business::_closed_days($xmas)], [qw(2026-12-25 2026-12-28 2026-12-31 2027-01-01 2027-01-04)], 'the closed weekdays, sorted') or diag explain [Time::Keeper::Business::_closed_days($xmas)];
is_deeply([Time::Keeper::Business::_open_days($xmas)], ['2026-12-19'], 'the worked weekend day');

{
    my $two = $C->new(holidays => [ { '2026-12-25' => 'Christmas Day' }, { '2026-12-25' => 'Noel' }, '2026-12-25' ]);
    is($two->is_holiday(d('2026-12-25')), 'Christmas Day', 'the first name given for a day is kept');
    my $fill = $C->new(holidays => [ '2026-12-25', { '2026-12-25' => 'Christmas Day' } ]);
    is($fill->is_holiday(d('2026-12-25')), 'Christmas Day', 'and a later name fills a day that had none');
    is_deeply([Time::Keeper::Business::_counts($fill)], [1, 0, 1, 5], 'a day given twice is one holiday');
    my $one = $C->new(holidays => '2026-12-25', working => '2026-12-19');
    is($one->is_holiday(d('2026-12-25')), 1, 'a single source needs no list');
    is($one->is_business_day(d('2026-12-19')), 1, 'nor a single working day');
    my $nested = $C->new(holidays => [ [ '2026-12-25', [ '2026-12-28' ] ] ]);
    is_deeply([Time::Keeper::Business::_counts($nested)], [2, 0, 2, 5], 'nested lists are flattened');
    my $twice = $C->new(working => ['2026-12-19', '2026-12-19', d('2026-12-19')]);
    is_deeply([Time::Keeper::Business::_counts($twice)], [0, 1, 0, 5], 'a working day given three times is one');
    is_deeply([Time::Keeper::Business::_open_days($twice)], ['2026-12-19'], '  and listed once');
}

# A Time::Keeper is read in its own zone (B3).
{
    my $sun = $C->new(weekend => [7]);
    my $tokyo = Time::Keeper->new(year => 2026, month => 10, day => 18, hour => 0, minute => 30, zone => 'Asia/Tokyo');
    is($sun->is_business_day($tokyo), 0, 'Sunday 00:30 in Tokyo is a Sunday');
    is($sun->is_business_day($tokyo->in_zone('UTC')), 1, 'the same instant in UTC is still Saturday');
    is($sun->is_weekend_day($tokyo), 1, 'is_weekend_day reads the same day');
    my $floating = Time::Keeper->new(year => 2026, month => 10, day => 18, zone => 'floating');
    is($sun->is_business_day($floating), 0, 'a floating value is read by its wall clock');
    my $hebrew = $tokyo->in_calendar('hebrew');
    is($sun->is_business_day($hebrew), 0, 'a value in another calendar is read by its Gregorian day');
    my $ym = Time::Keeper::YearMonth->new(year => 2026, month => 11);
    is($sun->is_business_day($ym), 0, 'a YearMonth is read as its first day (1 November 2026, a Sunday)');
    ok(!eval { $sun->is_business_day('2026-10-18'); 1 }, 'a string is refused');
    like($@, qr/^Time::Keeper::Business->is_business_day: not a Time::Keeper value or a Time::Keeper::Date/, '  by name');
    ok(!eval { $sun->is_holiday(undef); 1 }, 'undef is refused');
    like($@, qr/^Time::Keeper::Business->is_holiday: not a Time::Keeper value/, '  by name');
    ok(!eval { Time::Keeper::Business::is_business_day(\1, $tokyo); 1 }, 'a plain ref is not a schedule');
    like($@, qr/^Time::Keeper::Business->is_business_day: not a Time::Keeper::Business schedule/, '  by name');
    ok(!eval { $C->is_business_day($tokyo); 1 }, 'nor is the class');
}

# with, with_holidays, with_working_days.
{
    my $c = $xmas->with(weekend => [], name => 'always');
    is_deeply([$c->weekend], [], 'with replaces the key');
    is($c->name, 'always', 'and adds one');
    is($c->is_business_day(d('2026-12-26')), 0, 'the holidays are kept');
    is($c->is_business_day(d('2026-12-27')), 1, 'a Sunday now works');
    is_deeply([$xmas->weekend], [6, 7], 'the original is untouched');
    is($xmas->name, undef, '  and unnamed');
    ok(!eval { $xmas->with(nope => 1); 1 }, 'with refuses an unknown key');
    like($@, qr/^Time::Keeper::Business->with: unknown argument 'nope'/, '  by name');

    my $more = $xmas->with_holidays('2027-05-03', { '2027-12-27' => 'Christmas Day (substitute)' });
    is($more->is_holiday(d('2027-05-03')), 1, 'with_holidays adds a source');
    is($more->is_holiday(d('2027-12-27')), 'Christmas Day (substitute)', '  and a named one');
    is($more->is_holiday(d('2026-12-28')), 'Boxing Day (substitute)', '  keeping the old');
    is($xmas->is_holiday(d('2027-05-03')), undef, '  and the original has not got it');
    my $sat = $xmas->with_working_days('2027-01-02');
    is($sat->is_business_day(d('2027-01-02')), 1, 'with_working_days adds a worked Saturday');
    is($sat->is_business_day(d('2026-12-19')), 1, '  keeping the old');
    is($xmas->is_business_day(d('2027-01-02')), 0, '  and the original has not got it');
    ok(!eval { $xmas->with_working_days('2026-12-25'); 1 }, 'a worked day that is a holiday is refused');
}

# join.
{
    my $uk = $C->new(holidays => { '2026-12-25' => 'Christmas Day', '2026-12-28' => 'Boxing Day (substitute)' }, name => 'uk');
    my $eg = $C->new(weekend => 'ar-EG', holidays => { '2026-12-25' => 'Christmas Day', '2026-10-06' => 'Armed Forces Day' }, working => ['2026-10-10']);
    my $either = $uk->join($eg);
    is_deeply([$either->weekend], [5, 6, 7], 'either: the weekend is the union');
    is($either->is_business_day(d('2026-12-28')), 0, 'either: a holiday of one closes');
    is($either->is_business_day(d('2026-10-06')), 0, '  of the other too');
    is($either->is_holiday(d('2026-10-06')), 'Armed Forces Day', '  and is a holiday by name');
    is($either->is_business_day(d('2026-10-10')), 0, 'either: a Saturday worked in one is closed in the other');
    is($either->is_business_day(d('2026-10-09')), 0, 'either: Friday is closed (Egypt)');
    is($either->is_business_day(d('2026-10-11')), 0, '  and Sunday (UK)');
    is($either->is_business_day(d('2026-10-08')), 1, '  Thursday works');
    is("$either", 'Time::Keeper::Business', 'a join is unnamed unless asked');
    is($uk->join($eg, name => 'both')->name, 'both', '  and named when asked');

    my $both = $uk->join($eg, mode => 'both');
    is_deeply([$both->weekend], [6], 'both: the weekend is the intersection');
    is($both->is_business_day(d('2026-12-25')), 0, 'both: a holiday in both closes');
    is($both->is_holiday(d('2026-12-25')), 'Christmas Day', '  and is a holiday');
    is($both->is_business_day(d('2026-12-28')), 1, 'both: a holiday in one alone works');
    is($both->is_holiday(d('2026-12-28')), undef, '  and is not a holiday');
    is($both->is_business_day(d('2026-10-09')), 1, 'both: Friday works (UK does)');
    is($both->is_business_day(d('2026-10-11')), 1, '  and Sunday (Egypt does)');
    is($both->is_business_day(d('2026-10-10')), 1, 'both: a Saturday worked in Egypt is a business day');
    is($both->is_business_day(d('2026-10-17')), 0, '  but a plain Saturday is closed in both');

    ok(!eval { $uk->join($eg, mode => 'neither'); 1 }, 'an unknown mode is refused');
    like($@, qr/^Time::Keeper::Business->join: mode is 'either' or 'both', not 'neither'/, '  by name');
    ok(!eval { $uk->join('x'); 1 }, 'joining a non-schedule is refused');
    ok(!eval { $either->with(name => 'x'); 1 }, 'a joined schedule cannot be changed with with');
    like($@, qr/^Time::Keeper::Business->with: a joined schedule cannot be changed; change the schedules and join them again/, '  by name');
    ok(!eval { $either->with_holidays('2026-11-11'); 1 }, '  nor with with_holidays');
    my $again = $either->join($uk, mode => 'both');
    is($again->is_business_day(d('2026-10-09')), 1, 'a join of a join: Friday works again');
}

# The plain form, Storable and FREEZE/THAW.
{
    my $plain = $xmas->TO_JSON;
    is_deeply($plain, {
        weekend  => [6, 7],
        holidays => { '2026-12-25' => undef, '2026-12-26' => 'Boxing Day', '2026-12-28' => 'Boxing Day (substitute)',
                      '2026-12-31' => undef, '2027-01-01' => undef, '2027-01-04' => undef },
        working  => ['2026-12-19'],
    }, 'TO_JSON is the plain form') or diag explain $plain;
    my $back = $C->new(%$plain);
    is_deeply($back->TO_JSON, $plain, 'and new takes it back');
    is_deeply($named->TO_JSON, { weekend => [6, 7], holidays => {}, working => [], zone => 'Europe/London', name => 'london', hours => ['09:00-17:00'] },
              'zone, name and hours are carried');

    my $clone = dclone($xmas);
    isa_ok($clone, $C, 'a Storable clone');
    is_deeply($clone->TO_JSON, $plain, '  is the same schedule');
    is($clone->is_holiday(d('2026-12-28')), 'Boxing Day (substitute)', '  and answers');
    my $thawed = thaw(freeze($xmas->with(name => 'x')));
    is($thawed->name, 'x', 'freeze and thaw keep the name');
    is($thawed->is_business_day(d('2026-12-19')), 1, '  and the worked Saturday');

    my @frozen = $xmas->FREEZE('CBOR');
    is(scalar @frozen, 1, 'FREEZE gives one value');
    is_deeply($frozen[0], $plain, '  the plain form');
    my $th = $C->THAW('CBOR', @frozen);
    is_deeply($th->TO_JSON, $plain, 'THAW makes the schedule again');
    is(ref $th, $C, '  in the class');
    ok(!eval { $C->THAW('CBOR', 'junk'); 1 }, 'THAW of junk is refused');
    like($@, qr/^Time::Keeper::Business->THAW: not a frozen schedule/, '  by name');

    my $j = dclone($xmas->join($named));
    is($j->is_holiday(d('2026-12-28')), 'Boxing Day (substitute)', 'a cloned join is a literal schedule');
    is($j->with(name => 'y')->name, 'y', '  which with can change');

    {
        package My::Schedule;
        our @ISA = ('Time::Keeper::Business');
    }
    my $sub = My::Schedule->new(name => 'sub');
    is(ref $sub, 'My::Schedule', 'a subclass constructs in itself');
    is(ref $sub->with(name => 'x'), 'My::Schedule', '  with keeps it');
    is(ref $sub->join($xmas), 'My::Schedule', '  join keeps it');
    is(ref dclone($sub), 'My::Schedule', '  Storable keeps it');
    is("$sub", 'My::Schedule(sub)', '  and the string says it');
}

# A value written back on another day keeps everything but the day (B3).
{
    my $on = \&Time::Keeper::Business::_on_day;
    my $t = Time::Keeper->new(year => 2026, month => 10, day => 15, hour => 9, minute => 30, second => 5, nanosecond => 7,
                              zone => 'Asia/Tokyo', locale => 'fr');
    my $m = $on->($t, d('2026-10-19')->epoch_days);
    is(ref $m, 'Time::Keeper', 'a Time::Keeper comes back as one');
    is("$m", '2026-10-19T09:30:05.000000007+09:00', '  on the new day, same clock, same zone');
    is($m->locale, 'fr', '  same locale');
    is($m->zone_name, 'Asia/Tokyo', '  same zone by name');
    is($on->($t->in_calendar('hebrew'), d('2026-10-19')->epoch_days)->calendar, 'hebrew', '  same calendar');
    is("$t", '2026-10-15T09:30:05.000000007+09:00', '  the original untouched');
    my $utc = Time::Keeper->new(year => 2026, month => 1, day => 1, zone => 'UTC');
    is('' . $on->($utc, 0), '1970-01-01T00:00:00Z', 'a UTC value moved to day 0');
    my $fl = Time::Keeper->new(year => 2026, month => 1, day => 1, hour => 12, zone => 'floating');
    is('' . $on->($fl, 1), '1970-01-02T12:00:00', 'a floating value stays floating');
    my $ny = Time::Keeper->new(year => 2026, month => 3, day => 7, hour => 2, minute => 30, zone => 'America/New_York');
    is('' . $on->($ny, $ny->to_date->plus(days => 1)->epoch_days), '2026-03-08T03:30:00-04:00', 'a clock the new day skipped is carried forward');
    my $ov = Time::Keeper->new(year => 2026, month => 10, day => 31, hour => 1, minute => 30, zone => 'America/New_York');
    is('' . $on->($ov, $ov->to_date->plus(days => 1)->epoch_days), '2026-11-01T01:30:00-04:00', 'a clock the new day repeats takes the earlier');
    my $leap = Time::Keeper->new(year => 2016, month => 12, day => 31, hour => 23, minute => 59, second => 60, zone => 'UTC');
    is('' . $on->($leap, $leap->to_date->plus(days => 1)->epoch_days), '2017-01-01T23:59:59.999999999Z', 'a leap second moved to a day without one is the last instant of the minute');
    {
        package My::Keeper;
        our @ISA = ('Time::Keeper');
    }
    my $sub = bless Time::Keeper->now, 'My::Keeper';
    is(ref $on->($sub, 0), 'My::Keeper', 'a Time::Keeper subclass is kept');
    my $date = d('2026-10-15')->in_locale('de');
    my $md = $on->($date, $date->epoch_days + 4);
    is(ref $md, 'Time::Keeper::Date', 'a Date comes back as a Date');
    is("$md", '2026-10-19', '  on the new day');
    is($md->locale, 'de', '  in its locale');
    {
        package My::Date;
        our @ISA = ('Time::Keeper::Date');
    }
    is(ref $on->(bless(d('2026-10-15'), 'My::Date'), 0), 'My::Date', 'a Date subclass is kept');
    my $ym = Time::Keeper::YearMonth->new(year => 2026, month => 10, locale => 'fr');
    my $from_ym = $on->($ym, 3);
    is(ref $from_ym, 'Time::Keeper::Date', 'a YearMonth comes back as a Date');
    is("$from_ym", '1970-01-04', '  on the day asked');
    is($from_ym->locale, 'fr', "  in the month's locale");
    ok(!eval { $on->($utc, 366 * 1_000_000_000 + 400); 1 }, 'a day past the years the core holds is refused');
    like($@, qr/outside the years Time::Keeper holds|out of range/, "  by the core's word");
}

# A schedule with rules as data.
{
    my $b = $C->new(holidays => [ Time::Keeper::Business::Rule->uk, '2026-12-31' ], weekend => 'en-GB', name => 'uk');
    my $plain = $b->TO_JSON;
    is_deeply($plain->{rules}, [ Time::Keeper::Business::Rule->uk->TO_JSON ], 'TO_JSON gives the rules as data');
    is_deeply($plain->{holidays}, { '2026-12-31' => undef }, '  and the literal days, without the days the rules gave');
    for my $copy ([ 'new(%TO_JSON)', $C->new(%$plain) ], [ 'Storable', dclone($b) ], [ 'FREEZE/THAW', $C->THAW('CBOR', $b->FREEZE('CBOR')) ]) {
        my $bad = grep { join(' ', map { "$_->[0]" } $copy->[1]->holidays(year => $_)) ne join(' ', map { "$_->[0]" } $b->holidays(year => $_)) } 2024 .. 2034;
        is($bad, 0, "$copy->[0]: the same holidays for 2024 to 2034");
        is($copy->[1]->is_holiday(d('2026-12-31')), 1, '  and the literal day');
    }
    my $r = $C->new(rules => [ Time::Keeper::Business::Rule->target2, Time::Keeper::Business::Rule->uk->TO_JSON ]);
    is(scalar(() = $r->holidays(year => 2026)), 10, 'new takes rules as rules or as data');
    ok(!eval { $C->new(rules => ['x']); 1 }, '  and nothing else');
    like($@, qr/rules is a list of rules, or of rules as data/, '  by name');
    ok(!eval { freeze($C->new(holidays => sub { () })); 1 }, 'a code ref source still refuses to freeze');
}

# Threads: a copy answers alone after the parent lets go of its own.
SKIP: {
    skip 'no ithreads', 3 unless $Config{useithreads};
    my $s = $C->new(holidays => { '2026-12-25' => 'Christmas Day' }, working => ['2026-12-19'], name => 't');
    my $thr = threads->create(sub {
        my $copy = $s;
        return join ',', $copy->is_holiday(d('2026-12-25')), $copy->is_business_day(d('2026-12-19')), "$copy";
    });
    undef $s;
    is($thr->join, 'Christmas Day,1,Time::Keeper::Business(t)', 'the thread\'s copy answers after the parent freed its own');
    my $t2 = threads->create(sub { my $x = $C->new(holidays => ['2026-12-25']); $x->is_business_day(d('2026-12-25')) });
    is($t2->join, 0, 'a schedule made in a thread works there');
    pass('no crash on thread exit');
}

done_testing;

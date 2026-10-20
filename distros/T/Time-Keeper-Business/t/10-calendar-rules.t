#!perl
use 5.010;
use strict;
use warnings;
use Test::More;

use Time::Keeper;
use Time::Keeper::Business;

my $R = 'Time::Keeper::Business::Rule';
sub dates { [map { "$_->[0]" } @_] }
sub on { my ($rule, $y) = @_; dates($rule->holidays(year => $y)) }

my $eid = $R->fixed(calendar => 'islamic-umalqura', month_code => 'M10', day => 1, name => 'Eid al-Fitr');
is_deeply(on($eid, 2000), [qw(2000-01-08 2000-12-27)], 'Eid al-Fitr came twice in 2000');
is_deeply(on($eid, 2026), ['2026-03-20'], '  once in 2026');
is(($eid->holidays(year => 2026))[0][1], 'Eid al-Fitr', '  with its name');

my $passover = $R->fixed(calendar => 'hebrew', month_code => 'M07', day => 15, name => 'Passover');
is_deeply(on($passover, 2026), ['2026-04-02'], 'Passover 2026');
is_deeply(on($passover, 2027), ['2027-04-22'], 'Passover 2027');
is_deeply(on($passover->observed('next_business_day'), 2027), ['2027-04-22'], '  once, with an observed form, though the Hebrew year that touches 2026 holds it too');
is_deeply(on($passover->observed('none'), 2026), ['2026-04-02'], "  and 2026 does not list 5787's");

my $purim = $R->fixed(calendar => 'hebrew', month_code => 'M06', day => 14, name => 'Purim');
is_deeply(on($purim, 2026), ['2026-03-03'], 'Purim 2026, Adar of a common year');
is_deeply(on($purim, 2027), ['2027-03-23'], 'Purim 2027, Adar II of a leap year, by the code alone');
my $katan = $R->fixed(calendar => 'hebrew', month_code => 'M05L', day => 14, name => 'Purim Katan');
is_deeply(on($katan, 2027), ['2027-02-21'], 'Adar I 14 in a leap year');
is_deeply(on($katan, 2026), [], '  and nothing in a common year');
is_deeply(on($R->fixed(calendar => 'hebrew', month_code => 'M05L', day => 14, leap_month => 'common'), 2026), ['2026-03-03'], '  or Adar 14 with leap_month common');
is_deeply(on($R->fixed(calendar => 'hebrew', month_code => 'M05L', day => 14, leap_month => 'skip'), 2026), [], '  skip is the default');

my $hanukkah = $R->fixed(calendar => 'hebrew', month_code => 'M03', day => 25);
is_deeply(on($hanukkah, 2026), ['2026-12-05'], 'Hanukkah of 5787 in December 2026');
is_deeply(on($hanukkah, 2027), ['2027-12-25'], 'of 5788 in December 2027: two Hebrew years touch each Gregorian one');

my $lny = $R->fixed(calendar => 'chinese', month_code => 'M01', day => 1, name => 'Lunar New Year');
is_deeply(on($lny, 2026), ['2026-02-17'], 'Lunar New Year 2026');
is_deeply(on($lny, 2027), ['2027-02-07'], 'Lunar New Year 2027, the core\'s and ICU\'s reckoning');
is_deeply(on($lny, 3005), [], 'a year past the Chinese table gives no holiday, not a death');
is_deeply(on($lny, 999), [], '  nor before it');
is_deeply(on($R->fixed(calendar => 'dangi', month_code => 'M01', day => 1), 2026), ['2026-02-17'], 'Seollal 2026');

is_deeply(on($R->fixed(calendar => 'persian', month_code => 'M01', day => 1, name => 'Nowruz'), 2026), ['2026-03-21'], 'Nowruz 2026');

my $coptic13 = $R->fixed(calendar => 'coptic', month_code => 'M13', day => 6);
is_deeply(on($coptic13, 2027), ['2027-09-11'], 'the sixth day of the Coptic thirteenth month in a leap year');
is_deeply(on($coptic13, 2026), [], '  and nothing when the month has five');

is_deeply(on($R->fixed(calendar => 'gregory', month => 12, day => 25), 2026), ['2026-12-25'], 'the gregory calendar by name is the plain one');
is_deeply(on($R->fixed(month_code => 'M12', day => 25), 2026), ['2026-12-25'], 'a month code without a calendar is a Gregorian month');
is_deeply(on($R->fixed(calendar => 'japanese', month_code => 'M01', day => 1), 2026), ['2026-01-01'], 'a Gregorian-month calendar gives the same day');

my $sat = $R->nth(calendar => 'hebrew', month_code => 'M07', day_of_week => 6, n => 1);
my $last = $R->nth(calendar => 'hebrew', month_code => 'M07', day_of_week => 6, n => -1);
{
    my ($first, $lastsat);
    my $d = Time::Keeper::Date->new(year => 2026, month => 3, day => 1);
    for (1 .. 70) {
        my $h = Time::Keeper->new(year => $d->year, month => $d->month, day => $d->day, hour => 12, zone => 'UTC')->in_calendar('hebrew');
        if ($h->month_code eq 'M07' && $d->day_of_week == 6) { $first //= "$d"; $lastsat = "$d" }
        $d = $d->plus(days => 1);
    }
    is_deeply(on($sat, 2026), [$first], "the first Saturday of Nisan 5786 is $first");
    is_deeply(on($last, 2026), [$lastsat], "and the last $lastsat");
}

my $gulf = Time::Keeper::Business->new(weekend => [5, 6], holidays => $R->set($eid->observed('next_business_day'), weekend => [5, 6]));
is($gulf->is_holiday(Time::Keeper::Date->parse('2026-03-22')), 'Eid al-Fitr', 'an observed move on a calendar rule: Friday 20 March to Sunday the 22nd with a Friday-Saturday weekend');
is($gulf->is_business_day(Time::Keeper::Date->parse('2026-03-22')), 0, '  and the schedule closes it');
is_deeply(on($R->relative(rule => $passover, days => 6, name => 'Last day of Passover'), 2026), ['2026-04-08'], 'relative to a calendar rule');
is_deeply(on($R->set($eid, $passover, $lny), 2000), [qw(2000-01-08 2000-02-05 2000-04-20 2000-12-27)], 'a set of calendar rules in date order');

my @refused = (
    [[calendar => 'mayan', month_code => 'M01', day => 1], qr/^Time::Keeper::Business::Rule->fixed: unknown calendar 'mayan'/, 'an unknown calendar'],
    [[calendar => 'hebrew', month => 7, day => 15], qr/one or the other|in another calendar a month is given by its month_code/, 'month in another calendar'],
    [[calendar => 'hebrew', day => 15], qr/month_code is needed/, 'no month code'],
    [[calendar => 'hebrew', month => 7, month_code => 'M07', day => 15], qr/month and month_code are one or the other/, 'both'],
    [[calendar => 'hebrew', month_code => 'Nisan', day => 15], qr/month_code is M01 to M13, with L after it for a leap month: not 'Nisan'/, 'a month code that is not one'],
    [[calendar => 'hebrew', month_code => 'M14', day => 1], qr/month_code is M01 to M13/, 'M14'],
    [[calendar => 'hebrew', month_code => 'M13', day => 1], qr/the hebrew calendar has no month M13/, 'M13 where there is none'],
    [[calendar => 'hebrew', month_code => 'M06L', day => 1], qr/the hebrew calendar has no leap month M06L/, 'a leap month that does not exist'],
    [[calendar => 'islamic-umalqura', month_code => 'M05L', day => 1], qr/has no leap month M05L/, 'a leap month in a lunar calendar'],
    [[month_code => 'M13', day => 1], qr/the gregory calendar has no month M13/, 'M13 in the Gregorian'],
    [[calendar => 'hebrew', month_code => 'M07', day => 31], qr/day must be 1 to 30/, 'day 31 in another calendar'],
    [[calendar => 'hebrew', month_code => 'M05L', day => 1, leap_month => 'maybe'], qr/leap_month is 'skip' or 'common', not 'maybe'/, 'an unknown leap_month'],
);
for my $r (@refused) {
    my ($args, $re, $why) = @$r;
    ok(!eval { $R->fixed(@$args); 1 }, "refused: $why");
    like($@, $re, '  with the message');
}
ok(!eval { $R->easter(calendar => 'hebrew'); 1 }, 'easter takes no calendar');
like($@, qr/unknown argument 'calendar'/, '  by name');

my $chinese_leap = $R->fixed(calendar => 'chinese', month_code => 'M06L', day => 1);
my @leap_years = grep { @{ on($chinese_leap, $_) } } 2020 .. 2030;
is_deeply(\@leap_years, [2025], 'a Chinese leap sixth month in 2020 to 2030 only in 2025');
is_deeply(on($R->fixed(calendar => 'chinese', month_code => 'M06L', day => 1, leap_month => 'common'), 2026), on($R->fixed(calendar => 'chinese', month_code => 'M06', day => 1), 2026), '  and common gives the sixth month in a year without it');

done_testing;

#!perl
use 5.010;
use strict;
use warnings;
use Test::More;

# The Chinese, Dangi and astronomical Hijri calendars, read from tables of
# what ICU computes for the years 1000 to 3000.
use Time::Keeper;

my $K = 'Time::Keeper';
my $C = 'Time::Keeper::Calendar';
sub dies_like { my ($code, $re, $name) = @_; ok(!eval { $code->(); 1 }, $name) or return; like($@, $re, "$name: the message") }
sub cal { my ($t) = @_; sprintf '%d-%02d-%02d', $t->year, $t->month, $t->day }

# Chinese New Year, from the Hong Kong Observatory's tables
my %cny = (1984 => '1984-02-02', 1900 => '1900-01-31', 2000 => '2000-02-05', 2024 => '2024-02-10', 2025 => '2025-01-29', 2026 => '2026-02-17',
           2033 => '2033-01-31', 2034 => '2034-02-19', 1949 => '1949-01-29', 2012 => '2012-01-23');
for my $y (sort keys %cny) {
    is((split /T/, $K->new(year => $y, month => 1, day => 1, calendar => 'chinese')->iso8601)[0], $cny{$y}, "Chinese New Year $y is $cny{$y}");
}
my $t = $K->new(year => 2026, month => 10, day => 15, hour => 12, zone => 'UTC')->in_calendar('chinese');
is((split /T/, $K->new(year => 2027, month => 1, day => 1, calendar => 'chinese')->iso8601)[0], '2027-02-07', "ICU puts the New Year of 2027 on 7 February; the Observatory has the 6th, the new moon falling at 23:56 Beijing time: the table is ICU's");
is($t->calendar, 'chinese', 'in_calendar chinese');
is(cal($t), '2026-09-06', '15 October 2026 is the 6th of the 9th month');
is($t->month_code, 'M09', 'month code');
is($t->cyclic_year, 43, '2026 is bing-wu, the 43rd of the cycle');
is($t->era_year, 4663, "ICU's extended year");
is($t->era, 'era0', 'the one era, unnamed by CLDR');
is($t->related_year, 2026, 'related year');
is($K->new(year => 1984, month => 1, day => 1, calendar => 'chinese')->cyclic_year, 1, '1984 began a cycle (jia-zi)');
is($K->new(year => 1983, month => 1, day => 1, calendar => 'chinese')->cyclic_year, 60, 'and 1983 ended one');
is($C->months_in_year('chinese', 2025), 13, '2025 has a leap month');
is($C->month_code('chinese', 2025, 7), 'M06L', 'the leap sixth month, the seventh ordinal');
is((split /T/, $K->new(year => 2025, month => 7, day => 1, calendar => 'chinese')->iso8601)[0], '2025-07-25', 'which began on 25 July 2025');
is($K->new(year => 2025, month_code => 'M06L', day => 1, calendar => 'chinese')->month, 7, 'by code');
is($K->new(year => 2025, month_code => 'M07', day => 1, calendar => 'chinese')->month, 8, 'M07 is the eighth ordinal that year');
is($C->months_in_year('chinese', 2033), 13, '2033 has a leap month');
is($C->month_code('chinese', 2033, 12), 'M11L', 'the leap eleventh month, the hard case');
is((split /T/, $K->new(year => 2033, month => 12, day => 1, calendar => 'chinese')->iso8601)[0], '2033-12-22', 'which began on 22 December 2033');
is($K->parse('2034-01-10T00:00:00Z', calendar => 'chinese')->month_code, 'M11L', '10 January 2034 is still in it');
is($C->months_in_year('chinese', 2026), 12, '2026 has none');
dies_like(sub { $K->new(year => 2026, month_code => 'M06L', day => 1, calendar => 'chinese') }, qr/has no month M06L/, 'no leap sixth month in 2026');
ok($C->days_in_month('chinese', 2026, 1) == 29 || $C->days_in_month('chinese', 2026, 1) == 30, 'a month has 29 or 30 days');
my $sum = 0;
$sum += $C->days_in_month('chinese', 2026, $_) for 1 .. 12;
is($C->days_in_year('chinese', 2026), $sum, 'the year is the sum of its months');
is($C->days_in_year('chinese', 2026), $K->new(year => 2027, month => 1, day => 1, calendar => 'chinese')->epoch / 86400 - $K->new(year => 2026, month => 1, day => 1, calendar => 'chinese')->epoch / 86400, 'and the days to the next New Year');
is($C->days_in_year('chinese', 2025), 384, '2025, with its leap month, 384');
is($C->is_leap_year('chinese', 2025), 1, 'is_leap_year');
is($C->kind('chinese'), 'astronomical', 'the kind is what the calendar is');
is(cal($t->plus(months => 1)), '2026-10-06', 'a month on');
is(cal($t->plus(years => 1)), '2027-09-06', 'a year on keeps the month code');
is(cal($K->new(year => 2025, month => 7, day => 1, calendar => 'chinese')->plus(years => 1)), '2026-06-01', 'a leap sixth month moved to a year without one is the sixth');
is($K->new(year => 2025, month => 7, day => 1, calendar => 'chinese')->plus(years => 1)->month_code, 'M06', 'by code, without the L');
is(cal($t->truncate(to => 'year')), '2026-01-01', 'truncate to the year');
is($t->truncate(to => 'year')->iso8601, '2026-02-17T00:00:00Z', 'New Year');
is($t->end_of(to => 'year')->plus(nanoseconds => 1)->iso8601, '2027-02-07T00:00:00Z', 'end_of year: the nanosecond before the next New Year');
is($t->end_of(to => 'year')->month, 12, 'in the twelfth month');
my $d = $K->new(year => 2027, month => 1, day => 1, calendar => 'chinese') - $t;
is($t->plus($d)->iso8601, '2027-02-07T00:00:00Z', 'the difference adds back');
my $dangi = $t->in_calendar('dangi');
is(cal($dangi), '2026-09-05', 'Dangi is a day behind here: the day began earlier at Seoul');
is($dangi->cyclic_year, 43, 'the same cycle');
is($C->name('dangi'), 'Dangi', 'its name');
my $differ = 0;
for my $y (1000 .. 3000) {
    $differ++ if $K->new(year => $y, month => 1, day => 1, calendar => 'chinese')->epoch != $K->new(year => $y, month => 1, day => 1, calendar => 'dangi')->epoch;
}
cmp_ok($differ, '>', 0, "the Dangi New Year differs from the Chinese in $differ of 2001 years");
dies_like(sub { $K->new(year => 999, month => 1, day => 1, calendar => 'chinese') }, qr/the chinese calendar is tabled for its years 1000 to 3000 only/, 'before the table');
dies_like(sub { $K->new(year => 3001, month => 1, day => 1, calendar => 'chinese') }, qr/tabled for its years 1000 to 3000/, 'after it');
dies_like(sub { $K->parse('0999-06-01T00:00:00Z', calendar => 'chinese')->year }, qr/tabled for its years/, 'a day before the table cannot be read');
dies_like(sub { $K->new(year => 3000, month => 12, day => 1, calendar => 'chinese')->plus(months => 2) }, qr/out of range/, 'nor stepped past');
is($K->new(year => 3000, month => 1, day => 1, calendar => 'chinese')->year, 3000, 'but 3000 itself is tabled whole');
my $last = $K->new(year => 3000, month => $C->months_in_year('chinese', 3000), day => $C->days_in_month('chinese', 3000, $C->months_in_year('chinese', 3000)), calendar => 'chinese');
is($last->month, 13, 'to its last day: 3000 has a leap month');
dies_like(sub { $last->plus(days => 1)->year }, qr/tabled for its years 1000 to 3000/, 'and the day after it cannot be read');
is((split /T/, $K->new(year => 1000, month => 1, day => 1, calendar => 'chinese')->iso8601)[0], '1000-02-13', 'and 1000 (New Year 13 February, by ICU)');

my $h = $K->new(year => 2026, month => 10, day => 15, zone => 'UTC')->in_calendar('islamic');
is(cal($h), '1448-05-05', '15 October 2026 is 5 Jumada I 1448 by the astronomical reckoning');
is(cal($h->in_calendar('islamic-rgsa')), '1448-05-05', 'and the same in islamic-rgsa, which ICU computes the same way');
is(cal($h->in_calendar('islamic-civil')), '1448-05-03', 'two days off the civil table');
is(cal($h->in_calendar('islamic-umalqura')), '1448-05-04', 'one off Umm al-Qura');
is((split /T/, $K->new(year => 1447, month => 2, day => 1, calendar => 'islamic')->iso8601)[0], '2025-07-25', '1 Safar 1447');
is($h->era, 'ah', 'the era');
is($C->kind('islamic'), 'astronomical', 'the kind');
for my $y (1447 .. 1452) {
    is($C->is_leap_year('islamic', $y), $C->days_in_year('islamic', $y) == 355 ? 1 : 0, "$y AH is leap exactly when it has 355 days (" . $C->days_in_year('islamic', $y) . ")");
}
ok((grep { $C->is_leap_year('islamic', $_) } 1447 .. 1452) >= 1, 'and some of them are');
is($C->days_in_year('islamic', 1448), $K->new(year => 1449, month => 1, day => 1, calendar => 'islamic')->epoch / 86400 - $K->new(year => 1448, month => 1, day => 1, calendar => 'islamic')->epoch / 86400, 'the year length is what the two New Years say');
dies_like(sub { $K->new(year => 389, month => 1, day => 1, calendar => 'islamic') }, qr/tabled for its years 390 to 2452/, 'before the Hijri table');
is(cal($h->plus(months => 7)), '1448-12-05', 'a month step within the table');
is(cal($h->plus(years => 1)), '1449-05-05', 'a year step');
is(cal($h->truncate(to => 'month')), '1448-05-01', 'truncate');
my $hd = $K->new(year => 1450, month => 1, day => 1, calendar => 'islamic') - $h;
is($h->plus($hd)->epoch, $K->new(year => 1450, month => 1, day => 1, calendar => 'islamic')->epoch, 'K12');

done_testing;

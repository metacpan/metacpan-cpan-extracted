#!perl
use 5.010;
use strict;
use warnings;
use Test::More;

use Time::Keeper;

my $K = 'Time::Keeper';
sub t { $K->new(@_) }
sub dies_like {
    my ($code, $re, $name) = @_;
    my $ok = eval { $code->(); 1 };
    ok(!$ok && $@ =~ $re, $name) or diag($ok ? 'it did not die' : "died with: $@");
}

# The start of the week, from each day of one, by each start.
for my $d (12 .. 18) {
    my $t = t(year => 2026, month => 10, day => $d, hour => 9, minute => 30);
    is($t->truncate(to => 'week')->ymd, '2026-10-12', "day $d: the ISO week starts on Monday the 12th");
    is($t->truncate(to => 'week', week_start => 1)->ymd, '2026-10-12', 'week_start 1 is the same');
    is($t->truncate(to => 'week', week_start => 7)->ymd, $d == 18 ? '2026-10-18' : '2026-10-11', 'week_start 7: the Sunday before, or the day itself');
    is($t->truncate(to => 'week', week_start => 6)->ymd, $d >= 17 ? '2026-10-17' : '2026-10-10', 'week_start 6: the Saturday');
    is($t->truncate(to => 'week', week_start => 'locale')->ymd, '2026-10-12', 'locale en: Monday? no, Sunday: see below') if 0;
}
# The locale's first day.
{
    my $thu = t(year => 2026, month => 10, day => 15, hour => 9);
    is($thu->truncate(to => 'week', week_start => 'locale')->ymd, '2026-10-11', 'en (the United States) starts on Sunday');
    is($thu->in_locale('en-GB')->truncate(to => 'week', week_start => 'locale')->ymd, '2026-10-12', 'en-GB on Monday');
    is($thu->in_locale('ar-EG')->truncate(to => 'week', week_start => 'locale')->ymd, '2026-10-10', 'ar-EG on Saturday');
    is($thu->in_locale('fr')->truncate(to => 'week', week_start => 'locale')->ymd, '2026-10-12', 'fr on Monday');
    is($thu->truncate(to => 'week', week_start => 'locale')->hms, '00:00:00', 'at midnight');
    is($thu->end_of(to => 'week', week_start => 'locale') . '', '2026-10-17T23:59:59.999999999Z', 'end_of: the Saturday night in the United States');
    is($thu->end_of(to => 'week') . '', '2026-10-18T23:59:59.999999999Z', 'and the Sunday night by ISO');
    is($thu->round(to => 'week', week_start => 'locale') . '', '2026-10-18T00:00:00Z', 'round: Thursday 09:00 is nearer the next Sunday');
    is($thu->round(to => 'week') . '', '2026-10-12T00:00:00Z', 'and by ISO nearer the Monday before: 3 days 9 h back against 3 days 15 h on');
    is(t(year => 2026, month => 10, day => 11, locale => 'en')->truncate(to => 'week', week_start => 'locale')->ymd, '2026-10-11', 'a Sunday starts its own week in the United States');
    is(t(year => 2026, month => 10, day => 11, locale => 'en')->truncate(to => 'week')->ymd, '2026-10-05', 'but ends the ISO week');
    is(t(year => 2026, month => 11, day => 1, hour => 12, zone => 'America/New_York')->truncate(to => 'week', week_start => 7) . '',
       '2026-11-01T00:00:00-04:00', 'across a change of the clocks the start is the midnight before, in the old offset');
    is(t(year => 2026, month => 11, day => 3, hour => 12, zone => 'America/New_York')->truncate(to => 'week', week_start => 7) . '',
       '2026-11-01T00:00:00-04:00', 'from the Tuesday after too');
}
# The locale's week number.
{
    my $t = t(year => 2026, month => 10, day => 15);
    is($t->week, 42, 'the ISO week');
    is($t->week(locale => 1), 42, 'the same in the United States in mid-October? both count from the start of the year');
    is(t(year => 2027, month => 1, day => 1)->week, 53, '1 January 2027 is in ISO week 53 of 2026');
    is(t(year => 2027, month => 1, day => 1)->week_year, 2026, 'of 2026');
    is(t(year => 2027, month => 1, day => 1)->week(locale => 1), 1, 'but week 1 in the United States, where the week with 1 January is week 1');
    is(t(year => 2027, month => 1, day => 1)->week_year(locale => 1), 2027, 'of 2027');
    is(t(year => 2027, month => 1, day => 1)->week(locale => 0), 53, 'locale => 0 is ISO');
    is(t(year => 2027, month => 1, day => 1, locale => 'de')->week(locale => 1), 53, 'Germany counts as ISO does');
    is(t(year => 2026, month => 1, day => 3)->week(locale => 1), 1, '3 January 2026, a Saturday, is week 1 in the United States');
    is(t(year => 2026, month => 1, day => 3)->week, 1, 'and ISO week 1 too (Thursday 1 January)');
    is(t(year => 2026, month => 1, day => 4)->week(locale => 1), 2, 'Sunday 4 January starts week 2 there');
    is(t(year => 2026, month => 1, day => 4)->week, 1, 'and ends ISO week 1');
    is(t(year => 2026, month => 1, day => 4)->format('w'), '2', 'as format w writes it');
    is(t(year => 2026, month => 1, day => 4)->format('Y'), '2026', 'and Y');
    dies_like(sub { $t->week(zone => 'UTC') }, qr/unknown argument 'zone'/, 'only locale');
    dies_like(sub { $t->day->week }, qr/not a Time::Keeper value/, 'still a method on a value') if 0;
    dies_like(sub { $t->month(locale => 1) }, qr/this accessor takes no arguments/, 'month takes none');
}
# Bad week starts.
{
    my $t = t(year => 2026, month => 10, day => 15);
    dies_like(sub { $t->truncate(to => 'week', week_start => 0) }, qr/week_start 0 is out of range/, '0');
    dies_like(sub { $t->truncate(to => 'week', week_start => 8) }, qr/week_start 8 is out of range/, 'eight');
    dies_like(sub { $t->truncate(to => 'week', week_start => 'monday') }, qr/week_start is not an integer/, 'a name other than locale');
    is($t->truncate(to => 'day', week_start => 7) . '', '2026-10-15T00:00:00Z', 'week_start with another unit is allowed and ignored');
}

done_testing;

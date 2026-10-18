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

my $t = t(year => 2026, month => 10, day => 15, hour => 9, minute => 41, second => 17, nanosecond => 123456789);

# Increments.
{
    is($t->round(to => 'minute', increment => 15) . '', '2026-10-15T09:45:00Z', '09:41:17 to 15 minutes is 09:45');
    is($t->round(to => 'minute', increment => 15, mode => 'floor') . '', '2026-10-15T09:30:00Z', 'floor is 09:30');
    is($t->round(to => 'minute', increment => 15, mode => 'ceil') . '', '2026-10-15T09:45:00Z', 'ceil is 09:45');
    is($t->with(minute => 52)->round(to => 'minute', increment => 15, mode => 'ceil') . '', '2026-10-15T10:00:00Z',
       'ceil of minute 52 is the next hour');
    is($t->with(minute => 52)->round(to => 'minute', increment => 15) . '', '2026-10-15T09:45:00Z', 'but 09:52:17 is nearer 09:45');
    is($t->with(minute => 53)->round(to => 'minute', increment => 15) . '', '2026-10-15T10:00:00Z', 'and 09:53:17 nearer 10:00');
    is($t->round(to => 'hour', increment => 6) . '', '2026-10-15T12:00:00Z', '09:41 to 6 hours is 12:00');
    is($t->round(to => 'hour', increment => 6, mode => 'floor') . '', '2026-10-15T06:00:00Z', 'floor is 06:00');
    is($t->with(hour => 21)->round(to => 'hour', increment => 6) . '', '2026-10-16T00:00:00Z', '21:41 to 6 hours is the next midnight');
    is($t->round(to => 'second', increment => 15) . '', '2026-10-15T09:41:15Z', '17.1 s to 15 s is 15');
    is($t->round(to => 'millisecond', increment => 250) . '', '2026-10-15T09:41:17Z', '123 ms to 250 ms is 0');
    is($t->round(to => 'millisecond', increment => 250, mode => 'ceil') . '', '2026-10-15T09:41:17.250Z', 'ceil is 250');
    is($t->round(to => 'microsecond', increment => 500) . '', '2026-10-15T09:41:17.123500Z', '456 us to 500 us is 500');
    is($t->round(to => 'nanosecond', increment => 100) . '', '2026-10-15T09:41:17.123456800Z', '789 ns to 100 ns is 800');
    is($t->round(to => 'nanosecond', increment => 100, mode => 'floor') . '', '2026-10-15T09:41:17.123456700Z', 'floor 700');
    is($t->round(to => 'minute', increment => 1) . '', $t->round(to => 'minute') . '', 'increment 1 is the plain round');
    is($t->round(to => 'nanosecond') . '', "$t", 'to the nanosecond is the value');
    is($t->round(to => 'minute', increment => 15)->locale, $t->locale, 'the locale is kept');
}

# Modes at a midpoint and either side of it.
{
    my $mid = $t->with(minute => 37, second => 30, nanosecond => 0);
    is($mid->round(to => 'minute', increment => 15, mode => 'half_floor') . '', '2026-10-15T09:30:00Z', 'half_floor at the midpoint');
    is($mid->round(to => 'minute', increment => 15, mode => 'half_ceil') . '', '2026-10-15T09:45:00Z', 'half_ceil at the midpoint');
    is($mid->round(to => 'minute', increment => 15) . '', '2026-10-15T09:45:00Z', 'which is the default');
    is($mid->round(to => 'minute', increment => 15, mode => 'half_even') . '', '2026-10-15T09:30:00Z',
       'half_even: bucket 38 of the day is even');
    is($t->with(minute => 52, second => 30, nanosecond => 0)->round(to => 'minute', increment => 15, mode => 'half_even') . '',
       '2026-10-15T10:00:00Z', 'bucket 39 is odd, so up');
    my $under = $mid->with(nanosecond => 0)->minus(nanoseconds => 1);
    my $over  = $mid->plus(nanoseconds => 1);
    for my $mode (qw(half_floor half_ceil half_even)) {
        is($under->round(to => 'minute', increment => 15, mode => $mode) . '', '2026-10-15T09:30:00Z', "$mode a nanosecond under goes down");
        is($over->round(to => 'minute', increment => 15, mode => $mode) . '', '2026-10-15T09:45:00Z', "$mode a nanosecond over goes up");
    }
    is($mid->round(to => 'minute', increment => 15, mode => 'floor') . '', '2026-10-15T09:30:00Z', 'floor');
    is($mid->round(to => 'minute', increment => 15, mode => 'ceil') . '', '2026-10-15T09:45:00Z', 'ceil');
    my $start = $t->truncate(to => 'hour');
    is($start->round(to => 'hour', mode => 'ceil') . '', "$start", 'ceil of a value at a start stays');
    is($start->round(to => 'hour', mode => 'half_even') . '', "$start", 'as does every mode');
    # half_even in every unit.
    is($t->with(minute => 30, second => 0, nanosecond => 0)->round(to => 'hour', mode => 'half_even') . '', '2026-10-15T10:00:00Z',
       'hour 9 is odd: up');
    is($t->with(hour => 10, minute => 30, second => 0, nanosecond => 0)->round(to => 'hour', mode => 'half_even') . '',
       '2026-10-15T10:00:00Z', 'hour 10 is even: down');
    is($t->with(second => 30, nanosecond => 0)->round(to => 'minute', mode => 'half_even') . '', '2026-10-15T09:42:00Z',
       'minute 581 of the day is odd: up');
    is($t->with(minute => 40, second => 30, nanosecond => 0)->round(to => 'minute', mode => 'half_even') . '', '2026-10-15T09:40:00Z',
       'minute 580 is even: down');
    is($t->with(minute => 30, second => 0, nanosecond => 0)->round(to => 'minute', increment => 20, mode => 'half_even') . '',
       '2026-10-15T09:20:00Z', 'the 20-minute bucket 28 of the day is even: down, though 30 is bucket 1 of the hour');
    is($t->with(hour => 10, minute => 30, second => 0, nanosecond => 0)->round(to => 'minute', increment => 20, mode => 'half_even') . '',
       '2026-10-15T10:40:00Z', 'bucket 31 is odd: up');
    is($t->with(nanosecond => 500000000)->round(to => 'second', mode => 'half_even') . '', '2026-10-15T09:41:18Z',
       'second 34877 of the day is odd: up');
    is($t->with(second => 16, nanosecond => 500000000)->round(to => 'second', mode => 'half_even') . '', '2026-10-15T09:41:16Z',
       'second 34876 is even: down');
    is($t->with(nanosecond => 123500000)->round(to => 'millisecond', mode => 'half_even') . '', '2026-10-15T09:41:17.124Z',
       'millisecond ...123 is odd: up');
    is($t->with(nanosecond => 122500000)->round(to => 'millisecond', mode => 'half_even') . '', '2026-10-15T09:41:17.122Z',
       'millisecond ...122 is even: down');
    is($t->with(nanosecond => 123456500)->round(to => 'microsecond', mode => 'half_even') . '', '2026-10-15T09:41:17.123456Z',
       'microsecond ...456 is even: down');
    is($t->with(nanosecond => 123457500)->round(to => 'microsecond', mode => 'half_even') . '', '2026-10-15T09:41:17.123458Z',
       'microsecond ...457 is odd: up');
    is($t->with(nanosecond => 123456750)->round(to => 'nanosecond', increment => 100, mode => 'half_even') . '',
       '2026-10-15T09:41:17.123456800Z', 'the 100-ns bucket ...567 is odd: up');
    is($t->with(nanosecond => 123456650)->round(to => 'nanosecond', increment => 100, mode => 'half_even') . '',
       '2026-10-15T09:41:17.123456600Z', 'the bucket ...566 is even: down');
    # Calendar units take the modes, one at a time.
    is($t->round(to => 'month', mode => 'floor') . '', '2026-10-01T00:00:00Z', 'floor to the month is truncate');
    is($t->round(to => 'month', mode => 'ceil') . '', '2026-11-01T00:00:00Z', 'ceil is the next month');
    is($t->round(to => 'year', mode => 'half_floor') . '', '2027-01-01T00:00:00Z', 'October is nearer the next year');
    is(t(year => 2026, month => 7, day => 2, hour => 12)->round(to => 'year', mode => 'half_even') . '', '2026-01-01T00:00:00Z',
       '2026 is even, so a midpoint stays (2026 is not a leap year, so 2 July noon is the midpoint)');
    is(t(year => 2027, month => 7, day => 2, hour => 12)->round(to => 'year', mode => 'half_even') . '', '2028-01-01T00:00:00Z',
       '2027 is odd, so up');
}

# Bad arguments.
{
    dies_like(sub { $t->round(to => 'hour', increment => 5) }, qr/increment 5 does not divide the 24 hours/, '5 hours do not divide a day');
    dies_like(sub { $t->round(to => 'minute', increment => 7) }, qr/increment 7 does not divide the 60 minutes/, 'nor 7 minutes an hour');
    dies_like(sub { $t->round(to => 'minute', increment => 60) }, qr/increment 60 is out of range/, '60 minutes is an hour');
    dies_like(sub { $t->round(to => 'hour', increment => 24) }, qr/increment 24 is out of range/, '24 hours is a day');
    dies_like(sub { $t->round(to => 'millisecond', increment => 3) }, qr/does not divide the 1000 milliseconds/, '3 ms');
    dies_like(sub { $t->round(to => 'day', increment => 2) }, qr/increment 2 is out of range/, 'the calendar units take no increment');
    dies_like(sub { $t->round(to => 'minute', increment => 0) }, qr/increment 0 is out of range/, 'nor 0');
    dies_like(sub { $t->round(to => 'minute', increment => 1.5) }, qr/increment is not an integer/, 'nor a fraction');
    dies_like(sub { $t->round(to => 'minute', mode => 'nearest') }, qr/mode is 'floor', 'ceil', 'half_floor', 'half_ceil', 'half_even', 'trunc' or 'expand', not 'nearest'/,
              'a mode it does not know');
    dies_like(sub { $t->round('minute') }, qr/say to => one of year/, 'round wants to =>');
    dies_like(sub { $t->round(increment => 5) }, qr/say to => one of year/, 'and to is required');
    dies_like(sub { $t->truncate(to => 'minute', increment => 5) }, qr/unknown argument 'increment'/, 'truncate takes no increment');
    dies_like(sub { $t->end_of(to => 'minute', mode => 'floor') }, qr/unknown argument 'mode'/, 'nor end_of a mode');
    dies_like(sub { $t->round(to => 'fortnight') }, qr/'fortnight' is not year, quarter.*nanosecond/, 'a unit it does not know');
}

# Leap seconds.
{
    my $leap = t(year => 2016, month => 12, day => 31, hour => 23, minute => 59, second => 60, nanosecond => 600000000);
    is($leap->round(to => 'second') . '', '2017-01-01T00:00:00Z', '23:59:60.6 to the second is the midnight after');
    is($leap->round(to => 'second', mode => 'floor') . '', '2016-12-31T23:59:60Z', 'floor stays in the leap second');
    is($leap->round(to => 'second', increment => 15) . '', '2016-12-31T23:59:60Z',
       'the leap second starts a 15-second bucket of its own, so .6 is nearer its start');
    is($leap->round(to => 'minute') . '', '2017-01-01T00:00:00Z', 'to the minute');
    is(t(year => 2016, month => 12, day => 31, hour => 23, minute => 59, second => 59, nanosecond => 600000000)
       ->round(to => 'second', increment => 15) . '', '2016-12-31T23:59:60Z', '23:59:59.6 to 15 s: the bucket from :45 ends at :60');
}

# Hours in increments are wall-clock buckets, whatever the day's length.
{
    # New York goes back at 02:00 on 1 November 2026: a 25-hour day.
    my $late = t(year => 2026, month => 11, day => 1, hour => 3, minute => 30, zone => 'America/New_York');
    is($late->round(to => 'hour', increment => 6) . '', '2026-11-01T06:00:00-05:00', '03:30 EST is 4.5 h into 00:00..06:00 and 2.5 h from its end');
    is($late->with(hour => 1, overlap => 'later')->round(to => 'hour', increment => 6) . '', '2026-11-01T00:00:00-04:00',
       'the second 01:30 is 2.5 h in and 4.5 h from the end');
    is($late->round(to => 'hour', increment => 6, mode => 'floor') . '', '2026-11-01T00:00:00-04:00', 'floor is the day\'s start');
    # New York goes forward at 02:00 on 8 March 2026: a 23-hour day.
    my $spring = t(year => 2026, month => 3, day => 8, hour => 3, minute => 30, zone => 'America/New_York');
    is($spring->round(to => 'hour', increment => 6) . '', '2026-03-08T06:00:00-04:00', '03:30 EDT is 2.5 h in and 2.5 h from the end: a tie, so later');
    is($spring->round(to => 'hour', increment => 6, mode => 'half_even') . '', '2026-03-08T00:00:00-05:00', 'half_even: bucket 0 is even');
    is($spring->round(to => 'hour', increment => 2) . '', '2026-03-08T04:00:00-04:00', '03:30 in the 02:00 bucket: 02:00 did not happen, so the bucket starts at 03:00');
    is($spring->round(to => 'hour', increment => 2, mode => 'floor') . '', '2026-03-08T03:00:00-04:00', 'floor of it');
    # Lord Howe goes forward half an hour at 02:00 on 4 October 2026.
    my $lh = t(year => 2026, month => 10, day => 4, hour => 1, minute => 50, zone => 'Australia/Lord_Howe');
    is($lh->round(to => 'minute', increment => 15) . '', '2026-10-04T01:45:00+10:30', '01:50 to 15 minutes is 01:45');
    is($lh->round(to => 'minute', increment => 15, mode => 'ceil') . '', '2026-10-04T02:30:00+11:00', 'ceil: 02:00 did not happen, 02:30 did');
    is($lh->with(minute => 55)->round(to => 'minute', increment => 15) . '', '2026-10-04T02:30:00+11:00', 'and 01:55 is nearer the end of its bucket');
    is($lh->round(to => 'hour', increment => 2) . '', '2026-10-04T02:30:00+11:00', 'and 02:00 as a 2-hour boundary is 02:30');
    # Santiago has no midnight on 6 September 2026 (round to the day is t/26's).
    is(t(year => 2026, month => 9, day => 6, hour => 1, minute => 10, zone => 'America/Santiago')->round(to => 'hour', increment => 3) . '',
       '2026-09-06T01:00:00-03:00', 'the 00:00 bucket starts at the first moment, 01:00');
}

done_testing;

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

# Every unit, in UTC.
{
    my $t = t(year => 2026, month => 10, day => 15, hour => 9, minute => 41, second => 17,
              nanosecond => 123456789);
    my %want = (
        year        => '2026-12-31T23:59:59.999999999Z',
        quarter     => '2026-12-31T23:59:59.999999999Z',
        month       => '2026-10-31T23:59:59.999999999Z',
        week        => '2026-10-18T23:59:59.999999999Z',
        day         => '2026-10-15T23:59:59.999999999Z',
        hour        => '2026-10-15T09:59:59.999999999Z',
        minute      => '2026-10-15T09:41:59.999999999Z',
        second      => '2026-10-15T09:41:17.999999999Z',
        millisecond => '2026-10-15T09:41:17.123999999Z',
        microsecond => '2026-10-15T09:41:17.123456999Z',
    );
    is($t->end_of(to => $_) . '', $want{$_}, "end_of $_") for sort keys %want;
    is(t(year => 2026, month => 2, day => 3)->end_of(to => 'quarter') . '', '2026-03-31T23:59:59.999999999Z',
       'the first quarter ends on 31 March');
    is(t(year => 2028, month => 2, day => 3)->end_of(to => 'month') . '', '2028-02-29T23:59:59.999999999Z',
       'February of a leap year');
    is(t(year => 2026, month => 10, day => 18, hour => 9)->end_of(to => 'week') . '',
       '2026-10-18T23:59:59.999999999Z', 'on a Sunday the week ends that day');
    my $last = t(year => 2026, month => 10, day => 15, hour => 9, minute => 41, second => 17,
                 nanosecond => 999999999);
    is($last->end_of(to => 'second') . '', "$last", 'a value already at .999999999 is its own end');
    is($t->end_of(to => 'day')->locale, $t->locale, 'the locale is kept');
    is(t(year => 2026, month => 10, day => 15, locale => 'fr')->end_of(to => 'day')->locale, 'fr', 'in any locale');
}

# The sub-second units of truncate and round.
{
    my $t = t(year => 2026, month => 10, day => 15, hour => 9, minute => 41, second => 17,
              nanosecond => 123456789);
    is($t->truncate(to => 'millisecond') . '', '2026-10-15T09:41:17.123Z', 'truncate to the millisecond');
    is($t->truncate(to => 'microsecond') . '', '2026-10-15T09:41:17.123456Z', 'to the microsecond');
    is($t->round(to => 'millisecond') . '', '2026-10-15T09:41:17.123Z', 'round to the millisecond, down');
    is($t->round(to => 'microsecond') . '', '2026-10-15T09:41:17.123457Z', 'to the microsecond, up');
    is($t->with(nanosecond => 123500000)->round(to => 'millisecond') . '', '2026-10-15T09:41:17.124Z',
       'half way rounds up');
    is($t->with(nanosecond => 999999999)->round(to => 'millisecond') . '', '2026-10-15T09:41:18Z',
       'over the second');
    is($t->truncate(to => 'nanosecond') . '', "$t", 'truncate to the nanosecond is the value');
    is($t->end_of(to => 'nanosecond') . '', "$t", 'and so is its end');
    dies_like(sub { $t->end_of('day') }, qr/say to => one of year/, 'end_of wants to =>');
}

# Leap seconds.
{
    my $l = t(year => 2016, month => 12, day => 31, hour => 23, minute => 59, second => 59);
    is($l->end_of(to => 'day') . '', '2016-12-31T23:59:60.999999999Z', 'a day that ends in a leap second');
    is($l->end_of(to => 'year') . '', '2016-12-31T23:59:60.999999999Z', 'and the year');
    is($l->end_of(to => 'minute') . '', '2016-12-31T23:59:60.999999999Z', 'and the minute');
    my $in = t(year => 2016, month => 12, day => 31, hour => 23, minute => 59, second => 60, nanosecond => 500);
    is($in->end_of(to => 'second') . '', '2016-12-31T23:59:60.999999999Z', 'the end of the leap second');
    is($in->truncate(to => 'millisecond') . '', '2016-12-31T23:59:60Z', 'truncated within it');
    is($in->end_of(to => 'millisecond') . '', '2016-12-31T23:59:60.000999999Z', 'its first millisecond ends');
    is(t(year => 2016, month => 12, day => 31, hour => 23, minute => 59, second => 59)->end_of(to => 'second') . '',
       '2016-12-31T23:59:59.999999999Z', 'the second before it ends where every second does');
}

# The clocks changing.
{
    # Santiago's clocks go from 24:00 to 01:00 on 6 September 2026: the day has no midnight.
    my $sun = t(year => 2026, month => 9, day => 6, hour => 12, minute => 30, zone => 'America/Santiago');
    is($sun->end_of(to => 'day') . '', '2026-09-06T23:59:59.999999999-03:00', 'the end of the day with no midnight');
    is($sun->minus(days => 1)->end_of(to => 'day') . '', '2026-09-05T23:59:59.999999999-04:00',
       'the day before ends the nanosecond before the skipped midnight');
    is($sun->truncate(to => 'day') . '', '2026-09-06T01:00:00-03:00', 'its start is the first moment that happened');
    is($sun->round(to => 'day') . '', '2026-09-07T00:00:00-03:00',
       'round: the next midnight is the real one, not the first moment plus a day');
    is(t(year => 2026, month => 9, day => 6, hour => 12, zone => 'America/Santiago')->round(to => 'day') . '',
       '2026-09-06T01:00:00-03:00', 'and noon is nearer the start');
    # New York goes back at 02:00 on 1 November 2026.
    my $ny = t(year => 2026, month => 11, day => 1, hour => 12, zone => 'America/New_York');
    is($ny->end_of(to => 'day') . '', '2026-11-01T23:59:59.999999999-05:00', 'a 25-hour day ends at 23:59:59.999999999');
    is($ny->end_of(to => 'day')->minus_absolute($ny->truncate(to => 'day'))->total_seconds, 25 * 3600 - 1e-9,
       'and is 25 hours long');
    my $second = t(year => 2026, month => 11, day => 1, hour => 1, minute => 30, zone => 'America/New_York',
                   overlap => 'later');
    is($second->end_of(to => 'hour') . '', '2026-11-01T01:59:59.999999999-05:00', 'the second 01:30 ends the second 01 hour');
    is($second->minus(hours => 1)->end_of(to => 'hour') . '', '2026-11-01T01:59:59.999999999-04:00', 'the first, the first');
    # Lord Howe's clocks go from 02:00 to 02:30 on 4 October 2026.
    my $lh = t(year => 2026, month => 10, day => 4, hour => 1, minute => 30, zone => 'Australia/Lord_Howe');
    is($lh->end_of(to => 'hour') . '', '2026-10-04T01:59:59.999999999+10:30', 'an hour ending at a half-hour change');
    is($lh->end_of(to => 'day') . '', '2026-10-04T23:59:59.999999999+11:00', 'and its day');
    # Floating time has no changes and no leap seconds.
    is(t(year => 2016, month => 12, day => 31, zone => 'floating')->end_of(to => 'day') . '',
       '2016-12-31T23:59:59.999999999', 'floating time has no leap second to end in');
}

# The edge of the range.
is($K->max->end_of(to => 'year') . '', "" . $K->max, 'the last year ends where the range does');
is($K->max->end_of(to => 'second') . '', "" . $K->max, 'as does the last second');
is($K->max->minus(days => 1)->end_of(to => 'day') . '', "+999999999-12-30T23:59:59.999999999Z", 'the day before has a next');

done_testing;

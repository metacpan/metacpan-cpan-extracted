package Time::Keeper;

use 5.010;
use strict;
use warnings;

our $VERSION = '0.09';

our $CLOCK;

use XSLoader;
XSLoader::load('Time::Keeper', $VERSION);

use overload
    '<=>'  => \&_compare,
    'cmp'  => \&_compare,
    '""'   => \&TO_JSON,
    '+'    => '_add_overload',
    '-'    => '_sub_overload',
    'bool' => sub { 1 },
    fallback => 1;

use Time::Keeper::Duration;
use Time::Keeper::Date;
use Time::Keeper::YearMonth;
use Time::Keeper::MonthDay;
use Time::Keeper::Time;
use Time::Keeper::Calendar;

1;

__END__

=encoding utf8

=head1 NAME

Time::Keeper - dates and times with time zones, leap seconds and locales

=head1 VERSION

Version 0.09

=head1 SYNOPSIS

    use Time::Keeper;

    my $now   = Time::Keeper->now;                          # UTC
    my $there = Time::Keeper->now(zone => 'Asia/Tokyo');
    my $here  = Time::Keeper->now(zone => 'local');

    my $t = Time::Keeper->new(
        year => 2026, month => 10, day => 15, hour => 9,
        zone => 'Europe/London',
    );

    print $t->year, '-', $t->month, '-', $t->day, "\n";     # 2026-10-15
    print $t->zone_abbr, ' ', $t->offset, "\n";             # BST 3600
    print "$t\n";                                           # 2026-10-15T09:00:00+01:00

    my $tokyo = $t->in_zone('Asia/Tokyo');                  # the same instant
    my $first = $t->with(day => 1);                         # a new value
    print $t < $tokyo ? "earlier\n" : "not earlier\n";      # not earlier: they are equal

    my $e = Time::Keeper->from_epoch('1760000000.123456789', zone => '+05:30');

=head1 DESCRIPTION

Time::Keeper is a date and time library that does what L<Time::Piece> and
L<DateTime> do between them and is much faster than either. With time zones from the IANA
database, nanoseconds, leap seconds, and a calendar that runs from the year
-999,999,999 to 999,999,999.

A value is one instant, a time zone, and nothing else. B<Values never
change.> A method that would change one, such as L</with> or L</in_zone>,
returns a new value and leaves the old one as it was.

A value with no zone given is in UTC. The time zones live in
L<Time::Keeper::Zone>, which is loaded the first time a named zone is
asked for: a program that works only in UTC, in fixed offsets or in
floating time never loads the zone data.

Names and formats come from the value's locale, any of the more than a
thousand in the Unicode Common Locale Data Repository (CLDR); see
L</LOCALES>. English is the default.

=head1 CONSTRUCTORS

Every constructor is a class method and takes its arguments as name and
value pairs. An argument it does not know, or one given twice, is an error
that names it.

=head2 now

    my $t = Time::Keeper->now;
    my $t = Time::Keeper->now(zone => 'Asia/Tokyo');

The current time, to the nanosecond where the system gives it, or the
clock a test pinned (see L</TESTING>). C<zone> is
described under L</TIME ZONES>. Every constructor also takes C<locale>, as
described under L</LOCALES>, and C<calendar>, as described under
L</CALENDARS>.

=head2 today

    my $t = Time::Keeper->today(zone => 'local');

Midnight at the start of today in the zone. Where a zone's clocks jumped
over midnight, as some zones' spring changes do, it is the first moment of
the day that did happen: C<today> never dies on such a day.

=head2 try_new

    my $t = Time::Keeper->try_new(year => 2026, month => 2, day => 30);   # undef

As L</new>, but undef where L</new> would die, and C<$@> left as it was.

=head2 new

    my $t = Time::Keeper->new(
        year       => 2026,     # required
        month      => 10,       # 1 to 12; default 1
        day        => 15,       # default 1
        hour       => 9,        # 0 to 23; default 0
        minute     => 30,       # default 0
        second     => 0,        # 0 to 59, or 60 for a leap second; default 0
        nanosecond => 0,        # default 0
        zone       => 'Europe/London',
        gap        => 'croak',
        overlap    => 'earlier',
        locale     => 'en-GB',
    );

The value whose wall-clock time in the zone is the one given. A field out
of range, or a day the month does not have, is an error that names it.
C<gap> and C<overlap> are described under L</GAPS AND OVERLAPS>, and a
second of 60 under L</LEAP SECONDS>.

=head2 last_day_of_month

    my $t = Time::Keeper->last_day_of_month(year => 2028, month => 2);    # 29th

As L</new>, with the day the last of the month and C<month> required.

=head2 from_day_of_year

    my $t = Time::Keeper->from_day_of_year(year => 2026, day_of_year => 288);

As L</new>, with the date given by its day of the year, 1 to 365 or 366 in
a leap year.

=head2 from_iso_week

    my $t = Time::Keeper->from_iso_week(year => 2026, week => 42, day => 4);

As L</new>, with the date given by its ISO 8601 week: the week year, the
week (1 to 52, or 53 in a year that has one) and the day of the week, 1 for
Monday to 7 for Sunday, Monday if not given.

=head2 from_epoch

    my $t = Time::Keeper->from_epoch(1760000000);
    my $t = Time::Keeper->from_epoch('1760000000.123456789', zone => 'UTC');

The instant a number of seconds after 1970-01-01T00:00:00 UTC, in the zone
given. An integer, or a string of digits with up to nine decimal places, is
taken exactly. A number with a fraction is rounded to the microsecond,
because a floating-point number holds no more than that for times near
today: pass a string when the nanoseconds matter.

=head2 from_epoch_millis

=head2 from_epoch_micros

=head2 from_epoch_nanos

    my $t = Time::Keeper->from_epoch_millis(1760000000123, zone => 'Asia/Tokyo');
    my $t = Time::Keeper->from_epoch_nanos('1760000000123456789');

The instant a whole number of milliseconds, microseconds or nanoseconds
after the epoch: an integer, or a string of digits for one too large for the
perl's integers. A fraction is an error, since L</from_epoch> takes those.
Negative numbers count back, so -1 millisecond is 23:59:59.999 on 31
December 1969. A leap second cannot be named this way: the epoch has no
number for it.

=head2 from_object

    my $t = Time::Keeper->from_object(object => $datetime);
    my $t = Time::Keeper->from_object(object => $datetime, zone => 'Asia/Tokyo', locale => 'ja');

The instant of any object with a C<utc_rd_values> method, as L<DateTime>
and the modules built on it have. The zone is C<zone> if given, else the
object's own (the name its C<time_zone> gives), else UTC. A floating object
gives a floating value.

An object without C<utc_rd_values> but with C<epoch>, as L<Time::Piece> and
L<Time::Moment> have, gives the instant that returns (a string with a
fraction is read exactly, as L</from_epoch> reads one); its C<nanosecond>,
if it has the method, is taken too, and its C<tzoffset>, in seconds, gives a
fixed zone (UTC for an offset of zero) unless C<zone> is given. A
Time::Piece from C<localtime> is best given C<< zone => 'local' >>, so the
value has the machine's zone and its rules rather than one offset.

=head2 max

=head2 min

    my $last  = Time::Keeper->max;   # +999999999-12-31T23:59:59.999999999Z
    my $first = Time::Keeper->min;   # -999999999-01-01T00:00:00Z

The last and first instants a value can hold, in UTC.

=head1 ACCESSORS

The date and time fields are those of the value's wall-clock time in its
zone. Each is an integer.

=head2 year

The year. Years are counted astronomically: the year before 1 is 0.

=head2 month

1 to 12.

=head2 day

The day of the month, from 1.

=head2 hour

0 to 23.

=head2 hour_12

1 to 12: the hour on a twelve-hour clock, 12 at midnight and at noon.
L</am_pm> says which.

=head2 minute

0 to 59.

=head2 second

0 to 59, or 60 during a leap second.

=head2 nanosecond

=head2 microsecond

=head2 millisecond

The fraction of the second in each unit: 0 to 999,999,999, 999,999 and
999.

=head2 day_of_week

1 for Monday to 7 for Sunday, as ISO 8601 numbers them.

=head2 day_of_year

1 to 365, or 366 in a leap year.

=head2 quarter

1 to 4.

=head2 day_of_quarter

The day of the quarter, from 1.

=head2 week

=head2 week_year

    $t->week;                 # 42, ISO 8601's
    $t->week(locale => 1);    # the locale's: 43 in the United States

The ISO 8601 week, 1 to 53, and the year it belongs to. Weeks begin on a
Monday, and week 1 is the week with the year's first Thursday in it, so
the first days of January can belong to the last week of the year before.
With C<< locale => 1 >>, the week as the value's locale counts it, as
L</format>'s C<w> and C<Y> write it: from the locale's first day of the
week, with week 1 the first that holds its minimum of days of January.

=head2 week_of_month

The week of the month, 0 to 5, counted as DateTime counts it: the first
week is the first that has a Thursday in the month.

=head2 is_leap_year

True in a leap year.

=head2 is_weekend

=head2 is_weekday

True on a day of the locale's weekend, and true on any other day: Saturday
and Sunday in most of the world, Friday and Saturday in Egypt, Thursday and
Friday in Afghanistan, Sunday alone in India, as CLDR has it for the
locale's territory.

=head2 days_in_month

=head2 days_in_quarter

=head2 days_in_year

The number of days in the value's month, quarter and year.

=head2 offset

The zone's offset from UTC at this instant, in seconds east of UTC.

=head2 is_dst

True when the zone is on daylight saving time at this instant. Some zones
mark their winter time as daylight saving time and their summer time as
standard, as Ireland does: this says what the database says.

=head2 standard_offset

The offset of the zone's standard time at this instant, in seconds east of
UTC: in summer, the offset the clocks are an hour ahead of. The offset
itself for a fixed zone, 0 for UTC and floating time. What the database
calls standard is not always what the clocks are called: Europe/Dublin's
standard time is +01:00 all year, and its winter GMT is a daylight time an
hour behind it. Needs L<Time::Keeper::Zone> 0.03 or later.

=head2 dst_offset

How far the offset in force is from the standard one: L</offset> less
L</standard_offset>. 3600 in London in July, 1800 on Lord Howe Island in
January, 0 where the clocks have not moved, and -3600 in Dublin in winter.

=head2 is_utc

=head2 is_floating

True when the value is in UTC, or in floating time.

=head2 zone_name

The zone's name as it was given (a link, such as C<US/Eastern>, keeps its
own name), C<UTC>, C<floating>, or the offset of a fixed zone, such as
C<+05:30>.

=head2 zone_abbr

The zone's abbreviation at this instant, such as C<BST> or C<JST>, C<UTC>,
the offset of a fixed zone, or the empty string in floating time. Not every
zone has letters for its abbreviations: many are numbers, such as C<+04>.

=head2 locale

The value's locale, as its code: C<en>, C<fr-CA>.

=head2 epoch

The seconds from 1970-01-01T00:00:00 UTC, as an integer. During a leap
second it is that of the midnight after it.

=head2 hires_epoch

The same with the fraction of the second, as a floating-point number.

=head2 epoch_string

The same as a string, exact to the nanosecond: give it to L</from_epoch>
to have the instant back.

=head2 epoch_millis

=head2 epoch_micros

=head2 epoch_nanos

The same in milliseconds, microseconds and nanoseconds, as whole numbers:
the fraction below the unit is dropped, so -1 millisecond is 23:59:59.999 on
31 December 1969. Milliseconds and microseconds are an integer where one
fits, and past that a floating-point number, exact below 2**53 (every
millisecond of the next 280,000 years); nanoseconds are an integer on a
64-bit perl between September 1677 and April 2262, and a string of digits
beyond that or on a 32-bit perl, as L</epoch_string> is. During a leap
second the second is that of the midnight after, as L</epoch> has it.

=head2 julian_day

=head2 mjd

The Julian Day and the Modified Julian Day, with the fraction of the day.
A Julian Day begins at noon UTC.

=head2 tai_offset

TAI minus UTC, in seconds: 10 from 1972, and one more after each leap
second. Undefined before 1972, and in floating time. See L</LEAP SECONDS>.

=head1 NEW VALUES FROM OLD

=head2 with

    my $first = $t->with(day => 1);
    my $noon  = $t->with(hour => 12, minute => 0, second => 0);

A value in the same zone with the wall-clock fields given changed and the
rest as they were. It takes the fields L</new> does, apart from C<zone>,
and C<gap> and C<overlap>. C<day> may be C<last>, the last day of the
month; C<day_of_week>, 1 for Monday to 7 for Sunday, moves to that day of
the same ISO 8601 week, after the other fields have been set.

    my $end = $t->with(month => 2, day => 'last');
    my $sun = $t->with(day_of_week => 7);
    my $doy = $t->with(year => 2027, day_of_year => 60);
    my $wk  = $t->with(week => 1, day_of_week => 1);

C<day_of_year>, 1 to 366, and C<week>, an ISO 8601 week of the year
given or the value's own, set the date instead of C<month> and C<day>, and
cannot be given with them; C<week> keeps the value's day of the week unless
C<day_of_week> says otherwise.

=head2 try_with

As L</with>, but undef where L</with> would die, and C<$@> left as it was.

=head2 in_zone

    my $tokyo = $t->in_zone('Asia/Tokyo');

The same instant, in another zone. To or from floating time it is the
wall-clock time that is kept instead, and C<gap> and C<overlap> may be
given for that.

=head2 in_locale

    my $fr = $t->in_locale('fr');

The same instant in the same zone, with names and formats from another
locale.

=head2 as_utc

C<< $t->in_zone('UTC') >>.

=head2 as_floating

The same wall-clock time in floating time.

=head2 to_date

=head2 to_year_month

=head2 to_month_day

=head2 to_time

    $t->to_date;          # a Time::Keeper::Date: the wall-clock date
    $t->to_year_month;    # a Time::Keeper::YearMonth
    $t->to_month_day;     # a Time::Keeper::MonthDay
    $t->to_time;          # a Time::Keeper::Time: the wall-clock time of day

The value's wall-clock date or time of day, or part of the date, as a plain
class with the value's locale (see L</DATES WITHOUT TIMES>). During a leap
second C<to_time> gives 23:59:59.999999999, the last time of day there is.
C<< $t->date >> and C<< $t->time >> are still the strings.

=head1 ARITHMETIC

Amounts of time are L<Time::Keeper::Duration>s. Adding one to a value adds
its months first, then its days, to the wall-clock date, keeping the
wall-clock time; then its minutes, 60 seconds each; then its seconds,
which count leap seconds. So a day added across a change of the clocks
keeps the time of day, and 24 hours added does not:

    my $t = Time::Keeper->new(year => 2026, month => 3, day => 7, hour => 12,
                              zone => 'America/New_York');
    $t->plus(days => 1);     # 2026-03-08T12:00:00-04:00
    $t->plus(hours => 24);   # 2026-03-08T13:00:00-04:00

The difference of two values is the duration that takes the one to the
other: C<< $a->plus($b - $a) >> is always C<$b>. It has the most whole months
that do not go past C<$b>, then the most whole days, then the rest as
minutes and seconds.
C<$a - $b> is not always the negation of C<$b - $a>: months are not all one
length, so counting back from C<$b> can take a different number of days
than counting on from C<$a>.

=head2 plus

    my $later = $t->plus(months => 1, days => 2);
    my $later = $t->plus($duration);
    my $later = $t->plus(days => 1, gap => 'forward');

A new value, the duration later. It takes a duration, or the units of one
by name as L<Time::Keeper::Duration/new> takes them, and C<gap> and
C<overlap> for a wall-clock time the months or days land on that did not
happen or happened twice; see L</GAPS AND OVERLAPS>. C<$t + $duration> is
the same with the defaults.

=head2 minus

    my $earlier = $t->minus(days => 2);
    my $earlier = $t->minus($duration);
    my $between = $b->minus($a);        # a Time::Keeper::Duration

Given a duration or its units, a new value the duration earlier. Given
another value, the duration from that value to this one, as above.
C<$t - $duration> and C<$b - $a> are the same.

=head2 minus_absolute

    my $d = $b->minus_absolute($a);

The time from C<$a> to C<$b> as seconds and nanoseconds alone, counting
leap seconds: the time that passed.

=head2 delta_days

The number of days between the two values' dates, as a duration of days,
never negative.

=head2 delta_md

The months and days between the two values' dates, never negative.

=head2 delta_ms

The minutes and seconds between the two values, never negative.

=head2 until

=head2 since

    my $d = $a->until($b);                            # the same as $b - $a
    my $d = $a->until($b, largest => 'hours');        # PT747H30M15.5S
    my $d = $b->since($a, largest => 'weeks', smallest => 'days');
    my $d = $a->until($b, smallest => 'hours', mode => 'half_ceil');
    my $d = $a->until($b, smallest => 'minutes', increment => 15);

The duration from this value to C<$b> (C<until>), or from C<$a> to this
value (C<since>), in the units asked for. C<largest> is the largest unit
the duration may have: C<years> or C<months> give months, then days, then
the clock, as L</minus> does; C<weeks> or C<days> give days, then the clock;
C<hours> or C<minutes> give minutes of 60 seconds and then seconds; C<seconds>
and below give seconds alone, the time that passed, counting leap seconds
(a leap second crossed shows in the seconds whatever the largest unit).

C<smallest> drops the parts below it and rounds the unit's own part, to a
multiple of C<increment> for a clock unit, by C<mode>: C<trunc>, towards
zero, the default; C<expand>, away from it; and L</round>'s C<floor>,
C<ceil>, C<half_floor>, C<half_ceil> and C<half_even>, where C<floor> of a
negative duration is away from zero. The two candidates are measured as
instants from the start, so a day is as long as it was there, and a clock
part that rounds up into a whole day is carried into the days.

C<< $a->plus($a->until($b, largest => ...)) >> is C<$b> for every
C<largest>; with C<smallest> it is C<$b> rounded.

=head2 truncate

    my $monday = $t->truncate(to => 'week');
    my $ms     = $t->truncate(to => 'millisecond');

The start of the value's year, quarter, month, week (a Monday), day, hour,
minute, second, millisecond, microsecond or nanosecond. Where that wall-clock
time did not happen, the first moment after it that did.

    $t->truncate(to => 'week', week_start => 7);          # the Sunday
    $t->truncate(to => 'week', week_start => 'locale');   # the locale's first day

C<week_start> says what day a week begins on, 1 for Monday to 7 for Sunday,
or C<locale> for the value's locale's first day of the week: Sunday in the
United States, Saturday in Egypt. L</round> and L</end_of> take it too.

=head2 round

    my $t = $t->round(to => 'minute');
    my $t = $t->round(to => 'minute', increment => 15);
    my $t = $t->round(to => 'hour', increment => 6, mode => 'floor');

The start of the nearest year, quarter, month, week, day, hour, minute,
second, millisecond, microsecond or nanosecond, the later of two as near.

C<increment> rounds to a multiple of the unit: 15 minutes, 6 hours, 100
nanoseconds. It is for the clock units, and must divide the next unit up:
1 to 23 dividing 24 for an hour, a divisor of 60 for a minute or a second,
of 1000 for the rest. Hours in increments are counted on the wall clock, so
six-hour buckets begin at 00:00, 06:00, 12:00 and 18:00 local time whatever
the day's length; a bucket whose start the clocks skipped begins at the
first moment that did happen.

C<mode> says which way:

    floor       the start of the value's own bucket, as truncate gives it
    ceil        the start of the next, unless the value is at a start
    half_floor  the nearer, the earlier of two as near
    half_ceil   the nearer, the later of two as near; the default
    half_even   the nearer, the even-numbered bucket of two as near,
                counted from the start of the day, or of the calendar
    trunc       floor, and expand is ceil: for a value they are the same,
                and L</until> and L<Time::Keeper::Duration/round> tell them apart

Nearer is by the time that passed, so around a change of the clocks the two
candidates are not an equal number of wall-clock minutes apart.

=head2 end_of

    my $last = $t->end_of(to => 'month');    # 2026-10-31T23:59:59.999999999Z

The last nanosecond of the value's year, quarter, month, week, day, hour,
minute, second, millisecond, microsecond or nanosecond: the instant before
the next one begins. On a day that ends in a leap second it is 23:59:60.999999999, and on
a day whose midnight the clocks skipped it is the nanosecond before the
first moment that did happen.

=head2 next

=head2 previous

    my $monday = $t->next(day_of_week => 1);
    my $friday = $t->previous(day_of_week => 5, or_same => 1);

The value's time of day on the next, or the previous, day of the week
given, 1 for Monday to 7 for Sunday: strictly after, or before, the value's
own day, unless C<or_same> is true, when a value already on that day is
given back as it is. C<gap> and C<overlap> may be given, as for L</plus>.

=head2 nth_in_month

=head2 last_in_month

    my $thanksgiving = $t->nth_in_month(day_of_week => 4, n => 4);
    my $change       = $t->last_in_month(day_of_week => 7);

The value's time of day on the nth day of the week given in the value's
month, C<n> 1 to 5, or on the last of them with C<n> -1 or
C<last_in_month>. A month with no fifth such day is an error that names
it. C<gap> and C<overlap> as for L</plus>.

=head2 range

    my @days   = $start->range($end, by => 'day');
    my @weeks  = $start->range($end, by => 'week', inclusive => 0);
    my @hours  = $start->range($end, by => 'hour', step => 2);
    my @months = $start->range($end, by => 'month', end_of_month => 'limit');
    my @back   = $end->range($start, by => Time::Keeper::Duration->new(days => -1));
    my @safe   = $start->range($end, by => 'day', gap => 'forward');

The values from the start to the end, a step apart. C<by> is a unit name,
singular or plural, or a L<Time::Keeper::Duration>; C<step> multiplies it.
Each value is the start plus the step times its position, never the value
before plus the step, so a month from 31 January gives 3 March, 31 March
and 1 May, as L</plus> would, and C<end_of_month> says what a short month
does. The end is included when the step lands on it, unless
C<< inclusive => 0 >>. The step must move toward the end: a zero step, a
step with parts of both signs, or an end the step walks away from is an
error. C<gap> and C<overlap> as for L</plus>: a step of a day that keeps a
time of day the clocks skipped dies unless told what to do. A range of more
than about ten million values is refused; L</iterate> has no limit.

=head2 iterate

    my $next = $start->iterate($end, by => 'month');
    while (my $t = $next->()) { ... }

As L</range>, but a code ref giving the next value each time it is called
and undef after the last, for ranges too long to hold at once. Each
iterator keeps its own place; a copy made for a thread continues on its
own.

=head2 In another calendar

    my $t = Time::Keeper->new(year => 5784, month => 6, day => 30, calendar => 'hebrew');   # 30 Adar I
    $t->plus(months => 1);                           # 29 Adar II, wrapped to 1 Nisan
    $t->plus(months => 13, end_of_month => 'limit'); # 29 Adar 5785
    $t->plus(years => 1);                            # Adar 5785: a year without Adar I
    $t->plus(years => 3)->month_code;                # M05L: 5787 has one again
    $b - $t;                                         # months then days, the calendar's months
    $t->truncate(to => 'year');                      # 1 Tishri

In a calendar other than the Gregorian a month is the calendar's ordinal
month (L</CALENDARS>), so twelve months on from a day in a thirteen-month
Hebrew year is the month before the same month next year. C<years>, given
by name to L</plus> or L</minus>, are added first and keep the month by
its code: a day in Adar I moved to a year with no Adar I lands in Adar, as
ICU and Temporal have it, and C<end_of_month> says what a day the month
has not does. A L<Time::Keeper::Duration> has no years of its own: its
months are months, and L</minus>, L</until> and L</delta_md> give months
and days, so C<< $a + ($b - $a) >> is C<$b> in every calendar. L</truncate>,
L</round> and L</end_of> work on the calendar's years, quarters (three
ordinal months, a thirteenth month alone in quarter 5) and months, and on
the units below a week as ever; L</nth_in_month> and L</last_in_month> use
the calendar's month; L</next>, L</previous> and L</range> are days and are
the same in every calendar.

=head2 Months and the end of the month

A month added to 31 January has no 31st to land on. A duration says what to
do, as its C<end_of_month>: C<wrap> runs on into the next month (3 March, or
2 March in a leap year), C<limit> stops at the last day (28 February), and
C<preserve> keeps the last day of a month the last day of the month it
lands in. A duration of a positive number of months wraps unless told
otherwise, and one of a negative number preserves, as in L<DateTime>.

L<Time::Piece>'s C<add_months> and C<add_years> are C<< plus(months => $n) >> and
C<< plus(years => $n) >>, which wrap as they do.

=head1 FORMATTING

Names and formats come from the value's locale (see L</LOCALES>).
Formatting gives back characters: English's time formats put a narrow
no-break space (U+202F) before AM and PM, as CLDR has them.

=head2 strftime

    $t->strftime('%Y-%m-%d %H:%M:%S.%3N %z');
    my ($d, $tm) = $t->strftime('%F', '%T');

The conversions of C's C<strftime>, as L<DateTime> has them:

    %a %A     the day's name, short and long
    %b %h %B  the month's name, short and long
    %c %x %X  the locale's date and time, its date, its time
    %C        the century
    %d %e     the day of the month, padded with 0 and with a space
    %D %F     %m/%d/%y and %Y-%m-%d
    %g %G %V  the ISO week year in two digits and in full, the ISO week
    %H %k     the hour 0 to 23, padded with 0 and with a space
    %I %l     the hour 1 to 12, padded with 0 and with a space
    %j        the day of the year
    %m %M %S  the month, the minute, the second
    %N        nanoseconds; %3N milliseconds, %6N microseconds, %9N nanoseconds
    %p %P     AM or PM, am or pm
    %r %R %T  %I:%M:%S %p, %H:%M and %H:%M:%S
    %s        the epoch
    %u %w     the day of the week, 1 to 7 from Monday, 0 to 6 from Sunday
    %U %W     the week of the year, weeks starting on Sunday, on Monday
    %y %Y     the year in two digits and in full
    %z %Z     the offset as +HHMM, the zone's abbreviation
    %n %t %%  a newline, a tab, a %
    %{name}   what the method of that name returns

glibc's flags are taken too: C<%-d> drops the padding, C<%_d> pads with
spaces, C<%0e> with zeros, C<%^a> upper-cases, and a width such as
C<%10Y> pads a number to it. The names, and C<%c>, C<%x> and C<%X>, are the
locale's; the numbers are ASCII digits, as the machine-readable forms
strftime is used for need, except with glibc's C<O> modifier: C<%Od> is the
day in the locale's own digits (in C<ar-EG>, C<١٥>). C<E> is read and passed
over. A conversion it does not know is left as it
was. During a leap second C<%S> is 60. In floating time C<%z> is C<+0000>
and C<%Z> is C<floating>, as in DateTime. Given several patterns,
C<strftime> gives a result for each.

=head2 format

    $t->format('EEEE, d MMMM y');           # Thursday, 15 October 2026
    $t->format("h 'o''clock' a");           # 9 o'clock PM

A CLDR pattern, as Unicode Technical Standard 35 defines them. A run of
one letter is a field, and how many letters says how it is written: C<M>
10, C<MM> 10, C<MMM> Oct, C<MMMM> October, C<MMMMM> O. Text in single
quotes is written as it is, and C<''> is a quote. The fields:

    G         era
    y u       year
    Y         week year, as the locale counts weeks
    Q q       quarter
    M L       month
    w W       week of the year and of the month, as the locale counts them
    d D F     day of the month, day of the year, weekday in the month
    g         modified Julian day
    E e c     weekday
    a b B     AM or PM; noon and midnight; the period of the day
    h H K k j hour
    m s       minute, second
    S         fraction of a second
    A         milliseconds in the day
    z v V     zone names
    Z O X x   offsets

Numbers are written in the locale's own digits (see L</LOCALES>), except
the ISO 8601 offsets of C<X>, C<x> and C<Z>.

Weeks are counted as the locale counts them: a week starts on the
locale's first day, and week 1 of a year is the first to hold at least the
locale's minimum of days of January. In the United States weeks start on
Sunday and the week holding the 1st of January is week 1; in most of Europe
they are ISO 8601's. C<W> is 0 for the days before a month's first week.
L</week> and L</week_year> stay ISO's.

C<b> writes noon and midnight at exactly those times, and AM or PM at any
other. C<B> writes the locale's period of the day: C<in the morning>,
C<at night>, C<du soir>. A locale with no periods writes AM or PM.

The zone names are CLDR's, chosen as Unicode Technical Standard 35 says:

    z zzzz    the specific name: EDT, Eastern Daylight Time
    v vvvv    the generic name: ET, Eastern Time
    V         the zone's short id: usnyc
    VV        the zone's name: America/New_York
    VVV       the city: New York
    VVVV      the location: New York Time, France Time
    O OOOO    the GMT format: GMT-4, GMT-04:00, in the locale's words

A name the locale does not have falls back as the standard says: a
specific name to the GMT format; a generic one to the standard name, for a
zone with no daylight time within six months, then to the location, then
to the GMT format. A zone's name is the one in use at the time: Indiana's
Knox was on Eastern time in 1995 and is on Central time now.

Where L<DateTime>'s C<format_cldr> departs from the standard, the standard
is followed: C<YY> is the week year in two digits, not padded to two;
C<c> and C<e> count the days from the locale's first day of the week
(Sunday in the United States), not from Monday; C<w>, C<W> and C<Y> count
weeks as the locale does, not as ISO 8601 does; C<g> counts local days,
from local midnight, not UTC ones; C<ZZZZ> is C<GMT-04:00>, not
C<EDT-0400>; C<ZZZZZ> and C<X> write C<Z> for a zero offset; C<QQQQQ>,
C<aaaa> and C<aaaaa> have their narrow and wide forms; C<z>, C<v> and C<V>
are CLDR's names, not the zone's abbreviation (C<GMT+9>, not C<JST>, where
the locale has no name for it); and numbers are in the locale's digits.

=head2 format_date

=head2 format_time

=head2 format_datetime

    $t->format_date('full');       # Thursday, October 15, 2026
    $t->format_time('short');      # 9:05 PM
    $t->format_datetime;           # Oct 15, 2026, 9:05:07 PM

The locale's own format for the date, the time, or both, at C<full>,
C<long>, C<medium> (the default) or C<short>.

=head2 format_skeleton

    $t->format_skeleton('yMMMd');  # Oct 15, 2026

The locale's format for a skeleton: the fields wanted, without their order
or punctuation, which are the locale's. A skeleton the locale has no format
for is an error.
In another calendar the calendar's own skeletons come first (a C<y> matches
the C<yyyy> they are keyed by), then the Gregorian ones; see L</CALENDARS>.

=head2 format_relative

    $t->format_relative;                                  # 3 hours ago
    $t->format_relative(to => $then);                     # in 2 days
    $t->format_relative(unit => 'day');                   # yesterday
    $t->format_relative(numeric => 'always');             # 1 day ago
    $t->in_locale('fr')->format_relative(style => 'short');   # il y a 3 h

The value as a time relative to C<to>, which is now if not given, in the
locale's words, as C<Intl.RelativeTimeFormat> writes one. C<unit> is C<auto>
(the default: the largest of year, month, week, day, hour, minute and second
with a count that is not zero), or one of them, or C<quarter>. Days, weeks,
months and years are counted on the wall-clock dates in the value's zone, so
23:00 yesterday is C<yesterday> at 09:00 today, and hours, minutes and
seconds by the time that passed. C<style> is C<long>, C<short> or C<narrow>.
With C<numeric> C<auto>, the default, a count the locale has a word for is
written as the word: C<yesterday>, C<today>, C<tomorrow>, C<last month>,
C<now>; with C<always> it is written as a number: C<1 day ago>, C<in 0
days>. Numbers are in the locale's digits.

=head2 format_interval

    $a->format_interval($b, skeleton => 'yMMMd');   # Oct 15 – 17, 2026
    $a->format_interval($b, skeleton => 'hm');      # 9:00 – 10:30 AM
    $a->in_locale('fr')->format_interval($b, skeleton => 'yMMMd');   # 15–17 oct. 2026

The two values as an interval in the locale's words, as
C<Intl.DateTimeFormat>'s C<formatRange> writes one: the fields the skeleton
names, with what the two ends share written once. The greatest field that
differs, of era, year, month, day, the period of the day, hour and minute,
chooses the locale's interval format for the skeleton; where the two ends
agree in every field the skeleton shows, the start alone is written, as
L</format_skeleton> writes it; where they differ in a field the skeleton
does not show, both are written in full round the locale's dash. The end is
brought into the start's zone and written in the start's locale; the two are
written in the order given. A skeleton the locale has no interval formats
for is an error, and a value in floating time pairs only with another.

=head2 month_name

=head2 month_abbr

=head2 day_name

=head2 day_abbr

=head2 am_pm

=head2 era_name

=head2 era_abbr

=head2 quarter_name

=head2 quarter_abbr

The names, in the value's locale: C<October>, C<Oct>, C<Thursday>,
C<Thu>, C<PM>, C<Anno Domini>, C<AD>, C<4th quarter>, C<Q4>.

=head2 ymd

=head2 mdy

=head2 dmy

=head2 hms

=head2 date

=head2 time

    $t->ymd;           # 2026-10-15
    $t->dmy('/');      # 15/10/2026
    $t->hms('');       # 090507

The date in three orders, and the time, with the separator given (C<->
for dates and C<:> for the time by default). C<date> and C<time> are
C<ymd> and C<hms> with the default separators.

=head2 rfc3339

The RFC 3339 form: as L</iso8601>, and with its C<precision> option. RFC
3339 has no form for floating time or for a year outside 0000 to 9999,
and asking for one is an error.

=head2 rfc2822

    Thu, 15 Oct 2026 21:05:07 -0400

The Internet Message Format's date (RFC 5322, which replaced RFC 2822), in
English whatever the locale, without a fraction of a second.

=head2 rfc9557

    2026-10-15T21:05:07-04:00[America/New_York]

RFC 3339 with the zone's name after it in brackets, as RFC 9557 extends it:
the offset and the zone together, so a reader has the zone's rules as
well as the offset at that moment. UTC is C<+00:00[UTC]> and a fixed offset
names itself. Floating time has neither.
A value in another calendar ends C<[u-ca=hebrew]>, which L</parse> reads
back (see L</CALENDARS>).

=head2 http_date

    Fri, 16 Oct 2026 01:05:07 GMT

The date HTTP uses (RFC 9110): the instant in GMT, in English.

=head1 PARSING

Every parser makes a value the way L</new> does: a date that does not
exist, a weekday that is not the date's, or a leap second that was not one
is an error, and C<zone>, C<gap> and C<overlap> may be given. Text that
does not say its zone is read in C<zone>, or in UTC. An error says where in
the text it went wrong:

    Time::Keeper->parse: cannot parse '2026-10-15T25:00' at offset 13: the hour is past 24

=head2 parse

    my $t = Time::Keeper->parse('2026-10-15T09:00:00+09:00[Asia/Tokyo]');
    my $t = Time::Keeper->parse('Thu, 15 Oct 2026 09:00:00 +0900');
    my $t = Time::Keeper->parse('2026-10-15 09:00', zone => 'Europe/London');

Any of the standard forms:

=over 4

=item * ISO 8601, in the extended and the basic forms: calendar dates
(C<2026-10-15>), week dates (C<2026-W42-4>) and ordinal dates
(C<2026-288>), a year or a month alone, expanded years (C<+012026>), times
to the hour, minute or second with a fraction of the last (C<T09.5> is half
past nine), C<24:00> as the end of the day, and an offset or C<Z>.

=item * RFC 3339, which is ISO 8601 with a space allowed for the C<T>,
and RFC 9557, which adds the zone's name in brackets. Where the text has an
offset and a zone, the offset fixes the instant and the zone is the value's;
if they disagree and the zone is marked critical (C<[!Asia/Tokyo]>) it is
an error. C<[u-ca=gregory]> is understood; another calendar is refused, as
is any other critical annotation.

=item * The Internet Message Format's date (RFC 5322 and RFC 2822), with
the obsolete zone names (C<EST>, C<PDT>, and the military letters, which
are UTC), two-digit years, and comments; and the three forms HTTP accepts
(RFC 9110), including RFC 850's and C's C<asctime>.

=item * C<@> and an epoch, as GNU's C<date> reads one: C<@1760000000.5>.

=back

=head2 try_parse

As L</parse>, but undef where L</parse> would die, and C<$@> left as it was.

=head2 strptime

    my $t = Time::Keeper->strptime('15/10/2026 21:05', '%d/%m/%Y %H:%M');
    my $t = Time::Keeper->strptime('Thu Oct 15 9:05 PM', '%a %b %d %I:%M %p',
                                   zone => 'America/New_York');

The text read by a L</strftime> pattern. Every conversion L</strftime>
writes is read back, except C<%{method}>. Names are the locale's, matched in
any case, short or long, and digits may be any script's. White space in the pattern matches any amount, or none. A
field the pattern does not give takes L<Time::Piece>'s default: the year
1970, January, the 1st, midnight. C<%y> 69 to 99 is 1969 to 1999, and 00 to
68 is 2000 to 2068, as POSIX has it. C<%Z> reads an abbreviation: C<UTC>,
C<GMT>, C<UT> and C<Z> are UTC; any other could mean more than one zone and
is checked against C<zone>, which must be given, and in an overlap it says
which of the two times was meant.
With C<calendar>, the date conversions read that calendar's months and
years; see L</CALENDARS>.

=head2 try_strptime

As L</strptime>, but undef where it would die.

=head2 parse_cldr

    my $t = Time::Keeper->parse_cldr('Thursday, 15 October 2026', 'EEEE, d MMMM y');

The text read by a CLDR pattern, as L</format> writes them, in the locale
given by C<locale>. Where two numeric fields meet with nothing between
(C<yyyyMMdd>), each reads its own width. White space, and CLDR's no-break
spaces, match any amount. Digits may be any script's, in any locale.

The zone's names are read back: a specific or generic name, a city, a
location, or the GMT format in the locale's words or in plain C<GMT> or
C<UTC>. A name read gives the value its zone; a specific name says
standard or daylight time, which chooses between the two readings of a time
in an overlap. C<b> and C<B> make a 12-hour time AM or PM.
With C<calendar>, the eras, years and months are the calendar's, as
L</CALENDARS> describes; an RFC 9557 C<[u-ca=]> annotation in the text must
agree with it.

=head2 try_parse_cldr

As L</parse_cldr>, but undef where it would die.

=head2 parse_interval

    my ($start, $end) = Time::Keeper->parse_interval('2026-10-01/P1M');

An ISO 8601 interval: a start and an end, a start and a duration, or a
duration and an end, with a C</> between. Both values are given back.

=head1 COMPARING AND PRINTING

Values compare with C<< <=> >>, C<cmp> and the operators made from them,
so C<sort { $a <=> $b }> and C<$t == $u> work. Two values are equal when
they are the same instant, whatever their zones. A value in floating time
is a wall-clock time and not an instant: compared with any value, it is
the wall-clock times that are compared. Comparing a value with anything
that is not one is an error.

In a string a value is its L</iso8601> form.

=head2 compare

    my @sorted = sort { Time::Keeper->compare($a, $b) } @values;

-1, 0 or 1, as C<< <=> >> gives.

=head2 utc_rd_values

=head2 local_rd_values

    my ($days, $seconds, $nanoseconds) = $t->utc_rd_values;

The instant as L<DateTime> counts time between modules: the day counted
from 1 January of the year 1 as day 1, the seconds into it (86400 during a
leap second) and the nanoseconds; in UTC, or on the value's wall clock.
With them, C<< DateTime->from_object(object => $t) >> works.

=head2 iso8601

    2026-10-15T09:00:00+01:00
    2026-10-15T09:00:00.250Z

The ISO 8601 form: the wall-clock time and the offset, C<Z> for a value in
UTC, and no offset in floating time. A zone whose offset is zero, such as
London in winter, is C<+00:00>, not C<Z>: C<Z> says the time is UTC and
nothing about local time, as RFC 3339 has it. A fraction of a second is given in 3, 6 or 9
digits, whichever is the fewest that is exact. With C<precision>, exactly that many
digits, 0 to 9, truncated:

    $t->iso8601(precision => 3);   # 2026-10-15T09:00:00.123Z Years before 0 or after
9999 take ISO 8601's expanded form, such as C<+012026>.

    $t->iso8601(form => 'basic');     # 20261015T090000Z
    $t->iso8601(form => 'week');      # 2026-W42-4T09:00:00Z
    $t->iso8601(form => 'ordinal');   # 2026-288T09:00:00Z

C<form> chooses among ISO 8601's forms: C<extended>, the default, with its
separators; C<basic>, without them, as file names like it; C<week>, the
week date; and C<ordinal>, the day of the year. L</parse> reads the three
back, except a C<basic> form with an expanded year, whose number of year
digits ISO 8601 leaves to agreement. L</rfc3339> and L</rfc9557> take
C<precision> only.

=head2 TO_JSON

The L</iso8601> form, for JSON encoders that call C<TO_JSON>.

=head2 to_list

    my ($sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst) = $t->to_list;

The nine fields C<localtime> gives, in its conventions: the month from 0,
the year less 1900, Sunday 0, the day of the year from 0, and whether the
zone is on daylight saving time; the second is 60 during a leap second. For
code that was fed C<localtime>'s list.

=head1 TIME ZONES

A C<zone> argument is one of:

=over 4

=item * nothing, or C<undef>: UTC

=item * C<UTC>, C<GMT> or C<Z>: UTC

=item * C<floating>: a wall-clock time with no zone, as a calendar entry
might have

=item * an offset, such as C<+05:30>, C<-0800> or C<+01>: a fixed offset from
UTC of under 24 hours

=item * a zone's name from the IANA database, such as C<Europe/London>, in any
case; see L<Time::Keeper::Zone> for the names

=item * C<local>: this machine's zone, as L<Time::Keeper::Zone/local_name>
finds it

=item * another value: its zone

=back

=head1 GAPS AND OVERLAPS

When a zone's clocks go forward, the wall-clock times they jump over did
not happen; when they go back, the times they repeat happened twice.

C<gap> says what to do with a time that did not happen: C<croak>, the
default, dies with a message that says so; C<forward> gives the instant it
would be with the offset from before the change, which is later than the
change by the length of the gap; C<backward> gives the instant it would be
with the offset from after it.

C<overlap> says which of two instants to take: C<earlier>, the default, or
C<later>.

B<Ambiguity.> A value made can be asked whether its wall-clock time was
one of the repeated ones, and for the other instant that reads the same.
Both are worked out from the value's civil fields, however it was made: a
value from an epoch is as ambiguous as one from a wall clock. The methods
here, and L</next_transition> and L</previous_transition>, need
L<Time::Keeper::Zone> 0.03 or later, and die naming it with an older one.

=head2 is_ambiguous

True when the value's wall-clock time happened twice in its zone. False
in UTC, in a fixed offset and in floating time, and for a time the clocks
jumped over.

=head2 other_reading

    my $t = Time::Keeper->new(year => 2026, month => 11, day => 1, hour => 1, minute => 30,
                              zone => 'America/New_York');   # 01:30 EDT, the earlier
    $t->other_reading;                                       # 01:30 EST, an hour later

The other instant whose wall-clock time is this value's, in the same zone
(a link keeps its name) and locale, or undef when there is only one.

=head2 next_transition

=head2 previous_transition

    my $next = $t->next_transition;        # a value, or undef

The next, or the last, instant at which the value's zone changes its
offset, its DST flag or its abbreviation, as a value in the same zone and
locale, or undef when there is none. The next transition is strictly
after the value, the previous one strictly before it. UTC, a fixed offset
and floating time never change. L<Time::Keeper::Zone/transitions> lists
a zone's transitions over a span.

=head1 LEAP SECONDS

A leap second is 23:59:60 UTC on one of the 27 days that ended with one,
from 1972 to 2016. C<< second => 60 >> is accepted at that second, in any
zone (it was 08:59:60 in Tokyo), and refused at any other.

The leap seconds come from the list the International Earth Rotation and
Reference Systems Service publishes. It says when no further leap second
can come before:

=head2 leap_seconds_expire

    my $until = Time::Keeper->leap_seconds_expire;   # 2027-06-28T00:00:00Z

The list's expiry, as a value. Past it, no further leap second is known.
None has been added since 2016, and leap seconds are due to be given up by
2035.

=head1 LOCALES

    my $t = Time::Keeper->now(locale => 'fr');
    $t->format_date('full');              # jeudi 15 octobre 2026
    $t->in_locale('ja')->format_date('full');

A value's locale gives its names and formats: month and day names, eras,
AM and PM, the periods of the day, the date and time formats, the formats
by skeleton, the zone names, the first day of the week and the weekend, the
words for relative times, durations, lists and intervals, and its digits.
Every constructor and parser takes C<locale>; L</in_locale> changes it;
L</locale> gives it. The default is English, C<en>, as used in the United
States.

The data is the Unicode Common Locale Data Repository's, release 48.2.3,
for every locale in its C<full> set, every default-content code (C<fr-FR>,
which is C<fr>) and CLDR's aliases for retired codes (C<iw> is C<he>): the
codes L<DateTime::Locale> has, and more. A code is matched without regard to
case, with C<_> as C<->. L<Time::Keeper::Locale> lists them and answers
questions of each.

A locale's data is read the first time a value uses it, from one file
installed beside this module, and kept for the life of the process.
English is built in and reads nothing.

B<Digits.> Where a locale writes its own digits, as 84 do (C<ar-EG>, C<bn>,
C<fa>, C<mr>, C<my> and others), L</format>, L</format_date> and their
kin write them: C<١٥ أكتوبر ٢٠٢٦>. L<DateTime> writes ASCII digits in every
locale. L</strftime> writes ASCII digits unless asked with C<%O>, and the
fixed forms (L</iso8601>, L</rfc2822> and the others) always do. The
parsers read the digits of any script in any locale.

=head1 DATES WITHOUT TIMES

    my $d  = Time::Keeper::Date->new(year => 2026, month => 10, day => 15);
    my $ym = Time::Keeper::YearMonth->new(year => 2026, month => 10);
    my $md = Time::Keeper::MonthDay->new(month => 2, day => 29);
    my $tm = Time::Keeper::Time->new(hour => 9);
    my $t  = $d->at($tm, zone => 'Europe/London');

A date, a time of day, a year and month, and a month and day are classes
of their own: L<Time::Keeper::Date>, L<Time::Keeper::Time>,
L<Time::Keeper::YearMonth> and L<Time::Keeper::MonthDay>, loaded with this
module. None is a Time::Keeper
value and none pretends to be: a date has no hour and no zone, a pattern
letter that needs one is an error, and each compares only with its own
kind. They share the arithmetic, the locales, the formats and the parsers.
L</to_date>, L</to_time>, L</to_year_month> and L</to_month_day> take them
from a value; C<at>, C<on> and C<in_year> give a value or a date back.

=head1 CALENDARS

    my $t = Time::Keeper->new(year => 5787, month => 1, day => 1, calendar => 'hebrew');
    my $h = $t->in_calendar('hebrew');        # the same instant, read in another calendar
    $h->calendar;                             # hebrew
    $h->year;  $h->month;  $h->day;           # 5787, 1, 1: the calendar's
    $h->era;  $h->era_year;                   # am, 5787
    $h->month_code;  $h->is_leap_month;       # M01, 0
    $h->months_in_year;  $h->days_in_month;   # 13, 30
    $h->iso8601;  $h->epoch;  $h <=> $t;      # the instant, calendar blind

A value is an instant in a zone, and the calendar is how its wall-clock
date is read. Every constructor takes C<calendar>, and L</in_calendar> gives
the same instant read in another; the default is the Gregorian, never the
territory's. The accessors that name a date (L</year>, L</month>, L</day>,
L</day_of_year>, L</quarter>, L</day_of_quarter>, L</week_of_month>,
L</is_leap_year>, L</days_in_month>, L</days_in_year>, L</days_in_quarter>)
answer in the value's calendar; L</week> and L</week_year> are ISO 8601's
and stay Gregorian; the clock, the zone, the epoch, the comparisons and the
ISO 8601 strings are the same in every calendar.

Months are counted from the first month of the year as Temporal counts
them, so in a Hebrew leap year Adar I is the sixth month and Nisan the
eighth; L</month_code> gives the name that does not move, C<M07> for Nisan
and C<M05L> for Adar I. Quarters run over the ordinal months, three to a
quarter, so a thirteenth month is quarter 5. Years are continuous and may be
zero or negative; the era is a reading of the year:

    gregory          astronomical year            bce, ce
    buddhist         the Gregorian year + 543     be
    japanese         the Gregorian year           237 eras from Taika: era0 .. era231, meiji, taisho, showa, heisei, reiwa
    roc              the Gregorian year - 1911    broc, roc
    coptic           Anno Martyrum                before-am, am
    ethiopic         Amete Mihret                 aa (the year + 5500), am
    ethioaa          Amete Alem                   aa
    hebrew           Anno Mundi                   am
    islamic-*        Anno Hegirae                 ah, the years before it 0 and less, as ICU reads them
    persian          Anno Persico                 ap
    indian           Saka                         shaka
    chinese, dangi   the Gregorian year it begins in; era_year is ICU's count from 2637 BCE; cyclic_year 1 to 60

A Japanese day before Taika (645) is in the first era with a year of 0 or
less, as ICU reads it. The calendars are proleptic: the Buddhist, Japanese
and Minguo calendars are the Gregorian under another year count even before
1582, where ICU reads the Julian. The Persian calendar is ICU's 33-year
arithmetic with ICU's corrections, not the equinox; Umm al-Qura is Saudi
Arabia's table for 1300 to 1600 AH and the civil arithmetic outside it.
The four that follow the moon and the sun, C<chinese>, C<dangi>, C<islamic>
and C<islamic-rgsa>, are read from tables of what ICU computes, the Chinese
and Korean years 1000 to 3000 (1000 to 3000 is also the span ICU itself
warrants) and the Hijri years 390 to 2452 AH that lie within them; a day or
a year outside the tables is an error that names them. A Chinese or Dangi
year is named by the Gregorian year it begins in, its L</cyclic_year> is
its place in the cycle of sixty (1984 began one), and its leap month takes
the number of the month before it with an L: 2033's leap eleventh month is
C<M11L>, the twelfth ordinal month. The tables are ICU's and keep its few
disagreements with the Hong Kong Observatory, which has 2027's New Year on
6 February where ICU's new moon, at 23:56 Beijing time, gives the 7th.

Arithmetic in a calendar is described under L</ARITHMETIC>.

    $h->in_locale('he')->format('d MMMM y');              # ד׳ בחשוון תשפ״ז
    $t->in_calendar('japanese')->in_locale('ja')->format('Gy年M月d日');   # 令和8年10月15日
    $t->in_calendar('chinese')->format('U r');            # bing-wu 2026
    $h->format_date('full');  $h->month_name;  $h->era_abbr;
    $h->rfc9557;                                          # 2026-10-15T09:00:00+00:00[UTC][u-ca=hebrew]
    Time::Keeper->parse_cldr('24 Tishri 5787', 'd MMMM y', calendar => 'hebrew');

L</format>, L</strftime>, L</format_date>, L</format_datetime>,
L</format_skeleton>, L</ymd> and the name accessors write the value's
calendar: CLDR's month and era names for it in the value's locale, the
calendar's own date formats and skeletons, and its leap-month pattern
(C<Sixth Monthbis>, C<闰六月>). A locale with no names of its own for a
calendar inherits its parent's, then the root's; English is built in, so
every calendar works before the names file is read, and the file is read
on the first use of another locale. In a pattern C<G> is the calendar's
era, C<y> the year of the era, C<u> the continuous year, C<r> the Gregorian
year the calendar's year began in, C<U> the name of the cyclic year, and
C<M> or C<L> the month: as a number the ordinal month, as ICU writes it (the
Hebrew Iyar is 8 in a common year and 9 in a leap year), save that the
Chinese calendars write the number in the month code, the leap month in its
pattern (C<6bis>). A Chinese or Dangi year has four numbers:

    year, u       2026       the Gregorian year it began in
    y             43         its place in the cycle of sixty (cyclic_year)
    U             bing-wu    the cycle year's name (cyclic_year_name)
    r             2026       the related Gregorian year
    era_year, %Y  4663       ICU's continuous count from 2637 BCE

The numbering systems CLDR attaches to a calendar's patterns are honoured
when those patterns are used: a Hebrew date in C<he> is written in Hebrew
letters (C<ד׳ בחשוון תשפ״ז>, the thousands of the year dropped between
5001 and 5999 as ICU drops them), the day of a Chinese month in C<zh> in its
own numerals (C<初六>), the first year of a Japanese era in C<ja> as C<元>.
A pattern of your own is written in the locale's digits. The date
conversions of L</strftime> (C<%Y %y %C %m %d %e %j %B %b %x %c>) are the
calendar's and C<%G %V %g> stay ISO 8601: C<in_calendar('gregory')> first
for the Gregorian date. L</rfc9557> appends C<[u-ca=id]> for a value in
another calendar; L</parse> reads any known one (the date in the string is
always ISO 8601, as the RFC says) and refuses one that disagrees with a
C<calendar> argument. L</strptime> and L</parse_cldr> take C<calendar>:
C<G> matches the calendar's eras, C<y> and C<u> read the year of the era or
the continuous year, C<r> the related year, C<U> the cyclic year beside an
C<r> that fixes the cycle, and C<M>, C<L>, C<%m> and C<%B> the calendar's
month number or names and its leap pattern; a Chinese date needs a year.

The default calendar is the Gregorian everywhere, never the territory's;
L<Time::Keeper::Calendar/preferred> gives a territory's or a locale's
calendars in CLDR's order of preference, and a locale code may carry a
C<-u-ca-> extension naming a calendar, C<th-u-ca-buddhist>, which every
constructor, L</in_locale> and the parsers read as C<calendar> when none is
given and which L<Time::Keeper::Locale/code> strips. The day an era began is
L<Time::Keeper::Calendar/era_start>.

The plain classes in a calendar other than the Gregorian, L</format_relative>,
L</format_interval> and C<< largest => 'years' >> in L</until>, come in a
later release: each dies saying so on such a value.
L<Time::Keeper::Calendar> answers questions about a calendar that need no
value.

=head2 calendar

The id of the value's calendar: C<gregory> unless it was made or read in
another.

=head2 in_calendar

    my $h = $t->in_calendar('hebrew');

The same instant, zone and locale, read in the calendar given (an id or an
alias; see L<Time::Keeper::Calendar/ids>).

=head2 era

=head2 era_year

=head2 month_code

=head2 is_leap_month

=head2 months_in_year

=head2 related_year

=head2 cyclic_year

=head2 cyclic_year_name

The era's code and the year within it; the month's code (C<M01> to C<M13>,
C<L> after a leap month) and whether the month is a leap month; the months
in the year; the Gregorian year the calendar's year began in (CLDR's related
year); the year in the sixty-year cycle in the Chinese and Dangi calendars,
and its name in the value's locale (C<bing-wu>, C<丙午> in C<zh>), both undef
in the others.

=head1 SERIALISATION

A value freezes with L<Storable> as text: its instant, its zone by name
and its locale by code, so a value frozen by one release thaws in another.

A serialiser that calls no hook, such as L<Struct::Codec>, copies a value's
bytes and gives back a working value in the same process. The bytes hold
the zone by its place in L<Time::Keeper::Zone>'s table, which changes with
the zone database, so bytes kept past a release of that module may name
another zone: for storage, the hooks' text is the form to keep.

=head2 STORABLE_freeze

=head2 STORABLE_thaw

The L<Storable> hooks.

=head2 FREEZE

=head2 THAW

The same for the serialisers that use L<Types::Serialiser>'s protocol:
L<Sereal>, L<CBOR::XS> and L<JSON::XS> with C<allow_tags>. C<FREEZE> gives
the one string Storable gets, and C<THAW> takes it back.

=head1 C ABI

Another extension's C can do what a value does without calling Perl:
read the clock, find a zone by name, turn an instant into a wall clock in a
zone and back with the same choices for gaps and overlaps, write
C<strftime> and CLDR patterns in any locale, the ISO 8601 and HTTP dates,
parse every form L</parse> reads, find a locale by its code, and make a
Time::Keeper value or read one Perl made. Errors come back as codes rather
than exceptions. A value made there is a value here, and one from here can
be read there.

The interface is one header, F<time_keeper_abi.h>, installed with the
module. A consuming distribution finds it with L<ExtUtils::Depends>:

    my $pkg = ExtUtils::Depends->new('My::Module', 'Time::Keeper');

and resolves the table once, when it first needs it; the header shows how.
Nothing is linked against, and the table is versioned, so the two
distributions can be upgraded independently. It is at version 3: the
second version appended the calendars (an instant's fields read in any
calendar and back, formatting in one, the calendar a value is read in, a
calendar by its id), and the third the arithmetic the methods do (plus,
truncate, end_of, the weekday adjusters, a time set on a day), parse_cldr,
durations, a locale's code and weekend, a date (Time::Keeper::Date,
YearMonth and MonthDay) read and made, and a zone's next change of offset,
each failing with the reason its method would give. Each was appended after the entries before it, so a consumer
built against an older version keeps working.

=head1 THREADS

Values may be shared with or copied into threads.

=head2 CLONE

Sets up a new thread's copy of the module.

=head1 TESTING

    {
        local $Time::Keeper::CLOCK = Time::Keeper->parse('2026-10-15T09:00:00Z');
        Time::Keeper->now;                     # 2026-10-15T09:00:00Z
        Time::Keeper->today(zone => 'Asia/Tokyo');
        $t->format_relative;                   # measured from the pinned clock
    }
    local $Time::Keeper::CLOCK = sub { $t = $t->plus(seconds => 1) };
    local $Time::Keeper::CLOCK = sub { Time::Keeper->now->plus(hours => 1) };

Every reading of the clock, by L</now>, L</today>, L</format_relative>
without C<to>, L<Time::Keeper::Duration/compare> without a start and the
C ABI's C<now>, goes through C<$Time::Keeper::CLOCK> when it is defined.
It holds a value or an epoch, which pins the clock, or a code ref, called
for each reading, that returns either. While the code ref runs the system
clock is read, so the last example is a clock an hour fast. Set it with
C<local> so a test pins the clock for one block and nothing outside sees
it; it is for tests, and a module that sets it for its callers is in the
wrong. The pinned value's zone and locale are not taken: C<now> applies its
own arguments to the instant, as it does to the system's.

=head1 MOVING FROM TIME::PIECE AND DATETIME

=over 4

=item * B<Values never change.> DateTime's C<set>, C<add>, C<truncate> and
C<set_time_zone> change a value; L</with>, L</plus>, L</truncate> and
L</in_zone> return a new one. There is no C<clone>: a value is its own copy.

=item * B<UTC by default.> DateTime's default is floating time and
Time::Piece's C<localtime> is the machine's zone; here a value with no zone
is UTC, and C<< zone => 'local' >> asks for the machine's.

=item * B<A zone is a name and a locale a code.> L</zone_name> and
L</locale> give them; L<Time::Keeper::Zone> and L<Time::Keeper::Locale>
answer questions about them.

=item * B<Arithmetic adds months before days>, so C<< $b->minus($a) >> is
the duration that adds back to exactly C<$b>; DateTime adds days first, and
1.5% of its differences do not add back. L</delta_md> differs from
DateTime's in the same way.

=item * B<Gaps and overlaps> are chosen with C<gap> and C<overlap> (see
L</GAPS AND OVERLAPS>): a time that did not happen dies unless asked
otherwise, and of two that did the earlier is taken.

=item * B<In a string> a value is RFC 3339 with its offset;
C<< $t->strftime('%FT%T') >> is DateTime's form.

=item * B<Formatting follows CLDR> where DateTime's C<format_cldr> does
not (see L</format>): zone names, weeks counted as the locale counts them,
and the locale's own digits.

=item * C<< DateTime->from_object(object => $t) >> and
C<< Time::Keeper->from_object(object => $dt) >> move a time between the
two.

=back

Time::Piece's names map as C<mon> to L</month>, C<mday> to L</day>,
C<add_months> to C<< plus(months => $n) >>, C<localtime> to
C<< from_epoch($e, zone => 'local') >>; DateTime's as C<add> to L</plus>,
C<set> to L</with>, C<set_time_zone> to L</in_zone>, C<format_cldr> to
L</format>, C<time_zone_short_name> to L</zone_abbr>.

=head1 SEE ALSO

L<Time::Keeper::Zone>, L<DateTime>, L<Time::Piece>

=head1 AUTHOR

LNATION <email@lnation.org>

=head1 BUGS

Please report any bugs or feature requests to C<bug-time-keeper at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Time-Keeper>.

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

The locale data is from the Unicode Common Locale Data Repository,
Copyright (c) 1991-2026 Unicode, Inc., under the Unicode License v3.

=cut

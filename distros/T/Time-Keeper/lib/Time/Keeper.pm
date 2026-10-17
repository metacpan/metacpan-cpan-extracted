package Time::Keeper;

use 5.010;
use strict;
use warnings;

our $VERSION = '0.01';

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

1;

__END__

=encoding utf8

=head1 NAME

Time::Keeper - dates and times with time zones, leap seconds and locales

=head1 VERSION

Version 0.01

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

The current time, to the nanosecond where the system gives it. C<zone> is
described under L</TIME ZONES>. Every constructor also takes C<locale>, as
described under L</LOCALES>.

=head2 today

    my $t = Time::Keeper->today(zone => 'local');

Midnight at the start of today in the zone. Where a zone's clocks jumped
over midnight, as some zones' spring changes do, it is the first moment of
the day that did happen: C<today> never dies on such a day.

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

=head2 from_object

    my $t = Time::Keeper->from_object(object => $datetime);
    my $t = Time::Keeper->from_object(object => $datetime, zone => 'Asia/Tokyo', locale => 'ja');

The instant of any object with a C<utc_rd_values> method, as L<DateTime>
and the modules built on it have. The zone is C<zone> if given, else the
object's own (the name its C<time_zone> gives), else UTC. A floating object
gives a floating value.

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

The ISO 8601 week, 1 to 53, and the year it belongs to. Weeks begin on a
Monday, and week 1 is the week with the year's first Thursday in it, so
the first days of January can belong to the last week of the year before.

=head2 week_of_month

The week of the month, 0 to 5, counted as DateTime counts it: the first
week is the first that has a Thursday in the month.

=head2 is_leap_year

True in a leap year.

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
and C<gap> and C<overlap>.

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

=head2 truncate

    my $monday = $t->truncate(to => 'week');

The start of the value's year, quarter, month, week (a Monday), day, hour,
minute or second. Where that wall-clock time did not happen, the first
moment after it that did.

=head2 round

    my $t = $t->round(to => 'minute');

The start of the nearest year, quarter, month, week, day, hour, minute or
second, the later of two as near.

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

=head2 TO_JSON

The L</iso8601> form, for JSON encoders that call C<TO_JSON>.

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
by skeleton, the zone names, the first day of the week, and its digits.
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

=head1 SERIALISATION

A value freezes with L<Storable> as text: its instant, its zone by name
and its locale by code, so a value frozen by one release thaws in another.

=head2 STORABLE_freeze

=head2 STORABLE_thaw

The L<Storable> hooks.

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
distributions can be upgraded independently. It is at version 1.

=head1 THREADS

Values may be shared with or copied into threads.

=head2 CLONE

Sets up a new thread's copy of the module.

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

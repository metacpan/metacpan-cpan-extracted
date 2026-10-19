package Time::Keeper::Business;

use 5.010;
use strict;
use warnings;

our $VERSION = '0.01';

use Time::Keeper;

use XSLoader;
XSLoader::load('Time::Keeper::Business', $VERSION);

use Time::Keeper::Business::Rule;

use overload
    '""'   => \&_string,
    'bool' => sub { 1 },
    fallback => 1;

1;

__END__

=encoding utf8

=head1 NAME

Time::Keeper::Business - business days, business hours and holidays on Time::Keeper

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

    use Time::Keeper;
    use Time::Keeper::Business;

    my $b = Time::Keeper::Business->new(
        weekend  => 'en-GB',
        holidays => [ Time::Keeper::Business::Rule->uk, '2026-12-31' ],
        working  => [ '2026-12-19' ],
        hours    => { default => ['09:00-12:30', '13:30-17:30'], fri => ['09:00-13:00'] },
        zone     => 'Europe/London',
        name     => 'london',
    );

    my $d = Time::Keeper::Date->new(year => 2026, month => 12, day => 24);
    $b->is_business_day($d);                       # 1
    $b->is_holiday($d->plus(days => 1));           # Christmas Day
    $b->holidays(year => 2027);                    # ([Date, name], ...)

    $b->next_business_day($d);                     # 2026-12-29
    $b->plus_business_days($d, 3);                 # 2027-01-04
    $b->business_days_between($d, $d->plus(days => 14));   # 6
    $b->roll($d->plus(days => 2), convention => 'modified_following');
    $b->last_business_day(Time::Keeper::YearMonth->new(year => 2026, month => 12));

    my $t = Time::Keeper->new(year => 2026, month => 12, day => 18, hour => 11, zone => 'Europe/London');
    $b->is_business_hours($t);                     # 1
    $b->next_close($t);                            # 2026-12-18T13:00, a short Friday
    $b->plus_business_hours($t, hours => 4);       # 2026-12-19T11:00, the worked Saturday
    $b->business_hours_between($t, $t->plus(days => 3))->total('hours');   # 11.5
    $b->deadline($t, days => 2, end_of_day => 1);  # 2026-12-21T17:30

=head1 DESCRIPTION

A schedule, the days a business works, the holidays it does not, and the
hours of the day, over L<Time::Keeper>'s values. It answers the next or the
nth business day, how many business days or business hours lie between two
instants, and when an SLA deadline falls. A schedule is not a
L<Time::Keeper::Calendar>, which is a reckoning of years and months such as
the Hebrew calendar; a schedule reads any of those.

A schedule never changes, every method that would change one gives a new
one and leaves the old as it was.

=head1 CONSTRUCTOR

=head2 new

    my $b = Time::Keeper::Business->new(%spec);

The keys, each optional:

=over 4

=item weekend

The days that are closed every week: a list of day numbers, 1 for Monday to
7 for Sunday, or a locale code such as C<ar-EG>, whose territory's weekend
CLDR gives (Friday and Saturday there), read once. Saturday and Sunday
when the key is absent; an empty list for a seven-day week. One schedule
has one weekend: a value's own locale is never consulted.

=item holidays

A list of holiday sources, any mix of:

=over 4

=item * a date: a string any L<Time::Keeper::Date> can parse, a
Time::Keeper::Date, or a Time::Keeper (the date its own zone shows);

=item * a date in every year: C<--12-25>, a L<Time::Keeper::MonthDay>, or
C<< { month => 12, day => 25, name => 'Christmas Day' } >>; C<--02-29> falls
in leap years only;

=item * a hash of dates, of either kind, to names (C<undef> for no name);

=item * a code ref, called with a year and returning that year's holidays as
any of the above, as C<[date, name]> pairs, or as a hash whose keys may also
be C<MMDD> or C<MM-DD> of that year;

=item * an object with a C<holidays> method, asked C<< holidays(year => $y) >>
and read as a code ref's answer: L<Date::Holidays> and its adapters, which
give C<< { MMDD => name } >>, a L<Time::Keeper::Business::Rule> (a fixed date, the
nth weekday, Easter, with observed days; three countries ship as examples), or
another schedule;

=item * a list of any of these.

=back

The first name given for a day is kept, and a later one fills a day that
had none. A code ref or an object is asked once for each year the
schedule is questioned about, and one year either side, and never again
for that year; a question that would span more than about a thousand
years of such sources is refused, since a list is the right form for
that. A Date::Holidays object is used, never loaded: it is not a
prerequisite of this module.

=item working

Dates that are worked although they fall on the weekend: a Saturday a
business opens to make up for a holiday. A date that is also a holiday
given as a date is refused; a holiday a source gives for that day later
closes it again. A working day that falls on a weekday changes nothing.

=item zone

The zone the business hours are read in, any zone L<Time::Keeper> accepts
but C<floating>. Needed when C<hours> is given.

=item hours

    hours => ['09:00-17:00']
    hours => { default => ['09:00-12:30', '13:30-17:30'], fri => ['09:00-13:00'],
               '2026-12-24' => ['09:00-12:00'], '2026-12-31' => [] }

The business hours, as spans C<HH:MM-HH:MM> or C<HH:MM:SS-HH:MM:SS> of
the wall clock in C<zone>, each half-open, ending by C<24:00> and not
overlapping another. A list applies to every day; a hash gives a list a
weekday (C<1> to C<7>, or C<mon> to C<sun>), a C<default> for the weekdays
not named, and a list for a date that overrides its weekday, which may be
empty for a day closed early. A weekday that is worked must have hours or
a default; a weekend day without either has none, so a worked Saturday is
a business day with no business hours. A holiday has no hours whatever the
table says. A shift over midnight is written as two spans, C<22:00-24:00>
on the day and C<00:00-06:00> on the next.

=item name

A name, for messages and for the string form.

=back

An unknown key dies by name.

=head1 VALUES, ZONES AND CALENDARS

Every method that takes a value takes a L<Time::Keeper> or a
L<Time::Keeper::Date>, and one that gives a value back gives the same
class. A Time::Keeper's day is the date its own zone shows, and a value
written back on another day keeps its time of day, zone, locale and
calendar; a time of day the new day skipped is carried forward, as
C<< plus(days => 1, gap => 'forward') >> would carry it. A
L<Time::Keeper::YearMonth> is read as its first day where a month is
wanted.

=head1 THE SCHEDULE

=head2 is_business_day

    $b->is_business_day($v);    # 1 or 0

Whether the value's day is worked: not a weekend day, or a weekend day
listed as working, and not a holiday.

=head2 is_holiday

    $b->is_holiday($v);         # 'Christmas Day', 1, or undef

The holiday's name when the day is one, 1 when it is one without a name,
undef otherwise. A weekend day is not a holiday unless it is listed as
one.

=head2 is_weekend_day

Whether the day is one of the schedule's weekend days, worked or not.

=head2 holidays

    my @pairs = $b->holidays(year => 2026);
    my @pairs = $b->holidays($from, $to);        # both ends included
    my @pairs = $b->holidays($year_month);       # the month

The holidays in the span, in date order, each a pair C<[$date, $name]>
of a L<Time::Keeper::Date> and the name, or undef for a holiday without
one. Two values give the span between their days; one value gives its
month.

=head2 holiday_sources

The holiday sources as they were given.

=head2 weekend

The weekend days as a list of numbers, 1 for Monday to 7 for Sunday.

=head2 zone

=head2 name

=head2 hours

The key as given to L</new>, or undef.

=head2 with

    my $ny = $b->with(zone => 'America/New_York');

A new schedule with the keys given replaced and the rest kept. A joined
schedule (L</join>) cannot be changed this way: change the schedules and
join them again.

=head2 with_holidays

    my $c = $b->with_holidays('2027-05-03', { '2027-12-27' => 'Christmas Day (substitute)' });

A new schedule with more holiday sources added to the ones given.

=head2 with_working_days

A new schedule with more working days added.

=head2 join

    my $both = $london->join($new_york);                   # closed when either is
    my $any  = $london->join($new_york, mode => 'both');   # closed only when both are

Two schedules as one. With C<< mode => 'either' >>, the default, a day is
closed when either schedule has it closed, so the weekend is the union of
the two and a holiday of either counts: a settlement needs both markets
open. With C<< mode => 'both' >> a day is closed only when both have it
closed. C<< name => >> names the result.

=head1 BUSINESS DAYS

Every method here takes a L<Time::Keeper> or a L<Time::Keeper::Date> and
gives back the same class on the day found, a Time::Keeper with its time
of day, zone, locale and calendar kept (see L</VALUES, ZONES AND
CALENDARS>).

=head2 next_business_day

=head2 previous_business_day

    my $d = $b->next_business_day($v);      # strictly after
    my $d = $b->previous_business_day($v);  # strictly before

The first business day after, or before, the value's day. A schedule with
no business day within a year of it dies.

=head2 roll

    my $d = $b->roll($v);                                    # following
    my $d = $b->roll($v, convention => 'modified_following');

The value's day when it is a business day, else the day the convention
names: C<following>, the first business day after (the default);
C<preceding>, the last before; C<modified_following>, as following unless
that crosses into the next month, then preceding; C<modified_preceding>,
the mirror; C<nearest>, whichever of the two is closer, the following on a
tie, so a Saturday goes back and a Sunday forward; and C<none>, which dies
when the day is not a business day. These are ISDA's business day
conventions and numpy's roll modes.

=head2 plus_business_days

=head2 minus_business_days

    my $d = $b->plus_business_days($v, 10);
    my $d = $b->plus_business_days($v, -3, roll => 'following');
    my $d = $b->minus_business_days($v, 10);

The day that many business days on, or back. A day that is not a business
day is rolled first, forward for a positive count and back for a negative
one unless C<roll> names a convention, and a count of zero is that roll:
two business days after a Saturday is Wednesday. C<minus_business_days>
with C<n> is C<plus_business_days> with C<-n>.

=head2 business_days_between

    my $n = $b->business_days_between($from, $to);
    my $n = $b->business_days_between($from, $to, include_end => 1);

The business days from the first day up to but not including the second,
as numpy's C<busday_count> counts them: Monday to the next Monday is five.
Negative when the second day is earlier. C<< include_end => 1 >> counts
the second day too when it is a business day.

=head2 business_days

    my @days = $b->business_days($from, $to);

Every business day from the first day to the second, both included, in
order, each of the first value's class. More than about ten million is
refused.

=head2 nth_business_day

=head2 last_business_day

    my $d = $b->nth_business_day($v, 3);     # the third of the value's month
    my $d = $b->nth_business_day($ym, -1);   # the last
    my $d = $b->last_business_day($ym);

The nth business day of the value's month, counting from 1, or back from
the end with a negative n; the value may be a L<Time::Keeper::YearMonth>,
which gives a Date. A month with fewer business days than asked dies with
the count.

=head1 BUSINESS HOURS

The methods here take a L<Time::Keeper>: a date has no clock, and a
floating time no zone to read the hours in. The moment is read on the
schedule's wall clock and the answer comes back in the caller's zone,
locale, calendar and class.

=head2 HOW TIME IS RECKONED

Business time is the wall clock's, not elapsed time. Nine to five is eight
hours on the day the clocks go forward as on any other, a repeated hour
counts once, and a leap second is part of 23:59:59. An open or a close
that falls on a time the clocks skipped is the first moment after it, and
one in a repeated hour is the earlier reading, as L<Time::Keeper/new>
would choose. So on 8 March 2026 in New York a span C<02:00-04:00> opens
at 03:00.

=head2 is_business_hours

    $b->is_business_hours($t);     # 1 or 0

Whether the moment falls inside a span on a business day.

=head2 next_open

=head2 next_close

=head2 previous_open

=head2 previous_close

    my $open  = $b->next_open($t);        # $t itself when open
    my $close = $b->next_close($t);       # the close of that span
    my $open  = $b->previous_open($t);    # the open of the span $t is in, or the last before
    my $close = $b->previous_close($t);   # the last close at or before $t

The opens and closes around a moment. C<next_open> is the first moment at
or after it that is open, the moment itself when it is; C<next_close> the
close of the span that open begins; C<previous_close> the last close at or
before it, so at the stroke of a close it is that close; C<previous_open>
the open of the span the moment is in, or the last open before it. A
schedule with no business hours within a year of the moment dies.

=head2 business_hours_on

    my @spans = $b->business_hours_on($v);   # ([$open, $close], ...)

The spans of the value's day as pairs of values, in the caller's zone
for a Time::Keeper and in the schedule's for a Time::Keeper::Date; none
on a closed day. A close of C<24:00> is the next day's midnight.

=head1 BUSINESS TIME AND DEADLINES

Business time is the time inside the spans, on the wall clock (see L</HOW
TIME IS RECKONED>). The methods take a L<Time::Keeper>.

=head2 plus_business_hours

=head2 minus_business_hours

    my $t2 = $b->plus_business_hours($t, hours => 4);
    my $t2 = $b->plus_business_hours($t, hours => 1, minutes => 30, seconds => 0, nanoseconds => 0);
    my $t2 = $b->plus_business_hours($t, Time::Keeper::Duration->new(hours => 1, minutes => 30));
    my $t2 = $b->minus_business_hours($t, hours => 8);

The moment that much business time after, or before, the one given, by
C<hours>, C<minutes>, C<seconds>, C<milliseconds>, C<microseconds> and
C<nanoseconds>, or by a L<Time::Keeper::Duration> of those units (one with
months or days dies: use L</plus_business_days>). A start outside the
hours counts from the next open, or going back from the previous close;
an amount that ends exactly on a close stops at that close; zero is the
next open. Nanoseconds are kept.

=head2 business_hours_between

    my $d = $b->business_hours_between($t, $u);               # a Duration, PT6H30M
    my $h = $b->business_hours_between($t, $u)->total('hours');  # 6.5
    my $h = $b->business_hours_between($t, $u, number => 1);   # 6.5, without the Duration

The business time from the first moment to the second, as a
L<Time::Keeper::Duration> in hours, minutes, seconds and nanoseconds,
negative when the second is first. On a schedule open every hour of every
day it is the wall-clock difference, which differs from L<Time::Keeper/until>
by the hour the clocks changed when a change lies between.

=head2 deadline

    my $by = $b->deadline($t, hours => 4);                   # first response
    my $by = $b->deadline($t, days => 2, end_of_day => 1);   # the close of the second business day
    my $by = $b->deadline($t, days => 1, hours => 2);
    my $by = $b->deadline($t);                               # the next open

An SLA deadline. The clock starts at the next open after the moment; C<days>
steps that many business days keeping the time of day (a time outside that
day's hours moves to its next open); C<< end_of_day => 1 >> then moves to
the close of that day's last span; and the clock units, as
L</plus_business_hours> takes them, then run as business time. Every key
is optional and none may be negative.

=head1 SERIALISATION

=head2 TO_JSON

A plain hash: C<weekend> as a list of numbers, C<holidays> as a hash of
C<YYYY-MM-DD> to the name or undef, C<working> as the list of worked
weekend days, and C<zone>, C<name> and C<hours> where given. It is what
L</new> takes, so C<< Time::Keeper::Business->new(%$json) >> is the same
schedule.

=head2 STORABLE_freeze

=head2 STORABLE_thaw

=head2 FREEZE

=head2 THAW

L<Storable>, and L<Sereal> and L<CBOR::XS> through C<FREEZE> and C<THAW>,
carry the plain form, so a thawed schedule is the same schedule. A yearly
date travels as its C<--MM-DD> key. A schedule with a code ref or an
object among its sources cannot be frozen, nor a join of schedules with
yearly or such sources: list the holidays, or join the thawed schedules
again.

=head1 THREADS

=head2 CLONE

Sets up a new thread's copy of the module. A schedule copied into a
thread answers on its own.

=head1 EXAMPLES

The distribution's F<eg/> scripts print a year's holidays and the ten
business days after 20 December for the three rule sets of
L<Time::Keeper::Business::Rule>:

    perl eg/uk.pl 2027
    perl eg/us-federal.pl 2027
    perl eg/target2.pl 2027

An SLA desk in New York, open nine to six on weekdays, closed on the
federal holidays, answering within four business hours and resolving by
the close of the second business day:

    my $desk = Time::Keeper::Business->new(
        holidays => Time::Keeper::Business::Rule->us_federal,
        hours    => ['09:00-18:00'],
        zone     => 'America/New_York',
    );
    my $opened  = Time::Keeper->now;
    my $respond = $desk->deadline($opened, hours => 4);
    my $resolve = $desk->deadline($opened, days => 2, end_of_day => 1);

Two markets as one, for a settlement that needs both open:

    my $both = $london->join($new_york);
    my $settle = $both->plus_business_days($trade_date, 2);

=head1 SEE ALSO

L<Time::Keeper>, L<Time::Keeper::Date>, L<Time::Keeper::Business::Rule>, L<Date::Holidays>,
L<Business::Hours>, L<Date::Business>, L<DateTime::BusinessHours>

=head1 AUTHOR

LNATION <email@lnation.org>

=head1 BUGS

Please report any bugs or feature requests to C<bug-time-keeper-business at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Time-Keeper-Business>.

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut

package Time::Keeper::Recurrence;

use 5.010;
use strict;
use warnings;

use Time::Keeper;

our $VERSION = '0.03';

require XSLoader;
XSLoader::load('Time::Keeper::Recurrence', $VERSION);

require Time::Keeper::Recurrence::Set;

1;

__END__

=head1 NAME

Time::Keeper::Recurrence - rules that say when something happens again

=head1 VERSION

Version 0.03

=head1 SYNOPSIS

    use Time::Keeper::Recurrence;

    my $start = Time::Keeper->new(year => 2026, month => 10, day => 20, hour => 9, zone => 'Europe/London');

    my $r = Time::Keeper::Recurrence->new(
        rrule => 'FREQ=WEEKLY;INTERVAL=2;BYDAY=TU,TH;UNTIL=20271231T235959Z',
        start => $start,
    );
    my $c = Time::Keeper::Recurrence->cron('0 3 * * *', zone => 'America/New_York');
    my $e = Time::Keeper::Recurrence->every(2, 'weeks', on => [qw(tue thu)], at => '09:00', start => $start);

    $r->rrule;      # FREQ=WEEKLY;UNTIL=20271231T235959Z;INTERVAL=2;BYDAY=TU,TH
    $c->rrule;      # FREQ=MINUTELY;BYMINUTE=0;BYHOUR=3
    $e->cron;       # dies: a cron has no INTERVAL
    $r->freq;  $r->interval;  $r->until;  $r->zone;  $r->is_finite;

    $r->next(Time::Keeper->now);     # the next occurrence, a Time::Keeper value
    $r->between($a, $b);              # every occurrence from $a to $b
    $c->first(3);                     # the next three firings of the cron
    my $it = $r->iterate;  while (my $t = $it->()) { ... }

    # dates added and removed, and iCalendar text in and out
    my $s = $r->with(exdate => [$cancelled], rdate => '2026-12-28');
    my $s = Time::Keeper::Recurrence->parse_ical($vevent_text);
    print $s->ical;

    # a rule in another calendar: Rosh Hashanah every year
    my $rh = Time::Keeper::Recurrence->new(rrule => 'RSCALE=HEBREW;FREQ=YEARLY;BYMONTH=1;BYMONTHDAY=1', start => $start);

    # stored as text, and loaded again, the zone by name
    my $frozen = $r->FREEZE('JSON');

=head1 DESCRIPTION

A recurrence rule says when something happens again: every second Tuesday
and Thursday until the end of next year, the last Friday of every month at
five, three in the morning every day in New York. Time::Keeper::Recurrence
reads such rules as RFC 5545 writes them (the iCalendar C<RRULE>), as cron
writes them, and as named arguments, and walks them in any time zone with
the clocks' changes handled. Occurrences are L<Time::Keeper> values.

A rule walks in any calendar L<Time::Keeper> has, as RFC 7529 says (L</RULES
IN ANOTHER CALENDAR>), and in any zone, a skipped or doubled clock time
handled as L</CLOCKS THAT SKIP AND CLOCKS THAT REPEAT> says. A rule with
dates added or removed, or several rules, is a L<set|/SETS>; sets go in and
out as L<iCalendar|/ICALENDAR> text, and rules and sets are stored as text
(L</SERIALISATION>). A scheduler written in C reaches all of it through the
L</C ABI>.

=head1 THE THREE SPELLINGS

A rule is made by L</new> from an RRULE, by L</cron> from a cron expression,
or by L</every> from named arguments. Whichever door it came through, it is
the same kind of object with the same methods, and L</rrule> writes it as
an RRULE. L</cron> as a method writes it as a cron expression where the rule
is one a cron can say.

=head2 RRULE

RFC 5545 section 3.3.10. The parts may come in any order, each at most once;
C<FREQ> is required; C<UNTIL> and C<COUNT> exclude each other; a leading
C<RRULE:> is allowed; case does not matter.

    FREQ        SECONDLY MINUTELY HOURLY DAILY WEEKLY MONTHLY YEARLY: how the periods step
    INTERVAL    every nth period (1)
    COUNT       how many occurrences, counting the start
    UNTIL       the last moment an occurrence may fall on: YYYYMMDD (a day, inclusive),
                YYYYMMDDTHHMMSSZ (an instant) for a start with a zone,
                YYYYMMDDTHHMMSS (a wall time) for a floating start
    BYSECOND    0 to 60          BYMINUTE   0 to 59          BYHOUR  0 to 23
    BYDAY       MO TU WE TH FR SA SU, each with an ordinal before it (2TU, -1FR) when
                FREQ is MONTHLY or YEARLY: the nth such weekday of the month or year
    BYMONTHDAY  1 to 31, or -1 to -31 from the end     BYMONTH  1 to 12
    BYYEARDAY   1 to 366, or -1 to -366, not with DAILY, WEEKLY or MONTHLY
    BYWEEKNO    1 to 53, or -1 to -53, only with YEARLY
    BYSETPOS    which of a period's candidates to keep, 1 to 366 or from the end
    WKST        the first day of the week, MO (the default) to SU

A value out of range, a part given twice, a part the RFC says cannot meet
another, and a part this module does not know (RFC 7529's C<RSCALE> comes
in a later release) are errors that name the part and the value; the RFC
says an unknown part may be ignored, but a scheduler must not fire a rule
it half understood.

=head2 Cron

The grammar is L<Punk::Queue::Cron>'s, so a cron that is good there is good
here and a bad one fails with the same words. Five fields, minute hour
day-of-month month day-of-week: C<*>, ranges C<a-b>, steps C<*/n> and
C<a-b/n> (C<a/n> is C<a-hi/n>), lists C<a,b,c>, case-insensitive
three-letter month and day names, day-of-week 0 to 7 with 0 and 7 both
Sunday; the aliases C<@yearly> C<@annually> C<@monthly> C<@weekly> C<@daily>
C<@midnight> C<@hourly>; and C<@every E<lt>nE<gt>(s|m|h|d)>, an interval from
the last occurrence rather than a wall-clock grid. C<L>, C<W>, C<#> and C<?>,
and a sixth or seventh field, are refused by name rather than misread.

A cron is read as C<FREQ=MINUTELY> with its restricted fields as C<BY>
parts, and a field that matches everything (C<*>, C<1-31>, C<0-7>) is no
restriction at all. When BOTH day fields are restricted a day matching
EITHER fires, the cron reading since Vixie (C<0 12 8 * 0> runs on the 8th
and on Sundays); an RRULE's two day parts must both match, so such a cron
has an RRULE spelling that reads back differently, and a cron made from an
RRULE with both parts dies rather than change its meaning.

=head2 Named arguments

    Time::Keeper::Recurrence->every(2, 'weeks', on => [qw(tue thu)], at => '09:00', start => $t);
    Time::Keeper::Recurrence->every(1, 'month', on => 'last fri', at => '17:00', start => $t);
    Time::Keeper::Recurrence->every(1, 'month', on => [1, 15, -1], start => $t);

C<every(n, unit)> with the unit C<seconds>, C<minutes>, C<hours>, C<days>,
C<weeks>, C<months> or C<years> (singular or plural); C<on> a weekday or a
list of them, each with C<1st> to C<5th>, C<last> or a signed ordinal before
it for months and years, or a day of the month, 1 to 31 or from the end;
C<at> a time of day, C<HH:MM> or C<HH:MM:SS>; C<until> a L<Time::Keeper>
value, or C<count>. It is sugar for an RRULE and L</rrule> shows which.

=head1 CONSTRUCTORS

=head2 new

    my $r = Time::Keeper::Recurrence->new(rrule => 'FREQ=DAILY;COUNT=10', start => $t);
    my $r = Time::Keeper::Recurrence->new(rrule => $text, start => $t, gap => 'skip', overlap => 'both');

A rule from an RRULE and its start, a L<Time::Keeper> value: the start's
zone is the rule's zone, and its locale the occurrences' locale. C<gap> says
what an occurrence does whose wall time the clocks skipped: C<forward> (the
default for a rule: the first moment after the gap), C<backward>, C<skip>
or C<fail>; C<overlap> what a wall time that happened twice gives:
C<earlier> (the default), C<later> or C<both>; see L</CLOCKS THAT SKIP AND
CLOCKS THAT REPEAT>. C<calendar> names a calendar to walk the rule in, as
C<RSCALE> in the rule does; see L</RULES IN ANOTHER CALENDAR>.

=head2 cron

    my $c = Time::Keeper::Recurrence->cron('0 3 * * *');                               # UTC
    my $c = Time::Keeper::Recurrence->cron('0 3 * * *', zone => 'America/New_York');
    my $c = Time::Keeper::Recurrence->cron('*/15 * * * *', start => $t);
    $c->cron;                                                                           # the expression back

As a class method, a rule from a cron expression in the grammar above, in
the zone given, the start's zone, or UTC; C<gap> defaults to C<skip> and
C<overlap> to C<both> with cron's rule for a doubled hour, as L</CLOCKS THAT
SKIP AND CLOCKS THAT REPEAT> says. As a method on a rule, the cron expression that says
the rule, canonical (C<*/15> becomes C<0,15,30,45>), or an error naming what
a cron cannot say: an interval, seconds, an ordinal weekday, a count or an
end, a day counted from the end of the month, or an RRULE whose two day
parts must both match.

=head2 every

    my $e = Time::Keeper::Recurrence->every(2, 'weeks', on => [qw(tue thu)], start => $t);

The named door, described above; C<start> is required, and C<gap>,
C<overlap> and C<calendar> are as for L</new>. With a calendar, a year or a
month is the calendar's: C<< every(1, 'year', calendar => 'chinese', start => $new_year) >>
is the Chinese New Year.

=head2 check

    Time::Keeper::Recurrence->check('0 3 * * *');
    Time::Keeper::Recurrence->check('30 2 * * *', 'America/New_York');

Parses a cron expression and dies with the reason, or returns true; an
expression that can never fire (C<0 0 30 2 *>) dies here too, as it does
when a rule is made from it. What L<Punk::Queue::Cron/check> does, for the
same expressions and with the same words.

=head1 WHAT A RULE SAYS ABOUT ITSELF

=head2 freq

=head2 interval

=head2 count

=head2 until

=head2 wkst

The frequency as a lower-case word (C<daily>; C<every> for an C<@every>
cron); the interval; the count, or undef; UNTIL as a L<Time::Keeper> value
in the rule's zone (a UTC instant as given, a floating wall time, or the
last second of a DATE in the zone), or undef; the first day of the week, 1
Monday to 7 Sunday.

=head2 start

=head2 zone

=head2 gap

=head2 overlap

The start as a L<Time::Keeper> value, or undef for a cron made with a zone
alone; the zone's name as L<Time::Keeper> writes it (C<America/New_York>,
C<UTC>, C<+05:30>, C<floating>); the gap and overlap choices as words.

=head2 is_finite

True when the rule ends: it has a count or an UNTIL. A cron never does.

=head2 calendar

=head2 skip

The calendar the rule walks in, as L<Time::Keeper> names it (C<hebrew>,
C<chinese>, C<gregory>), and its SKIP choice (C<omit>, C<backward>,
C<forward>); both undef for a rule with no RSCALE.

=head1 THE TEXT BACK

=head2 rrule

    $r->rrule;    # FREQ=MONTHLY;COUNT=10;BYDAY=1FR

The rule as an RRULE, in one canonical form: the RFC's order of parts,
values ascending, C<INTERVAL=1> and C<WKST=MO> left out. Reading it back
gives the same rule. An C<@every> cron has none and dies.

=head2 describe

    Time::Keeper::Recurrence->cron('*/15 9-17 * * 1-5')->describe;
    # Every 15 minutes from 09:00 to 17:45, Monday to Friday
    $r->describe;    # On the first Monday of every month, 10 times

The rule in English words, one sentence without its full stop. It is read from
the rule as compiled, so a cron, an RRULE and C<every> that say the same thing
read the same: the time of day ("At 09:00", "Every 2 hours, on the hour", "Every
hour from 08:00 to 18:00"), the days ("Monday to Friday", "the first Monday", "the
last weekday", "the 1st and the 15th", cron's "on the 13th of the month, or on
Friday"), the months ("from March to October"), the cycle ("of every month", "every
2 weeks"), the end (", 10 times", ", until 2026-12-31") and an RSCALE rule's
calendar (", in the Hebrew calendar", its months as numbers). A rule that takes its
time of day from its start says no time. A part the words do not cover reads as
its numbers, never as nothing.

=head2 ical

    print $r->ical;
    # DTSTART;TZID=America/New_York:20261020T090000
    # RRULE:FREQ=WEEKLY;BYDAY=TU,TH

The rule as iCalendar content lines: its start as a DTSTART and the RRULE,
as L<Time::Keeper::Recurrence::Set/ical> writes a set of one rule. A cron
with no start has no DTSTART; one that fires on either of two day fields,
or an C<@every>, has no RRULE spelling and dies.

=head1 THE WALK

    $r->next($t);                    # the first occurrence strictly after $t, or undef
    $r->previous($t);                # the last strictly before, or undef
    $r->between($a, $b);             # a list: $a inclusive, $b exclusive
    $r->first(10);                   # the first ten
    $r->contains($t);                # is $t an occurrence
    my $it = $r->iterate($from);     # a code ref: the next each call, undef at the end
    while (my $t = $it->()) { ... }

=head2 How a rule is read

RFC 5545's recurrence is a two-step machine. The periods are seconds,
minutes, hours, days, weeks, months or years, C<INTERVAL> of them apart,
counted from the start's period: C<FREQ=MONTHLY;INTERVAL=18> from September
1997 reads September 1997, then March 1999, and nothing between. Inside a
period the C<BY> parts expand (a list of hours gives an occurrence at every
one) or limit (a list of months keeps only days that fall in them), in the
RFC's table: a part for a unit larger than the frequency limits, a part for
a smaller unit expands. Where a day-level rule gives no day part the start's
own stands in (C<FREQ=YEARLY;BYMONTH=6,7> is the start's day of June and
July), and where no clock part is given the start's hour, minute and second
are kept. C<BYSETPOS> keeps the nth of what a period produced, counted from
its end when negative. A day the month or year does not have, 31 April or
30 February, is dropped and never moved, so C<FREQ=MONTHLY;BYMONTHDAY=31>
is seven times a year.

The start is the first occurrence whether or not it fits the rule, as the
RFC says of C<COUNT>, and C<COUNT> counts it. C<UNTIL> is inclusive. An
occurrence is a L<Time::Keeper> value in the rule's zone and locale, with
the start's fraction of a second. A cron's start, when it has one, is a
bound rather than an occurrence, and its occurrences fall on the minute.

Wall times become instants through the rule's zone; see L</CLOCKS THAT SKIP
AND CLOCKS THAT REPEAT>.

=head2 Infinite rules

A rule with no C<COUNT> and no C<UNTIL> never ends, so L</between> takes
two bounds, L</first> a count, and L</iterate> gives one occurrence at a
time; L</between> dies past ten million occurrences and says to iterate. A
rule that can never fire dies rather than walk forever: a day-level rule
with nothing in a thousand of its periods in a row, a rule stepping hours,
minutes or seconds with nothing in five years of days, and a cron is
checked for that when it is made, as L<Punk::Queue::Cron> checks it. One
period that would hold more than a hundred thousand occurrences dies too.

=head2 next

=head2 previous

    my $t = $r->next($from);    my $t = $r->next;        # from now
    my $t = $r->previous($from);

The first occurrence strictly after a moment, or the last strictly before
it: a L<Time::Keeper> value, or undef when the rule has none there. With no
argument, from now. An C<@every> cron gives the moment plus or minus its
interval.

=head2 between

    my @t = $r->between($a, $b);

The occurrences from C<$a> inclusive to C<$b> exclusive, in order, as RFC
5545 bounds a period. Dies past ten million.

=head2 first

    my @t = $r->first(5);

The first n occurrences: from the start for a rule, after now for a cron.
Fewer come back when the rule ends sooner.

=head2 contains

Whether a L<Time::Keeper> value is an occurrence, to the nanosecond.

=head2 iterate

    my $it = $r->iterate;           # from the start, which comes first
    my $it = $r->iterate($from);    # strictly after $from

A code reference giving the next occurrence each time it is called and
undef when the rule has ended, holding its own copy of the rule and its
place in it.

=head1 RULES IN ANOTHER CALENDAR

    my $rosh_hashanah = Time::Keeper::Recurrence->new(
        rrule => 'RSCALE=HEBREW;FREQ=YEARLY;BYMONTH=1;BYMONTHDAY=1',
        start => Time::Keeper->new(year => 5787, month => 1, day => 1, calendar => 'hebrew', zone => 'Asia/Jerusalem'),
    );
    $rosh_hashanah->next($t)->format('d MMMM y');    # 1 Tishri 5788

RFC 7529 adds C<RSCALE> to an RRULE: the calendar the rule is read in, any
calendar L<Time::Keeper> has, by its id or an alias in any case (C<HEBREW>,
C<CHINESE>, C<ISLAMIC-UMALQURA>, C<ETHIOPIC>, C<GREGORIAN>). Then a year and
a month are the calendar's: FREQ=YEARLY steps the calendar's years and
FREQ=MONTHLY its months, one at a time by their order in the year, so a
month after Adar I is Adar II and a Hebrew leap year is thirteen months.
C<BYMONTH> takes the calendar's months, up to 13, and C<BYMONTHDAY> and
C<BYYEARDAY> count its days, a year day up to 385. Weeks, days and times
are the same in every calendar, and every occurrence is a L<Time::Keeper>
value read in the rule's calendar, in the start's zone and locale.

Months are numbered as L<Time::Keeper/month_code> numbers them, and a leap
month is its number with C<L>: in the Hebrew calendar, C<5L> is Adar I, the
month a leap year adds, and C<6> is Adar in a common year and Adar II in a
leap year, as RFC 7529 says; in the Chinese calendar C<6L> is the leap
month after the sixth. A rule from a start in a leap month with FREQ=YEARLY
and no BYMONTH has that leap month, as the RFC says: from 15 Adar I it
recurs on 15 Adar I, in leap years.

C<SKIP> says what a date the year does not have becomes. The month is
settled first, then the day:

=over

=item omit

The default: it is dropped, as RFC 5545 drops 30 February. Adar and Adar II
have 29 days, so C<BYMONTH=6;BYMONTHDAY=30> never fires; C<BYMONTH=5L;BYMONTHDAY=30>,
30 Adar I, fires in leap years only.

=item backward

A leap month the year lacks becomes the month before it, and a day its
month lacks the month's last day: 30 Adar I is 30 Shevat in a common year,
and 30 Adar is 29 Adar.

=item forward

A leap month the year lacks becomes the month after it, and a day its
month lacks the first of the next month: 30 Adar I is Adar in a common year,
whose 30th does not exist, so it is 1 Nisan. With C<RSCALE=GREGORIAN>, a
birthday on 29 February is 1 March in a common year. A day moved on to the
next month belongs to the year or month it came from, for INTERVAL,
BYSETPOS and COUNT.

=back

C<SKIP> without C<RSCALE> dies, as the RFC says it must, and so do a leap
month and a thirteenth month. C<BYWEEKNO> with C<RSCALE> dies: no calendar
here but the Gregorian numbers its weeks. A rule in a calendar has no cron
spelling. L</rrule> writes C<RSCALE> first and C<SKIP> last, and only when
it is not C<OMIT>.

=head1 CLOCKS THAT SKIP AND CLOCKS THAT REPEAT

    my $c = Time::Keeper::Recurrence->cron('30 2 * * *', zone => 'America/New_York');
    $c->next($t);                  # never 02:30 on 8 March 2026: the clocks went forward over it
    my $r = Time::Keeper::Recurrence->new(rrule => 'FREQ=DAILY', start => $ny_0230);
    $r->next($t);                  # 03:30 that day: moved forward by the hour the clocks skipped
    Time::Keeper::Recurrence->new(rrule => 'FREQ=DAILY', start => $ny_0130, overlap => 'both');
                                   # 01:30 EDT and 01:30 EST on 1 November 2026, both

A rule's occurrences are wall times in its zone, and twice a year a wall
time in most zones either did not happen or happened twice. Each is turned
into an instant through L<Time::Keeper::Zone>, which knows both readings of
a doubled wall time and the offsets either side of a skipped one, and the
rule says what to do:

=over

=item gap

For a wall time the clocks went forward over: C<forward>, the first moment
after the gap shifted by its length (02:30 becomes 03:30 where an hour was
skipped, 02:45 where Lord Howe skipped half an hour), as a calendar moves an
appointment; C<backward>, the moment before the gap; C<skip>, no occurrence
that period; C<fail>, an error naming the wall time and the zone. A rule
defaults to C<forward>, a cron to C<skip>, which is what cron has done
since Vixie wrote it and what L<Punk::Queue::Cron> does.

=item overlap

For a wall time the clocks went back over: C<earlier>, the first reading;
C<later>, the second; C<both>, both, in order of their instants. A rule
defaults to C<earlier>, once. A cron defaults to C<both> with cron's own
rule laid over it: a pinned minute fires once, at the first reading, and a
sweeping expression (C<* * * * *>) fires at every real minute of the
doubled hour, since each of its wall minutes has another occurrence between
its two readings. That is the rule of Vixie cron and of L<Punk::Queue::Cron>.

=back

UTC, a fixed offset and floating time have no such moments: a floating rule
gives floating occurrences, which a reader may place in a zone afterwards
as any floating value. C<UNTIL> ending in C<Z> is an instant; a floating
C<UNTIL> a wall time; a C<DATE> C<UNTIL> the last second of that day in the
rule's zone. The bounds of L</between> are instants.

=head1 SETS

    my $set = $r->with(exdate => [$cancelled], rdate => [$moved_to]);
    my $set = $r->with(rule => $other, exdate => '2026-12-25');

A rule with dates added or removed, or more than one rule, is a
L<Time::Keeper::Recurrence::Set>: the same walking methods over the merge
of every rule's occurrences, with iCalendar's RDATE in and EXDATE out.

=head2 with

A set from this rule and what is given: C<rdate> dates added, C<exdate>
dates removed, C<rule> rules added, each one item or an array reference
of them. A date is a Time::Keeper value, which is one occurrence to the
second, or a whole day as a Time::Keeper::Date or a C<YYYY-MM-DD> string.
The rule itself is left as it was. L<Time::Keeper::Recurrence::Set/with>
has the whole of it.

=head1 ICALENDAR

    my $set = Time::Keeper::Recurrence->parse_ical(<<'ICS');
    DTSTART;TZID=America/New_York:20261020T090000
    RRULE:FREQ=WEEKLY;BYDAY=TU,TH
    EXDATE;TZID=America/New_York:20261126T090000
    ICS

=head2 parse_ical

A set from the recurrence properties of one iCalendar component, or a
bare list of its lines: C<DTSTART> (with a C<TZID>, or ending in C<Z> for
UTC, or bare for a floating rule, or C<VALUE=DATE> for a whole day),
C<RRULE> (several make several rules), C<RDATE> and C<EXDATE> (lists, timed
or C<VALUE=DATE> whole days; a C<PERIOD> is refused, since a period is not
an occurrence), and C<EXRULE>, which is applied but never written back.
Every other property is ignored, so a whole VEVENT may be given. Folded
lines are unfolded, whether folded with CRLF or LF alone. A C<TZID> is an
IANA name, with or without a leading slash, or a Windows name such as
C<Eastern Standard Time>, read through L<Time::Keeper::Zone>. A timed
EXDATE or RDATE with no TZID is read in the start's zone, and one in
another zone matches by instant: feeds are read leniently and written
strictly. A DTSTART with no RRULE is one occurrence.

The lines back are L</ical> on a rule and L<Time::Keeper::Recurrence::Set/ical>
on a set.

=head1 SERIALISATION

A rule stores as text and loads from it, with its zone kept by name and
its locale by code, so a scheduler can keep rules in a column and read
them back on another machine. The frozen form of a rule is one line:
C<tkr1>, the zone, the locale, the start as an epoch (or C<->), its
nanoseconds, the gap and overlap choices, then C<rrule> or C<cron> and the
text. A cron stays a cron, whichever its spelling.

=head2 FREEZE

The text, for CBOR::XS, Sereal and JSON::XS with C<allow_tags>.

=head2 THAW

A rule from that text, with the zone looked up by name in this build.

=head2 STORABLE_freeze

The same text, for Storable: C<freeze>, C<thaw> and C<dclone> work on a rule.

=head2 STORABLE_thaw

A rule from it, into the object Storable is building.

=head2 TO_JSON

For JSON encoders with C<convert_blessed>: the rule's RRULE text, or a
cron's expression.

=head1 C ABI

A scheduler written in C can compile a rule and walk it, or ask for the
next occurrence of a rule kept as text, with no Perl method call. The
table is F<time_keeper_recurrence_abi.h>, installed with the module and
found by L<ExtUtils::Depends>; it includes Time::Keeper's
F<time_keeper_abi.h> for its instants and zones. It is resolved at run
time, so nothing links against this module:

    #include "time_keeper_recurrence_abi.h"

    static const time_keeper_recurrence_abi *TKR = NULL;

    SV *sv = eval_pv("require Time::Keeper::Recurrence; Time::Keeper::Recurrence::_abi_ptr()", 0);
    if (sv && SvOK(sv) && !SvTRUE(ERRSV)) {
        const time_keeper_recurrence_abi *t = INT2PTR(const time_keeper_recurrence_abi *, SvUV(sv));
        if (TIME_KEEPER_RECURRENCE_ABI_OK(t)) TKR = t;
    }

    double next;
    char err[200];
    if ((TKR->cron_next)(aTHX_ "30 2 * * *", 10, "America/New_York", 16, now, &next, err, sizeof err) == 0)
        ...

The table, version 1:

=over

=item compile, next, previous, release

A handle from an RRULE and its start, a cron expression and its zone, or
iCalendar lines; the first occurrence strictly after an instant and the
last strictly before it; the handle given back. A handle compiled is the
object the Perl constructor makes, with every check it makes.

=item cron_next, rrule_next

The next occurrence of a rule given as text, in a zone given by name, in
epoch seconds, in one call: what a scheduler that keeps its rules as text
needs. C<cron_next> takes the zone names Punk::Queue uses, C<UTC>,
C<local> and C<+HHMM>, and every IANA name.

=item new_sv, from_sv

A Perl object for a handle's rule, and a handle for such an object.

=back

Every entry returns a code, C<TIME_KEEPER_RECURRENCE_OK> or one of C<BAD>
(with the reason in the caller's buffer, in the words the methods die
with), C<NONE> (the rule has ended or cannot fire again), C<RANGE> and
C<GAP>; nothing croaks but loading Time::Keeper::Zone and running out of
memory. The table only grows, and a consumer checks C<abi_version> with
C<< >= >>. The header says the rest.

=head2 _abi_ptr

=head2 _abi_version

=head2 _abi_selftest

The table's address, its version, and a check that calls every entry
through a pointer as a consumer would, returning 0 and an object it made.

=head1 CLASS METHODS

=head2 abi_versions

    my ($keeper, $zone) = Time::Keeper::Recurrence->abi_versions;

The versions of the two tables this module runs on, L<Time::Keeper>'s and
L<Time::Keeper::Zone>'s, each at least the version it was built to call.
Loading the module needs L<Time::Keeper> and dies naming what is missing or
too old; L<Time::Keeper::Zone> is loaded the first time a named zone is
needed, which this method also does.

=head1 SPEED

Measured on the author's machine (Apple silicon, perl 5.42), the best of
five half-second runs, with the dist's F<bench/> scripts, which are in its
repository and not in the distribution:

    next on a daily rule, UTC                        2.7 million a second
    next on a daily rule, America/New_York           1.4 million a second
    next on a monthly last-Friday rule, New York     1.2 million a second
    next on a cron, UTC or a fixed offset            9.3 million a second
    a cron made, its expression checked              4.6 million a second
    a year of a weekly rule, between                  40,000 a second
    parse_ical of a VEVENT                           830,000 a second

Against L<Punk::Queue::Cron>, whose next_after reads a cron's text on each
call and returns an epoch where this returns a L<Time::Keeper> value, a
cron made once walks 1.8 to 4.2 times faster. A cron made and walked on
every call is 0.6 to 1.5 times as fast as next_after: making a rule also
checks that it can fire and builds an object, which next_after does not.

=head1 SEE ALSO

L<Time::Keeper::Recurrence::Set>, L<Time::Keeper>, L<Time::Keeper::Zone>,
L<Punk::Queue::Cron>, L<DateTime::Event::ICal>, RFC 5545 (iCalendar's
recurrence rules), RFC 7529 (recurrence in other calendars).

=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut

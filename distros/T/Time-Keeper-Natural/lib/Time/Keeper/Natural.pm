package Time::Keeper::Natural;

use 5.010;
use strict;
use warnings;

our $VERSION = '0.03';

use XSLoader;
XSLoader::load('Time::Keeper::Natural', $VERSION);

use Time::Keeper;
use Time::Keeper::Locale;
use Time::Keeper::Natural::Lexicon;
use Time::Keeper::Natural::Words;
use Time::Keeper::Natural::Match;

1;

__END__

=encoding utf8

=head1 NAME

Time::Keeper::Natural - the words people use for a time, read in every locale

=head1 VERSION

Version 0.03

=head1 SYNOPSIS

    use Time::Keeper::Natural;

    # the clock at Thursday 15 October 2026, 09:00 in London
    my $n = Time::Keeper::Natural->new(zone => 'Europe/London', locale => 'en-GB');
    $n->parse('tomorrow');                          # 2026-10-16T00:00:00+01:00
    $n->parse('in 3 days');                         # 2026-10-18T09:00:00+01:00
    $n->parse('next Tuesday at 3 pm');              # 2026-10-20T15:00:00+01:00
    $n->parse('end of last month');                 # 2026-09-30T23:59:59.999999999+01:00
    $n->parse('in two weeks');                      # 2026-10-29T09:00:00+00:00
    $n->parse_duration('1 hour, 30 minutes');       # PT1H30M
    my ($from, $to) = $n->parse_interval('15 – 17 Oct 2026');
    $n->new(calendar => 'hebrew')->parse('4 Heshvan 5787');   # 2026-10-15T00:00:00+01:00
    $n->in_locale('fr')->parse('il y a 3 heures');  # 2026-10-15T06:00:00+01:00
    $n->in_locale('ja')->parse('来月末');            # 2026-11-30T23:59:59.999999999+00:00
    $n->try_parse('sometime');                      # undef

    my $m = $n->match('15 October');
    $m->assumed;                                    # ('time', 'year', 'zone')

    Time::Keeper::Natural->parse('tomorrow', zone => 'Asia/Tokyo');

It reads relative phrases (L</RELATIVE TIME>), durations (L</DURATIONS>),
dates and times in the locale's own formats, alone or on a day (L</ABSOLUTE
DATES AND TIMES>), intervals (L</INTERVALS>), and, where a locale has a word table, "end of", "start
of", "at" and "on" (L</WORDS>). A method that cannot read a text dies saying
what it could not read.

=head1 DESCRIPTION

A natural phrase for a time, "next Tuesday at 3 pm", "in two weeks", "end of
last month", read into a L<Time::Keeper> value, a L<Time::Keeper::Date> or a
L<Time::Keeper::Duration>, relative to a moment called the anchor, in the
locale's own words.

What it promises comes in two tiers, and C<coverage> says which tier a locale
is in.

=head2 What it reads in every locale

Whatever Time::Keeper writes in a locale, this module reads back in that
locale: the relative time C<format_relative> writes ("3 hours ago",
"yesterday", "il y a 3 heures"), the durations C<Duration-E<gt>format>
writes ("1 hour, 30 minutes", "1:05:09"), the intervals C<format_interval>
writes ("15–17 Oct 2026"), and the locale's own date and time formats and
skeletons, in all 1,121 locales of CLDR, with digits in any
script. The test suite proves it by writing each of these and reading it
back.

=head2 What it reads where it has the words

CLDR has no words for "end of", "start of", "at", "on" or "the". Those come
from a small word table the distribution ships per locale, English first.
C<coverage> answers C<words> for a locale with a table and C<data> for one
without, which reads everything in the first tier and none of this.

=head1 WHAT IT DOES NOT READ

=over

=item Free text.

A text is read whole or not at all: "let's meet next Tuesday" dies. Finding
a date somewhere inside a sentence is another job, with its own guesses.

=item Recurrence and vague words.

"every Tuesday", "sometime next week", "soon".

=item Idioms CLDR does not have.

"a fortnight", "tonight", "EOD", "Tuesday the 20th", "Tuesday of next week"; and a
spelling the locale's rules do not write ("twentyone").

=item Holidays and business days.

"the day after Thanksgiving", "three working days from now".

=item What a language's grammar keeps out of reach.

Where "end of" wants a case CLDR does not have (German, Greek and Russian
genitives, Hindi's oblique case), the edges read with month names, years and
dates only; each table says what it cannot do in its own header.

=back

Three choices a reader will look for, each made once: a bare hour in a locale
whose clock has twelve hours dies unless C<bare_hour> says which; a period
word alone is the period's first moment ("next month" is the 1st); and "next
Tuesday" is the first Tuesday after today, never today.

The word tables other than English's are first drafts, marked unreviewed in
their files, and await a native reader.

=head1 OPTIONS

Every method takes the options as name and value pairs, either on C<new> or,
in the class form, after the text. An unknown or repeated option dies by name.

=over

=item now

A Time::Keeper value, the anchor that "tomorrow" and "in 3 days" are counted
from. Without it the anchor is C<Time::Keeper-E<gt>now>, which reads
C<$Time::Keeper::CLOCK>, so a test pins it with C<local>.

=item zone

The zone of the result, any zone Time::Keeper takes; an anchor given as
C<now> is read in it. Without it the result is in the anchor's zone, which
is UTC when the anchor is the clock.

=item locale

The locale whose words are read and the result carries, any code
Time::Keeper knows; an anchor given as C<now> is read in it, which also
decides its week's first day. Without it the anchor's locale is used, English
when the anchor is the clock.

=item bare_hour

What a bare hour with no half of the day means in a locale whose clock has
twelve hours: C<am>, C<pm>, or C<next>, the first reading after the anchor
on that day. Without it such an hour dies. In a locale whose clock has
twenty-four hours a bare hour is the hour.

=item prefer

C<future> or C<past>: which side of the anchor to take where the text does
not say. It does four things, all in that one sense: a date with no year
moves to the later or the earlier year; a bare weekday is the coming or the
last one; a phrase CLDR writes for two days (Hindi's "कल", yesterday and
tomorrow) is the later or the earlier of them; and a day of the month with
no month ("the 15th") is the next or the last such day. Without it the
anchor's year and month are taken, a bare weekday is the coming one, and a
phrase with two meanings dies.

=item keep_zone

True to leave a value read with a zone in its text ("3 pm EST") in that zone,
rather than bring it into the parser's (L</ZONES>).

=item calendar

A calendar's id, any L<Time::Keeper::Calendar> knows (C<hebrew>,
C<japanese>, C<islamic-umalqura>...): its dates are read and the values are
in it (L</CALENDARS>). A C<-u-ca-> extension in C<locale>
(C<ja-u-ca-japanese>) gives it too, unless C<calendar> is given. Without
either, the Gregorian.

=back

=head1 METHODS

=head2 new

    my $n = Time::Keeper::Natural->new(zone => 'Europe/London', locale => 'fr');
    my $m = $n->new(bare_hour => 'pm');

A parser with the options given. Called on a parser, a new one with that
parser's options and these on top; an option given as C<undef> is dropped.
A parser is immutable.

=head2 parse

    my $t = $n->parse('next Tuesday at 3 pm');
    my $t = Time::Keeper::Natural->parse('tomorrow', zone => 'Asia/Tokyo');

The Time::Keeper value the whole text names, or a death saying what it
could not read (L</ERRORS>). A phrase that names a day and no time is the
day's first moment, as C<today> is. The value is in the parser's zone and
locale.

=head2 try_parse

As C<parse>, but C<undef> where C<parse> would die, with C<$@> left as it was.

=head2 parse_date

The Time::Keeper::Date of the moment the text names: "next Tuesday" is a
date, and "in 3 hours" is the date of that moment.

=head2 try_parse_date

As C<parse_date>, with C<undef> for a death.

=head2 parse_duration

The Time::Keeper::Duration the text names, "2 weeks", "1 hour, 30
minutes", "1:05:09", "PT90M" (L</DURATIONS>); a text that names a moment
rather than a length dies.

=head2 try_parse_duration

As C<parse_duration>, with C<undef> for a death.

=head2 match

    my $m = $n->match('15 October');
    $m->value;      # 2026-10-15T00:00:00+01:00
    $m->assumed;    # ('time', 'year', 'zone')

What C<parse> would read, as a L<Time::Keeper::Natural::Match>: the value,
the precision the text named, and what was assumed to make it a value. A text
C<parse> would die on gives C<undef>, never a death, whatever the reason.

=head2 match_date

As C<match>, the value a Time::Keeper::Date and the kind C<date>.

=head2 match_duration

As C<match> for what C<parse_duration> reads, the kind C<duration> and the
precision C<none>.

=head2 parse_interval

    my ($start, $end) = $n->parse_interval('Monday to Friday');

The two Time::Keeper values an interval names, its start and its end
(L</INTERVALS>); a text that names one time dies saying so.

=head2 try_parse_interval

As C<parse_interval>, with an empty list for a death.

=head2 match_interval

As C<match> for what C<parse_interval> reads: the kind C<interval>, the
start as C<value> and the end as C<to>.

=head2 coverage

    Time::Keeper::Natural->coverage('en-AU');   # words, through en
    Time::Keeper::Natural->coverage('fr');      # data, until French has a table

C<words> for a locale with a word table in its chain, C<data> for one
without, which reads everything in the first tier and none of L</WORDS>. An
unknown locale dies.

=head2 locales

The codes of the locales with a word table of their own.

=head2 in_locale

    my $fr = $n->in_locale('fr');

A new parser reading that locale's words, the other options kept.

=head2 in_zone

A new parser whose results are in that zone, the other options kept.

=head2 now

The anchor: the C<now> given, in the C<zone> given if there is one, else the
clock's reading in the zone and locale given. Read afresh on every call, so a
clock that moves is followed.

=head2 zone

The zone results are in: the option, else the anchor's.

=head2 locale

The locale whose words are read: the option as its canonical code, else the
anchor's.

=head2 bare_hour

The option, or C<undef>.

=head2 prefer

The option, or C<undef>.

=head2 keep_zone

The option, or C<undef>.

=head2 calendar

The option, or C<undef>.

=head1 RELATIVE TIME

    # the clock pinned to Thursday 2026-10-15T09:00:00 Europe/London
    $n->parse('tomorrow');                 # 2026-10-16T00:00:00+01:00
    $n->parse('now');                      # 2026-10-15T09:00:00+01:00
    $n->parse('in 3 days');                # 2026-10-18T09:00:00+01:00
    $n->parse('3 hours ago');              # 2026-10-15T06:00:00+01:00
    $n->parse('in 2 weeks and 3 days');    # 2026-11-01T09:00:00+00:00
    $n->parse('next Tuesday');             # 2026-10-20T00:00:00+01:00
    $n->parse('last month');               # 2026-09-01T00:00:00+01:00
    $n->parse('this week');                # the week's first day, by the locale
    $n->in_locale('fr')->parse('après-demain');
    $n->in_locale('de')->parse('vor 2 Wochen');

The words are the locale's own, as L<Time::Keeper::Locale/relative_names>
gives them and L<Time::Keeper/format_relative> writes them, so whatever
C<format_relative> writes in a locale reads back in it. Their meaning:

=over

=item A period word is the start of its period.

"today" is the day's first moment, "this week" the first moment of the
locale's week (Sunday in C<en-US>, Monday in C<en-GB>), "next month" the first
moment of next month, "last year" 1 January of last year, "this quarter" the
quarter's first day. "now" is the anchor itself.

=item A weekday is a day.

"next Tuesday" is the first Tuesday strictly after the anchor, "last Tuesday"
the first strictly before, "this Tuesday" the Tuesday of the anchor's locale
week, which may be past; "in 2 Tuesdays" the second Tuesday after the anchor.
Each is the day's first moment.

=item A count of units is added to the anchor.

"in 3 days" and "3 days ago" keep the anchor's time of day; "in 3 hours" is
three hours of elapsed time. Years, quarters, months, weeks and days are
counted on the calendar, as C<format_relative> counts them, so a day across a
clock change is still a day; hours, minutes and seconds are counted on the
clock.

=item A chain adds its parts in one direction.

"in 2 weeks and 3 days", "1 hour, 30 minutes and 10 seconds ago", "dans 2
semaines et 3 jours", "in 2 Wochen und 3 Tagen": the first or the last part
carries the direction ("in", "ago"), the others are bare counts, joined by
the locale's list words or by nothing. Months are added before days, as
C<plus> adds them. A chain that points both ways dies; one with no direction
is a duration, which C<parse_duration> reads.

=back

A count never dies for a wrong plural: "in 1 days" is one day. A day that
lands in a clock change that skipped it moves forward to the first moment
that existed. Where CLDR's data gives one string to both directions (its
Arabic short month pattern for a few months ago carries the word for "in"),
the direction whose marker the text carries wins, so the text means what a
reader would take it to mean rather than what the faulty pattern was for.

Some languages write one word for two days, and CLDR keeps it for both:
Hindi's "कल" is yesterday and tomorrow, and a speaker tells them apart by the
verb's tense, which the parser does not see. Such a phrase dies naming both
readings, "'कल' means yesterday and tomorrow in hi; pass prefer", unless
C<prefer> says which: C<future> takes the later, C<past> the earlier, and
C<match> reports the C<direction> as assumed. The same holds wherever the
phrase stands, before a time ("कल 15:00") or after one. The locales whose
data has such phrases are few: Arabic, Danish, Hindi and a handful more.

=head1 ABSOLUTE DATES AND TIMES

    # the clock pinned to Thursday 2026-10-15T09:00:00 Europe/London, en-GB
    $n->parse('2026-10-20T15:00:00Z');       # 2026-10-20T16:00:00+01:00, in the parser's zone
    $n->parse('15 October 2026');            # 2026-10-15T00:00:00+01:00
    $n->parse('15 October');                 # the same, the year assumed
    $n->parse('15/10/2026');                 # the locale's short date
    $n->parse('October 2026');               # 2026-10-01T00:00:00+01:00
    $n->parse('15:30');                      # 2026-10-15T15:30:00+01:00, today
    $n->parse('3 pm');                       # 2026-10-15T15:00:00+01:00
    $n->parse('3 in the afternoon');         # the same
    $n->parse('noon');                       # 2026-10-15T12:00:00+01:00
    $n->parse('next Tuesday 3 pm');          # 2026-10-20T15:00:00+01:00
    $n->parse('tomorrow 15:30');             # 2026-10-16T15:30:00+01:00
    $n->parse('15 October 9 am');            # 2026-10-15T09:00:00+01:00
    $n->in_locale('en-US')->parse('Oct 20'); # 2026-10-20T00:00:00+01:00
    $n->parse('Oct 20');                     # dies: en-GB writes 20 Oct

A date or a time is read through the locale's own formats, so the order of
day and month is the locale's and never a guess. The forms tried, in turn:
what L<Time::Keeper/parse> reads (ISO 8601, the RFC dates, C<@epoch>), in the
parser's zone when the text names none; the locale's four date-and-time, four
date and four time formats; every skeleton of its C<available_formats>, with
and without zero padding and, for a time, with and without its spaces ("3pm");
a bare hour; and C<noon> or C<midnight>. A date with no year takes the
anchor's year (C<prefer> moves one that is past or to come to the other
side; today stands); a date with no time is the day's first moment; a time
with no date is on the anchor's date. A weekday that does not fit the date
dies saying what day it was.

A bare hour is the hour in a locale whose clock has twenty-four; in one whose
clock has twelve it dies unless C<bare_hour> says C<am>, C<pm> or C<next>
(the first reading after the anchor that day, else the later one). "3 in the
afternoon" places the hour by the locale's day-period rules.

A day and a time combine either way round: a relative day or an absolute
date, and a time, joined by a space ("next Tuesday 3 pm", "3 pm tomorrow",
"15 October 9 am", "明日15:30"). The time replaces the day's; a time on a
phrase that already names one ("in 3 hours 5 pm") dies.

    $n->parse('the 15th');                  # 2026-10-15T00:00:00+01:00
    $n->parse('15th October');              # 2026-10-15T00:00:00+01:00
    $n->parse('the 1st of next month');     # 2026-11-01T00:00:00+00:00
    $n->parse('the 2nd at 3 pm');           # 2026-10-02T15:00:00+01:00
    $n->in_locale('fr')->parse('le 1er octobre');

A day of the month may be written as an ordinal in digits, as the locale's
CLDR rules write one ("15th", "1er", "1.º", "2:a"; about forty locales have
them, L</NUMBER WORDS>): in the locale's own date order, before a month and
the word table's "of", or alone, when it is that day of the anchor's month
and C<match> assumes the C<month> (under C<prefer>, the next or the last
such day). A time may follow it. The ordinal is read only where the text
does not read without it, so a phrase that already meant something keeps its
meaning (Vietnamese "thứ 2" is Monday), and a month without the day dies
saying so ("2026-11 has no day 31").

=head1 ZONES

    $n->parse('3 pm EST');                      # 2026-10-15T21:00:00+01:00
    $n->parse('15:30 Europe/Paris');            # 2026-10-15T14:30:00+01:00
    $n->parse('9:00 GMT+2');                    # 2026-10-15T08:00:00+01:00
    $n->parse('tomorrow 9:00 America/New_York');  # 2026-10-16T14:00:00+01:00
    $n->new(keep_zone => 1)->parse('3 pm EST');   # 2026-10-15T15:00:00-05:00
    $n->in_locale('fr')->parse('15:30 heure d’été d’Europe centrale');

A zone may follow what is read: an IANA name, C<UTC> or C<GMT>; one of the
locale's own zone names, specific, generic or a city ("Eastern Standard
Time", "Pacific Time", "Paris Time"), or its GMT format ("GMT+2", "UTC+2");
an offset ("+05:30"); or an abbreviation. The text is read in that zone and
the value brought into the parser's zone, unless C<keep_zone>, and C<match>
no longer assumes the C<zone>.

A standard or daylight name keeps its offset out of season: "3 pm EST" in
October is 15:00 at -05:00, though New York is then on daylight time. An
abbreviation the locale's CLDR names do not have ("JST", "CEST" in English)
is read where every zone that uses it, in the tz database, gives it one
offset, and dies where they differ ("IST" is India, Ireland and Israel),
unless the parser's zone is one that uses it. A time that falls in the
named zone's gap moves forward, as one in the parser's zone does.

=head1 CALENDARS

    my $h = $n->new(calendar => 'hebrew');
    $h->parse('4 Heshvan 5787');           # 2026-10-15T00:00:00+01:00, in the Hebrew calendar
    $h->parse('next month');               # 1 Kislev 5787: the calendar's next month
    $h->parse('end of next month');        # 30 Kislev 5787
    $n->new(locale => 'ja-u-ca-japanese')->parse('令和8年10月15日');
    $n->new(calendar => 'chinese')->parse('Mo9 6, 2026');
    $n->in_locale('he')->new(calendar => 'hebrew')->parse('ד׳ בחשוון תשפ״ז');

With C<calendar>, a text is read in that calendar's own date formats and
names in the locale, as Time::Keeper writes them, in all seventeen
calendars: eras ("令和8年", "8 Reiwa"), the Hebrew months and their leap
month, the Chinese and Korean calendars' years by the cycle of sixty ("ding-wei",
or its place, "43", the nearest such year to the anchor), a two-digit year
in the anchor's century of the calendar, and the numerals some calendars are
written in (Hebrew numerals, the lunar days 初六; with Time::Keeper 0.09).
A date written in the Gregorian still reads.

The anchor is taken in the calendar, so relative phrases count its months
and years: "next month" in the Hebrew calendar is the first of the next
Hebrew month, and "next year" in the Islamic one the next Hijri year. Every
value comes back in the calendar. Day ordinals ("the 15th") and the word
table's phrases count the Gregorian month, and intervals read the Gregorian
formats.

=head1 RELATIVE TO A POINT

    $n->parse('3 days after tomorrow');        # 2026-10-19T00:00:00+01:00
    $n->parse('2 weeks before 15 October');    # 2026-10-01T00:00:00+01:00
    $n->parse('the day after the 20th');       # 2026-10-21T00:00:00+01:00
    $n->parse('tomorrow evening');             # 2026-10-16T18:00:00+01:00
    $n->in_locale('fr')->parse('demain matin');
    $n->parse('this weekend');                 # 2026-10-17T00:00:00+01:00
    $n->parse('next weekend');                 # 2026-10-24T00:00:00+01:00

Where the locale has the words, a duration before or after a point: the
duration as C<parse_duration> reads it, the point as C<parse> does, moved
by Time::Keeper's arithmetic, so "3 days after 23 October" is three
calendar days across a change of the clocks; "the day after" and "the day
before" move a point by a day. The precision is the finer of the two.

A day and a part of it, in every locale: the day as C<parse> reads one,
the part by any of its CLDR names ("evening", "in the evening", "soir",
"Abend"), at the start the locale's day-period rules give it, precision
hour, C<period start> assumed. CLDR's rules are taken as they are, so in
English the morning begins at midnight and "tomorrow morning" is 00:00;
where two parts share a name (French "matin", the night and the morning),
the longer is meant.

The weekend, where the locale has the word: CLDR's "this week", "next
week" and "last week" with the table's word for the weekend in place of
the week's. This weekend is the one under way, else the coming one, by the
locale's weekend days (Saturday and Sunday in en-GB, Friday and Saturday in
en-IL, Sunday alone in en-IN), whatever day its week starts on; the next and
the last are a week either side. The value is its first day's first moment.

=head1 WORDS

    $n->parse('end of last month');          # 2026-09-30T23:59:59.999999999+01:00
    $n->parse('start of next week');         # 2026-10-19T00:00:00+01:00
    $n->parse('the end of the year');        # 2026-12-31T23:59:59.999999999+00:00
    $n->parse('end of October');             # 2026-10-31T23:59:59.999999999+00:00
    $n->parse('end of today');               # 2026-10-15T23:59:59.999999999+01:00
    $n->parse('tomorrow at 3 pm');           # 2026-10-16T15:00:00+01:00
    $n->parse('at 3 pm');                    # 2026-10-15T15:00:00+01:00
    $n->parse('on Tuesday at 9 am');         # 2026-10-20T09:00:00+01:00
    $n->parse('Tuesday');                    # 2026-10-20T00:00:00+01:00

CLDR has no words for the start or the end of a period, for the "at" between
a day and a time, for "on" before a day, or for "the". A locale gets them
from a small table the distribution ships, C<words/E<lt>codeE<gt>.txt> beside
the module (L<Time::Keeper::Natural::Words>), English first; a locale whose
chain has no table reads everything else and none of these, and C<coverage>
says which.

Word tables ship for: ar, bn, de, el, en, es, fr, hi, it, ja, ko, nl, pt, ru, th, zh.

Every table but English's is unreviewed, written as the first draft of each
language and marked so in its file; each carries the phrases its test lines
prove and says what its grammar keeps out of reach. A language that puts
"end" after the period ("来月末", "다음 달 말", "অক্টোবরের শেষ") is written as a
frame, and an article a contraction swallowed ("fin du mois dernier") is put
back before giving up. A language whose "end of" wants a case CLDR does not
have (German's genitive, Russian's) reads its edges with month names, years
and dates only. The table's keys, the whole of them: C<start_of>, C<end_of>,
C<at>, C<on>, C<skip> (words dropped where a part begins), C<and> (a chain
joiner, where the locale's list pattern has none), C<of> and C<last> (for
"the last Friday of October"), C<range> (two points as an interval, see
L</INTERVALS>), and C<after>, C<before> and C<weekend> (L</RELATIVE TO A
POINT>).

"start of" and "end of" take any period the parser reads: a period word
("last month", "next week", "today"), a weekday ("next Tuesday"), a date ("15
October"), a month ("October", "October 2026"), a year ("2026"), or a bare
unit name ("the month", "the year") for the current one. The result is the
period's first moment or its last nanosecond, by the locale's week. A phrase
that names a moment ("end of in 3 hours") dies: a moment has no end.

A bare weekday name is the coming one, today included ("Thursday" on a
Thursday is today), or the past one under C<prefer =E<gt> 'past'>. This is
the one place a name is given a direction, because "Tuesday at 3 pm" in a
message means the coming Tuesday; C<match> reports it as assumed.

=head1 NUMBER WORDS

    $n->parse('in two weeks');                       # 2026-10-29T09:00:00+00:00
    $n->parse('twenty one days ago');                # 2026-09-24T09:00:00+01:00
    $n->parse('in a week');                          # the article is one
    $n->in_locale('fr')->parse('dans deux semaines');
    $n->in_locale('de')->parse('vor einundzwanzig Tagen');
    $n->parse_duration('two hours and thirty minutes');
    $n->parse('the third Friday of next month');     # 2026-11-20T00:00:00+00:00
    $n->parse('the last Friday of October');         # 2026-10-30T00:00:00+00:00

Where a count is read as digits it is also read as a word, 0 to 99, in the
locales whose CLDR data has spellout rules, about ninety of them
(L<Time::Keeper::Natural::Numbers>); every form those rules write is read,
with hyphens or spaces, and no other. English's "a" and "an" are one. The
day ordinals in digits come the same way, from the locales'
C<%digits-ordinal> rules, English's "st", "nd", "rd" and "th" chosen by CLDR's
ordinal plural rules when the distribution is built.

"the third Friday of next month" counts a weekday in a month: an ordinal word,
1 to 5, or the word table's "last", then a weekday name, the table's "of", and
anything that names a month ("next month", "October", "October 2026"). A
month with no fifth Friday dies saying so, and so does a week or a year in
place of the month. This needs the table's C<of> and C<last> keys, so it reads
where a locale has a word table.

=head1 DURATIONS

    $n->parse_duration('1 hour, 30 minutes');          # PT1H30M
    $n->parse_duration('1 hr 30 min');                 # PT1H30M
    $n->parse_duration('1:05:09');                     # PT1H5M9S
    $n->parse_duration('2 weeks');                     # P14D, a duration's days
    $n->parse_duration('1 year, 2 months and 3 days'); # P1Y2M3D
    $n->parse_duration('PT90M');                       # PT1H30M
    $n->in_locale('de')->parse_duration('1 Std., 30 Min.');
    $n->in_locale('ar')->parse_duration('ساعتان و30 دقيقة');

Whatever C<Duration-E<gt>format> writes in a locale and a style,
C<parse_duration> reads back in it. Three forms are tried in turn: the ISO
8601 form C<Duration-E<gt>parse> reads; the locale's digital clock
("1:05:09", "1.05.09" in Finnish), where two parts are hours and minutes, as
the digital style writes them, never minutes and seconds; and the locale's
unit words in any width, joined by its list words, by commas or by nothing,
in any order ("30 minutes and 1 hour"). A unit given twice dies. Where one
word serves two units in a width (English's narrow "m" is months and
minutes), the chain decides: a part is read as the nearest unit below the
one before it, and a lone "30m" is minutes.

    $n->parse_duration('1.5 hours');                   # PT1H30M
    $n->parse_duration('2.5 weeks');                   # P17DT12H
    $n->in_locale('de')->parse_duration('1,5 Stunden');
    $n->parse('in 1.5 hours');                         # 2026-10-15T10:30:00+01:00

A count may have a fraction, written with the locale's decimal sign ("1.5",
"1,5", "٢٫٥"), in a duration or a relative phrase. It is converted down
exactly: 1.5 hours is an hour and thirty minutes, 0.25 days six hours. A
month, a quarter or a year has no fixed length, so a fraction of one dies,
and so does a fraction finer than a nanosecond. A number in groups of three
with the locale's group separator ("1,500 seconds", "1.500 Sekunden") is
read whole; a full stop between digits is never dropped, so "1.5 hours" is
not fifteen.

Parts are unsigned, as C<Duration-E<gt>format> writes them: a text with a
sign dies naming it. Milliseconds and microseconds become nanoseconds.
C<parse> of a duration dies saying C<parse_duration> reads it, and
C<parse_duration> of a moment dies saying it is a time.

=head1 INTERVALS

    $n->parse_interval('15 – 17 Oct 2026');       # the 15th 00:00, the 17th 23:59:59.999999999
    $n->parse_interval('9:00 – 10:30');           # 09:00, 10:30 today
    $n->parse_interval('2026-10-15T09:00/PT2H');  # 09:00, 11:00
    $n->parse_interval('Monday to Friday');       # next Monday 00:00, that Friday's end
    $n->parse_interval('from 9 am to 5 pm');      # 09:00, 17:00 today
    $n->parse_interval('10 pm to 2 am');          # 22:00 today, 02:00 tomorrow
    $n->in_locale('ja')->parse_interval('2026年10月15日～17日');

Three forms are tried in turn. The ISO 8601 form with a C</>, as
C<Time::Keeper-E<gt>parse_interval> reads it, ends included. What
C<format_interval> writes, in every locale: the text is read against each of
the locale's interval formats, split where the field that differs begins
again, and what the two ends share, written once, is lent to the end without
it ("15 – 17 Oct 2026" is October 2026 for both). And, where the locale has
the words, two phrases round a C<range> phrase of its word table ("from {0}
to {1}", "between {0} and {1}") or round its dash, each read as C<parse>
reads it and the second against the first: "Monday to Friday" is the Friday
after that Monday, and "15 to 17 October" the 15th of the second's month. A
hyphen is read for the locale's dash. Where the locale writes the end first
round its dash, as Balochi does, so is it read.

An end that names a day or a longer period runs to that period's last
nanosecond, as C<end_of> gives it ("Monday to Friday" ends as Friday does);
an end that names a time is that instant ("9 to 5" ends at 5). An end
named without a date that falls before the start is the next one: "10 pm to
2 am" ends tomorrow. A bare hour at the end is the next one after the
start whatever C<bare_hour> says ("9 am to 5" ends at 17:00); the start's
follows C<bare_hour>. An
interval whose end is still before its start dies, and so does a text that
names one time.

The precision is the start's, and the Match assumes what either end
assumed.


    my $m = $n->match('next Tuesday at 3 pm');
    $m->value;        # 2026-10-20T15:00:00+01:00
    $m->precision;    # hour
    $m->assumed;      # ('zone')
    $n->match('Tuesday')->assumed;        # ('weekday next', 'time', 'zone')
    $n->match('nonsense');                # undef

C<parse> gives a value and leaves the caller unable to tell what the text
said from what was filled in. C<match> gives both; see
L<Time::Keeper::Natural::Match> for the list of what can be assumed, which is
fixed.

=head1 ERRORS

Every method that reads a text either returns what it names or dies. A
death from reading has one shape:

    Time::Keeper::Natural->parse: cannot read 'next week zzz' at 'zzz': no such word in en

The text, the first token that could not be read, and the reason. The
reasons are a fixed set, and the parser refuses to give any other: C<the text is
empty>, C<no such word in E<lt>localeE<gt>>, C<one direction a phrase>,
C<a duration, not a time; parse_duration reads it>, C<a time, not a
duration>, C<E<lt>unitE<gt> is given twice>, C<a sign; a duration is
unsigned>, C<a bare hour; say am, pm or pass bare_hour>, C<E<lt>dateE<gt> was
a E<lt>weekdayE<gt>>, C<a time on a time>, C<a moment, not a period>,
C<nothing left after 'E<lt>wordE<gt>'>, C<an ordinal weekday is counted in a
month, not a E<lt>unitE<gt>>, C<no month has a E<lt>nthE<gt> E<lt>dayE<gt>>,
C<E<lt>yyyy-mmE<gt> has no E<lt>nthE<gt> E<lt>dayE<gt>>, and C<coverage of
E<lt>localeE<gt> is data; 'E<lt>phraseE<gt>' needs its words>, given when a
locale with no word table is handed English's "end of" or "at": the text may
be right, and the locale has no words for it; and C<'E<lt>phraseE<gt>' means
E<lt>readingE<gt> and E<lt>readingE<gt> in E<lt>localeE<gt>; pass prefer>, for a
phrase CLDR writes for two days (L</RELATIVE TIME>); C<'E<lt>abbreviationE<gt>'
names more than one zone in E<lt>localeE<gt>> (L</ZONES>); C<a month has no
fixed length> (or a quarter, or a year) and C<a fraction finer than a
nanosecond> (L</DURATIONS>); and from
C<parse_interval>, C<the interval ends before it starts> and C<a single
time, not an interval>. An option
that is wrong dies from C<new>, naming the option. The C<try_> forms give
C<undef> (C<try_parse_interval> an empty list) for any of these and leave
C<$@> alone.

=head1 TESTING

    local $Time::Keeper::CLOCK = Time::Keeper->parse('2026-10-15T09:00:00Z');

Pins the clock the anchor is read from, for one block; see
L<Time::Keeper/TESTING>. Every test in this distribution does so.

=head1 SEE ALSO

L<Time::Keeper>, L<Time::Keeper::Locale>, L<Time::Keeper::Duration>,
L<Time::Keeper::Natural::Match>, L<Time::Keeper::Natural::Words>,
L<Time::Keeper::Natural::Numbers>, L<Time::Keeper::Natural::Lexicon>.

L<Date::Parse> and L<Time::ParseDate> read English, by rules of thumb.
chrono (JavaScript) and dateparser (Python) find dates inside free text.

CLDR's date fields and spellout rules, which this module reads backwards:
L<https://cldr.unicode.org/>.

=head1 AUTHOR

LNATION <email@lnation.org>

=head1 BUGS

Please report any bugs or feature requests to C<bug-time-keeper-natural at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Time-Keeper-Natural>.

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

The number words and the locale data are from the Unicode Common Locale Data
Repository, Copyright (c) 1991-2026 Unicode, Inc., under the Unicode License v3.

=cut

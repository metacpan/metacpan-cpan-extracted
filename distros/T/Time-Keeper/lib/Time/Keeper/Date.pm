package Time::Keeper::Date;

use 5.010;
use strict;
use warnings;

our $VERSION = '0.09';

use Time::Keeper;

use overload
    '<=>'  => '_compare',
    'cmp'  => '_compare',
    '""'   => 'iso8601',
    '+'    => '_add_overload',
    '-'    => '_sub_overload',
    'bool' => sub { 1 },
    fallback => 1;

1;

__END__

=encoding utf8

=head1 NAME

Time::Keeper::Date - a date with no time of day

=head1 VERSION

Version 0.09

=head1 SYNOPSIS

    use Time::Keeper;

    my $d = Time::Keeper::Date->new(year => 2026, month => 10, day => 15);
    my $d = Time::Keeper::Date->today(zone => 'Europe/London');
    my $d = Time::Keeper::Date->parse('2026-10-15');
    my $d = $t->to_date;                      # from a Time::Keeper value

    $d->day_of_week;                          # 4, Thursday
    $d->plus(months => 1);                    # 2026-11-15
    $d->next(day_of_week => 1);               # the Monday after
    $d->format('EEEE d MMMM y');              # Thursday 15 October 2026
    $d->at(hour => 9, zone => 'Europe/London');   # a Time::Keeper value
    "$d";                                     # 2026-10-15

=head1 DESCRIPTION

A date with no time of day and no zone: a birthday, a due date, a day in a
calendar. It is not a L<Time::Keeper> value and does not pretend to be one:
it has no hour, no epoch and no zone, a pattern letter that needs a time of
day is an error rather than a fabricated C<00>, and it compares only with
another date. What it shares with a value it shares exactly: the same
calendar arithmetic (months first, then days, so C<< $a + ($b - $a) >> is
C<$b>), the same CLDR names and formats in every locale, the same parsers,
the same serialisation hooks.

A date in a locale carries that locale into its names and formats, as a
value does; see L<Time::Keeper/LOCALES>.

=head1 CONSTRUCTORS

=head2 new

    my $d = Time::Keeper::Date->new(year => 2026, month => 10, day => 15);
    my $d = Time::Keeper::Date->new(year => 2026, month => 10, day => 15, locale => 'fr');

The date given. C<month> and C<day> default to 1. A day the month does not
have is an error. There are no time keys and no zone.

=head2 last_day_of_month

=head2 from_day_of_year

=head2 from_iso_week

    Time::Keeper::Date->last_day_of_month(year => 2024, month => 2);   # 2024-02-29
    Time::Keeper::Date->from_day_of_year(year => 2026, day_of_year => 288);
    Time::Keeper::Date->from_iso_week(year => 2026, week => 42, day => 4);

As L<Time::Keeper/new>'s aliases, without a time: the last day of the
month, the day of the year, the day of the ISO week (C<day> 1 Monday to 7
Sunday, default Monday).

=head2 today

    my $d = Time::Keeper::Date->today;
    my $d = Time::Keeper::Date->today(zone => 'Asia/Tokyo');

Today's date in the zone, UTC by default; it reads the clock
L<Time::Keeper/TESTING> describes.

=head2 from_epoch_days

    my $d = Time::Keeper::Date->from_epoch_days(20741);   # 2026-10-15

The date that many days after 1 January 1970; negative for before.

=head2 parse

=head2 strptime

=head2 parse_cldr

    Time::Keeper::Date->parse('2026-10-15');
    Time::Keeper::Date->parse('2026-W42-4');
    Time::Keeper::Date->parse('2026-288');
    Time::Keeper::Date->strptime('15/10/2026', '%d/%m/%Y');
    Time::Keeper::Date->parse_cldr('15 octobre 2026', 'd MMMM y', locale => 'fr');

As L<Time::Keeper>'s, but giving a date. C<parse> reads the ISO 8601 date
forms, calendar, week and ordinal, extended and basic, and refuses text
that names a time of day, an offset or a zone: a date holds none of them. A
month alone is its first day and a week alone its Monday. Under a pattern,
the pattern says what the text holds and the date keeps the date: a C<%H>
in a C<strptime> pattern is read and dropped. Each takes C<locale>.

=head2 try_new

=head2 try_parse

=head2 try_strptime

=head2 try_parse_cldr

As the method without C<try_>, but undef where it would die, with C<$@>
left as it was.

=head1 ACCESSORS

=head2 year

=head2 month

=head2 day

=head2 day_of_week

=head2 day_of_year

=head2 quarter

=head2 day_of_quarter

=head2 week

=head2 week_year

=head2 week_of_month

=head2 is_leap_year

=head2 days_in_month

=head2 days_in_year

=head2 days_in_quarter

=head2 is_weekend

=head2 is_weekday

As L<Time::Keeper/ACCESSORS>; C<week> and C<week_year> take
C<< locale => 1 >> for the locale's weeks.

=head2 epoch_days

Days since 1 January 1970, negative before it; the inverse of
L</from_epoch_days>.

=head2 locale

The locale's code.

=head2 month_name

=head2 month_abbr

=head2 day_name

=head2 day_abbr

=head2 era_name

=head2 era_abbr

=head2 quarter_name

=head2 quarter_abbr

The locale's names, as L<Time::Keeper/month_name> and the rest.

=head1 NEW DATES FROM OLD

=head2 with

    $d->with(day => 1);
    $d->with(day => 'last');
    $d->with(day_of_year => 60);
    $d->with(week => 42);            # keeps the day of the week
    $d->with(day_of_week => 3);      # the Wednesday of the same ISO week

As L<Time::Keeper/with>, for the date's parts.

=head2 in_locale

The same date in another locale.

=head2 to_year_month

=head2 to_month_day

    $d->to_year_month;    # a Time::Keeper::YearMonth, 2026-10
    $d->to_month_day;     # a Time::Keeper::MonthDay, --10-15

=head2 at

    my $t = $d->at(hour => 9, minute => 30, zone => 'Europe/London');
    my $t = $d->at($time_of_day, zone => 'Europe/London', gap => 'forward');
    my $t = $d->at(zone => 'America/Sao_Paulo');    # midnight, or the first moment after it

The L<Time::Keeper> value at that time of day on this date in the zone (UTC
by default), with the date's locale. The time is given by its parts, or as
a L<Time::Keeper::Time> first. C<gap> and C<overlap> as for
L<Time::Keeper/new>; with no time given, a midnight the clocks skipped
gives the first moment that happened, as L<Time::Keeper/today> does.

=head1 ARITHMETIC

=head2 plus

=head2 minus

    $d->plus(months => 1);
    $d->plus(years => 1, months => 2, weeks => 3, days => 4);
    $d->plus(months => 1, end_of_month => 'limit');
    $d->plus($duration);
    $d->minus($other_date);          # a duration

Years, months, weeks and days, by name or as a L<Time::Keeper::Duration>,
with C<end_of_month> as L<Time::Keeper/plus> takes it. Hours and anything
smaller are an error: a date has no clock to add them to. C<minus> with
another date gives the duration from it to this one, months then days
(L<Time::Keeper/ARITHMETIC>). The operators C<+> and C<-> do the same.

=head2 delta_days

=head2 delta_md

The duration between two dates, in days alone, or in months and days;
never negative.

=head2 truncate

=head2 round

=head2 end_of

    $d->truncate(to => 'month');                      # the first
    $d->truncate(to => 'week', week_start => 'locale');
    $d->end_of(to => 'year');                         # 31 December
    $d->round(to => 'month', mode => 'floor');

To a year, quarter, month or week, as L<Time::Keeper/truncate>; C<end_of>
gives the period's last day.

=head2 next

=head2 previous

=head2 nth_in_month

=head2 last_in_month

    $d->next(day_of_week => 1);
    $d->next(day_of_week => 1, or_same => 1);
    $d->nth_in_month(day_of_week => 4, n => 3);
    $d->last_in_month(day_of_week => 7);

As L<Time::Keeper/next> and the rest, without C<gap> and C<overlap>.

=head1 COMPARING AND PRINTING

=head2 compare

    Time::Keeper::Date->compare($a, $b);   # -1, 0 or 1

The operators C<< <=> >>, C<==>, C<< < >> and so on do the same. A date
compares only with another date; a L<Time::Keeper> value or a year and
month beside it is an error.

=head2 iso8601

=head2 TO_JSON

C<2026-10-15>; years outside 0000 to 9999 with a sign and six digits.
C<"$d"> is the same.

=head2 ymd

=head2 mdy

=head2 dmy

=head2 date

As L<Time::Keeper/ymd>; C<date> is C<ymd> with hyphens.

=head1 FORMATTING

=head2 strftime

=head2 format

=head2 format_date

=head2 format_skeleton

    $d->format('EEEE d MMMM y');
    $d->strftime('%A %-d %B %Y');
    $d->format_date('full');
    $d->format_skeleton('yMMMd');

As L<Time::Keeper>'s, for the date's letters. A letter that needs a time of
day or a zone (C<H>, C<a>, C<z>, C<%T>, C<%c>, C<%s> and their kin) is an
error naming it, not a fabricated value; L<Time::Keeper/at> gives a value
when a time is wanted.

=head1 SERIALISATION

=head2 STORABLE_freeze

=head2 STORABLE_thaw

=head2 FREEZE

=head2 THAW

L<Storable>'s and the C<Types::Serialiser> protocol's hooks, as
L<Time::Keeper/SERIALISATION>: the frozen text carries the kind, so a
frozen date thaws only as a date.

=head2 utc_rd_values

The Rata Die day and zero seconds, for L<DateTime>'s C<from_object>.

=head1 SEE ALSO

L<Time::Keeper>, L<Time::Keeper::YearMonth>, L<Time::Keeper::MonthDay>.

=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut

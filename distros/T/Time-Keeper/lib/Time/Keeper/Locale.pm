package Time::Keeper::Locale;

use 5.010;
use strict;
use warnings;

our $VERSION = '0.09';

use Time::Keeper;

1;

__END__

=encoding utf8

=head1 NAME

Time::Keeper::Locale - what CLDR says of every locale Time::Keeper knows

=head1 VERSION

Version 0.09

=head1 SYNOPSIS

    use Time::Keeper::Locale;

    my @codes = Time::Keeper::Locale->codes;                  # 1121 of them
    Time::Keeper::Locale->name('fr_CA');                      # French (Canada)
    Time::Keeper::Locale->native_name('fr-CA');               # français (Canada)
    Time::Keeper::Locale->first_day_of_week('en-GB');         # 1, Monday
    Time::Keeper::Locale->names('de', 'months', 'abbreviated');
    Time::Keeper::Locale->cldr_version;                       # 48.2.3

=head1 DESCRIPTION

The calendar names and formats a L<Time::Keeper> value uses come from the
Unicode Common Locale Data Repository (CLDR). This module answers
questions about that data without a value.

Every method is a class method and takes a locale's code first. A code is
matched without regard to case, with C<_> taken as C<->: C<fr_CA>, C<fr-ca>
and C<fr-CA> are one locale. Every locale in CLDR's C<full> set is here,
and every code CLDR lists as default content, which names its parent's data
(C<fr-FR> is C<fr>), as L<DateTime::Locale> has them; and CLDR's aliases for
retired codes, such as C<iw> for C<he>, C<in> for C<id>. A code it does not
know is an error.

A locale's data is read the first time something asks for it, and kept for
the life of the process. English is always there and reads nothing.

=head1 METHODS

=head2 codes

The codes of every locale, English first.

=head2 code

    Time::Keeper::Locale->code('EN_gb');    # en-GB
    Time::Keeper::Locale->code('iw');       # he
    Time::Keeper::Locale->code('xx');       # undef

The locale's code as Time::Keeper writes it, or undef for one it does not
know. This is the one method that does not die for an unknown code.
A C<-u-ca-> extension naming a calendar (C<th-u-ca-buddhist>) is not part
of the code and is stripped here and in every method that takes a locale;
L<Time::Keeper/CALENDARS> says what reads it.

=head2 name

=head2 native_name

The locale's name in English, and in its own language: C<French (Canada)>
and C<français (Canada)>, as CLDR's display pattern makes them.

=head2 cldr_version

The CLDR release the data was compiled from.

=head2 first_day_of_week

The first day of the week where the locale is used, 1 for Monday to 7 for
Sunday: 7 in the United States, 1 in most of Europe, 6 in some countries.
The locale's region decides it; a language with no region takes the one
CLDR thinks most likely (C<fr> is France).

=head2 min_days_in_first_week

How many days of January the first week of a year must hold: 4 where
weeks are counted as ISO 8601 counts them, 1 in the United States.

=head2 prefers_24_hour_time

True if the locale's own times are written with a 24-hour clock.

=head2 names

    my @months = Time::Keeper::Locale->names('fr', 'months');
    my @days   = Time::Keeper::Locale->names('fr', 'days', 'abbreviated', 'stand-alone');

A list of names: C<months> (January first), C<days> (Monday first),
C<quarters>, C<eras> (before Christ, then after) or C<am_pm>. A width may
follow, C<wide> (the default), C<abbreviated> or C<narrow>, and C<short>
for days; and a context, C<format> (the default), the form used inside a
date, or C<stand-alone>, the form used alone. Where a language has only
one form the two are the same.
A calendar's id may follow as a fifth argument: its C<months> (CLDR's
slots, thirteen for the Hebrew with Adar II a fourteenth), C<eras> and
C<cyclic_years> in the locale, as L<Time::Keeper/CALENDARS> uses them.

=head2 day_periods

    my $p = Time::Keeper::Locale->day_periods('en');
    $p->{noon};             # noon
    $p->{afternoon1};       # in the afternoon

The locale's names for the parts of a day, as a hash reference keyed by
CLDR's ids: C<am>, C<pm>, C<midnight>, C<noon>, C<morning1>, C<morning2>,
C<afternoon1>, C<afternoon2>, C<evening1>, C<evening2>, C<night1> and
C<night2>, those the locale has. A width may follow, C<wide> (the default),
C<abbreviated> or C<narrow>, and a context, C<format> (the default), the
form inside a time, or C<stand-alone>, the form used alone; where a language
has one form the two are the same. These are the words C<B> writes in a
pattern.

    Time::Keeper::Locale->day_periods('es', 'wide', 'stand-alone');

=head2 day_period_rules

    my @rules = Time::Keeper::Locale->day_period_rules('en');
    # { period => 'morning1', from => 360, before => 720 }, ... { period => 'noon', at => 720 }

When each named period is, as a list of hash references: the period's id and
either C<from> and C<before>, minutes of the day with the end excluded, or
C<at>, the one minute of C<midnight> or C<noon>. CLDR cuts the day at
midnight, so no period crosses it: English's night runs from 21:00 to 24:00
and its morning from 00:00. Locales that share CLDR's rules share them.

=head2 formats

    my ($full, $long, $medium, $short) = Time::Keeper::Locale->formats('ja', 'date');

The locale's four CLDR patterns for C<date>, C<time> or C<datetime>. In a
C<datetime> pattern C<{1}> is the date and C<{0}> the time.
A calendar's id as a third argument gives the calendar's own C<date> and
C<datetime> patterns; the time patterns are the Gregorian's. A pattern is
returned as its letters, without the numbering system CLDR may attach to it.

=head2 available_formats

A hash reference of the locale's patterns by skeleton, as
L<Time::Keeper/format_skeleton> uses them.
A calendar's id as a second argument lays the calendar's skeletons over
the Gregorian ones.

=head2 calendars

    my @ids = Time::Keeper::Locale->calendars('th');   # buddhist gregory

The calendars the locale's territory uses, most preferred first:
L<Time::Keeper::Calendar/preferred> for a locale code.

=head2 parts

    my $p = Time::Keeper::Locale->parts('zh-Hant-TW');
    $p->{territory};               # TW
    $p->{script_name};             # Traditional
    $p->{native_territory_name};   # 台灣

The locale's subtags, C<language>, C<script>, C<territory> and C<variant>
(undef for those it does not have), with each one's name in English
(C<language_name> and so on) and in the locale itself
(C<native_language_name> and so on), as a hash reference.

=head2 digits

The ten digits the locale writes, 0 to 9: C<0> to C<9> in most, C<٠> to
C<٩> in C<ar-EG>, C<০> to C<৯> in C<bn>.

=head2 number_symbols

    my $s = Time::Keeper::Locale->number_symbols('de');
    $s->{decimal};          # ,
    $s->{group};            # .
    $s->{minus};            # -

The symbols the locale writes numbers with, in its default numbering
system: the decimal separator, the group separator and the minus sign. Some
carry a Unicode mark, as Arabic's minus does.

=head2 ascii_digits

    Time::Keeper::Locale->ascii_digits('٢٠٢٦');   # 2026

The text with the digits of every script written as 0 to 9, as the parsers
read them; anything else is left as it is.

=head2 weekend_start

=head2 weekend_end

    Time::Keeper::Locale->weekend_start('ar-EG');   # 5, Friday

The first and last day of the locale's weekend, 1 for Monday to 7 for
Sunday, from CLDR's data for the locale's territory: Saturday and Sunday in
most of the world, Friday and Saturday in Egypt, Thursday and Friday in
Afghanistan, Sunday alone in India.

=head2 plural_category

    Time::Keeper::Locale->plural_category('ru', 21);   # one
    Time::Keeper::Locale->plural_category('ru', 5);    # many

The CLDR plural category of a whole number in the locale: C<zero>, C<one>,
C<two>, C<few>, C<many> or C<other>. English has C<one> and C<other>;
Russian C<one>, C<few>, C<many> and C<other>; Arabic all six; Japanese
C<other> alone. The sign is ignored.

=head2 relative_names

    my $r = Time::Keeper::Locale->relative_names('en', 'day');
    $r->{display};          # day
    $r->{at}{-1};           # yesterday
    $r->{at}{1};            # tomorrow
    $r->{future}{one};      # in {0} day
    $r->{past}{other};      # {0} days ago

The locale's words for a relative time in a field (C<year>, C<quarter>,
C<month>, C<week>, C<day>, C<hour>, C<minute> or C<second>) and a width
(C<long>, the default, C<short> or C<narrow>), as a hash reference: the
field's name, the words for the field -2 to 2 away where the locale has
them (C<at>, keyed by the offset), and the patterns for a count in the
future and the past by plural category, with C<{0}> for the number.

A weekday is a field too, C<mon> to C<sun>: C<at> holds the locale's "last
Tuesday", "this Tuesday" and "next Tuesday" (-1, 0 and 1), and the patterns
are its "in {0} Tuesdays" and "{0} Tuesdays ago". A weekday has no
C<display> name; L</names> gives the day's.

=head2 unit_patterns

    my $u = Time::Keeper::Locale->unit_patterns('de', 'hour', 'short');
    $u->{display};          # Std.
    $u->{count}{one};       # {0} Std.

The locale's words for a duration unit (C<year>, C<month>, C<week>,
C<day>, C<hour>, C<minute>, C<second>, C<millisecond>, C<microsecond> or
C<nanosecond>) in a width (C<long>, C<short> or C<narrow>): its name and
the pattern for a count by plural category.

=head2 duration_patterns

A hash reference of the locale's patterns for a duration written as digits:
C<hm> (C<h:mm>), C<hms> (C<h:mm:ss>) and C<ms> (C<m:ss>).

=head2 list_patterns

    my $l = Time::Keeper::Locale->list_patterns('en', 'unit');
    $l->{two};              # {0}, {1}
    $l->{start};  $l->{middle};  $l->{end};

The locale's patterns for joining a list, of the type C<standard> (and),
C<unit>, C<unit-short> or C<unit-narrow>, as a hash reference: C<two> for a
list of two, and C<start>, C<middle> and C<end> for a longer one.

=head2 interval_formats

    my $i = Time::Keeper::Locale->interval_formats('en', 'yMMMd');
    $i->{d};                # MMM d – d, y
    $i->{M};                # MMM d – MMM d, y
    my $all = Time::Keeper::Locale->interval_formats('en');   # by skeleton

The locale's interval formats for a skeleton: a hash reference from the
greatest field that differs between the two ends (C<y>, C<M>, C<d>, C<a>,
C<h>, C<H>, C<m>, C<B> or C<G>) to the pattern, whose second half begins at
the first field that repeats. With no skeleton, every skeleton's, as a hash
of hashes.

=head2 interval_fallback

The locale's pattern for an interval no format fits, C<{0} – {1}> in English.

=head1 SEE ALSO

L<Time::Keeper>, L<https://cldr.unicode.org/>

=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

The locale data is from the Unicode Common Locale Data Repository,
Copyright (c) 1991-2026 Unicode, Inc., under the Unicode License v3.

=cut

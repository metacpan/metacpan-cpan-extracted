package Time::Keeper::Locale;

use 5.010;
use strict;
use warnings;

our $VERSION = '0.01';

use Time::Keeper;

1;

__END__

=encoding utf8

=head1 NAME

Time::Keeper::Locale - what CLDR says of every locale Time::Keeper knows

=head1 VERSION

Version 0.01

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

=head2 formats

    my ($full, $long, $medium, $short) = Time::Keeper::Locale->formats('ja', 'date');

The locale's four CLDR patterns for C<date>, C<time> or C<datetime>. In a
C<datetime> pattern C<{1}> is the date and C<{0}> the time.

=head2 available_formats

A hash reference of the locale's patterns by skeleton, as
L<Time::Keeper/format_skeleton> uses them.

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

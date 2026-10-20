package Time::Keeper::Calendar;

use 5.010;
use strict;
use warnings;

our $VERSION = '0.09';

use Time::Keeper;

1;

__END__

=encoding utf8

=head1 NAME

Time::Keeper::Calendar - the calendars Time::Keeper values can be read in

=head1 VERSION

Version 0.09

=head1 SYNOPSIS

    use Time::Keeper;

    Time::Keeper::Calendar->ids;                       # gregory, buddhist, japanese, ...
    Time::Keeper::Calendar->name('hebrew');            # Hebrew
    Time::Keeper::Calendar->kind('islamic-umalqura');  # tabular
    Time::Keeper::Calendar->eras('japanese');          # era0 .. meiji taisho showa heisei reiwa
    Time::Keeper::Calendar->months_in_year('hebrew', 5784);   # 13
    Time::Keeper::Calendar->days_in_month('hebrew', 5784, 'M05L');   # 30
    Time::Keeper::Calendar->is_leap_year('persian', 1403);
    Time::Keeper::Calendar->preferred('TH');                 # buddhist gregory
    Time::Keeper::Calendar->era_start('japanese', 'reiwa');   # 2019-05-01, a Time::Keeper::Date

=head1 DESCRIPTION

Questions about a calendar that need no value: its id and English name, how
it is computed, its eras, and the shape of a year. The calendars themselves
are described under L<Time::Keeper/CALENDARS>; a value is read in one with
L<Time::Keeper/in_calendar> or made in one with C<calendar> on any
constructor.

=head1 CLASS METHODS

=head2 ids

The seventeen ids, in the engine's order: C<gregory>, C<buddhist>,
C<japanese>, C<roc>, C<coptic>, C<ethiopic>, C<ethioaa>, C<hebrew>,
C<islamic-civil>, C<islamic-tbla>, C<islamic-umalqura>, C<islamic>,
C<islamic-rgsa>, C<persian>, C<indian>, C<chinese>, C<dangi>. Every method
that takes an id also takes C<iso8601> and C<gregorian> for C<gregory>,
C<ethiopic-amete-alem> for C<ethioaa> and C<islamicc> for C<islamic-civil>,
in any case.

=head2 name

=head2 kind

=head2 canonical

    Time::Keeper::Calendar->name('roc');          # Minguo
    Time::Keeper::Calendar->kind('hebrew');       # arithmetic
    Time::Keeper::Calendar->canonical('gregorian');   # gregory

CLDR's English name; C<arithmetic>, C<tabular> (Umm al-Qura, from Saudi
Arabia's table) or C<astronomical> (the four that follow the moon and the
sun, read from tables of what ICU computes for the years 1000 to 3000); the
id an alias stands for.

=head2 eras

The era codes, earliest first: C<bce> and C<ce>, C<be>, the 237 Japanese
eras (CLDR names the last five, C<meiji> to C<reiwa>; the rest are
C<era0> to C<era231> by CLDR's index until a later release brings their
names), C<broc> and C<roc>, C<before-am> and C<am>, C<aa> and C<am>, C<ah>,
C<ap>, C<shaka>.

=head2 months_in_year

=head2 days_in_month

=head2 days_in_year

=head2 is_leap_year

=head2 month_code

    Time::Keeper::Calendar->months_in_year('hebrew', 5784);        # 13
    Time::Keeper::Calendar->days_in_month('coptic', 1740, 13);     # 6
    Time::Keeper::Calendar->days_in_month('hebrew', 5784, 'M05L'); # 30, Adar I
    Time::Keeper::Calendar->days_in_year('islamic-civil', 1445);   # 355
    Time::Keeper::Calendar->is_leap_year('indian', 1946);
    Time::Keeper::Calendar->month_code('hebrew', 5784, 6);         # M05L

The shape of a year, by the calendar's continuous year and ordinal month;
C<days_in_month> also takes a month code.

=head2 preferred

    my @ids = Time::Keeper::Calendar->preferred('TH');      # buddhist gregory
    my @ids = Time::Keeper::Calendar->preferred('zh-Hant'); # gregory roc chinese

The calendars a territory uses, most preferred first, from CLDR's
preference data: a territory is two capital letters or three digits (C<001>
is the world), and a locale code gives its territory's list, the territory
it names or, when it names none, the one CLDR thinks its language is likely
in (C<ko> is Korea, C<zh-Hant> Taiwan). A territory CLDR says nothing of
gets the world's list, the Gregorian alone. The default calendar of a value
is never taken from this; see L<Time::Keeper/CALENDARS>.

=head2 era_start

    Time::Keeper::Calendar->era_start('japanese', 'reiwa');   # 2019-05-01

The first day of an era, as a L<Time::Keeper::Date>; undef for an era with
no beginning (C<bce>, C<broc>). The code is matched in any case.

=head2 names

    my @months = Time::Keeper::Calendar->names('hebrew', 'he', 'months');
    my @eras   = Time::Keeper::Calendar->names('japanese', 'ja', 'eras', 'abbreviated');

The calendar's names in a locale: L<Time::Keeper::Locale/names> with the
calendar given, the id first and the locale second, then C<months>, C<eras>
or C<cyclic_years>, a width and a context.

=head1 SEE ALSO

L<Time::Keeper>.

=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut

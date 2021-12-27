package Tripletail::DateTime::Calendar::Gregorian;
use strict;
use warnings;
use Tripletail::DateTime::Calendar::MonthDay qw(monthAndDayToDayOfYear monthAndDayToDayOfYearRollOver dayOfYearToMonthAndDay);
use Tripletail::DateTime::Calendar::OrdinalDate qw(toOrdinalDate fromOrdinalDate isGregorianLeapYear);
use Tripletail::DateTime::Math qw(div mod);

use Exporter 'import';
our @EXPORT_OK = qw(
    toGregorian
    fromGregorian
    fromGregorianRollOver
    addGregorianMonthsClip
    addGregorianYearsClip
   );

=encoding utf8

=head1 NAME

Tripletail::DateTime::Calendar::Gregorian - 内部用

=begin comment

=head1 DESCRIPTION

This module provides a set of functions to handle Proleptic Gregorian
calendar.

=head1 EXPORT

Nothing by default.

=head1 FUNCTIONS

=head2 C<< toGregorian >>

    my ($y, $m, $d) = toGregorian($mjd);

Convert to proleptic Gregorian calendar. First element of result is
year, second month number (1-12), third day (1-31).

=cut

sub toGregorian {
    my ($mjd        ) = @_;
    my ($year , $yd ) = toOrdinalDate($mjd);
    my ($month, $day) = dayOfYearToMonthAndDay(scalar isGregorianLeapYear($year), $yd);

    return ($year, $month, $day);
}

=head2 C<< fromGregorian >>

    my $mjd = fromGregorian($y, $m, $d);

Convert from proleptic Gregorian calendar. First argument is year,
second month number (1-12), third day (1-31). Invalid values will be
clipped to the correct range, month first, then day.

=cut

sub fromGregorian {
    my ($y, $m, $d) = @_;
    return fromOrdinalDate(
        $y,
        monthAndDayToDayOfYear(scalar isGregorianLeapYear($y), $m, $d));
}

=head2 C<< fromGregorianRollOver >>

    my $mjd = fromGregorianRollOver($y, $m, $d);

This is similar to L</"fromGregorian"> except days past the last day
of the month will be rolled over to the next month.

=cut

sub fromGregorianRollOver {
    my ($y, $m, $d) = @_;
    return fromOrdinalDate(
        $y,
        monthAndDayToDayOfYearRollOver(scalar isGregorianLeapYear($y), $m, $d));
}

=head2 C<< addGregorianMonthsClip >>

    my $mjd1 = addGregorianMonthsClip($n, $mjd);

Add months, with days past the last day of the month clipped to the
last day. For instance, 2005-01-30 + 1 month = 2005-02-28.

=cut

sub addGregorianMonthsClip {
    my ($n, $day) = @_;
    return fromGregorian(_addGregorianMonths($n, $day));
}

sub _addGregorianMonths {
    my ($n , $day  ) = @_;
    my ($y , $m, $d) = toGregorian($day);
    my ($y1, $m1   ) = _rolloverMonths($y, $m + $n);

    return ($y1, $m1, $d);
}

sub _rolloverMonths {
    my ($y, $m) = @_;

    return ($y + div($m - 1, 12), mod($m - 1, 12) + 1);
}

=head2 C<< addGregorianYearsClip >>

    my $mjd1 = addGregorianYearsClip($n, $mjd);

Add years, matching month and day, with Feb 29th clipped to Feb 28th
if necessary. For instance, 2004-02-29 + 2 years = 2006-02-28.

=cut

sub addGregorianYearsClip {
    my ($n, $day) = @_;
    return addGregorianMonthsClip($n * 12, $day);
}

=end comment

=head1 SEE ALSO

L<Tripletail::DateTime>

=head1 AUTHOR INFORMATION

This framework is free software; you can redistribute it and/or modify it under the same terms as Perl itself

このフレームワークはフリーソフトウェアです。あなたは Perl と同じライセンスの 元で再配布及び変更を行うことが出来ます。

Address bug reports and comments to: tl@tripletail.jp

Official web site: http://tripletail.jp/

=cut

1;

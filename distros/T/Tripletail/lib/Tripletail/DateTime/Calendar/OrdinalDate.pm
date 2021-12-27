package Tripletail::DateTime::Calendar::OrdinalDate;
use strict;
use warnings;
use Exporter 'import';
use List::Util qw(min);
use Tripletail::DateTime::Math qw(div mod divMod clip);
our @EXPORT_OK = qw(
    toOrdinalDate
    fromOrdinalDate
    isGregorianLeapYear
   );

=encoding utf8

=head1 NAME

Tripletail::DateTime::Calendar::OrdinalDate - 内部用

=begin comment

=head1 DESCRIPTION

This module provides a set of functions to handle ISO 8601 Ordinal
Date format.

=head1 EXPORT

Nothing by default.

=head1 FUNCTIONS

=head2 C<< toOrdinalDate >>

    my ($year, $yd) = toOrdinalDate($mjd);

Convert a Modified Julian Day into ISO 8601 Ordinal Date format. First
element of result is year (proleptic Gregorian calendar), second is
the day of the yar, with 1 for Jan 1, and 365 (or 366 in leap years)
for Dec 31.

=cut

sub toOrdinalDate {
    my $a              = $_[0] + 678575;
    my ($quadcent, $b) = divMod($a, 146097);
    my $cent           = min(div($b, 36524), 3);
    my $c              = $b - ($cent * 36524);
    my ($quad, $d)     = divMod($c, 1461);
    my $y              = min(div($d, 365), 3);
    my $yd             = $d - ($y * 365) + 1;
    my $year           = $quadcent * 400 + $cent * 100 + $quad * 4 + $y + 1;

    return ($year, $yd);
}

=head2 C<< fromOrdinalDate >>

    my $mjd = fromOrdinalDate($year, $yd);

Convert from ISO 8601 Ordinal Date format to Modified Julian
Day. Invalid day numbers will be clipped to the correct range (1 to
365 or 366).

=cut

sub fromOrdinalDate {
    my ($year, $day) = @_;
    my $y    = $year - 1;
    my $days = isGregorianLeapYear($year) ? 366 : 365;

    return clip(1, $days, $day)
         + 365 * $y
         + div($y,   4)
         - div($y, 100)
         + div($y, 400)
         - 678576;
}

=head2 C<< isGregorianLeapYear >>

    my $bool = isGregorianLeapYear($year);

Is this year a leap year according to the proleptic Gregorian
calendar?

=cut

sub isGregorianLeapYear {
    my ($year) = @_;

    if (mod($year, 4) == 0 and
          ((mod($year, 400) == 0) or not (mod($year, 100) == 0))) {
        return 1;
    }
    else {
        return;
    }
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

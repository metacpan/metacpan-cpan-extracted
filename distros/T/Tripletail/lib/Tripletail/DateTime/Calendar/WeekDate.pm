package Tripletail::DateTime::Calendar::WeekDate;
use strict;
use warnings;
use Exporter 'import';
use Tripletail::DateTime::Math qw(div divMod);
use Tripletail::DateTime::Calendar::OrdinalDate qw(toOrdinalDate fromOrdinalDate);
our @EXPORT_OK = qw(toWeekDate);

=encoding utf8

=head1 NAME

Tripletail::DateTime::Calendar::WeekDate - 内部用

=begin comment

=head1 DESCRIPTION

This module provides a set of functions to handle ISO 8601 Week Date
format.

=head1 EXPORT

Nothing by default.

=head1 FUNCTIONS

=head2 C<< toWeekDate >>

    my ($weekYear, $week, $dayOfWeek) = toWeekDate($mjd);

Convert to ISO 8601 Week Date format. First element of result is year,
second week number (1-53), third day of week (1 for Monday to 7 for
Sunday).  Note that "Week" years are not quite the same as Gregorian
years, as the first day of the year is always a Monday.  The first
week of a year is the first week to contain at least four days in the
corresponding Gregorian year.

=cut

sub toWeekDate {
    my ($mjd              ) = @_;
    my $d                   = $mjd + 2;
    my ($d_div_7, $d_mod_7) = divMod($d, 7);
    my ($y0     , $yd     ) = toOrdinalDate($mjd);
    my $bar                 = sub { return $d_div_7 - div($_[0], 7)          };
    my $foo                 = sub { return $bar->(fromOrdinalDate($_[0], 6)) };
    my ($y1     , $w1     ) = do {
        my $w0 = $bar->($d - $yd + 4);
        if ($w0 == -1) {
            ($y0 - 1, $foo->($y0 - 1));
        }
        elsif ($w0 == 52) {
            if ($foo->($y0 + 1) == 0) {
                ($y0 + 1, 0);
            }
            else {
                ($y0, 52);
            }
        }
        else {
            ($y0, $w0);
        }
    };

    return ($y1, $w1 + 1, $d_mod_7 + 1);
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

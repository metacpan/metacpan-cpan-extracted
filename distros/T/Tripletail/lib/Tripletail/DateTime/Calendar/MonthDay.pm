package Tripletail::DateTime::Calendar::MonthDay;
use strict;
use warnings;
use Exporter 'import';
use Tripletail::DateTime::Math qw(div clip);
our @EXPORT_OK = qw(
    monthAndDayToDayOfYear
    monthAndDayToDayOfYearRollOver
    dayOfYearToMonthAndDay
    monthLength
   );

=encoding utf8

=head1 NAME

Tripletail::DateTime::Calendar::MonthDay - 内部用

=begin comment

=head1 DESCRIPTION

This module provides a set of functions to handle months and days in
the Gregorian or Julian calendars.

=head1 EXPORT

Nothing by default.

=head1 FUNCTIONS

=head2 C<< monthAndDayToDayOfYear >>

    my $yd = monthAndDayToDayOfYear($isLeap, $month, $day);

Convert month and day in the Gregorian or Julian calendars to day of
year. First arg is the leap year flag.

=cut

sub monthAndDayToDayOfYear {
    my ($isLeap, $month, $day) = @_;
    my $month1 = clip(1, 12, $month);
    my $day1   = clip(1, _monthLength_($isLeap, $month1), $day);
    my $k      = $month1 <= 2 ?  0
               : $isLeap      ? -1
               :                -2
               ;
    return div(367 * $month1 - 362, 12) + $k + $day1;
}

=head2 C<< monthAndDayToDayOfYearRollOver >>

    my $yd = monthAndDayToDayOfYear($isLeap, $month, $day);

This is similar to L</"monthAndDayToDayOfYear"> except days past the
last day of the month will be rolled over to the next month.

=cut

sub monthAndDayToDayOfYearRollOver {
    my ($isLeap, $month, $day) = @_;
    my $month1 = clip(1, 12, $month);
    my $k      = $month1 <= 2 ?  0
               : $isLeap      ? -1
               :                -2
               ;
    return div(367 * $month1 - 362, 12) + $k + $day;
}

=head2 C<< dayOfYearToMonthAndDay >>

    my ($month, $day) = dayOfYearToMonthAndDay($isLeap, $yd);

Convert day of year in the Gregorian or Julian calendars to month and
day. First arg is leap year flag.

=cut

sub dayOfYearToMonthAndDay {
    my ($isLeap, $yd) = @_;
    my $lengths = _monthLengths($isLeap);
    my $days    = $isLeap ? 366 : 365;

    return _findMonthDay($lengths, clip(1, $days, $yd));
}

sub _findMonthDay {
    my ($lengths, $day) = @_;

    my $month = 1;
    foreach my $length (@$lengths) {
        if ($day > $length) {
            $month += 1;
            $day   -= $length;
        }
        else {
            last;
        }
    }

    return ($month, $day);
}

=head2 C<< monthLength >>

    my $len = monthLength($isLeap, $month);

The length of a given month in the Gregorian or Julian
calendars. First arg is the leap year flag.

=cut

sub monthLength {
    return _monthLength_($_[0], clip(1, 12, $_[1]));
}

sub _monthLength_ {
    return _monthLengths($_[0])->[$_[1] - 1];
}

sub _monthLengths {
    #       Jan Feb              Mar Apr May Jun Jul Aug Sep Oct Nov Dec
    return [31, $_[0] ? 29 : 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];
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

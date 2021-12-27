package Tripletail::DateTime::Format::RFC733;
use strict;
use warnings;
use Exporter 'import';
use Tripletail::DateTime::Calendar::Gregorian qw(toGregorian fromGregorianRollOver);
use Tripletail::DateTime::Calendar::WeekDate qw(toWeekDate);
use Tripletail::DateTime::LocalTime qw(timeToTimeOfDay timeOfDayToTime);
use Tripletail::DateTime::Math qw(quot widenYearOf2Digits);
our @EXPORT_OK = qw(
    parseRFC733DateTime
    renderRFC733DateTime
   );

my @WDAY_NAMES_SHORT  = qw(Mon    Tue     Wed       Thu      Fri    Sat      Sun   );
my @WDAY_NAMES_LONG   = qw(Monday Tuesday Wednesday Thursday Friday Saturday Sunday);

my @MONTH_NAMES_SHORT = qw(Jan     Feb      Mar   Apr   May Jun  Jul  Aug    Sep       Oct     Nov      Dec     );
my @MONTH_NAMES_LONG  = qw(January February March April May June July August September October November December);

my %NUMERIC_MONTH_OF = (
    do {
        my $i = 1;
        map { $_ => $i++ } @MONTH_NAMES_SHORT;
    },
    do {
        my $i = 1;
        map { $_ => $i++ } @MONTH_NAMES_LONG;
    }
   );

my %RFC733_TZ_TABLE = (
    GMT =>      0,
    NST =>  -3*60-30,
    AST =>  -4*60,
    ADT =>  -3*60,
    EST =>  -5*60,
    EDT =>  -4*60,
    CST =>  -6*60,
    CDT =>  -5*60,
    MST =>  -7*60,
    MDT =>  -6*60,
    PST =>  -8*60,
    PDT =>  -7*60,
    YST =>  -9*60,
    YDT =>  -8*60,
    HST => -10*60,
    HDT =>  -9*60,
    BST => -11*60,
    BDT => -10*60,
    Z   =>      0,
    A   =>  -1*60,
    M   => -12*60,
    N   =>  +1*60,
    Y   => +12*60
   );
my %RFC733_TZ_TABLE_OFF = reverse %RFC733_TZ_TABLE;

sub _a2r {
    my $re = join('|', map { quotemeta } @_);
    return qr/$re/;
}

=encoding utf8

=head1 NAME

Tripletail::DateTime::Format::RFC733 - 内部用

=begin comment

=head1 DESCRIPTION

This module provides a set of functions to parse and render RFC 733
Date and Time format.

=head1 EXPORT

Nothing by default.

=head1 FUNCTIONS

=head2 C<< parseRFC733DateTime >>

    my ($localDay, $localDayTime, $timeZone)
      = parseRFC733DateTime('Tue, 01-Sep-2015 12:23:11 +0900');

Try to parse a given string as an RFC 733 Date and Time format.Return
a triple of local MJD, local day time, and time-zone on success,
nothing otherwise.

=cut

my $RE_WDAY      = _a2r(@WDAY_NAMES_SHORT , @WDAY_NAMES_LONG );
my $RE_MONTH     = _a2r(@MONTH_NAMES_SHORT, @MONTH_NAMES_LONG);
my $RE_DAY       = qr/0?[1-9]|[12][0-9]|3[01]/; # 1*2DIGIT
my $RE_YEAR      = qr/\d{4}|\d{2}/;
my $RE_DATE      = qr/($RE_DAY)[- ]($RE_MONTH)[- ]($RE_YEAR)/;
my $RE_2H        = qr/2[0-3]|[0-1][0-9]/; # 00 .. 23
my $RE_2M        = qr/[0-5][0-9]/;        # 00 .. 59
my $RE_2S        = $RE_2M;
my $RE_TIME      = qr/($RE_2H):?($RE_2M)(?::?($RE_2S))?/;
my $RE_TIMEZONE  = do {
    my $names   = _a2r(keys %RFC733_TZ_TABLE);
    my $numeric = qr/[+\-]\d{4}/;

    qr/$names|$numeric/;
};
my $RE_DATE_TIME = qr/(?:$RE_WDAY, )?$RE_DATE (?:$RE_TIME)[- ]($RE_TIMEZONE)/;

sub parseRFC733DateTime {
    my $str = shift;

    if ($str =~ m/^$RE_DATE_TIME$/o) {
        return (
            fromGregorianRollOver(widenYearOf2Digits($3), $NUMERIC_MONTH_OF{$2}, $1),
            timeOfDayToTime($4, $5, $6 || 0),
            _parseRFC733TimeZone($7)
           );
    }
    else {
        return;
    }
}

sub _parseRFC733TimeZone {
    my $str = shift;

    if (defined(my $tz = $RFC733_TZ_TABLE{$str})) {
        return $tz;
    }
    elsif ($str =~ m/^([+\-])(\d{2})(\d{2})$/) {
        return ($1 eq '-' ? -1 : 1) * ($2 * 60 + $3);
    }
    else {
        return;
    }
}

=head2 C<< renderRFC733DateTime >>

    my $str = renderRFC733DateTime($localDay, $localDayTime, $timeZone);

Render a triple of local mJD, local day time, and time-zone as a
string in RFC 733 Date and Time format.

=cut

sub renderRFC733DateTime {
    my ($day , $dayTime, $tz  ) = @_;
    my ($y   , $m      , $d   ) = toGregorian($day);
    my (undef, undef   , $wDay) = toWeekDate($day);
    my ($hour, $min    , $sec ) = timeToTimeOfDay($dayTime);

    return sprintf(
        '%s, %02d-%s-%04d %02d:%02d:%02d %s',
        $WDAY_NAMES_SHORT[$wDay-1],
        $d, $MONTH_NAMES_SHORT[$m-1], $y,
        $hour, $min, $sec,
        _renderRFC733TimeZone($tz));
}

sub _renderRFC733TimeZone {
    my $tz = shift;

    if (defined(my $name = $RFC733_TZ_TABLE_OFF{$tz})) {
        $name;
    }
    else {
        my $h = quot(abs($tz), 60);
        my $m = abs($tz) - $h * 60;
        return sprintf('%s%02d%02d', $tz < 0 ? '-' : '+', $h, $m);
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

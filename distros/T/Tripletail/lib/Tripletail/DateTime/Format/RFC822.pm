package Tripletail::DateTime::Format::RFC822;
use strict;
use warnings;
use Exporter 'import';
use Tripletail::DateTime::Calendar::Gregorian qw(toGregorian fromGregorianRollOver);
use Tripletail::DateTime::Calendar::WeekDate qw(toWeekDate);
use Tripletail::DateTime::LocalTime qw(timeToTimeOfDay timeOfDayToTime);
use Tripletail::DateTime::Math qw(quot widenYearOf2Digits);
our @EXPORT_OK = qw(
    $RE_RFC822_TIMEZONE
    parseRFC822DateTime
    renderRFC822DateTime
    parseRFC822TimeZone
    renderRFC822TimeZone
   );

my @WDAY_NAMES  = qw(Mon Tue Wed Thu Fri Sat Sun);
my @MONTH_NAMES = qw(Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec);

my %NUMERIC_MONTH_OF = do {
    my $i = 1;
    map { $_ => $i++ } @MONTH_NAMES;
};

my %RFC822_TZ_TABLE = (
    UT  =>      0,
    GMT =>      0,
    EST =>  -5*60,
    EDT =>  -4*60,
    CST =>  -6*60,
    CDT =>  -5*60,
    MST =>  -7*60,
    MDT =>  -6*60,
    PST =>  -8*60,
    PDT =>  -7*60,
    Z   =>      0,
    A   =>  -1*60,
    M   => -12*60,
    N   =>  +1*60,
    Y   => +12*60
   );
my %RFC822_TZ_TABLE_OFF = reverse %RFC822_TZ_TABLE;

sub _a2r {
    my $re = join('|', map { quotemeta } @_);
    return qr/$re/;
}

=encoding utf8

=head1 NAME

Tripletail::DateTime::Format::RFC822 - 内部用

=begin comment

=head1 DESCRIPTION

This module provides a set of functions to parse and render RFC 822
Date and Time format.

=head1 EXPORT

Nothing by default.

=head1 VARIABLES

=head2 C<< $RE_RFC822_TIMEZONE >>

A variable containing a compiled regex which matches to RFC 822
time-zone. You must not modify it.

=cut

our $RE_RFC822_TIMEZONE = do {
    my $names   = _a2r(keys %RFC822_TZ_TABLE);
    my $numeric = qr/[+\-]\d{4}/;

    qr/$names|$numeric/;
};

=head1 FUNCTIONS

=head2 C<< parseRFC822DateTime >>

    my ($localDay, $localDayTime, $timeZone)
      = parseRFC822DateTime('Tue, 01 Sep 2015 12:23:11 +0900');

Try to parse a given string as a (liberal) RFC 822 Date and Time
format. This function accepts 4-digit years while RFC 822 doesn't
allow them. Return a triple of local MJD, local day time, and
time-zone on success, nothing otherwise.

=cut

my $RE_WDAY      = _a2r(@WDAY_NAMES);
my $RE_MONTH     = _a2r(@MONTH_NAMES);
my $RE_DAY       = qr/0?[1-9]|[12][0-9]|3[01]/; # 1*2DIGIT
my $RE_YEAR      = qr/\d{4}|\d{2}/;
my $RE_DATE      = qr/($RE_DAY) ($RE_MONTH) ($RE_YEAR)/;
my $RE_2H        = qr/2[0-3]|[0-1][0-9]/; # 00 .. 23
my $RE_2M        = qr/[0-5][0-9]/;        # 00 .. 59
my $RE_2S        = $RE_2M;
my $RE_TIME      = qr/($RE_2H):($RE_2M)(?::($RE_2S))?/;
my $RE_DATE_TIME = qr/(?:$RE_WDAY, )?$RE_DATE $RE_TIME ($RE_RFC822_TIMEZONE)/;

sub parseRFC822DateTime {
    my $str = shift;

    if ($str =~ m/^$RE_DATE_TIME$/o) {
        return (
            fromGregorianRollOver(widenYearOf2Digits($3), $NUMERIC_MONTH_OF{$2}, $1),
            timeOfDayToTime($4, $5, $6 || 0),
            parseRFC822TimeZone($7)
           );
    }
    else {
        return;
    }
}

=head2 C<< renderRFC822DateTime >>

    my $str = renderRFC822DateTime($localDay, $localDayTime, $timeZone);

Render a triple of local mJD, local day time, and time-zone as a
string in RFC 822 Date and Time format.

=cut

sub renderRFC822DateTime {
    my ($day , $dayTime, $tz  ) = @_;
    my ($y   , $m      , $d   ) = toGregorian($day);
    my (undef, undef   , $wDay) = toWeekDate($day);
    my ($hour, $min    , $sec ) = timeToTimeOfDay($dayTime);

    return sprintf(
        '%s, %02d %s %04d %02d:%02d:%02d %s',
        $WDAY_NAMES[$wDay-1],
        $d, $MONTH_NAMES[$m-1], $y,
        $hour, $min, $sec,
        renderRFC822TimeZone($tz));
}

=head2 C<< parseRFC822TimeZone >>

    my $tz = parseRFC822TimeZone('+0900');

Try to parse a given string as an RFC 822 time-zone. Return the number
of minutes offset from UTC on success, nothing otherwise.

=cut

sub parseRFC822TimeZone {
    my $str = shift;

    if (defined(my $tz = $RFC822_TZ_TABLE{$str})) {
        return $tz;
    }
    elsif ($str =~ m/^([+\-])(\d{2})(\d{2})$/) {
        return ($1 eq '-' ? -1 : 1) * ($2 * 60 + $3);
    }
    else {
        return;
    }
}

=head2 C<< renderRFC822TimeZone >>

    my $str = renderRFC822TimeZone($tz);

Render the number of minutes offset from UTC into a string
representing an RFC 822 time-zone.

=cut

sub renderRFC822TimeZone {
    my $tz = shift;

    if (defined(my $name = $RFC822_TZ_TABLE_OFF{$tz})) {
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

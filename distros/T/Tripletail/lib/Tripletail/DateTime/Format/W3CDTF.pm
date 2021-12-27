package Tripletail::DateTime::Format::W3CDTF;
use strict;
use warnings;
use Exporter 'import';
use Tripletail::DateTime::Calendar::Gregorian qw(toGregorian fromGregorianRollOver);
use Tripletail::DateTime::LocalTime qw(getCurrentTimeZone timeToTimeOfDay timeOfDayToTime);
use Tripletail::DateTime::Math qw(quot);
our @EXPORT_OK = qw(
    $RE_W3CDTF_TIMEZONE
    parseW3CDTF
    renderW3CDTF
    parseW3CDTFTimeZone
    renderW3CDTFTimeZone
   );

=encoding utf8

=head1 NAME

Tripletail::DateTime::Format::W3CDTF - 内部用

=begin comment

=head1 DESCRIPTION

This module provides a set of functions to parse and render W3C Date
and Time Format.

=head1 EXPORT

Nothing by default.

=head1 VARIABLES

=head2 C<< $RE_W3CDTF_TIMEZONE >>

A variable containing a compiled regex which matches to W3CDTF
time-zone. You must not modify it.

=cut

our $RE_W3CDTF_TIMEZONE = qr/Z|[+\-]\d{2}:\d{2}/;

=head1 FUNCTIONS

=head2 C<< parseW3CDTF >>

    my ($localDay, $localDayTime, $timeZone)
      = parseW3CDTF('2000-01-02T03:04:05+09:00');

Try to parse a given string as a W3C Date and Time Format. Return a
triple of local MJD, local day time, and time-zone on success, nothing
otherwise.

=cut

my $RE_4YEAR  = qr/\d{4}/;
my $RE_2MONTH = qr/0[1-9]|1[0-2]/;
my $RE_2DAY   = qr/0[1-9]|[12][0-9]|3[01]/;
my $RE_2H     = qr/2[0-3]|[0-1][0-9]/; # 00 .. 23
my $RE_2M     = qr/[0-5][0-9]/;        # 00 .. 59
my $RE_2S     = $RE_2M;

sub parseW3CDTF {
    my $str = shift;

    if ($str =~ m/^($RE_4YEAR)$/o or
        $str =~ m/^($RE_4YEAR)-($RE_2MONTH)$/o or
        $str =~ m/^($RE_4YEAR)-($RE_2MONTH)-($RE_2DAY)$/o or
        $str =~ m/^($RE_4YEAR)-($RE_2MONTH)-($RE_2DAY)T($RE_2H):($RE_2M)($RE_W3CDTF_TIMEZONE)$/o or
        $str =~ m/^($RE_4YEAR)-($RE_2MONTH)-($RE_2DAY)T($RE_2H):($RE_2M):($RE_2S)($RE_W3CDTF_TIMEZONE)$/o or
        $str =~ m/^($RE_4YEAR)-($RE_2MONTH)-($RE_2DAY)T($RE_2H):($RE_2M):($RE_2S)\.\d+($RE_W3CDTF_TIMEZONE)$/o) {

        my $localDay = fromGregorianRollOver($1, $2 || 1, $3 || 1);
        my $localDayTime;
        my $timeZone;

        if (defined $6) {
            if (defined $7) {
                $localDayTime = timeOfDayToTime($4, $5, $6);
                $timeZone     = parseW3CDTFTimeZone($7);
            }
            else {
                $localDayTime = timeOfDayToTime($4, $5, 0);
                $timeZone     = parseW3CDTFTimeZone($6);
            }
        }
        else {
            $localDayTime = 0;
            # NOTE: This is technically wrong, as a W3C date without
            # time is not in any specific time-zone. But what should
            # we do otherwise?
            $timeZone     = getCurrentTimeZone();
        }

        return ($localDay, $localDayTime, $timeZone);
    }
    else {
        return;
    }
}

=head2 C<< renderW3CDTF >>

    my $str = renderW3CDTF($localDay, $localDayTime, $timeZone);

Render a triple of local mJD, local day time, and time-zone as a
string in W3C Date and Time Format.

=cut

sub renderW3CDTF {
    my ($day , $dayTime, $tz ) = @_;
    my ($y   , $m      , $d  ) = toGregorian($day);
    my ($hour, $min    , $sec) = timeToTimeOfDay($dayTime);

    return sprintf(
        '%04d-%02d-%02dT%02d:%02d:%02d%s',
        $y, $m, $d, $hour, $min, $sec, renderW3CDTFTimeZone($tz));
}

=head2 C<< parseW3CDTFTimeZone >>

    my $tz = parseW3CDTFTimeZone('+09:00');

Try to parse a given string as a W3C time-zone. Return the number of
minutes offset from UTC on success, nothing otherwise.

=cut

sub parseW3CDTFTimeZone {
    my $str = shift;

    if ($str eq 'Z') {
        return 0;
    }
    elsif ($str =~ m/^([+\-])(\d{2}):(\d{2})$/) {
        return ($1 eq '-' ? -1 : 1) * ($2 * 60 + $3);
    }
    else {
        return;
    }
}

=head2 C<< renderW3CDTFTimeZone >>

    my $str = renderW3CDTFTimeZone($tz);

Render the number of minutes offset from UTC into a string
representing a time-zone in W3C Date and Time Format.

=cut

sub renderW3CDTFTimeZone {
    my $tz = shift;

    if ($tz == 0) {
        return 'Z';
    }
    else {
        my $h = quot(abs($tz), 60);
        my $m = abs($tz) - $h * 60;
        return sprintf('%s%02d:%02d', $tz < 0 ? '-' : '+', $h, $m);
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

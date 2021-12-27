package Tripletail::DateTime::LocalTime;
use strict;
use warnings;
use Exporter 'import';
use Time::Local qw(timegm);
use Tripletail::DateTime::Clock::POSIX qw(posixDayLength utcTimeToPOSIXSeconds);
use Tripletail::DateTime::Clock::UTC qw(getCurrentTime);
use Tripletail::DateTime::Math qw(div mod divMod);
our @EXPORT_OK = qw(
    getTimeZone
    getCurrentTimeZone

    utcToLocalTimeOfDay
    localToUTCTimeOfDay
    timeToTimeOfDay
    timeOfDayToTime

    utcToLocalTime
    localTimeToUTC
   );

=encoding utf8

=head1 NAME

Tripletail::DateTime::LocalTime - 内部用

=begin comment

=head1 EXPORT

Nothing by default.

=head1 FUNCTIONS

=head2 Time-zones

A time-zone is a whole number of minutes offset from UTC.

=head3 C<< getTimeZone >>

    my $tz = getTimeZone($mjd, $dayTime);

Return the local time-zone for a given UTC time (varying as per
summertime adjustments).

=cut

sub getTimeZone {
    my $utc   = utcTimeToPOSIXSeconds(@_);
    my @local = localtime($utc);
    my $local = timegm   (@local);

    return int(($local - $utc) / 60);
}

=head3 C<< getCurrentTimeZone >>

    my $tz = getCurrentTimeZone();

Get the current time-zone in minutes offset from UTC.

=cut

sub getCurrentTimeZone {
    return getTimeZone(getCurrentTime())
}

=head2 Time of day

Time of day as represented in hour, minute and second, typically used
to express local time of day.

=head3 C<< utcToLocalTimeOfDay >>

    my ($adj, $h, $m, $s)
      = utcToLocalTimeOfDay($tz, $utcHour, $utcMinute, $utcSecond);

Convert a time-of-day in UTC to a time-of-day in some time-zone,
together with a day adjustment.

=cut

sub utcToLocalTimeOfDay {
    my ($tz, $h, $m, $s) = @_;
    my $m1       = $m + $tz;
    my $h1       = $h + div($m1, 60);
    my ($i, $h2) = divMod($h1, 24);
    my $m2       = mod($m1, 60);

    return ($i, $h2, $m2, $s);
}

=head3 C<< localToUTCTimeOfDay >>

    my ($adj, $h, $m, $s)
      = localToUTCTimeOfDay($tz, $locHour, $locMinute, $locSecond);

Convert a time-of-day in some time-zone to a time-of-day in UTC,
together with a day adjustment.

=cut

sub localToUTCTimeOfDay {
    my ($tz, @tod) = @_;

    return utcToLocalTimeOfDay(-$tz, @tod);
}

=head3 C<< timeToTimeOfDay >>

    my ($h, $m, $s) = timeToTimeOfDay($dayTime);

Get a time-of-day given a time since midnight. Time more than 24h will
be converted to leap-seconds.

=cut

sub timeToTimeOfDay {
    my ($dt) = @_;

    if ($dt >= posixDayLength()) {
        return (23, 59, 60 + ($dt - posixDayLength()));
    }
    else {
        my $s1       = $dt;
        my ($m1, $s) = divMod($s1, 60);
        my ($h , $m) = divMod($m1, 60);
        return ($h, $m, $s);
    }
}

=head3 C<< timeOfDayToTime >>

    my $dayTime = timeOfDayToTime($h, $m, $s);

Find out how much time since midnight a given time-of-day is.

=cut

sub timeOfDayToTime {
    my ($h, $m, $s) = @_;

    return (($h * 60) + $m) * 60 + $s;
}

=head2 Local time

A simple day and time aggregate, where the day is of the specified
parameter, and the time is a time-of-day. Conversion of this (as local
civil time) to UTC depends on the time zone. Conversion of this (as
local mean time) to UT1 depends on the longitude.

=head3 C<< utcToLocalTime >>

    my ($mjd, $h, $m, $s)
      = utcToLocalTime($tz, $utcMJD, $utcDayTime);

Convert an UTC time in a given time-zone into a local time.

=cut

sub utcToLocalTime {
    my ($tz, $day, $dt) = @_;
    my ($i, @tod      ) = utcToLocalTimeOfDay($tz, timeToTimeOfDay($dt));

    return ($i + $day, @tod);
}

=head3 C<< localTimeToUTC >>

    my ($mjd, $dayTime) = localTimeToUTC($tz, $localMJD, $h, $m, $s);

Convert a local time in a given time-zone into an UTC time.

=cut

sub localTimeToUTC {
    my ($tz, $day, @tod) = @_;
    my ($i, @todUTC    ) = localToUTCTimeOfDay($tz, @tod);

    return ($i + $day, timeOfDayToTime(@todUTC));
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

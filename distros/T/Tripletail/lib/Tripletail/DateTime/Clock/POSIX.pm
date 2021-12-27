package Tripletail::DateTime::Clock::POSIX;
use strict;
use warnings;
use Exporter 'import';
use List::Util qw(min);
use Tripletail::DateTime::Math qw(divMod);
our @EXPORT_OK = qw(
    posixDayLength
    unixEpochDay
    posixSecondsToUTCTime
    utcTimeToPOSIXSeconds
   );

=encoding utf8

=head1 NAME

Tripletail::DateTime::Clock::POSIX - 内部用

=begin comment

=head1 DESCRIPTION

POSIX time, if you need to deal with timestamps and the like.

=head1 EXPORT

Nothing by default.

=head1 FUNCTIONS

=head2 C<< posixDayLength >>

    my $len = posixDayLength();

Return the constant C<86400>, which is the nominal seconds in every
day.

=cut

use constant posixDayLength => 86400;

=head2 C<< unixEpochDay >>

    my $day = unixEpochDay();

Return the constant C<40587>, which is the UNIX epoch day in MJD.

=cut

use constant unixEpochDay => 40587;

=head2 C<< posixSecondsToUTCTime >>

    my ($mjd, $dayTime) = posixSecondsToUTCTime($posixSeconds);

Convert a POSIX seconds into a pair of UTC MJD and the number of
seconds from midnight.

=cut

sub posixSecondsToUTCTime {
    my ($d, $t) = divMod($_[0], posixDayLength());
    return ($d + unixEpochDay(), $t);
}

=head2 C<< utcTimeToPOSIXSeconds >>

    my $posixSeconds = utcTimeToPOSIXSeconds($mjd, $dayTime);

Convert an UTC time into a POSIX seconds.

=cut

sub utcTimeToPOSIXSeconds {
    my ($d, $t) = @_;
    return ($d - unixEpochDay()) * posixDayLength() + min(posixDayLength(), $t);
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

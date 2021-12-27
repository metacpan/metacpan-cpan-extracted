package Tripletail::DateTime::Clock::UTC;
use strict;
use warnings;
use Exporter 'import';
use Tripletail::DateTime::Clock::POSIX qw(posixSecondsToUTCTime);
our @EXPORT_OK = qw(getCurrentTime);

=encoding utf8

=head1 NAME

Tripletail::DateTime::Clock::UTC - 内部用

=begin comment

=head1 DESCRIPTION

UTC is time as measured by a clock, corrected to keep pace with the
earth by adding or removing occasional seconds, known as "leap
seconds". These corrections are not predictable and are announced with
six month's notice. No table of these corrections is provided, as any
program compiled with it would become out of date in six months.

UTC time is represented as a pair of day number and a time offset from
midnight. Note that if a day has a leap second added to it, it will
have 86401 seconds.

=head1 EXPORT

Nothing by default.

=head1 FUNCTIONS

=head2 C<< getCurrentTime >>

    my ($mjd, $dayTime) = getCurrentTime();

Get the current UTC time from the system clock.

=cut

sub getCurrentTime {
    return posixSecondsToUTCTime(time);
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

package Tripletail::DateTime::Format::Apache;
use strict;
use warnings;
use Exporter 'import';
use Tripletail::DateTime::Calendar::Gregorian qw(fromGregorianRollOver);
use Tripletail::DateTime::Format::RFC822 qw(parseRFC822TimeZone);
use Tripletail::DateTime::LocalTime qw(getCurrentTimeZone timeOfDayToTime);
our @EXPORT_OK = qw(parseApacheDateTime);

my @WDAY_NAMES  = qw(Mon Tue Wed Thu Fri Sat Sun);
my @MONTH_NAMES = qw(Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec);

my %NUMERIC_MONTH_OF = do {
    my $i = 1;
    map { $_ => $i++ } @MONTH_NAMES;
};

sub _a2r {
    my $re = join('|', map { quotemeta } @_);
    return qr/$re/;
}

=encoding utf8

=head1 NAME

Tripletail::DateTime::Format::Apache - 内部用

=begin comment

=head1 DESCRIPTION

This module provides a set of functions to parse a date and time
string that can be seen in Apache log files.

=head1 EXPORT

Nothing by default.

=head1 FUNCTIONS

=head2 C<< parseApacheDateTime >>

    my ($localDay, $localDayTime, $timeZone)
      = parseApacheDateTime('01/Sep/2015:17:15:44 +0900');

Try to parse a given string that can be seen in Apache log
files. Return a triple of local MJD, local day time, and time-zone on
success, nothing otherwise.

=cut

my $RE_WDAY      = _a2r(@WDAY_NAMES);
my $RE_MONTH     = _a2r(@MONTH_NAMES);
my $RE_DAY       = qr/0[1-9]|[12][0-9]|3[01]/; # 2DIGIT
my $RE_YEAR      = qr/\d{4}/;
my $RE_2H        = qr/2[0-3]|[0-1][0-9]/; # 00 .. 23
my $RE_2M        = qr/[0-5][0-9]/;        # 00 .. 59
my $RE_2S        = $RE_2M;
my $RE_TIME      = qr/($RE_2H):($RE_2M):($RE_2S)/;
my $RE_TIMEZONE  = qr/\S+/;
my $RE_AP_ACCESS = qr/($RE_DAY)\/($RE_MONTH)\/($RE_YEAR):$RE_TIME ($RE_TIMEZONE)/;
my $RE_AP_ERROR  = qr/$RE_WDAY ($RE_MONTH) ($RE_DAY) $RE_TIME ($RE_YEAR)/;
my $RE_AP_INDEX  = qr/($RE_DAY)-($RE_MONTH)-($RE_YEAR) $RE_TIME/;

sub parseApacheDateTime {
    my $str = shift;

    if ($str =~ m/^$RE_AP_ACCESS$/o) {
        return (
            fromGregorianRollOver($3, $NUMERIC_MONTH_OF{$2}, $1),
            timeOfDayToTime($4, $5, $6),
            parseRFC822TimeZone($7)
           );
    }
    elsif ($str =~ m/^$RE_AP_ERROR$/o) {
        return (
            fromGregorianRollOver($6, $NUMERIC_MONTH_OF{$1}, $2),
            timeOfDayToTime($3, $4, $5),
            getCurrentTimeZone()
           );
    }
    elsif ($str =~ m/^$RE_AP_INDEX$/o) {
        return (
            fromGregorianRollOver($3, $NUMERIC_MONTH_OF{$2}, $1),
            timeOfDayToTime($4, $5, $6),
            getCurrentTimeZone()
           );
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

package Tripletail::DateTime::Format::DateCmd;
use strict;
use warnings;
use Exporter 'import';
use Tripletail::DateTime::Calendar::Gregorian qw(fromGregorianRollOver);
use Tripletail::DateTime::Format::Generic qw(parseGenericTimeZone);
use Tripletail::DateTime::LocalTime qw(timeOfDayToTime);
our @EXPORT_OK = qw(parseDateCmdDateTime);

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

Tripletail::DateTime::Format::DateCmd - 内部用

=begin comment

=head1 DESCRIPTION

This module provides a set of functions to parse a date and time
string produced by C<date(1)> in the C<C> locale.

=head1 EXPORT

Nothing by default.

=head1 FUNCTIONS

=head2 C<< parseDateCmdDateTime >>

    my ($localDay, $localDayTime, $timeZone)
      = parseRFC822DateTime('Tue Sep  1 17:15:44 JST 2015');

Try to parse a given string produced by C<date(1)> in the C<C>
locale. Return a triple of local MJD, local day time, and time-zone on
success, nothing otherwise.

=cut

my $RE_WDAY      = _a2r(@WDAY_NAMES);
my $RE_MONTH     = _a2r(@MONTH_NAMES);
my $RE_DAY       = qr/ ?[1-9]|[12][0-9]|3[01]/; # 1*2DIGIT
my $RE_YEAR      = qr/\d{4}/;
my $RE_2H        = qr/2[0-3]|[0-1][0-9]/; # 00 .. 23
my $RE_2M        = qr/[0-5][0-9]/;        # 00 .. 59
my $RE_2S        = $RE_2M;
my $RE_TIME      = qr/($RE_2H):($RE_2M):($RE_2M)/;
my $RE_TIMEZONE  = qr/\S+/;
my $RE_DATE_TIME = qr/$RE_WDAY ($RE_MONTH) ($RE_DAY) $RE_TIME ($RE_TIMEZONE) ($RE_YEAR)/;

sub parseDateCmdDateTime {
    my $str = shift;

    if ($str =~ m/^$RE_DATE_TIME$/o) {
        my $day      = fromGregorianRollOver($7, $NUMERIC_MONTH_OF{$1}, $2);
        my $dayTime  = timeOfDayToTime($3, $4, $5);
        my $timeZone = parseGenericTimeZone($6);

        if (defined $timeZone) {
            return ($day, $dayTime, $timeZone);
        }
        else {
            return;
        }
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

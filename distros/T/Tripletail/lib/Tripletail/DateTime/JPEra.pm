package Tripletail::DateTime::JPEra;
use strict;
use warnings;
use Exporter 'import';
use Tripletail::DateTime::Calendar::Gregorian qw(toGregorian fromGregorian);
our @EXPORT_OK = qw(parseJPEra renderJPEra);

my @JP_ERAS = (
    [1868,  9,  8, '明治'], # 開始西暦, 開始月, 開始日, 年号
    [1912,  7, 30, '大正'],
    [1926, 12, 25, '昭和'],
    [1989,  1,  8, '平成'],
   );
my @REV_JP_ERAS = reverse @JP_ERAS;

=encoding utf8

=head1 NAME

Tripletail::DateTime::JPEra - 内部用

=begin comment

=head1 DESCRIPTION

This module provides a set of functions to handle Japanese era
calendar scheme.

=head1 EXPORT

Nothing by default.

=head1 FUNCTIONS

=head2 C<< parseJPEra >>

    my $year = parseJPYear('平成27年');

Try to parse an year in Japanese era calendar scheme into a Gregorian
year. Raises an exception on failure.

=cut

my $RE_JP_ERA_NAME = _a2r(map {$_->[3]} @JP_ERAS);

sub parseJPEra {
    my ($str) = @_;

    if ($str =~ m/^($RE_JP_ERA_NAME)(\d+|元)年$/) {
        foreach my $ent (@JP_ERAS) {
            if ($ent->[3] eq $1) {
                if ($2 eq '元') {
                    return $ent->[0];
                }
                else {
                    return $ent->[0] + $2 - 1;
                }
            }
        }
    }

    die __PACKAGE__.": failed to parse japanese era: $str (和暦の解析に失敗しました)\n";
}

sub _a2r {
    my $re = join('|', map { quotemeta } @_);
    return qr/$re/;
}

=head2 C<< renderJPEra >>

    my $jpEra = renderJPEra($mjd);

Render the given day to Japanese era calendar scheme. Raises an
exception on failure.

=cut

sub renderJPEra {
    my ($day               ) = @_;
    my ($year, undef, undef) = toGregorian($day);

    foreach my $ent (@REV_JP_ERAS) {
        my $origin = fromGregorian(@$ent[0 .. 2]);

        if ($day >= $origin) {
            return sprintf(
                '%s%s年',
                $ent->[3],
                $year == $ent->[0] ? '元' : $year - $ent->[0] + 1
               );
        }
    }

    die __PACKAGE__.": failed to render japanese era: $day (和暦の表示に失敗しました)\n";
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

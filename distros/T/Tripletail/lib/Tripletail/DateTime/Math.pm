package Tripletail::DateTime::Math;
use strict;
use warnings;
use Exporter 'import';
our @EXPORT_OK = qw(quot div mod divMod clip widenYearOf2Digits);

=encoding utf8

=head1 NAME

Tripletail::DateTime::Math - 内部用

=begin comment

=head1 DESCRIPTION

This module contains several mathematical functions that are missing
from the Perl core.

=head1 EXPORT

Nothing by default.

=head1 FUNCTIONS

=head2 C<< quot >>

    my $q = quot($x, $y);

Integer division truncated toward zero. Note that C<< quot($x, $y) >>
is slightly different from C<< int($x / $y) >> for the latter involves
floating-point arithmetic and thus subject to rounding errors.

=cut

sub quot {
    use integer;
    return $_[0] / $_[1];
}

=head2 C<< div >>

    my $d = div($x, $y);

Integer division truncated toward negative infinity. Note that C<<
div($x, $y) >> is completely different from C<< int($x / $y) >> for
the latter is truncated toward zero and also involves floating-point
arithmetic.

=cut

sub div {
    use integer;
    my ($x, $y) = @_;

    if ($x > 0 and $y < 0) {
        return (($x - 1) / $y) - 1;
    }
    elsif ($x < 0 and $y > 0) {
        return (($x + 1) / $y) - 1;
    }
    else {
        return $x / $y;
    }
}

=head2 C<< mod >>

    my $m = mod($x, $y);

Integer modulus, satisfying C<< div($x, $y)*$y + mod($x, $y) == $x
>>. Note that C<< mod($x, $y) >> is not always the same as C<< $x % $y
>> for the latter becomes different when "use integer" is in effect.

=cut

sub mod {
    no integer;
    return $_[0] % $_[1];
}

=head2 C<< divMod >>

    my ($d, $m) = divMod($x, $y);

Simultaneous L</"div"> and L</"mod">.

=cut

sub divMod {
    use integer;
    my ($n, $d) = @_;
    my $f       = div($n, $d);

    return ($f, $n - $f * $d);
}

=head2 C<< clip >>

    my $x1 = clip($a, $b, $x);

Coerce C<< $x >> into the range of C<< [$a, $b] >> (inclusive).

=cut

sub clip {
    my ($a, $b, $x) = @_;

    if ($x < $a) {
        return $a;
    }
    elsif ($x > $b) {
        return $b;
    }
    else {
        return $x;
    }
}

=head2 C<< widenYearOf2Digits >>

    my $year = widenYearOf2Digits($2year);

This function behaves as follows:

=over

=item When C<$2year> >= 100

Return C<$2year> as-is.

=item When C<$2year> >= 50

Return C<< $2year + 1900 >>.

=item Otherwise

Return C<< $2year + 2000 >>.

=back

=cut

sub widenYearOf2Digits {
    my ($year) = @_;

    if ($year < 100) {
        return ($year < 50 ? 2000 : 1900) + $year;
    }
    else {
        return $year;
    }
}

=end comment

=head1 SEE ALSO

L<Tripletail>

=head1 AUTHOR INFORMATION

This framework is free software; you can redistribute it and/or modify it under the same terms as Perl itself

このフレームワークはフリーソフトウェアです。あなたは Perl と同じライセンスの 元で再配布及び変更を行うことが出来ます。

Address bug reports and comments to: tl@tripletail.jp

Official web site: http://tripletail.jp/

=cut

1;

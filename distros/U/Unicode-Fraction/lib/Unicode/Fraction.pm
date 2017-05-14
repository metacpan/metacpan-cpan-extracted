use strict;
use warnings;
package Unicode::Fraction;
# ABSTRACT: easy generation of UTF-8 fractions

use Carp;
use Unicode::Subscript qw(subscript superscript);

BEGIN {
    use Exporter;
    our @ISA = qw(Exporter);
    our @EXPORT_OK = qw(fraction);
}

my $SOLIDUS = "\x{2044}";
my $ONE_OVER = "\x{215f}";

my %FRACTION_CHAR = (
    '1/2' => "\x{00bd}",
    '0/3' => "\x{2189}",
    '1/3' => "\x{2153}",
    '2/3' => "\x{2154}",
    '1/4' => "\x{00bc}",
    '3/4' => "\x{00be}",
    '1/5' => "\x{2155}",
    '2/5' => "\x{2156}",
    '3/5' => "\x{2157}",
    '4/5' => "\x{2158}",
    '1/6' => "\x{2159}",
    '5/6' => "\x{215a}",
    '1/7' => "\x{2150}",
    '1/8' => "\x{215b}",
    '3/8' => "\x{215c}",
    '5/8' => "\x{215d}",
    '7/8' => "\x{215e}",
    '1/9' => "\x{2151}",
    '1/10' => "\x{2152}",
);


sub fraction {
    my ($num, $denom) = @_;
    defined $num && defined $denom or croak 'usage: fraction($num, $denom)';

    if (my $frac = _fraction_char($num, $denom)) {
        return $frac;
    }
    elsif ($num == 1) {
        return $ONE_OVER . subscript($denom);
    }
    else {
        return superscript($num) . $SOLIDUS . subscript($denom);
    }
}

# Return the special Unicode char for selected fractions
# e.g. 1/2, 3/8 etc. or return undef
sub _fraction_char {
    my ($num, $denom) = @_;
    return $FRACTION_CHAR{"$num/$denom"}; 
}


1;


__END__
=pod

=encoding utf-8

=head1 NAME

Unicode::Fraction - easy generation of UTF-8 fractions

=head1 SYNOPSIS

 use Unicode::Fraction qw(fraction);
 say fraction(1,2); # ½
 say fraction(1,12); # ⅟₁₂
 say fraction(35,48); # ³⁵⁄₄₈

=head1 DESCRIPTION

This module provides a simple function to print vulgar fractions
in UTF-8.

=head1 FUNCTIONS

=head2 fraction ($num, $denom)

Generate a UTF-8 encoding string representing the given fraction,
using the most compact representation available. The standard
Unicode glyphs (¼, ½, etc.) are used if possible; failing that,
subscripted and superscripted numbers are used (with either the
'⁄' or '⅟' glyphs).

Fractions are not normalised, that is, fraction(2,4) is distinct
from fraction(1,2).

=head1 AUTHOR

Richard Harris <RJH@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Richard Harris.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


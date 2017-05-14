use strict;
use warnings;
use utf8;
use Test::More tests => 22;
use Unicode::Subscript qw(subscript superscript);

my @tests = (
    # original, subscript, superscript
    ['    ', '    ', '    '],
    ['', '', ''],
    ['stu', 'ₛₜᵤ', 'ˢᵗᵘ'],
    ['0123', '₀₁₂₃', '⁰¹²³'],
    ['98', '₉₈', '⁹⁸'],
    ['2+2=4', '₂₊₂₌₄', '²⁺²⁼⁴'],
    ['(*)', '₍*₎', '⁽*⁾'],
    ['x--', 'ₓ₋₋', 'ˣ⁻⁻'],
    ['B', 'B', 'ᴮ'],
    ['e', 'ₑ', 'ᵉ'],
    ['testing', 'ₜₑₛₜᵢₙg', 'ᵗᵉˢᵗⁱⁿᵍ'],
);

for my $test (@tests) {
    my ($orig, $exp_sub, $exp_super) = @$test;
    is( subscript($orig), $exp_sub, "subscript of '$orig'" );
    is( superscript($orig), $exp_super, "superscript of '$orig'" );
}

use strict;
use warnings;
use utf8;
use Test::More tests => 24;
use Unicode::Fraction qw(fraction);

my %tests = (
    '1/2' => '½',
    '1/4' => '¼',
    '3/4' => '¾',
    '1/7' => '⅐',
    '1/9' => '⅑',
    '1/10' => '⅒',
    '1/3' => '⅓',
    '2/3' => '⅔',
    '1/5' => '⅕',
    '2/5' => '⅖',
    '3/5' => '⅗',
    '4/5' => '⅘',
    '1/6' => '⅙',
    '5/6' => '⅚',
    '1/8' => '⅛',
    '3/8' => '⅜',
    '5/8' => '⅝',
    '7/8' => '⅞',
    '0/3' => '↉',
    '1/11' => '⅟₁₁',
    '1/120' => '⅟₁₂₀',
    '3/16' => '³⁄₁₆',
    '11/12' => '¹¹⁄₁₂',
    '12340/56789' => '¹²³⁴⁰⁄₅₆₇₈₉',
);

while( my($input, $expected) = each %tests ) {
    my ($num, $denom) = split '/', $input;
    is( fraction($num, $denom), $expected, $input );
}


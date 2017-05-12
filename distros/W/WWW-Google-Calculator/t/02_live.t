use Test::Base;

plan skip_all => 'set TEST_LIVE to enable this test' unless $ENV{TEST_LIVE};
plan tests => 1 * blocks;

use WWW::Google::Calculator;

sub calc {
    my $calc = WWW::Google::Calculator->new;
    $calc->calc(@_);
}

filters {
    input => [qw/chomp calc/],
    expected => [qw/chomp/],
};

run_compare input => 'expected';

__END__

# basic tests (listed as example at http://www.google.com/help/calculator.html)

=== Addition
--- input
3+44
--- expected
3 + 44 = 47

=== subtraction
--- input
13-5
--- expected
13 - 5 = 8

=== multiplication
--- input
7*8
--- expected
7 * 8 = 56

=== division
--- input
12/3
--- expected
12 / 3 = 4

=== exponentiation (raise to a power of)
--- input
8^2
--- expected
8^2 = 64

=== modulo (finds the remainder after division)
--- input
8%7
--- expected
8 mod 7 = 1

=== X choose Y determines the number of ways of choosing a set of Y elements from a set of X elements
--- input
18 choose 4
--- expected
18 choose 4 = 3060

=== calculates the nth root of a number
--- input
5th root of 32
--- expected
5th root of 32 = 2

=== X % of Y computes X percent of Y
--- input
20% of 150
--- expected
20% of 150 = 30

=== square root
--- input
sqrt(9)
--- expected
sqrt(9) = 3

=== trigonometric functions (numbers are assumed to be radians)
--- input
sin(pi/3)
--- expected
sin(pi / 3) = 0.866025404

=== trigonometric functions (numbers are assumed to be radians) 2
--- input
tan(45 degrees)
--- expected
tan(45 degrees) = 1

=== logarithm base e
--- input
ln(17)
--- expected
ln(17) = 2.83321334

=== ogarithm base 10
--- input
log(1,000)
--- expected
log(1 000) = 3

=== factorial
--- input
5!
--- expected
5 ! = 120

=== calc with units
--- input
1 a.u./c
--- expected
(1 Astronomical Unit) / the speed of light = 8.31675359 minutes

=== units translation
--- input
300kbps in KB/s
--- expected
300 kbps = 37.5 kilobytes / second

=== multiplier (reported by Torkild Retvedt)
--- input
10^20
--- expected
10^20 = 1.0 * 10^20

=== currency
--- input
1 usd in eur
--- expected regexp
1 U.S. dollar = \S+ Euros

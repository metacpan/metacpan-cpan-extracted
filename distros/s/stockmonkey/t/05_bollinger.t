
use Test;
use strict;
use Math::Business::BollingerBands;

my $bb = new Math::Business::BollingerBands(20,2);

# NOTE: This example was taken from
# http://stockcharts.com/school/doku.php?id=chart_school:technical_indicators:bollinger_bands
# 2012-11-29 2012

my @closes = qw(
    86.16 89.09 88.78 90.32 89.07 91.15 89.44 89.17 86.93 87.68 86.96 89.43
    89.32 88.72 87.45 87.26 89.50 87.90 89.13 90.70 92.90 92.98 91.80 92.66
    92.68 92.30 92.77 92.54 92.95 93.20 91.07 89.83 89.74 90.40 90.74 88.02
    88.09 88.84 90.78 90.54 91.39 90.65
);

my @matchers = (
    # The stockcharts csample alculations were altered by as much as 2 cents
    # here-and-there because we don't throw away as much roundoff error as
    # their spreadsheet apparently does.

    [qw(87.95 91.24 94.53)],
    [qw(87.96 91.17 94.37)],
    [qw(87.95 91.05 94.15)],
);

my ($L,$M,$U,$match);

plan tests => 3*(1+@matchers);

$bb->insert(splice @closes, 0, 19);
($L,$M,$U) = $bb->query;
ok( $L, undef );
ok( $M, undef );
ok( $U, undef );

$bb->insert(splice @closes, 0, -3);

while( $match = shift @matchers ) {
    $bb->insert(shift @closes);
    ($L,$M,$U) = $bb->query;
    ok( sprintf('%0.2f', $L), sprintf('%0.2f', $match->[0]) );
    ok( sprintf('%0.2f', $M), sprintf('%0.2f', $match->[1]) );
    ok( sprintf('%0.2f', $U), sprintf('%0.2f', $match->[2]) );
}

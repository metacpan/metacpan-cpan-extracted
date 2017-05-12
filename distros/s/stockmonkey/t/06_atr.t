
use Test;
use strict;
use Math::Business::ATR;

# example stolen from http://stockcharts.com/school/doku.php?id=chart_school:technical_indicators:average_true_range_atr
my @data_points = (
    [ 61.0000, 59.0312, 59.3750 ],
    [ 61.0000, 58.3750, 58.9062 ],
    [ 58.8438, 53.6250, 54.3125 ],
    [ 55.1250, 47.4375, 51.0000 ],
    [ 54.0625, 50.5000, 51.5938 ],
    [ 53.9688, 49.7812, 52.0000 ],
    [ 56.0000, 52.5000, 55.4375 ],
    [ 55.2188, 52.6250, 52.9375 ],
    [ 55.0312, 53.2500, 54.5312 ],
    [ 57.4922, 53.7500, 56.5312 ],
    [ 57.0938, 55.2500, 55.3438 ],
    [ 56.8125, 54.3438, 55.7188 ],
    [ 55.5625, 50.0000, 50.1562 ],
    [ 50.0625, 46.8438, 48.8125 ],
    [ 47.6875, 44.4688, 44.5938 ],
    [ 44.9062, 40.6250, 42.6562 ],
);

my @ATR = (
    3.6646,
    3.7131,
    3.7537,
);

plan tests => 1+@data_points;

my $atr = recommended Math::Business::ATR;

my $c = 0;
for my $dp (@data_points) {
    $atr->insert($dp);

    my $q = $atr->query;
    if( defined $q ) {
        ok( map {sprintf '%0.4f', $_} $atr->query, shift @ATR );

    } else {
        ok(1);
    }
}

ok( int @ATR, 0 );

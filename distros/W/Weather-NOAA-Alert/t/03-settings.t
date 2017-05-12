#!perl -T

use strict;
use warnings;

use Test::More tests => 10;

use Weather::NOAA::Alert;
my $g = Weather::NOAA::Alert->new();

is( $g->formatTime(), 0, 'retreive default formatTime setting');
$g->formatTime( 1);
is( $g->formatTime(), 1, 'set and retreive formatTime setting');

is( $g->formatAsterisk(), 0, 'retreive default formatAsterisk setting');
$g->formatAsterisk( 1);
is( $g->formatAsterisk(), 1, 'set and retreive formatAsterisk setting');

is( $g->printLog(), 0, 'retreive default  setting');
$g->printLog( 1);
is( $g->printLog(), 1, 'set and retreive  setting');

is( $g->printActions(), 0, 'retreive default printActions setting');
$g->printActions( 1);
is( $g->printActions(), 1, 'set and retreive printActions setting');

is( $g->errorLog(), 0, 'retreive default errorLog setting');
$g->errorLog( 1);
is( $g->errorLog(), 1, 'set and retreive errorLog setting');


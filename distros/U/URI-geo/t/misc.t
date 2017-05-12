#!perl

use strict;
use warnings;

use URI::geo;
use Test::More tests => 6;

ok my $guri = URI::geo->new( 55, -1 ), 'new';
my @loc = $guri->location( 48, 16 );
is_deeply [@loc], [ 48, 16, undef ], 'location returns new value';

is $guri->latitude( 50 ),  50, 'latitude returns new value';
is $guri->longitude( 13 ), 13, 'longitude returns new value';
is $guri->altitude( 24 ),  24, 'altitude returns new value';

is $guri->as_string, 'geo:50,13,24', 'stringify';

# vim:ts=2:sw=2:et:ft=perl


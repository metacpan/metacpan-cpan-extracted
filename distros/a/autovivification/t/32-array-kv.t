#!perl -T

use strict;
use warnings;

use lib 't/lib';
use Test::Leaner;

BEGIN {
 if ("$]" >= 5.011) { plan tests => 9 * 3 * 64 } else { plan skip_all => 'perl 5.11 required for keys/values @array' }
}

use autovivification::TestCases;

while (<DATA>) {
 1 while chomp;
 next unless /#/;
 testcase_ok($_, '@');
}

__DATA__

--- keys ---

$x # keys @$x # '', 0, [ ]
$x # keys @$x # '', 0, undef #
$x # keys @$x # '', 0, undef # +fetch
$x # keys @$x # '', 0, [ ] # +exists
$x # keys @$x # '', 0, [ ] # +delete
$x # keys @$x # '', 0, [ ] # +store

$x # keys @$x # qr/^Reference vivification forbidden/, undef, undef # +strict +fetch
$x # keys @$x # '', 0, [ ] # +strict +exists
$x # keys @$x # '', 0, [ ] # +strict +delete
$x # keys @$x # '', 0, [ ] # +strict +store

$x # [ keys @$x ] # '', [ ], [ ]
$x # [ keys @$x ] # '', [ ], undef #
$x # [ keys @$x ] # '', [ ], undef # +fetch
$x # [ keys @$x ] # '', [ ], [ ] # +exists +delete +store

$x->[0] = 1 # [ keys @$x ] # '', [0], [ 1 ]
$x->[0] = 1 # [ keys @$x ] # '', [0], [ 1 ] #
$x->[0] = 1 # [ keys @$x ] # '', [0], [ 1 ] # +fetch
$x->[0] = 1 # [ keys @$x ] # '', [0], [ 1 ] # +exists +delete +store

$x # keys @{$x->[0]} # '', 0, [ [ ] ]
$x # keys @{$x->[0]} # '', 0, undef #
$x # keys @{$x->[0]} # '', 0, undef # +fetch
$x # keys @{$x->[0]} # '', 0, [ [ ] ] # +exists
$x # keys @{$x->[0]} # '', 0, [ [ ] ] # +delete
$x # keys @{$x->[0]} # '', 0, [ [ ] ] # +store

$x # keys @{$x->[0]} # qr/^Reference vivification forbidden/, undef, undef # +strict +fetch
$x # keys @{$x->[0]} # '', 0, [ [ ] ] # +strict +exists
$x # keys @{$x->[0]} # '', 0, [ [ ] ] # +strict +delete
$x # keys @{$x->[0]} # '', 0, [ [ ] ] # +strict +store

$x # [ keys @{$x->[0]} ] # '', [ ], [ [ ] ]
$x # [ keys @{$x->[0]} ] # '', [ ], undef #
$x # [ keys @{$x->[0]} ] # '', [ ], undef # +fetch
$x # [ keys @{$x->[0]} ] # '', [ ], [ [ ] ] # +exists +delete +store

--- values ---

$x # values @$x # '', 0, [ ]
$x # values @$x # '', 0, undef #
$x # values @$x # '', 0, undef # +fetch
$x # values @$x # '', 0, [ ] # +exists
$x # values @$x # '', 0, [ ] # +delete
$x # values @$x # '', 0, [ ] # +store

$x # values @$x # qr/^Reference vivification forbidden/, undef, undef # +strict +fetch
$x # values @$x # '', 0, [ ] # +strict +exists
$x # values @$x # '', 0, [ ] # +strict +delete
$x # values @$x # '', 0, [ ] # +strict +store

$x # [ values @$x ] # '', [ ], [ ]
$x # [ values @$x ] # '', [ ], undef #
$x # [ values @$x ] # '', [ ], undef # +fetch
$x # [ values @$x ] # '', [ ], [ ] # +exists +delete +store

$x->[0] = 1 # [ values @$x ] # '', [ 1 ], [ 1 ]
$x->[0] = 1 # [ values @$x ] # '', [ 1 ], [ 1 ] #
$x->[0] = 1 # [ values @$x ] # '', [ 1 ], [ 1 ] # +fetch
$x->[0] = 1 # [ values @$x ] # '', [ 1 ], [ 1 ] # +exists +delete +store

$x # values @{$x->[0]} # '', 0, [ [ ] ]
$x # values @{$x->[0]} # '', 0, undef #
$x # values @{$x->[0]} # '', 0, undef # +fetch
$x # values @{$x->[0]} # '', 0, [ [ ] ] # +exists
$x # values @{$x->[0]} # '', 0, [ [ ] ] # +delete
$x # values @{$x->[0]} # '', 0, [ [ ] ] # +store

$x # values @{$x->[0]} # qr/^Reference vivification forbidden/, undef, undef # +strict +fetch
$x # values @{$x->[0]} # '', 0, [ [ ] ] # +strict +exists
$x # values @{$x->[0]} # '', 0, [ [ ] ] # +strict +delete
$x # values @{$x->[0]} # '', 0, [ [ ] ] # +strict +store

$x # [ values @{$x->[0]} ] # '', [ ], [ [ ] ]
$x # [ values @{$x->[0]} ] # '', [ ], undef #
$x # [ values @{$x->[0]} ] # '', [ ], undef # +fetch
$x # [ values @{$x->[0]} ] # '', [ ], [ [ ] ] # +exists +delete +store

# 04-station.t
#
# Test suite for WWW::Velib::Station
#
# Copyright (C) 2007 David Landgren

use strict;

use Test::More tests => 30;

my $Unchanged = 'The scalar remains the same';
$_ = $Unchanged;

eval q{ use_ok 'WWW::Velib::Station' };
eval q{ use_ok 'WWW::Velib::Map' };

my $s = WWW::Velib::Station->new(2007);
ok( defined($s), 'new() defines ...' );
is( ref($s), 'WWW::Velib::Station', '... a WWW::Velib::Station object' );

like( $s->available, qr/\A\d+\Z/, 'available()' );
like( $s->free,      qr/\A\d+\Z/, 'free()' );
like( $s->disabled,  qr/\A\d+\Z/, 'disabled()' );
like( $s->total,     qr/\A\d+\Z/, 'total()' );

my $m = WWW::Velib::Map->new(file => 'eg/data/map.cache.v1');
is( ref($m), 'WWW::Velib::Map', 'loaded a WWW::Velib::Map object from v1 cache' );

my @result = $m->search( n => 2, station => 1001 );
is( scalar(@result), 2, 'found 2 nearest stations to 1001' );

my $station = $result[0];
is( ref($station), 'WWW::Velib::Station', 'search result is WWW::Velib::Station object' );
is( $station->distance_from($result[0]), 0, 'distance from self');
is( $station->open, 1, 'nearest is open');

is( $station->name,         '01001 - ILE DE LA CITE PONT NEUF', 'nearest name');
is( $station->full_address, q{41 QUAI DE L'HORLOGE - 75001 PARIS}, 'nearest full address');
is( $station->address,      q{41 QUAI DE L'HORLOGE -}, 'nearest address');
is( sprintf('%0.4f', $station->latitude), 48.8571, 'nearest latitude');
is( sprintf('%0.4f', $station->longitude), 2.3416, 'nearest longitude');

$station = $result[1];
is( $station->distance_from($result[0]), 485, 'distance of next');
is( $station->distance_from($result[0], 2), 486, 'distance of next (2m scale)');
is( $station->open, 1, 'next is open');

is( $station->name,         q{06020 - SAINT MICHEL DANTON}, 'next name');
is( $station->full_address, q{2 RUE DANTON - 75006 PARIS}, 'next full address');
is( $station->address,      q{2 RUE DANTON -}, 'next address');
is( sprintf('%0.4f', $station->latitude), 48.8528, 'next latitude' );
is( sprintf('%0.4f', $station->longitude), 2.3426, 'next longitude' );

@result = $m->search( distance => 1250, station => 1001 );
is( scalar(@result), 18, 'found 60 stations within 1.25km of station 1001' );

$station = $result[-1];
cmp_ok( $station->distance_from($result[0]), '<=', 1250, 'farthest within range');

@result = $m->search( station => 123456789 );
is (scalar(@result), 0, 'non-existant station');

is($_, $Unchanged, $Unchanged);

#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use JSON::MaybeXS;
use FindBin;

use_ok('WWW::MetaForge::ArcRaiders::Result::MapMarker');

# Load fixture
my $fixture_file = "$FindBin::Bin/fixtures/map-data-dam.json";
open my $fh, '<', $fixture_file or die "Cannot open $fixture_file: $!";
my $json = do { local $/; <$fh> };
close $fh;

my $data = decode_json($json);
ok($data->{allData}, 'Fixture has allData');
ok(scalar @{$data->{allData}} >= 5, 'Fixture has at least 5 markers');

subtest 'arc/tick marker' => sub {
  my $tick_data = $data->{allData}[0];
  my $tick = WWW::MetaForge::ArcRaiders::Result::MapMarker->from_hashref($tick_data);

  isa_ok($tick, 'WWW::MetaForge::ArcRaiders::Result::MapMarker');
  isa_ok($tick, 'WWW::MetaForge::GameMapData::Result::MapMarker');

  is($tick->id, 'd1098bdf-fe93-1eb1-8c09-f5f8803c9386', 'id correct');
  is($tick->mapID, 'dam', 'mapID correct');
  is($tick->category, 'arc', 'category correct');
  is($tick->subcategory, 'tick', 'subcategory correct');
  is($tick->type, 'arc/tick', 'type combines category/subcategory');

  # Coordinates (lng -> x, lat -> y)
  ok(defined $tick->x, 'has x coordinate');
  ok(defined $tick->y, 'has y coordinate');
  cmp_ok($tick->x, '>', 3000, 'x coordinate reasonable (from lng)');
  cmp_ok($tick->y, '>', 1000, 'y coordinate reasonable (from lat)');

  is($tick->behindLockedDoor, 0, 'not behind locked door');
  is($tick->eventConditionMask, 1, 'eventConditionMask correct');
  ok(defined $tick->updated_at, 'has updated_at');
};

subtest 'marker with behindLockedDoor true' => sub {
  my $locked_data = $data->{allData}[4];  # weapon_case with behindLockedDoor: true
  my $locked = WWW::MetaForge::ArcRaiders::Result::MapMarker->from_hashref($locked_data);

  is($locked->category, 'containers', 'container category correct');
  is($locked->subcategory, 'weapon_case', 'weapon_case subcategory correct');
  is($locked->behindLockedDoor, 1, 'behindLockedDoor is true');
  is($locked->added_by, 'dannehtv', 'added_by correct');
  is($locked->last_edited_by, 'Dannehtv', 'last_edited_by correct');
};

subtest 'marker with lootAreas' => sub {
  my $locker_data = $data->{allData}[2];  # locker with lootAreas: "Electrical"
  my $locker = WWW::MetaForge::ArcRaiders::Result::MapMarker->from_hashref($locker_data);

  is($locker->category, 'containers', 'container category correct');
  is($locker->subcategory, 'locker', 'locker subcategory correct');
  is($locker->instanceName, 'Red Lockers', 'instanceName correct');
  is($locker->name, 'Red Lockers', 'name alias works');
  is($locker->lootAreas, 'Electrical', 'lootAreas correct');
};

subtest '_raw accessor' => sub {
  my $marker = WWW::MetaForge::ArcRaiders::Result::MapMarker->from_hashref($data->{allData}[0]);

  ok($marker->_raw, 'has _raw accessor');
  is(ref $marker->_raw, 'HASH', '_raw is hashref');
  is($marker->_raw->{mapID}, 'dam', '_raw contains original data');
};

subtest 'coordinates method' => sub {
  my $marker = WWW::MetaForge::ArcRaiders::Result::MapMarker->from_hashref($data->{allData}[0]);
  my $coords = $marker->coordinates;

  is(ref $coords, 'HASH', 'coordinates returns hashref');
  ok(exists $coords->{x}, 'coordinates has x');
  ok(exists $coords->{y}, 'coordinates has y');
};

subtest 'boolean behindLockedDoor coercion' => sub {
  # Test with false value
  my $marker1 = WWW::MetaForge::ArcRaiders::Result::MapMarker->from_hashref({
    id => 'test-1', mapID => 'dam', category => 'test', subcategory => 'test',
    lat => 100, lng => 200, behindLockedDoor => 0,
  });
  is($marker1->behindLockedDoor, 0, 'behindLockedDoor false');

  # Test with true value
  my $marker2 = WWW::MetaForge::ArcRaiders::Result::MapMarker->from_hashref({
    id => 'test-2', mapID => 'dam', category => 'test', subcategory => 'test',
    lat => 100, lng => 200, behindLockedDoor => 1,
  });
  is($marker2->behindLockedDoor, 1, 'behindLockedDoor true');
};

done_testing;

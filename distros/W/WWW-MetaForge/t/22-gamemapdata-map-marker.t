#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

use WWW::MetaForge::GameMapData::Result::MapMarker;

subtest 'from_hashref with MetaForge format' => sub {
  my $data = {
    id             => 'test-uuid-1234',
    lat            => 1259,
    lng            => 3312.858,
    zlayers        => 2147483647,
    mapID          => 'dam',
    updated_at     => '2025-10-15T12:03:27.657044+00:00',
    added_by       => 'testuser',
    last_edited_by => 'editor',
  };

  my $marker = WWW::MetaForge::GameMapData::Result::MapMarker->from_hashref($data);

  is($marker->id, 'test-uuid-1234', 'id');
  is($marker->lat, 1259, 'lat');
  is($marker->lng, 3312.858, 'lng');
  is($marker->zlayers, 2147483647, 'zlayers');
  is($marker->mapID, 'dam', 'mapID');
  is($marker->updated_at, '2025-10-15T12:03:27.657044+00:00', 'updated_at');
  is($marker->added_by, 'testuser', 'added_by');
  is($marker->last_edited_by, 'editor', 'last_edited_by');
};

subtest 'convenience accessors x/y/z' => sub {
  my $data = {
    id      => 'test-2',
    lat     => 100,
    lng     => 200,
    zlayers => 5,
    mapID   => 'dam',
  };

  my $marker = WWW::MetaForge::GameMapData::Result::MapMarker->from_hashref($data);

  is($marker->x, 200, 'x is alias for lng');
  is($marker->y, 100, 'y is alias for lat');
  is($marker->z, 5, 'z is alias for zlayers');
};

subtest 'coordinates method' => sub {
  my $marker = WWW::MetaForge::GameMapData::Result::MapMarker->from_hashref({
    id    => 'test-3',
    lat   => 20,
    lng   => 10,
    mapID => 'dam',
  });

  my $coords = $marker->coordinates;
  is_deeply($coords, { x => 10, y => 20 }, 'coordinates without z');

  my $marker_z = WWW::MetaForge::GameMapData::Result::MapMarker->from_hashref({
    id      => 'test-4',
    lat     => 20,
    lng     => 10,
    zlayers => 5,
    mapID   => 'dam',
  });

  my $coords_z = $marker_z->coordinates;
  is_deeply($coords_z, { x => 10, y => 20, z => 5 }, 'coordinates with z');
};

subtest 'base class type and name return undef' => sub {
  my $marker = WWW::MetaForge::GameMapData::Result::MapMarker->from_hashref({
    id    => 'test-5',
    lat   => 100,
    lng   => 200,
    mapID => 'dam',
  });

  is($marker->type, undef, 'base class type returns undef');
  is($marker->name, undef, 'base class name returns undef');
};

subtest '_raw preserved' => sub {
  my $data = {
    id           => 'test-6',
    lat          => 100,
    lng          => 200,
    mapID        => 'dam',
    custom_field => 'custom_value',
  };

  my $marker = WWW::MetaForge::GameMapData::Result::MapMarker->from_hashref($data);

  is($marker->_raw->{custom_field}, 'custom_value', '_raw contains original data');
  is($marker->_raw->{mapID}, 'dam', '_raw contains mapID');
};

subtest 'optional fields can be undef' => sub {
  my $marker = WWW::MetaForge::GameMapData::Result::MapMarker->from_hashref({
    id    => 'test-7',
    lat   => 100,
    lng   => 200,
    mapID => 'dam',
  });

  is($marker->zlayers, undef, 'zlayers can be undef');
  is($marker->updated_at, undef, 'updated_at can be undef');
  is($marker->added_by, undef, 'added_by can be undef');
  is($marker->last_edited_by, undef, 'last_edited_by can be undef');
};

done_testing;

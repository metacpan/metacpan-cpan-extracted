#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

use_ok('WWW::MetaForge::ArcRaiders::Result::Arc');

subtest 'constructor' => sub {
  my $arc = WWW::MetaForge::ArcRaiders::Result::Arc->new(
    id          => 301,
    name        => 'Cold Snap',
    type        => 'MajorEvent',
    description => 'A sudden cold front.',
    maps        => ['Blue Gate', 'Dam'],
    duration    => 7200,
    loot        => [
      { item => 'Frost Core', chance => 0.2 },
    ],
    _raw        => {},
  );

  is($arc->id, 301, 'id');
  is($arc->name, 'Cold Snap', 'name');
  is($arc->type, 'MajorEvent', 'type');
  is(scalar @{$arc->maps}, 2, 'maps count');
  is($arc->duration, 7200, 'duration');
};

subtest 'from_hashref with single map' => sub {
  my $arc = WWW::MetaForge::ArcRaiders::Result::Arc->from_hashref({
    id   => 302,
    name => 'Harvester',
    type => 'MinorEvent',
    map  => 'Spaceport',  # single map field
  });

  is($arc->name, 'Harvester', 'name');
  is(scalar @{$arc->maps}, 1, 'maps converted from single map');
  is($arc->maps->[0], 'Spaceport', 'map value');
};

subtest 'from_hashref with maps array' => sub {
  my $arc = WWW::MetaForge::ArcRaiders::Result::Arc->from_hashref({
    id   => 'storm',
    name => 'Storm',
    maps => ['Dam', 'Blue Gate'],
  });

  is(scalar @{$arc->maps}, 2, 'maps array preserved');
};

subtest 'cooldown/frequency mapping' => sub {
  my $arc1 = WWW::MetaForge::ArcRaiders::Result::Arc->from_hashref({
    id       => 'test1',
    name     => 'Test1',
    cooldown => 3600,
  });
  is($arc1->cooldown, 3600, 'cooldown field');

  my $arc2 = WWW::MetaForge::ArcRaiders::Result::Arc->from_hashref({
    id        => 'test2',
    name      => 'Test2',
    frequency => 1800,
  });
  is($arc2->cooldown, 1800, 'frequency mapped to cooldown');
};

subtest 'defaults' => sub {
  my $arc = WWW::MetaForge::ArcRaiders::Result::Arc->from_hashref({
    id   => 'minimal',
    name => 'Minimal',
  });

  is(ref $arc->maps, 'ARRAY', 'maps is array');
  is(ref $arc->loot, 'ARRAY', 'loot is array');
  is(scalar @{$arc->maps}, 0, 'maps empty');
  is(scalar @{$arc->loot}, 0, 'loot empty');
};

done_testing;

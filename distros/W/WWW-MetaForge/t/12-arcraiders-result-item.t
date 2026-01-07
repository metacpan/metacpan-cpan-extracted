#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

use_ok('WWW::MetaForge::ArcRaiders::Result::Item');

subtest 'constructor with all fields' => sub {
  my $item = WWW::MetaForge::ArcRaiders::Result::Item->new(
    id          => 'ferro-i',
    name        => 'Ferro I',
    slug        => 'ferro-i',
    category    => 'Weapon',
    rarity      => 'Common',
    description => 'Heavy break-action rifle.',
    stats       => { damage => 40, range => 53.1 },
    weight      => 8.0,
    stack_size  => 1,
    base_value  => 475,
    _raw        => {},
  );

  is($item->id, 'ferro-i', 'id');
  is($item->name, 'Ferro I', 'name');
  is($item->category, 'Weapon', 'category');
  is($item->rarity, 'Common', 'rarity');
  is($item->weight, 8.0, 'weight');
  is($item->stack_size, 1, 'stack_size');
  is($item->base_value, 475, 'base_value');
  is($item->stats->{damage}, 40, 'stats.damage');
};

subtest 'from_hashref with API field names' => sub {
  my $data = {
    id          => 'angled-grip-i',
    name        => 'Angled Grip I',
    item_type   => 'Modification',  # API uses item_type
    rarity      => 'Common',
    description => 'Reduces recoil.',
    value       => 640,             # API uses value
    stat_block  => {                # API uses stat_block
      weight    => 0.25,
      stackSize => 1,
    },
    updated_at  => '2025-12-18T17:36:00Z',  # API uses updated_at
  };

  my $item = WWW::MetaForge::ArcRaiders::Result::Item->from_hashref($data);

  is($item->id, 'angled-grip-i', 'id from hashref');
  is($item->name, 'Angled Grip I', 'name from hashref');
  is($item->category, 'Modification', 'category mapped from item_type');
  is($item->base_value, 640, 'base_value mapped from value');
  is($item->weight, 0.25, 'weight extracted from stat_block');
  is($item->stack_size, 1, 'stack_size extracted from stat_block');
  is($item->last_updated, '2025-12-18T17:36:00Z', 'last_updated mapped from updated_at');
  is($item->slug, 'angled-grip-i', 'slug defaults to id');
};

subtest 'from_hashref with minimal data' => sub {
  my $item = WWW::MetaForge::ArcRaiders::Result::Item->from_hashref({
    id   => 'test-item',
    name => 'Test Item',
  });

  is($item->id, 'test-item', 'id set');
  is($item->name, 'Test Item', 'name set');
  ok(!defined $item->rarity, 'rarity is undef');
  is_deeply($item->crafting_requirements, [], 'crafting_requirements defaults to []');
  is_deeply($item->sold_by, [], 'sold_by defaults to []');
};

subtest 'arrays default to empty' => sub {
  my $item = WWW::MetaForge::ArcRaiders::Result::Item->from_hashref({
    id   => 'test',
    name => 'Test',
  });

  is(ref $item->crafting_requirements, 'ARRAY', 'crafting_requirements is array');
  is(ref $item->sold_by, 'ARRAY', 'sold_by is array');
  is(ref $item->used_in, 'ARRAY', 'used_in is array');
  is(ref $item->compatible_with, 'ARRAY', 'compatible_with is array');
};

subtest '_raw preserves original data' => sub {
  my $original = { id => 'test', name => 'Test', custom_field => 'custom_value' };
  my $item = WWW::MetaForge::ArcRaiders::Result::Item->from_hashref($original);

  is_deeply($item->_raw, $original, '_raw contains original data');
  is($item->_raw->{custom_field}, 'custom_value', 'custom fields accessible via _raw');
};

done_testing;

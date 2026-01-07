#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

use_ok('WWW::MetaForge::ArcRaiders::Result::Quest');

subtest 'constructor' => sub {
  my $quest = WWW::MetaForge::ArcRaiders::Result::Quest->new(
    id             => 'a-bad-feeling',
    name           => 'A Bad Feeling',
    description    => 'Find and search any ARC Probe.',
    objectives     => ['Find ARC Probe', 'Search it'],
    required_items => [],
    rewards        => [
      { item => 'Metal Parts', quantity => 1 },
    ],
    _raw           => {},
  );

  is($quest->id, 'a-bad-feeling', 'id');
  is($quest->name, 'A Bad Feeling', 'name');
  is(scalar @{$quest->objectives}, 2, 'objectives count');
  is(scalar @{$quest->rewards}, 1, 'rewards count');
};

subtest 'from_hashref' => sub {
  my $quest = WWW::MetaForge::ArcRaiders::Result::Quest->from_hashref({
    id          => 'upgrade-stash',
    name        => 'Upgrade Stash Capacity',
    description => 'Expedition Project.',
    requiredItems => [
      { item => 'Scrap Metal', quantity => 100 },
    ],
    rewards => [
      { coins => 1000 },
    ],
  });

  is($quest->name, 'Upgrade Stash Capacity', 'name');
  is($quest->required_items->[0]{item}, 'Scrap Metal', 'required_items mapped');
  is($quest->rewards->[0]{coins}, 1000, 'rewards');
};

subtest 'quest chain fields' => sub {
  my $quest = WWW::MetaForge::ArcRaiders::Result::Quest->new(
    id         => 'quest-2',
    name       => 'Quest 2',
    next_quest => 3,
    prev_quest => 1,
    _raw       => {},
  );

  is($quest->next_quest, 3, 'next_quest');
  is($quest->prev_quest, 1, 'prev_quest');
};

subtest 'defaults' => sub {
  my $quest = WWW::MetaForge::ArcRaiders::Result::Quest->from_hashref({
    id   => 'minimal',
    name => 'Minimal Quest',
  });

  is(ref $quest->objectives, 'ARRAY', 'objectives is array');
  is(ref $quest->required_items, 'ARRAY', 'required_items is array');
  is(ref $quest->rewards, 'ARRAY', 'rewards is array');
  is(scalar @{$quest->objectives}, 0, 'objectives empty');
};

done_testing;

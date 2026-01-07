#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

use_ok('WWW::MetaForge::ArcRaiders::Result::Trader');

subtest 'constructor' => sub {
  my $trader = WWW::MetaForge::ArcRaiders::Result::Trader->new(
    name        => 'TianWen',
    description => 'Reclusive gunsmith.',
    location    => 'Speranza',
    inventory   => [
      { item => 'Ferro I', price => 1425 },
      { item => 'Angled Grip I', price => 1920 },
    ],
    _raw        => {},
  );

  is($trader->name, 'TianWen', 'name');
  is($trader->description, 'Reclusive gunsmith.', 'description');
  is(scalar @{$trader->inventory}, 2, 'inventory count');
};

subtest 'from_hashref' => sub {
  my $trader = WWW::MetaForge::ArcRaiders::Result::Trader->from_hashref({
    name        => 'Apollo',
    description => 'Traveling mechanic.',
    inventory   => [
      { item => 'Barricade Kit', price => 1920 },
    ],
  });

  is($trader->name, 'Apollo', 'name');
  is($trader->inventory->[0]{item}, 'Barricade Kit', 'inventory item');
  is($trader->inventory->[0]{price}, 1920, 'inventory price');
};

subtest 'find_item method' => sub {
  my $trader = WWW::MetaForge::ArcRaiders::Result::Trader->new(
    name      => 'Test',
    inventory => [
      { item => 'Ferro I', price => 1425 },
      { item => 'Angled Grip I', price => 1920 },
      { item => 'Heavy Ammo', price => 900 },
    ],
    _raw      => {},
  );

  my $found = $trader->find_item('Ferro I');
  ok(defined $found, 'find_item returns result');
  is($found->{price}, 1425, 'found correct item');

  my $found_ci = $trader->find_item('ferro i');  # case insensitive
  ok(defined $found_ci, 'find_item is case insensitive');

  my $not_found = $trader->find_item('NonExistent');
  ok(!defined $not_found, 'find_item returns undef for missing');
};

subtest 'has_item method' => sub {
  my $trader = WWW::MetaForge::ArcRaiders::Result::Trader->new(
    name      => 'Test',
    inventory => [
      { item => 'Ferro I', price => 1425 },
    ],
    _raw      => {},
  );

  ok($trader->has_item('Ferro I'), 'has_item returns true for existing');
  ok($trader->has_item('ferro i'), 'has_item is case insensitive');
  ok(!$trader->has_item('NonExistent'), 'has_item returns false for missing');
};

subtest 'empty inventory' => sub {
  my $trader = WWW::MetaForge::ArcRaiders::Result::Trader->from_hashref({
    name => 'Empty Trader',
  });

  is(ref $trader->inventory, 'ARRAY', 'inventory is array');
  is(scalar @{$trader->inventory}, 0, 'inventory is empty');
  ok(!$trader->has_item('Anything'), 'has_item false on empty inventory');
};

done_testing;

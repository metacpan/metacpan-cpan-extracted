#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use FindBin;
use lib "$FindBin::Bin/lib";

use_ok('WWW::MetaForge::ArcRaiders');

my $cache_dir = tempdir(CLEANUP => 1);

# Always use MockUA for these tests - we need predictable fixture data
diag("Using MockUA for requirements tests");
require MockUA;
my $api = WWW::MetaForge::ArcRaiders->new(
  ua        => MockUA->new(fixtures_dir => "$FindBin::Bin/fixtures"),
  cache_dir => $cache_dir,
  use_cache => 0,
);

subtest 'find_item_by_name works' => sub {
  my $item = $api->find_item_by_name('Ferro II');
  ok($item, 'found Ferro II');
  is($item->name, 'Ferro II', 'correct name');
  is($item->id, 'ferro-ii', 'correct id');

  my $not_found = $api->find_item_by_name('Nonexistent Item');
  ok(!$not_found, 'returns undef for missing item');

  # Case insensitive
  my $lower = $api->find_item_by_name('ferro ii');
  ok($lower, 'case insensitive search works');
  is($lower->name, 'Ferro II', 'found correct item with lowercase');
};

subtest 'find_item_by_id works' => sub {
  my $item = $api->find_item_by_id('ferro-ii');
  ok($item, 'found by id');
  is($item->name, 'Ferro II', 'correct name');
};

subtest 'calculate_requirements - single item with components' => sub {
  my $result = $api->calculate_requirements(
    items => [{ item => 'Ferro II', count => 1 }]
  );

  ok($result, 'got result');
  ok(ref $result->{requirements} eq 'ARRAY', 'requirements is array');
  ok(ref $result->{missing} eq 'ARRAY', 'missing is array');

  # Ferro II requires: Ferro I (1), Metal Parts (5), Steel Spring (2)
  my %by_name = map { $_->{item}->name => $_->{count} } @{$result->{requirements}};

  is($by_name{'Ferro I'}, 1, 'needs 1 Ferro I');
  is($by_name{'Metal Parts'}, 5, 'needs 5 Metal Parts');
  is($by_name{'Steel Spring'}, 2, 'needs 2 Steel Spring');
};

subtest 'calculate_requirements - item with count > 1' => sub {
  my $result = $api->calculate_requirements(
    items => [{ item => 'Ferro II', count => 2 }]
  );

  my %by_name = map { $_->{item}->name => $_->{count} } @{$result->{requirements}};

  is($by_name{'Ferro I'}, 2, 'needs 2 Ferro I for 2x Ferro II');
  is($by_name{'Metal Parts'}, 10, 'needs 10 Metal Parts for 2x Ferro II');
  is($by_name{'Steel Spring'}, 4, 'needs 4 Steel Spring for 2x Ferro II');
};

subtest 'calculate_requirements - item without components' => sub {
  my $result = $api->calculate_requirements(
    items => [{ item => 'Metal Parts', count => 5 }]
  );

  is(scalar @{$result->{requirements}}, 0, 'no requirements for base material');
  is(scalar @{$result->{missing}}, 1, 'one missing entry');
  is($result->{missing}[0]{reason}, 'not_craftable', 'marked as not craftable');
};

subtest 'calculate_requirements - missing item' => sub {
  my $result = $api->calculate_requirements(
    items => [{ item => 'Nonexistent Weapon', count => 1 }]
  );

  is(scalar @{$result->{requirements}}, 0, 'no requirements');
  is(scalar @{$result->{missing}}, 1, 'one missing entry');
  is($result->{missing}[0]{reason}, 'not_found', 'marked as not found');
};

subtest 'calculate_base_requirements - resolves crafting chain' => sub {
  # Ferro III -> Ferro II + Advanced Circuit (2) + Metal Parts (10)
  # Ferro II -> Ferro I + Metal Parts (5) + Steel Spring (2)
  # Advanced Circuit -> Basic Circuit (2) + Metal Parts (1)
  # So Ferro III base requirements:
  #   Ferro I: 1
  #   Metal Parts: 10 + 5 + 2*1 = 17
  #   Steel Spring: 2
  #   Basic Circuit: 2*2 = 4

  my $result = $api->calculate_base_requirements(
    items => [{ item => 'Ferro III', count => 1 }]
  );

  ok($result, 'got result');

  my %by_name = map { $_->{item}->name => $_->{count} } @{$result->{requirements}};

  is($by_name{'Ferro I'}, 1, 'needs 1 Ferro I (base weapon)');
  is($by_name{'Metal Parts'}, 17, 'needs 17 Metal Parts total');
  is($by_name{'Steel Spring'}, 2, 'needs 2 Steel Spring');
  is($by_name{'Basic Circuit'}, 4, 'needs 4 Basic Circuit');

  # Advanced Circuit should NOT be in base requirements - it's craftable
  ok(!exists $by_name{'Advanced Circuit'}, 'Advanced Circuit resolved to base materials');
  ok(!exists $by_name{'Ferro II'}, 'Ferro II resolved to base materials');
};

subtest 'calculate_base_requirements - multiple items' => sub {
  my $result = $api->calculate_base_requirements(
    items => [
      { item => 'Ferro II', count => 1 },
      { item => 'Advanced Circuit', count => 3 },
    ]
  );

  my %by_name = map { $_->{item}->name => $_->{count} } @{$result->{requirements}};

  # Ferro II: Ferro I (1), Metal Parts (5), Steel Spring (2)
  # Advanced Circuit x3: Basic Circuit (6), Metal Parts (3)
  # Total Metal Parts: 5 + 3 = 8

  is($by_name{'Ferro I'}, 1, 'needs 1 Ferro I');
  is($by_name{'Metal Parts'}, 8, 'needs 8 Metal Parts total');
  is($by_name{'Steel Spring'}, 2, 'needs 2 Steel Spring');
  is($by_name{'Basic Circuit'}, 6, 'needs 6 Basic Circuit');
};

subtest 'clear_items_cache works' => sub {
  # Ensure cache is populated
  $api->find_item_by_name('Ferro I');
  ok($api->_items_cache, 'cache is populated');

  $api->clear_items_cache;
  ok(!$api->_items_cache, 'cache is cleared');
};

done_testing;

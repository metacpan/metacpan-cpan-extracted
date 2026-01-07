#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Temp qw( tempdir );
use lib 't/lib';

use WWW::ARDB;
use MockUA;

my $tmpdir = tempdir(CLEANUP => 1);
my $mock_ua = MockUA->new(fixtures_dir => 't/fixtures');

my $api = WWW::ARDB->new(
    ua        => $mock_ua,
    use_cache => 0,
);

# Test items collection
subtest 'items collection' => sub {
    my $items = $api->items;
    ok(ref($items) eq 'ARRAY', 'items returns arrayref');
    is(scalar @$items, 5, 'correct item count');
    isa_ok($items->[0], 'WWW::ARDB::Result::Item');
    is($items->[0]->id, 'acoustic_guitar', 'first item id');
    is($items->[0]->name, 'Acoustic Guitar', 'first item name');
    is($items->[0]->rarity, 'legendary', 'first item rarity');
};

# Test items_raw
subtest 'items_raw' => sub {
    my $data = $api->items_raw;
    ok(ref($data) eq 'ARRAY', 'items_raw returns arrayref');
    is(scalar @$data, 5, 'correct count');
    ok(ref($data->[0]) eq 'HASH', 'elements are hashrefs');
    is($data->[0]{id}, 'acoustic_guitar', 'raw data accessible');
};

# Test single item
subtest 'single item' => sub {
    my $item = $api->item('acoustic_guitar');
    isa_ok($item, 'WWW::ARDB::Result::Item');
    is($item->id, 'acoustic_guitar', 'id');
    is($item->name, 'Acoustic Guitar', 'name');
    is($item->weight, 1, 'weight (detail field)');
    is($item->stack_size, 1, 'stack_size (detail field)');
    is(scalar @{$item->breakdown}, 2, 'breakdown count');
    is($item->breakdown->[0]{name}, 'Wires', 'breakdown item');
};

# Test item_raw
subtest 'item_raw' => sub {
    my $data = $api->item_raw('acoustic_guitar');
    ok(ref($data) eq 'HASH', 'item_raw returns hashref');
    is($data->{id}, 'acoustic_guitar', 'raw id');
    is($data->{weight}, 1, 'raw weight');
};

# Test quests collection
subtest 'quests collection' => sub {
    my $quests = $api->quests;
    ok(ref($quests) eq 'ARRAY', 'quests returns arrayref');
    is(scalar @$quests, 2, 'correct quest count');
    isa_ok($quests->[0], 'WWW::ARDB::Result::Quest');
    is($quests->[0]->id, 'picking_up_the_pieces', 'first quest id');
    is($quests->[0]->title, 'Picking Up The Pieces', 'first quest title');
};

# Test quests_raw
subtest 'quests_raw' => sub {
    my $data = $api->quests_raw;
    ok(ref($data) eq 'ARRAY', 'quests_raw returns arrayref');
    is($data->[0]{title}, 'Picking Up The Pieces', 'raw title');
};

# Test single quest
subtest 'single quest' => sub {
    my $quest = $api->quest('picking_up_the_pieces');
    isa_ok($quest, 'WWW::ARDB::Result::Quest');
    is($quest->title, 'Picking Up The Pieces', 'title');
    is(scalar @{$quest->maps}, 5, 'maps count (detail)');
    is(scalar @{$quest->rewards}, 3, 'rewards count (detail)');
    is($quest->trader_name, 'Shani', 'trader_name');
    is($quest->trader_type, 'Security', 'trader_type');
};

# Test quest_raw
subtest 'quest_raw' => sub {
    my $data = $api->quest_raw('picking_up_the_pieces');
    ok(ref($data) eq 'HASH', 'quest_raw returns hashref');
    is(scalar @{$data->{rewards}}, 3, 'raw rewards');
};

# Test arc_enemies collection
subtest 'arc_enemies collection' => sub {
    my $enemies = $api->arc_enemies;
    ok(ref($enemies) eq 'ARRAY', 'arc_enemies returns arrayref');
    is(scalar @$enemies, 3, 'correct enemy count');
    isa_ok($enemies->[0], 'WWW::ARDB::Result::ArcEnemy');
    is($enemies->[0]->id, 'wasp', 'first enemy id');
    is($enemies->[0]->name, 'Wasp', 'first enemy name');
};

# Test arc_enemies_raw
subtest 'arc_enemies_raw' => sub {
    my $data = $api->arc_enemies_raw;
    ok(ref($data) eq 'ARRAY', 'arc_enemies_raw returns arrayref');
    is($data->[0]{name}, 'Wasp', 'raw name');
};

# Test single arc_enemy
subtest 'single arc_enemy' => sub {
    my $enemy = $api->arc_enemy('wasp');
    isa_ok($enemy, 'WWW::ARDB::Result::ArcEnemy');
    is($enemy->name, 'Wasp', 'name');
    is($enemy->image, '/arc/images/wasp.png', 'image (detail)');
    is(scalar @{$enemy->drop_table}, 3, 'drop_table count');
    is(scalar @{$enemy->related_maps}, 2, 'related_maps count');
    is_deeply($enemy->drops, ['Medium Ammo', 'Wires', 'Scrap Electronics'], 'drops helper');
};

# Test arc_enemy_raw
subtest 'arc_enemy_raw' => sub {
    my $data = $api->arc_enemy_raw('wasp');
    ok(ref($data) eq 'HASH', 'arc_enemy_raw returns hashref');
    is(scalar @{$data->{dropTable}}, 3, 'raw dropTable');
};

# Test find_item_by_name
subtest 'find_item_by_name' => sub {
    my $item = $api->find_item_by_name('Wires');
    ok(defined $item, 'found item');
    is($item->id, 'wires', 'correct item');

    # Case-insensitive
    my $item2 = $api->find_item_by_name('ACOUSTIC GUITAR');
    ok(defined $item2, 'case-insensitive search');
    is($item2->id, 'acoustic_guitar', 'correct item');

    # Not found
    my $item3 = $api->find_item_by_name('nonexistent');
    ok(!defined $item3, 'returns undef for not found');
};

# Test find_item_by_id
subtest 'find_item_by_id' => sub {
    my $item = $api->find_item_by_id('acoustic_guitar');
    ok(defined $item, 'found item');
    is($item->name, 'Acoustic Guitar', 'correct item');
};

# Test find_quest_by_title
subtest 'find_quest_by_title' => sub {
    my $quest = $api->find_quest_by_title('Supply Run');
    ok(defined $quest, 'found quest');
    is($quest->id, 'supply_run', 'correct quest');

    # Case-insensitive
    my $quest2 = $api->find_quest_by_title('PICKING UP THE PIECES');
    ok(defined $quest2, 'case-insensitive search');
    is($quest2->id, 'picking_up_the_pieces', 'correct quest');

    # Not found
    my $quest3 = $api->find_quest_by_title('nonexistent');
    ok(!defined $quest3, 'returns undef for not found');
};

# Test find_arc_enemy_by_name
subtest 'find_arc_enemy_by_name' => sub {
    my $enemy = $api->find_arc_enemy_by_name('Grunt');
    ok(defined $enemy, 'found enemy');
    is($enemy->id, 'grunt', 'correct enemy');

    # Case-insensitive
    my $enemy2 = $api->find_arc_enemy_by_name('WASP');
    ok(defined $enemy2, 'case-insensitive search');
    is($enemy2->id, 'wasp', 'correct enemy');

    # Not found
    my $enemy3 = $api->find_arc_enemy_by_name('nonexistent');
    ok(!defined $enemy3, 'returns undef for not found');
};

done_testing;

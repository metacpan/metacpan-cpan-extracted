#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Temp qw( tempdir );

use WWW::ARDB;

my $tmpdir = tempdir(CLEANUP => 1);

my $api = WWW::ARDB->new(
    use_cache => 1,
    cache_dir => $tmpdir,
);

isa_ok($api, 'WWW::ARDB');
isa_ok($api->request, 'WWW::ARDB::Request');
isa_ok($api->cache, 'WWW::ARDB::Cache');
isa_ok($api->ua, 'LWP::UserAgent');

SKIP: {
    skip 'Set USE_LIVE_API=1 to run live API tests', 50
        unless $ENV{USE_LIVE_API};

    # ===== Items =====
    subtest 'items collection' => sub {
        my $items = $api->items;
        ok(ref($items) eq 'ARRAY', 'items returns arrayref');
        ok(scalar @$items > 0, 'items has content');
        isa_ok($items->[0], 'WWW::ARDB::Result::Item');
        ok(defined $items->[0]->id, 'item has id');
        ok(defined $items->[0]->name, 'item has name');
    };

    subtest 'items_raw' => sub {
        my $data = $api->items_raw;
        ok(ref($data) eq 'ARRAY', 'items_raw returns arrayref');
        ok(scalar @$data > 0, 'has content');
        ok(ref($data->[0]) eq 'HASH', 'elements are hashrefs');
    };

    subtest 'single item' => sub {
        my $item = $api->item('acoustic_guitar');
        isa_ok($item, 'WWW::ARDB::Result::Item');
        is($item->id, 'acoustic_guitar', 'item id');
        is($item->name, 'Acoustic Guitar', 'item name');
        ok(defined $item->description, 'has description (detail field)');
    };

    subtest 'item_raw' => sub {
        my $data = $api->item_raw('acoustic_guitar');
        ok(ref($data) eq 'HASH', 'item_raw returns hashref');
        is($data->{id}, 'acoustic_guitar', 'raw id');
    };

    # ===== Quests =====
    subtest 'quests collection' => sub {
        my $quests = $api->quests;
        ok(ref($quests) eq 'ARRAY', 'quests returns arrayref');
        ok(scalar @$quests > 0, 'quests has content');
        isa_ok($quests->[0], 'WWW::ARDB::Result::Quest');
        ok(defined $quests->[0]->id, 'quest has id');
        ok(defined $quests->[0]->title, 'quest has title');
    };

    subtest 'quests_raw' => sub {
        my $data = $api->quests_raw;
        ok(ref($data) eq 'ARRAY', 'quests_raw returns arrayref');
        ok(scalar @$data > 0, 'has content');
    };

    subtest 'single quest' => sub {
        # Get first quest from list to use as test
        my $quests = $api->quests;
        my $quest_id = $quests->[0]->id;

        my $quest = $api->quest($quest_id);
        isa_ok($quest, 'WWW::ARDB::Result::Quest');
        is($quest->id, $quest_id, 'quest id matches');
        ok(defined $quest->title, 'has title');
    };

    subtest 'quest_raw' => sub {
        my $quests = $api->quests;
        my $quest_id = $quests->[0]->id;

        my $data = $api->quest_raw($quest_id);
        ok(ref($data) eq 'HASH', 'quest_raw returns hashref');
        is($data->{id}, $quest_id, 'raw id matches');
    };

    # ===== ARC Enemies =====
    subtest 'arc_enemies collection' => sub {
        my $enemies = $api->arc_enemies;
        ok(ref($enemies) eq 'ARRAY', 'arc_enemies returns arrayref');
        ok(scalar @$enemies > 0, 'arc_enemies has content');
        isa_ok($enemies->[0], 'WWW::ARDB::Result::ArcEnemy');
        ok(defined $enemies->[0]->id, 'enemy has id');
        ok(defined $enemies->[0]->name, 'enemy has name');
    };

    subtest 'arc_enemies_raw' => sub {
        my $data = $api->arc_enemies_raw;
        ok(ref($data) eq 'ARRAY', 'arc_enemies_raw returns arrayref');
        ok(scalar @$data > 0, 'has content');
    };

    subtest 'single arc_enemy' => sub {
        my $enemy = $api->arc_enemy('wasp');
        isa_ok($enemy, 'WWW::ARDB::Result::ArcEnemy');
        is($enemy->id, 'wasp', 'enemy id');
        is($enemy->name, 'Wasp', 'enemy name');
        ok(scalar @{$enemy->drop_table} > 0, 'has drop_table (detail field)');
    };

    subtest 'arc_enemy_raw' => sub {
        my $data = $api->arc_enemy_raw('wasp');
        ok(ref($data) eq 'HASH', 'arc_enemy_raw returns hashref');
        is($data->{id}, 'wasp', 'raw id');
        ok(exists $data->{dropTable}, 'has dropTable');
    };

    # ===== Find methods =====
    subtest 'find_item_by_name' => sub {
        my $item = $api->find_item_by_name('Acoustic Guitar');
        ok(defined $item, 'found item');
        is($item->id, 'acoustic_guitar', 'correct item');

        # Case-insensitive
        my $item2 = $api->find_item_by_name('acoustic guitar');
        ok(defined $item2, 'case-insensitive search works');

        # Not found
        my $item3 = $api->find_item_by_name('xyznonexistent123');
        ok(!defined $item3, 'returns undef for not found');
    };

    subtest 'find_item_by_id' => sub {
        my $item = $api->find_item_by_id('acoustic_guitar');
        ok(defined $item, 'found item');
        is($item->name, 'Acoustic Guitar', 'correct item');
    };

    subtest 'find_quest_by_title' => sub {
        my $quests = $api->quests;
        my $first_title = $quests->[0]->title;

        my $quest = $api->find_quest_by_title($first_title);
        ok(defined $quest, 'found quest');
        is($quest->title, $first_title, 'correct quest');

        # Case-insensitive
        my $quest2 = $api->find_quest_by_title(lc($first_title));
        ok(defined $quest2, 'case-insensitive search works');

        # Not found
        my $quest3 = $api->find_quest_by_title('xyznonexistent123');
        ok(!defined $quest3, 'returns undef for not found');
    };

    subtest 'find_arc_enemy_by_name' => sub {
        my $enemy = $api->find_arc_enemy_by_name('Wasp');
        ok(defined $enemy, 'found enemy');
        is($enemy->id, 'wasp', 'correct enemy');

        # Case-insensitive
        my $enemy2 = $api->find_arc_enemy_by_name('wasp');
        ok(defined $enemy2, 'case-insensitive search works');

        # Not found
        my $enemy3 = $api->find_arc_enemy_by_name('xyznonexistent123');
        ok(!defined $enemy3, 'returns undef for not found');
    };

    # ===== Cache =====
    subtest 'clear_cache' => sub {
        # Ensure cache has data
        $api->items;
        my @files_before = glob("$tmpdir/*.json");
        ok(scalar @files_before > 0, 'cache has files');

        # Clear specific endpoint
        $api->clear_cache('items');

        # Clear all
        $api->items;  # repopulate
        $api->clear_cache;
        my @files_after = glob("$tmpdir/*.json");
        is(scalar @files_after, 0, 'cache cleared');
    };
}

done_testing;

#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

use WWW::ARDB::Request;

my $request = WWW::ARDB::Request->new;
isa_ok($request, 'WWW::ARDB::Request');

# Test items endpoint
my $items_req = $request->items;
isa_ok($items_req, 'HTTP::Request');
is($items_req->method, 'GET', 'Items request is GET');
is($items_req->uri, 'https://ardb.app/api/items', 'Items URL correct');

# Test item endpoint
my $item_req = $request->item('acoustic_guitar');
is($item_req->uri, 'https://ardb.app/api/items/acoustic_guitar', 'Item URL correct');

# Test quests endpoint
my $quests_req = $request->quests;
is($quests_req->uri, 'https://ardb.app/api/quests', 'Quests URL correct');

# Test quest endpoint
my $quest_req = $request->quest('picking_up_the_pieces');
is($quest_req->uri, 'https://ardb.app/api/quests/picking_up_the_pieces', 'Quest URL correct');

# Test arc_enemies endpoint
my $enemies_req = $request->arc_enemies;
is($enemies_req->uri, 'https://ardb.app/api/arc-enemies', 'Arc enemies URL correct');

# Test arc_enemy endpoint
my $enemy_req = $request->arc_enemy('wasp');
is($enemy_req->uri, 'https://ardb.app/api/arc-enemies/wasp', 'Arc enemy URL correct');

done_testing;

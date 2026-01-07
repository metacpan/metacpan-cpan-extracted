#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

use WWW::ARDB::Result::ArcEnemy;

my $data = {
    id          => 'wasp',
    name        => 'Wasp',
    icon        => '/arc/icons/wasp.svg',
    image       => '/arc/images/wasp.png',
    dropTable   => [
        { id => 'medium_ammo', name => 'Medium Ammo', rarity => 'common', value => 4 },
        { id => 'wires', name => 'Wires', rarity => 'uncommon', value => 200 },
    ],
    relatedMaps => [],
    updatedAt   => '2025-10-23T12:37:58.471Z',
};

my $enemy = WWW::ARDB::Result::ArcEnemy->from_hashref($data);
isa_ok($enemy, 'WWW::ARDB::Result::ArcEnemy');

is($enemy->id, 'wasp', 'id');
is($enemy->name, 'Wasp', 'name');
is($enemy->icon, '/arc/icons/wasp.svg', 'icon');
is($enemy->image, '/arc/images/wasp.png', 'image');
is(scalar @{$enemy->drop_table}, 2, 'drop_table count');
is($enemy->drop_table->[0]{name}, 'Medium Ammo', 'first drop name');
is_deeply($enemy->related_maps, [], 'related_maps');
is($enemy->updated_at, '2025-10-23T12:37:58.471Z', 'updated_at');

is($enemy->icon_url, 'https://ardb.app/arc/icons/wasp.svg', 'icon_url');
is($enemy->image_url, 'https://ardb.app/arc/images/wasp.png', 'image_url');
is_deeply($enemy->drops, ['Medium Ammo', 'Wires'], 'drops');

done_testing;

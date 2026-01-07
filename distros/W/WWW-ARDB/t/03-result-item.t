#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

use WWW::ARDB::Result::Item;

my $data = {
    id          => 'acoustic_guitar',
    name        => 'Acoustic Guitar',
    description => 'A playable acoustic guitar.',
    rarity      => 'legendary',
    type        => 'quick use',
    value       => 7000,
    weight      => 1,
    stackSize   => 1,
    icon        => '/arc/icons/acoustic_guitar.webp',
    foundIn     => [],
    maps        => [],
    breakdown   => [
        { id => 'wires', name => 'Wires', amount => 6 },
        { id => 'metal_parts', name => 'Metal Parts', amount => 4 },
    ],
    updatedAt   => '2025-12-28T14:24:01.035Z',
};

my $item = WWW::ARDB::Result::Item->from_hashref($data);
isa_ok($item, 'WWW::ARDB::Result::Item');

is($item->id, 'acoustic_guitar', 'id');
is($item->name, 'Acoustic Guitar', 'name');
is($item->description, 'A playable acoustic guitar.', 'description');
is($item->rarity, 'legendary', 'rarity');
is($item->type, 'quick use', 'type');
is($item->value, 7000, 'value');
is($item->weight, 1, 'weight');
is($item->stack_size, 1, 'stack_size');
is($item->icon, '/arc/icons/acoustic_guitar.webp', 'icon');
is_deeply($item->found_in, [], 'found_in');
is_deeply($item->maps, [], 'maps');
is(scalar @{$item->breakdown}, 2, 'breakdown count');
is($item->updated_at, '2025-12-28T14:24:01.035Z', 'updated_at');

is($item->icon_url, 'https://ardb.app/arc/icons/acoustic_guitar.webp', 'icon_url');

# Test with null rarity
my $common_data = {
    id     => 'some_item',
    name   => 'Some Item',
    rarity => undef,
};
my $common_item = WWW::ARDB::Result::Item->from_hashref($common_data);
is($common_item->rarity, undef, 'null rarity');

done_testing;

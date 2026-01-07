#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

use WWW::ARDB::Result::Quest;

my $data = {
    id          => 'picking_up_the_pieces',
    title       => 'Picking Up The Pieces',
    description => 'Help repair infrastructure after the storm.',
    maps        => [
        { id => 'dam', name => 'Dam Battlegrounds' },
        { id => 'spaceport', name => 'The Spaceport' },
    ],
    steps       => [
        { title => 'Loot containers', amount => 3 },
    ],
    trader      => {
        id          => 'shani',
        name        => 'Shani',
        type        => 'Security',
        description => 'A security officer.',
    },
    requiredItems => [],
    xpReward      => 0,
    updatedAt     => '2025-10-31T12:00:00.000Z',
};

my $quest = WWW::ARDB::Result::Quest->from_hashref($data);
isa_ok($quest, 'WWW::ARDB::Result::Quest');

is($quest->id, 'picking_up_the_pieces', 'id');
is($quest->title, 'Picking Up The Pieces', 'title');
is($quest->description, 'Help repair infrastructure after the storm.', 'description');
is(scalar @{$quest->maps}, 2, 'maps count');
is(scalar @{$quest->steps}, 1, 'steps count');
is($quest->steps->[0]{title}, 'Loot containers', 'step title');
is($quest->steps->[0]{amount}, 3, 'step amount');
is($quest->xp_reward, 0, 'xp_reward');
is($quest->updated_at, '2025-10-31T12:00:00.000Z', 'updated_at');

is($quest->trader_name, 'Shani', 'trader_name');
is($quest->trader_type, 'Security', 'trader_type');
is_deeply($quest->map_names, ['Dam Battlegrounds', 'The Spaceport'], 'map_names');

done_testing;

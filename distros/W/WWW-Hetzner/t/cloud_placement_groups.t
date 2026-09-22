#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use lib 't/lib';

use Test::WWW::Hetzner::Mock;

subtest 'list placement groups' => sub {
    my $fixture = load_fixture('placement_groups_list');

    my $cloud = mock_cloud(
        'GET /placement_groups' => $fixture,
    );

    my $pgs = $cloud->placement_groups->list;

    is(ref $pgs, 'ARRAY', 'returns array');
    is(scalar @$pgs, 1, 'one placement group');
    isa_ok($pgs->[0], 'WWW::Hetzner::Cloud::PlacementGroup');
    is($pgs->[0]->id, 1300, 'placement group id');
    is($pgs->[0]->name, 'web-spread', 'placement group name');
    is($pgs->[0]->type, 'spread', 'placement group type');
    is(scalar @{$pgs->[0]->servers}, 2, 'two servers');
};

subtest 'get placement group' => sub {
    my $fixture = load_fixture('placement_groups_get');

    my $cloud = mock_cloud(
        '/placement_groups/1300' => $fixture,
    );

    my $pg = $cloud->placement_groups->get(1300);

    isa_ok($pg, 'WWW::Hetzner::Cloud::PlacementGroup');
    is($pg->id, 1300, 'placement group id');
    is($pg->servers->[0], 123, 'first server');
};

subtest 'create placement group' => sub {
    my $fixture = load_fixture('placement_groups_create');

    my $cloud = mock_cloud(
        'POST /placement_groups' => sub {
            my ($method, $path, %opts) = @_;
            my $body = $opts{body};
            is($body->{name}, 'new-group', 'name in request');
            is($body->{type}, 'spread', 'type in request');
            return $fixture;
        },
    );

    my $pg = $cloud->placement_groups->create(
        name => 'new-group',
        type => 'spread',
    );

    isa_ok($pg, 'WWW::Hetzner::Cloud::PlacementGroup');
    is($pg->id, 1400, 'new placement group id');
    isa_ok($pg->action, 'WWW::Hetzner::Action', 'create action is an Action');
    is($pg->action->command, 'create_placement_group', 'action command');
};

subtest 'create placement group without action (unmanaged)' => sub {
    my $fixture = load_fixture('placement_groups_create');
    delete $fixture->{action};

    my $cloud = mock_cloud(
        'POST /placement_groups' => $fixture,
    );

    my $pg = $cloud->placement_groups->create(
        name => 'new-group',
        type => 'spread',
    );

    is($pg->action, undef, 'action is undef when API omits it');
};

subtest 'delete placement group' => sub {
    my $cloud = mock_cloud(
        'DELETE /placement_groups/1300' => {},
    );

    $cloud->placement_groups->delete(1300);
    ok(1, 'delete succeeded');
};

done_testing;

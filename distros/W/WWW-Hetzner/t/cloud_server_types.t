#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use lib 't/lib';

use Test::WWW::Hetzner::Mock;

subtest 'list server types' => sub {
    my $fixture = load_fixture('server_types_list');

    my $cloud = mock_cloud(
        'GET /server_types' => $fixture,
    );

    my $types = $cloud->server_types->list;

    is(ref $types, 'ARRAY', 'returns array');
    is(scalar @$types, 3, 'three types');
    is($types->[0]{name}, 'cx11', 'first type name');
    is($types->[1]{name}, 'cx23', 'second type name');
    is($types->[1]{cores}, 2, 'cx23 cores');
    is($types->[1]{memory}, 4, 'cx23 memory');
};

subtest 'get server type by id' => sub {
    my $fixture = load_fixture('server_types_get');

    my $cloud = mock_cloud(
        'GET /server_types/22' => $fixture,
    );

    my $type = $cloud->server_types->get(22);

    is($type->{id}, 22, 'type id');
    is($type->{name}, 'cx23', 'type name');
    is($type->{cores}, 2, 'type cores');
};

subtest 'get server type by name' => sub {
    my $fixture = load_fixture('server_types_list');

    my $cloud = mock_cloud(
        'GET /server_types' => $fixture,
    );

    my $type = $cloud->server_types->get_by_name('cx23');

    is($type->{name}, 'cx23', 'type name');
    is($type->{cores}, 2, 'type cores');
    ok(!$type->{deprecated}, 'not deprecated');
};

subtest 'get server type by name - not found' => sub {
    my $fixture = load_fixture('server_types_list');

    my $cloud = mock_cloud(
        'GET /server_types' => $fixture,
    );

    my $type = $cloud->server_types->get_by_name('nonexistent');

    ok(!defined $type, 'returns undef for not found');
};

done_testing;

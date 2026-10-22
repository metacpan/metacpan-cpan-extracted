#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use JSON::PP ();
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

subtest 'server type carries its locations' => sub {
    my $fixture = load_fixture('server_types_list_current');

    my $cloud = mock_cloud(
        'GET /server_types' => $fixture,
    );

    my $type = $cloud->server_types->get_by_name('cx23');

    can_ok($type, 'locations');
    return unless $type->can('locations');

    my $locations = $type->locations;
    is(ref $locations, 'ARRAY', 'locations is an arrayref');
    is(scalar @$locations, 2, 'two locations');

    is($locations->[0]{name}, 'fsn1', 'first location name');
    is($locations->[1]{name}, 'nbg1', 'second location name');

    ok($locations->[0]{available},  'the type is available in fsn1');
    ok(!$locations->[1]{available}, 'the type is not available in nbg1');

    is_deeply(
        [ sort keys %{ $locations->[0] } ],
        [qw(available deprecated name)],
        'the API field names are kept as they are'
    );

    is_deeply(
        $type->data->{locations},
        $locations,
        'data carries the locations'
    );
};

subtest 'deprecated falls away when the API does not send it' => sub {
    my $cloud = mock_cloud(
        'GET /server_types' => {
            server_types => [
                {
                    id     => 22,
                    name   => 'cx23',
                    cores  => 2,
                    memory => 4,
                    disk   => 40,
                    locations => [
                        { name => 'fsn1', available => JSON::PP::true, deprecated => JSON::PP::false },
                    ],
                },
            ],
        },
    );

    my $type = $cloud->server_types->get_by_name('cx23');

    ok(!defined $type->deprecated, 'deprecated is undef');

    can_ok($type, 'locations');
    return unless $type->can('locations');

    is($type->locations->[0]{name}, 'fsn1', 'the locations are still there');
};

done_testing;

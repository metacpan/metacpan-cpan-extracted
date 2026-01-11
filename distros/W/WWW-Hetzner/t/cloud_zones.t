#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use lib 't/lib';

use Test::WWW::Hetzner::Mock;

subtest 'list zones' => sub {
    my $fixture = load_fixture('zones_list');

    my $cloud = mock_cloud(
        'GET /zones' => $fixture,
    );

    my $zones = $cloud->zones->list;

    is(ref $zones, 'ARRAY', 'returns array');
    is(scalar @$zones, 1, 'one zone');
    is($zones->[0]{id}, 'zone123456', 'zone id');
    is($zones->[0]{name}, 'example.com', 'zone name');
    is($zones->[0]{status}, 'verified', 'zone status');
};

subtest 'list zones by label' => sub {
    my $fixture = load_fixture('zones_list');

    my $cloud = mock_cloud(
        'GET /zones' => sub {
            my ($method, $path, %opts) = @_;
            return $fixture;
        },
    );

    my $zones = $cloud->zones->list_by_label('env=production');

    is(scalar @$zones, 1, 'one zone');
    is($zones->[0]{labels}{env}, 'production', 'label matches');
};

subtest 'get zone' => sub {
    my $fixture = load_fixture('zones_get');

    my $cloud = mock_cloud(
        '/zones/zone123456' => $fixture,
    );

    my $zone = $cloud->zones->get('zone123456');

    is($zone->{id}, 'zone123456', 'zone id');
    is($zone->{name}, 'example.com', 'zone name');
    is($zone->{ttl}, 3600, 'zone ttl');
};

subtest 'create zone' => sub {
    my $fixture = load_fixture('zones_create');

    my $cloud = mock_cloud(
        'POST /zones' => sub {
            my ($method, $path, %opts) = @_;
            my $body = $opts{body};

            is($body->{name}, 'newdomain.com', 'name in request');

            return $fixture;
        },
    );

    my $zone = $cloud->zones->create(
        name => 'newdomain.com',
    );

    is($zone->{id}, 'zone789012', 'new zone id');
    is($zone->{name}, 'newdomain.com', 'new zone name');
    is($zone->{status}, 'pending', 'new zone status');
};

subtest 'update zone' => sub {
    my $fixture = load_fixture('zones_update');

    my $cloud = mock_cloud(
        'PUT /zones/zone123456' => sub {
            my ($method, $path, %opts) = @_;
            is($opts{body}{labels}{env}, 'staging', 'labels in request');
            return $fixture;
        },
    );

    my $zone = $cloud->zones->update('zone123456',
        labels => { env => 'staging' },
    );

    is($zone->{labels}{env}, 'staging', 'labels updated');
};

subtest 'delete zone' => sub {
    my $cloud = mock_cloud(
        'DELETE /zones/zone123456' => {},
    );

    my $result = $cloud->zones->delete('zone123456');
    ok(1, 'delete succeeded');
};

subtest 'create zone with ttl' => sub {
    my $fixture = load_fixture('zones_create');

    my $cloud = mock_cloud(
        'POST /zones' => sub {
            my ($method, $path, %opts) = @_;
            my $body = $opts{body};

            is($body->{name}, 'newdomain.com', 'name in request');
            is($body->{ttl}, 7200, 'ttl in request');

            return $fixture;
        },
    );

    my $zone = $cloud->zones->create(
        name => 'newdomain.com',
        ttl  => 7200,
    );

    is($zone->{name}, 'newdomain.com', 'zone created');
};

subtest 'create zone with labels' => sub {
    my $fixture = load_fixture('zones_create');

    my $cloud = mock_cloud(
        'POST /zones' => sub {
            my ($method, $path, %opts) = @_;
            my $body = $opts{body};

            is($body->{labels}{env}, 'test', 'labels in request');

            return $fixture;
        },
    );

    my $zone = $cloud->zones->create(
        name   => 'newdomain.com',
        labels => { env => 'test' },
    );

    ok($zone, 'zone created with labels');
};

subtest 'export zone' => sub {
    my $cloud = mock_cloud(
        'GET /zones/zone123456/export' => { zonefile => '$ORIGIN example.com.' },
    );

    my $result = $cloud->zones->export('zone123456');
    ok($result, 'export returned data');
};

subtest 'create zone requires name' => sub {
    my $cloud = mock_cloud();

    eval { $cloud->zones->create() };
    like($@, qr/name required/, 'name required');
};

subtest 'get zone requires id' => sub {
    my $cloud = mock_cloud();

    eval { $cloud->zones->get() };
    like($@, qr/Zone ID required/, 'id required');
};

subtest 'update zone requires id' => sub {
    my $cloud = mock_cloud();

    eval { $cloud->zones->update() };
    like($@, qr/Zone ID required/, 'id required');
};

subtest 'delete zone requires id' => sub {
    my $cloud = mock_cloud();

    eval { $cloud->zones->delete() };
    like($@, qr/Zone ID required/, 'id required');
};

subtest 'export zone requires id' => sub {
    my $cloud = mock_cloud();

    eval { $cloud->zones->export() };
    like($@, qr/Zone ID required/, 'id required');
};

subtest 'rrsets requires zone_id' => sub {
    my $cloud = mock_cloud();

    eval { $cloud->zones->rrsets() };
    like($@, qr/Zone ID required/, 'zone_id required');
};

subtest 'rrsets accessor' => sub {
    my $fixture = load_fixture('rrsets_list');

    my $cloud = mock_cloud(
        'GET /zones/zone123456/rrsets' => $fixture,
    );

    my $rrsets = $cloud->zones->rrsets('zone123456');
    isa_ok($rrsets, 'WWW::Hetzner::Cloud::API::RRSets');

    my $records = $rrsets->list;
    is(scalar @$records, 5, 'five rrsets');
};

done_testing;

#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use lib 't/lib';

use Test::WWW::Hetzner::Mock;

subtest 'list volumes' => sub {
    my $fixture = load_fixture('volumes_list');

    my $cloud = mock_cloud(
        'GET /volumes' => $fixture,
    );

    my $volumes = $cloud->volumes->list;

    is(ref $volumes, 'ARRAY', 'returns array');
    is(scalar @$volumes, 2, 'two volumes');
    isa_ok($volumes->[0], 'WWW::Hetzner::Cloud::Volume');
    is($volumes->[0]->id, 555, 'volume id');
    is($volumes->[0]->name, 'my-data', 'volume name');
    is($volumes->[0]->size, 50, 'volume size');
    is($volumes->[0]->status, 'available', 'volume status');
    is($volumes->[0]->format, 'ext4', 'volume format');
    is($volumes->[0]->location, 'fsn1', 'volume location');
    ok(!$volumes->[0]->is_attached, 'first volume not attached');
    ok($volumes->[1]->is_attached, 'second volume attached');
    is($volumes->[1]->server, 12345, 'attached to server');
};

subtest 'get volume' => sub {
    my $fixture = load_fixture('volumes_get');

    my $cloud = mock_cloud(
        '/volumes/555' => $fixture,
    );

    my $volume = $cloud->volumes->get(555);

    isa_ok($volume, 'WWW::Hetzner::Cloud::Volume');
    is($volume->id, 555, 'volume id');
    is($volume->name, 'my-data', 'volume name');
    is($volume->linux_device, '/dev/disk/by-id/scsi-0HC_Volume_555', 'linux device');
    is($volume->labels->{env}, 'test', 'label value');
};

subtest 'create volume' => sub {
    my $fixture = load_fixture('volumes_create');

    my $cloud = mock_cloud(
        'POST /volumes' => sub {
            my ($method, $path, %opts) = @_;
            my $body = $opts{body};

            is($body->{name}, 'new-volume', 'name in request');
            is($body->{size}, 20, 'size in request');
            is($body->{location}, 'fsn1', 'location in request');

            return $fixture;
        },
    );

    my $volume = $cloud->volumes->create(
        name     => 'new-volume',
        size     => 20,
        location => 'fsn1',
    );

    isa_ok($volume, 'WWW::Hetzner::Cloud::Volume');
    is($volume->id, 777, 'new volume id');
    is($volume->name, 'new-volume', 'new volume name');
    is($volume->status, 'creating', 'new volume status');
};

subtest 'delete volume' => sub {
    my $cloud = mock_cloud(
        'DELETE /volumes/555' => {},
    );

    my $result = $cloud->volumes->delete(555);
    ok(1, 'delete succeeded');
};

subtest 'create volume requires params' => sub {
    my $cloud = mock_cloud();

    eval { $cloud->volumes->create() };
    like($@, qr/name required/, 'name required');

    eval { $cloud->volumes->create(name => 'test') };
    like($@, qr/size required/, 'size required');

    eval { $cloud->volumes->create(name => 'test', size => 10) };
    like($@, qr/location required/, 'location required');
};

subtest 'attach volume' => sub {
    my $fixture = load_fixture('volumes_action');

    my $cloud = mock_cloud(
        'POST /volumes/555/actions/attach' => sub {
            my ($method, $path, %opts) = @_;
            is($opts{body}{server}, 12345, 'server in request');
            return $fixture;
        },
    );

    my $result = $cloud->volumes->attach(555, 12345);
    is($result->{action}{command}, 'attach_volume', 'action command');
};

subtest 'detach volume' => sub {
    my $fixture = load_fixture('volumes_action');
    $fixture->{action}{command} = 'detach_volume';

    my $cloud = mock_cloud(
        'POST /volumes/555/actions/detach' => $fixture,
    );

    my $result = $cloud->volumes->detach(555);
    is($result->{action}{command}, 'detach_volume', 'action command');
};

subtest 'resize volume' => sub {
    my $fixture = load_fixture('volumes_action');
    $fixture->{action}{command} = 'resize_volume';

    my $cloud = mock_cloud(
        'POST /volumes/555/actions/resize' => sub {
            my ($method, $path, %opts) = @_;
            is($opts{body}{size}, 100, 'size in request');
            return $fixture;
        },
    );

    my $result = $cloud->volumes->resize(555, 100);
    is($result->{action}{command}, 'resize_volume', 'action command');
};

subtest 'volume entity methods' => sub {
    my $fixture = load_fixture('volumes_get');

    my $cloud = mock_cloud(
        '/volumes/555' => $fixture,
    );

    my $volume = $cloud->volumes->get(555);

    # Test data method
    my $data = $volume->data;
    is($data->{id}, 555, 'data id');
    is($data->{name}, 'my-data', 'data name');
    is($data->{size}, 50, 'data size');
};

done_testing;

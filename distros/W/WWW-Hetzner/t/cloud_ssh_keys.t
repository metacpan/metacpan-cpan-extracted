#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use lib 't/lib';

use Test::WWW::Hetzner::Mock;

subtest 'list ssh keys' => sub {
    my $fixture = load_fixture('ssh_keys_list');

    my $cloud = mock_cloud(
        'GET /ssh_keys' => $fixture,
    );

    my $keys = $cloud->ssh_keys->list;

    is(ref $keys, 'ARRAY', 'returns array');
    is(scalar @$keys, 1, 'one key');
    isa_ok($keys->[0], 'WWW::Hetzner::Cloud::SSHKey');
    is($keys->[0]->id, 2323, 'key id');
    is($keys->[0]->name, 'ocp-omnicorp', 'key name');
};

subtest 'get ssh key by name' => sub {
    my $fixture = load_fixture('ssh_keys_list');

    my $cloud = mock_cloud(
        'GET /ssh_keys' => $fixture,
    );

    my $key = $cloud->ssh_keys->get_by_name('ocp-omnicorp');

    isa_ok($key, 'WWW::Hetzner::Cloud::SSHKey');
    is($key->id, 2323, 'key id');
    is($key->name, 'ocp-omnicorp', 'key name');
};

subtest 'create ssh key' => sub {
    my $cloud = mock_cloud(
        'POST /ssh_keys' => sub {
            my ($method, $path, %opts) = @_;
            my $body = $opts{body};

            is($body->{name}, 'my-key', 'name in request');
            like($body->{public_key}, qr/^ssh-rsa/, 'public_key in request');

            return {
                ssh_key => {
                    id         => 9999,
                    name       => $body->{name},
                    public_key => $body->{public_key},
                },
            };
        },
    );

    my $key = $cloud->ssh_keys->create(
        name       => 'my-key',
        public_key => 'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQ...',
    );

    isa_ok($key, 'WWW::Hetzner::Cloud::SSHKey');
    is($key->id, 9999, 'new key id');
    is($key->name, 'my-key', 'new key name');
};

subtest 'ensure ssh key - creates when missing' => sub {
    my $created = 0;

    my $cloud = mock_cloud(
        'GET /ssh_keys' => { ssh_keys => [] },
        'POST /ssh_keys' => sub {
            $created = 1;
            return {
                ssh_key => {
                    id         => 9999,
                    name       => 'my-key',
                    public_key => 'ssh-rsa AAAAB3...',
                },
            };
        },
    );

    my $key = $cloud->ssh_keys->ensure('my-key', 'ssh-rsa AAAAB3...');

    ok($created, 'create was called');
    isa_ok($key, 'WWW::Hetzner::Cloud::SSHKey');
    is($key->id, 9999, 'key id');
};

subtest 'ensure ssh key - returns existing when matches' => sub {
    my $fixture = {
        ssh_keys => [{
            id         => 2323,
            name       => 'my-key',
            public_key => 'ssh-rsa AAAAB3...',
        }],
    };

    my $cloud = mock_cloud(
        'GET /ssh_keys' => $fixture,
    );

    my $key = $cloud->ssh_keys->ensure('my-key', 'ssh-rsa AAAAB3...');

    isa_ok($key, 'WWW::Hetzner::Cloud::SSHKey');
    is($key->id, 2323, 'existing key returned');
};

subtest 'get ssh key by id' => sub {
    my $fixture = load_fixture('ssh_keys_get');

    my $cloud = mock_cloud(
        'GET /ssh_keys/2323' => $fixture,
    );

    my $key = $cloud->ssh_keys->get(2323);

    isa_ok($key, 'WWW::Hetzner::Cloud::SSHKey');
    is($key->id, 2323, 'key id');
    is($key->name, 'ocp-omnicorp', 'key name');
};

subtest 'update ssh key' => sub {
    my $cloud = mock_cloud(
        'PUT /ssh_keys/2323' => sub {
            my ($method, $path, %opts) = @_;
            is($opts{body}{name}, 'new-name', 'name in request');
            return {
                ssh_key => {
                    id   => 2323,
                    name => 'new-name',
                },
            };
        },
    );

    my $key = $cloud->ssh_keys->update(2323, name => 'new-name');

    isa_ok($key, 'WWW::Hetzner::Cloud::SSHKey');
    is($key->name, 'new-name', 'key renamed');
};

subtest 'delete ssh key' => sub {
    my $cloud = mock_cloud(
        'DELETE /ssh_keys/2323' => {},
    );

    my $result = $cloud->ssh_keys->delete(2323);
    ok(1, 'delete succeeded');
};

done_testing;

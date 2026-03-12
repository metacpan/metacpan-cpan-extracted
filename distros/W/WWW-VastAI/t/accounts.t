#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use lib 't/lib';

use Test::WWW::VastAI::Mock;

subtest 'account resources cover keys, env vars, user and invoices' => sub {
    my $vast = mock_vast(
        'GET /ssh/' => {
            ssh_keys => [
                { id => 1, public_key => 'ssh-ed25519 AAAA test@host' },
            ],
        },
        'POST /ssh/' => {
            ssh_key => { id => 2, public_key => 'ssh-ed25519 BBBB second@host' },
        },
        'PUT /ssh/1/' => sub {
            my ($method, $path, %opts) = @_;
            is($opts{body}{ssh_key}, 'ssh-ed25519 CCCC updated@host', 'ssh update body');
            return {
                ssh_key => { id => 1, public_key => 'ssh-ed25519 CCCC updated@host' },
            };
        },
        'DELETE /ssh/1/' => { success => 1 },
        'GET /auth/apikeys/' => {
            api_keys => [
                { id => 77, key => 'vast_123', permissions => ['read'] },
            ],
        },
        'POST /auth/apikeys/' => sub {
            my ($method, $path, %opts) = @_;
            is($opts{body}{name}, 'ci', 'api key name forwarded');
            return {
                api_key => {
                    id          => 78,
                    key         => 'vast_456',
                    permissions => ['read', 'write'],
                },
            };
        },
        'DELETE /auth/apikeys/77/' => { success => 1 },
        'GET /users/current/' => {
            user => {
                id      => 99,
                email   => 'ops@example.invalid',
                balance => 123.45,
                sid     => 'user-99',
            },
        },
        'GET /secrets/' => {
            secrets => {
                HF_TOKEN => 'secret',
            },
        },
        'POST /secrets/' => sub {
            my ($method, $path, %opts) = @_;
            is($opts{body}{name}, 'HF_TOKEN', 'env name forwarded');
            is($opts{body}{value}, 'new-secret', 'env value forwarded');
            return { success => 1 };
        },
        'PUT /secrets/' => { success => 1 },
        'DELETE /secrets/' => sub {
            my ($method, $path, %opts) = @_;
            is($opts{body}{name}, 'HF_TOKEN', 'env delete uses body');
            return { success => 1 };
        },
        'GET /invoices/' => {
            invoices => [
                { id => 'inv_1', description => 'GPU usage', amount => '42.00', type => 'charge' },
            ],
        },
    );

    my $ssh_keys = $vast->ssh_keys->list;
    isa_ok($ssh_keys->[0], 'WWW::VastAI::SSHKey');
    is($ssh_keys->[0]->id, 1, 'ssh key id');

    my $new_ssh = $vast->ssh_keys->create('ssh-ed25519 BBBB second@host');
    is($new_ssh->id, 2, 'created ssh key wrapped');

    my $updated_ssh = $ssh_keys->[0]->update('ssh-ed25519 CCCC updated@host');
    like($updated_ssh->key, qr/updated/, 'object update refreshes key');
    ok($ssh_keys->[0]->delete->{success}, 'ssh key delete');

    my $api_keys = $vast->api_keys->list;
    isa_ok($api_keys->[0], 'WWW::VastAI::APIKey');

    my $api_key = $vast->api_keys->create(
        name        => 'ci',
        permissions => ['read', 'write'],
    );
    is($api_key->id, 78, 'api key created');
    ok($api_keys->[0]->delete->{success}, 'api key deleted');

    my $user = $vast->user->current;
    isa_ok($user, 'WWW::VastAI::User');
    is($user->email, 'ops@example.invalid', 'user email');

    my $secrets = $vast->env_vars->list;
    is($secrets->{HF_TOKEN}, 'secret', 'env vars listed');
    ok($vast->env_vars->create(name => 'HF_TOKEN', value => 'new-secret')->{success}, 'env var create');
    ok($vast->env_vars->update(name => 'HF_TOKEN', value => 'rotated')->{success}, 'env var update');
    ok($vast->env_vars->delete('HF_TOKEN')->{success}, 'env var delete');

    my $invoices = $vast->invoices->list(limit => 5);
    isa_ok($invoices->[0], 'WWW::VastAI::Invoice');
    is($invoices->[0]->description, 'GPU usage', 'invoice wrapped');
};

done_testing;

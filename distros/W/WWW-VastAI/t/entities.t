#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;

use WWW::VastAI::APIKey;
use WWW::VastAI::Endpoint;
use WWW::VastAI::Invoice;
use WWW::VastAI::Object;
use WWW::VastAI::Offer;
use WWW::VastAI::SSHKey;
use WWW::VastAI::Template;
use WWW::VastAI::User;
use WWW::VastAI::Volume;
use WWW::VastAI::Workergroup;

my $client = bless {}, 'Test::WWW::VastAI::Client';

subtest 'base object keeps id and raw payload' => sub {
    my $object = WWW::VastAI::Object->new(
        client => $client,
        data   => {
            id    => 17,
            label => 'payload',
        },
    );

    is($object->id, 17, 'id accessor reads payload id');
    is($object->raw->{label}, 'payload', 'raw returns payload hashref');
};

subtest 'simple entity accessors expose payload fields' => sub {
    my $offer = WWW::VastAI::Offer->new(
        client => $client,
        data   => {
            id         => 7001,
            gpu_name   => 'RTX_4090',
            num_gpus   => 2,
            dph_total  => 0.89,
            machine_id => 42,
        },
    );
    is($offer->ask_contract_id, 7001, 'offer id falls back to id');
    is($offer->gpu_name, 'RTX_4090', 'offer gpu name');
    is($offer->num_gpus, 2, 'offer gpu count');
    is($offer->dph_total, 0.89, 'offer hourly price');
    is($offer->machine_id, 42, 'offer machine id');

    my $ssh_key = WWW::VastAI::SSHKey->new(
        client => $client,
        data   => {
            id         => 88,
            public_key => 'ssh-ed25519 AAAA test@unit',
            created_at => '2026-03-12T10:00:00Z',
        },
    );
    like($ssh_key->key, qr/^ssh-ed25519 /, 'ssh key falls back to public_key');
    is($ssh_key->created_at, '2026-03-12T10:00:00Z', 'ssh key creation time');

    my $template = WWW::VastAI::Template->new(
        client => $client,
        data   => {
            id      => 11,
            hash_id => 'tmpl-11',
            name    => 'CUDA 12',
            image   => 'nvidia/cuda:12.4.1-base',
        },
    );
    is($template->hash_id, 'tmpl-11', 'template hash id');
    is($template->name, 'CUDA 12', 'template name');
    like($template->image, qr/cuda/, 'template image');

    my $volume = WWW::VastAI::Volume->new(
        client => $client,
        data   => {
            id            => 3001,
            status        => 'ready',
            machine_id    => 55,
            public_ipaddr => '198.51.100.8',
        },
    );
    is($volume->status, 'ready', 'volume status');
    is($volume->machine_id, 55, 'volume machine id');
    is($volume->public_ipaddr, '198.51.100.8', 'volume public ip');

    my $endpoint = WWW::VastAI::Endpoint->new(
        client => $client,
        data   => {
            id             => 501,
            endpoint_name  => 'llama-prod',
            endpoint_state => 'running',
            api_key        => 'endpoint-token',
        },
    );
    is($endpoint->endpoint_name, 'llama-prod', 'endpoint name');
    is($endpoint->endpoint_state, 'running', 'endpoint state');
    is($endpoint->api_key, 'endpoint-token', 'endpoint api key');

    my $workergroup = WWW::VastAI::Workergroup->new(
        client => $client,
        data   => {
            id            => 801,
            endpoint_id   => 501,
            endpoint_name => 'llama-prod',
            template_hash => 'tmpl-prod',
            api_key       => 'group-token',
        },
    );
    is($workergroup->endpoint_id, 501, 'workergroup endpoint id');
    is($workergroup->endpoint_name, 'llama-prod', 'workergroup endpoint name');
    is($workergroup->template_hash, 'tmpl-prod', 'workergroup template hash');
    is($workergroup->api_key, 'group-token', 'workergroup api key');

    my $api_key = WWW::VastAI::APIKey->new(
        client => $client,
        data   => {
            id          => 77,
            key         => 'vast_123',
            rights      => 'read',
            permissions => ['read', 'write'],
        },
    );
    is($api_key->key, 'vast_123', 'api key token');
    is($api_key->rights, 'read', 'api key rights');
    is_deeply($api_key->permissions, ['read', 'write'], 'api key permissions');

    my $user = WWW::VastAI::User->new(
        client => $client,
        data   => {
            id      => 99,
            email   => 'ops@example.invalid',
            balance => 123.45,
            ssh_key => 'ssh-ed25519 AAAA ops@unit',
            sid     => 'user-99',
        },
    );
    is($user->email, 'ops@example.invalid', 'user email');
    is($user->balance, 123.45, 'user balance');
    like($user->ssh_key, qr/^ssh-ed25519 /, 'user ssh key');
    is($user->sid, 'user-99', 'user sid');

    my $invoice = WWW::VastAI::Invoice->new(
        client => $client,
        data   => {
            id          => 'inv_1',
            type        => 'charge',
            source      => 'instance',
            description => 'GPU usage',
            amount      => '42.00',
        },
    );
    is($invoice->type, 'charge', 'invoice type');
    is($invoice->source, 'instance', 'invoice source');
    is($invoice->description, 'GPU usage', 'invoice description');
    is($invoice->amount, '42.00', 'invoice amount');
};

done_testing;

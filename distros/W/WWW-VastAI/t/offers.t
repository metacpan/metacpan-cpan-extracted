#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use lib 't/lib';

use Test::WWW::VastAI::Mock;

subtest 'search offers wraps marketplace data' => sub {
    my $vast = mock_vast(
        'POST /bundles/' => sub {
            my ($method, $path, %opts) = @_;
            is($opts{body}{limit}, 2, 'limit forwarded');
            is($opts{body}{type}, 'on-demand', 'filter forwarded');
            return [
                {
                    ask_contract_id => 7001,
                    gpu_name        => 'RTX_4090',
                    num_gpus        => 2,
                    dph_total       => 0.89,
                    machine_id      => 42,
                },
            ];
        },
        'PUT /asks/7001/' => {
            new_contract => {
                id            => 991,
                label         => 'offer-born',
                actual_status => 'running',
                ssh_host      => '198.51.100.24',
                ssh_port      => 41100,
            },
        },
    );

    my $offers = $vast->offers->search(
        limit => 2,
        type  => 'on-demand',
    );

    is(ref $offers, 'ARRAY', 'returns arrayref');
    is(scalar @{$offers}, 1, 'one offer');
    isa_ok($offers->[0], 'WWW::VastAI::Offer');
    is($offers->[0]->ask_contract_id, 7001, 'offer id accessor');
    is($offers->[0]->gpu_name, 'RTX_4090', 'gpu accessor');

    my $instance = $offers->[0]->create_instance(
        image   => 'vastai/base',
        disk    => 32,
        runtype => 'ssh',
    );
    isa_ok($instance, 'WWW::VastAI::Instance');
    is($instance->id, 991, 'instance created from offer');
};

done_testing;

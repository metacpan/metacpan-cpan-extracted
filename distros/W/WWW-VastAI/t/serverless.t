#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use lib 't/lib';

use Test::WWW::VastAI::Mock;

subtest 'serverless endpoints and workergroups' => sub {
    my $vast = mock_vast(
        'GET /endptjobs/' => {
            endpoints => [
                {
                    id             => 501,
                    endpoint_name  => 'llama-prod',
                    endpoint_state => 'running',
                },
            ],
        },
        'POST /endptjobs/' => sub {
            my ($method, $path, %opts) = @_;
            is($opts{body}{endpoint_name}, 'llama-dev', 'endpoint name forwarded');
            return {
                endpoint => {
                    id             => 502,
                    endpoint_name  => 'llama-dev',
                    endpoint_state => 'pending',
                },
            };
        },
        'DELETE /endptjobs/501/' => { success => 1 },
        'POST /get_endpoint_workers/' => sub {
            my ($method, $path, %opts) = @_;
            is($opts{body}{endpoint_id}, 501, 'endpoint workers body');
            return { workers => [ { machine_id => 7 } ] };
        },
        'POST /get_endpoint_logs/' => sub {
            my ($method, $path, %opts) = @_;
            is($opts{body}{endpoint_name}, 'llama-prod', 'endpoint logs body');
            return { logs => "boot ok\n" };
        },
        'GET /workergroups/' => {
            workergroups => [
                {
                    id            => 801,
                    endpoint_name => 'llama-prod',
                    template_hash => 'tmpl-prod',
                },
            ],
        },
        'POST /workergroups/' => sub {
            my ($method, $path, %opts) = @_;
            is($opts{body}{template_hash}, 'tmpl-dev', 'template hash forwarded');
            return {
                workergroup => {
                    id            => 802,
                    endpoint_name => 'llama-dev',
                    template_hash => 'tmpl-dev',
                },
            };
        },
        'PUT /workergroups/801/' => sub {
            my ($method, $path, %opts) = @_;
            is($opts{body}{template_hash}, 'tmpl-prod-2', 'workergroup update body');
            return {
                workergroup => {
                    id            => 801,
                    endpoint_name => 'llama-prod',
                    template_hash => 'tmpl-prod-2',
                },
            };
        },
        'DELETE /workergroups/801/' => { success => 1 },
        'POST /get_workergroup_workers/' => sub {
            my ($method, $path, %opts) = @_;
            is($opts{body}{workergroup_id}, 801, 'workergroup workers body');
            return { workers => [ { machine_id => 99 } ] };
        },
        'POST /get_workergroup_logs/' => sub {
            my ($method, $path, %opts) = @_;
            is($opts{body}{workergroup_id}, 801, 'workergroup logs body');
            return { logs => "worker ready\n" };
        },
    );

    my $endpoints = $vast->endpoints->list;
    isa_ok($endpoints->[0], 'WWW::VastAI::Endpoint');
    is($endpoints->[0]->endpoint_name, 'llama-prod', 'endpoint list wraps data');
    is($endpoints->[0]->workers->{workers}[0]{machine_id}, 7, 'endpoint workers');
    like($endpoints->[0]->logs->{logs}, qr/boot ok/, 'endpoint logs');
    ok($endpoints->[0]->delete->{success}, 'endpoint delete');

    my $created_endpoint = $vast->endpoints->create(
        endpoint_name => 'llama-dev',
        min_load      => 0,
        target_util   => 0.7,
    );
    is($created_endpoint->id, 502, 'endpoint create');

    my $groups = $vast->workergroups->list;
    isa_ok($groups->[0], 'WWW::VastAI::Workergroup');
    is($groups->[0]->workers->{workers}[0]{machine_id}, 99, 'workergroup workers');
    like($groups->[0]->logs->{logs}, qr/worker ready/, 'workergroup logs');

    my $created_group = $vast->workergroups->create(
        endpoint_name => 'llama-dev',
        template_hash => 'tmpl-dev',
    );
    is($created_group->id, 802, 'workergroup create');

    my $updated_group = $groups->[0]->update(template_hash => 'tmpl-prod-2');
    is($updated_group->template_hash, 'tmpl-prod-2', 'workergroup update');
    ok($groups->[0]->delete->{success}, 'workergroup delete');
};

done_testing;

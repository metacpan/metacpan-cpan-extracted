#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use lib 't/lib';

use Test::WWW::VastAI::Mock;

subtest 'volumes list create and delete' => sub {
    my $vast = mock_vast(
        'GET /volumes/' => {
            volumes => [
                {
                    id            => 3001,
                    status        => 'ready',
                    machine_id    => 55,
                    public_ipaddr => '198.51.100.8',
                },
            ],
        },
        'PUT /volumes/' => sub {
            my ($method, $path, %opts) = @_;
            is($opts{body}{size}, 150, 'size forwarded');
            is($opts{body}{label}, 'training-cache', 'label forwarded');
            return {
                volume => {
                    id            => 3002,
                    status        => 'creating',
                    machine_id    => 56,
                    public_ipaddr => '198.51.100.9',
                },
            };
        },
        'DELETE /volumes/' => sub {
            my ($method, $path, %opts) = @_;
            is($opts{body}{id}, 3001, 'delete sends id body');
            return { success => 1 };
        },
    );

    my $volumes = $vast->volumes->list;
    isa_ok($volumes->[0], 'WWW::VastAI::Volume');
    is($volumes->[0]->status, 'ready', 'volume status');

    my $created = $vast->volumes->create(
        size  => 150,
        label => 'training-cache',
    );
    is($created->id, 3002, 'created volume wrapped');
    ok($volumes->[0]->delete->{success}, 'object delete works');
};

done_testing;

#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use lib 't/lib';

use Test::WWW::VastAI::Mock;

subtest 'templates use query and body mapping' => sub {
    my $vast = mock_vast(
        'GET /template/' => {
            templates => [
                {
                    id      => 11,
                    hash_id => 'tmpl-hash-1',
                    name    => 'CUDA 12',
                    image   => 'nvidia/cuda:12.4.1-base',
                },
            ],
        },
        'POST /template/' => sub {
            my ($method, $path, %opts) = @_;
            is($opts{body}{name}, 'Python 3.12', 'name forwarded');
            is($opts{body}{image}, 'python:3.12-slim', 'image forwarded');
            return {
                template => {
                    id      => 12,
                    hash_id => 'tmpl-hash-2',
                    name    => 'Python 3.12',
                    image   => 'python:3.12-slim',
                },
            };
        },
        'PUT /template/' => sub {
            my ($method, $path, %opts) = @_;
            is($opts{body}{hash_id}, 'tmpl-hash-1', 'hash id forwarded');
            is($opts{body}{image}, 'python:3.13-slim', 'update payload forwarded');
            return {
                template => {
                    id      => 11,
                    hash_id => 'tmpl-hash-1',
                    name    => 'CUDA 12',
                    image   => 'python:3.13-slim',
                },
            };
        },
        'DELETE /template/' => sub {
            my ($method, $path, %opts) = @_;
            is($opts{body}{id}, 11, 'delete sends id body');
            return { success => 1 };
        },
    );

    my $templates = $vast->templates->list(
        select_filters => { use_ssh => { eq => \1 } },
        order_by       => [['created_at', 'desc']],
    );
    is(scalar @{$templates}, 1, 'template list wrapped');
    isa_ok($templates->[0], 'WWW::VastAI::Template');

    my $created = $vast->templates->create(
        name  => 'Python 3.12',
        image => 'python:3.12-slim',
    );
    is($created->hash_id, 'tmpl-hash-2', 'created template wrapped');

    my $updated = $templates->[0]->update(image => 'python:3.13-slim');
    is($updated->image, 'python:3.13-slim', 'object update works');

    ok($templates->[0]->delete->{success}, 'object delete works');
};

done_testing;

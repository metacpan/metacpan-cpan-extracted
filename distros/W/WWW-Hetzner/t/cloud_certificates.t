#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use lib 't/lib';

use Test::WWW::Hetzner::Mock;

subtest 'list certificates' => sub {
    my $fixture = load_fixture('certificates_list');

    my $cloud = mock_cloud(
        'GET /certificates' => $fixture,
    );

    my $certs = $cloud->certificates->list;

    is(ref $certs, 'ARRAY', 'returns array');
    is(scalar @$certs, 1, 'one certificate');
    isa_ok($certs->[0], 'WWW::Hetzner::Cloud::Certificate');
    is($certs->[0]->id, 1100, 'certificate id');
    is($certs->[0]->name, 'my-cert', 'certificate name');
    is($certs->[0]->type, 'managed', 'certificate type');
    ok($certs->[0]->is_managed, 'is_managed');
};

subtest 'get certificate' => sub {
    my $fixture = load_fixture('certificates_get');

    my $cloud = mock_cloud(
        '/certificates/1100' => $fixture,
    );

    my $cert = $cloud->certificates->get(1100);

    isa_ok($cert, 'WWW::Hetzner::Cloud::Certificate');
    is($cert->id, 1100, 'certificate id');
    is(scalar @{$cert->domain_names}, 2, 'two domains');
};

subtest 'create certificate' => sub {
    my $fixture = load_fixture('certificates_create');

    my $cloud = mock_cloud(
        'POST /certificates' => sub {
            my ($method, $path, %opts) = @_;
            my $body = $opts{body};
            is($body->{name}, 'new-cert', 'name in request');
            is($body->{type}, 'managed', 'type in request');
            return $fixture;
        },
    );

    my $cert = $cloud->certificates->create(
        name         => 'new-cert',
        type         => 'managed',
        domain_names => ['test.example.com'],
    );

    isa_ok($cert, 'WWW::Hetzner::Cloud::Certificate');
    is($cert->id, 1200, 'new certificate id');
};

subtest 'delete certificate' => sub {
    my $cloud = mock_cloud(
        'DELETE /certificates/1100' => {},
    );

    $cloud->certificates->delete(1100);
    ok(1, 'delete succeeded');
};

done_testing;

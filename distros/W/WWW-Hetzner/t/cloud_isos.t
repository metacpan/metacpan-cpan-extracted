#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use lib 't/lib';

use Test::WWW::Hetzner::Mock;
use WWW::Hetzner::Cloud;

# MockIO that also records the request URLs, so the filter parameters the ISO
# controller sends can be asserted -- MockIO strips the query string before
# route matching, so a route callback never sees them.
{
    package Test::ISOs::CapturingIO;
    use Moo;
    extends 'Test::WWW::Hetzner::MockIO';

    has urls => (is => 'ro', default => sub { [] });

    around call => sub {
        my ($orig, $self, $req) = @_;
        push @{ $self->urls }, $req->url;
        return $self->$orig($req);
    };
}

sub capturing_cloud {
    my (%routes) = @_;

    my $io = Test::ISOs::CapturingIO->new(
        routes   => \%routes,
        base_url => 'https://api.hetzner.cloud/v1',
    );

    return ($io, WWW::Hetzner::Cloud->new(token => 'test-token', io => $io));
}

subtest 'list isos' => sub {
    my $fixture = load_fixture('isos_list');

    my $cloud = mock_cloud(
        'GET /isos' => $fixture,
    );

    my $isos = $cloud->isos->list;

    is(ref $isos, 'ARRAY', 'returns array');
    is(scalar @$isos, 3, 'three isos');
    isa_ok($isos->[0], 'WWW::Hetzner::Cloud::ISO');
    is($isos->[0]->id, 4711, 'iso id');
    is($isos->[0]->name, 'netboot.xyz.iso', 'iso name');
    is($isos->[0]->description, 'netboot.xyz', 'iso description');
    is($isos->[0]->type, 'public', 'iso type');
    is($isos->[0]->architecture, 'x86', 'iso architecture');
    ok(!defined $isos->[0]->deprecation, 'not deprecated');
};

subtest 'list isos with filters' => sub {
    my $fixture = load_fixture('isos_list');

    my ($io, $cloud) = capturing_cloud(
        'GET /isos' => $fixture,
    );

    $cloud->isos->list(architecture => 'arm');

    like($io->urls->[0], qr{/isos\?}, 'query string appended');
    like($io->urls->[0], qr{architecture=arm}, 'architecture filter sent to the API');
};

subtest 'deprecated iso' => sub {
    my $fixture = load_fixture('isos_list');

    my $cloud = mock_cloud(
        'GET /isos' => $fixture,
    );

    my $iso = $cloud->isos->list->[2];

    is($iso->name, 'FreeBSD-11.0-RELEASE-amd64-dvd1', 'deprecated iso name');
    is($iso->deprecation->{unavailable_after}, '2023-09-01T00:00:00+00:00',
        'deprecation unavailable_after');
    is($iso->deprecation->{announced}, '2023-06-01T00:00:00+00:00',
        'deprecation announced');
};

subtest 'get iso by id' => sub {
    my $fixture = load_fixture('isos_get');

    my $cloud = mock_cloud(
        'GET /isos/4711' => $fixture,
    );

    my $iso = $cloud->isos->get(4711);

    isa_ok($iso, 'WWW::Hetzner::Cloud::ISO');
    is($iso->id, 4711, 'iso id');
    is($iso->name, 'netboot.xyz.iso', 'iso name');
    is($iso->architecture, 'x86', 'iso architecture');
};

subtest 'get iso by id - id required' => sub {
    my $cloud = mock_cloud();

    eval { $cloud->isos->get };
    like($@, qr/ISO ID required/, 'croaks without id');
};

subtest 'get iso by name filters server-side' => sub {
    my $fixture = load_fixture('isos_list');

    my ($io, $cloud) = capturing_cloud(
        'GET /isos' => $fixture,
    );

    my $iso = $cloud->isos->get_by_name('netboot.xyz-arm64.iso');

    isa_ok($iso, 'WWW::Hetzner::Cloud::ISO');
    is($iso->id, 4712, 'iso id');
    is($iso->architecture, 'arm', 'iso architecture');
    like($io->urls->[0], qr{name=netboot\.xyz-arm64\.iso},
        'name filter sent to the API rather than scanning a paginated list');
};

subtest 'get iso by name - not found' => sub {
    my $fixture = load_fixture('isos_list');

    my $cloud = mock_cloud(
        'GET /isos' => $fixture,
    );

    my $iso = $cloud->isos->get_by_name('nonexistent.iso');

    ok(!defined $iso, 'returns undef for not found');
};

subtest 'iso data' => sub {
    my $fixture = load_fixture('isos_get');

    my $cloud = mock_cloud(
        'GET /isos/4711' => $fixture,
    );

    my $data = $cloud->isos->get(4711)->data;

    is(ref $data, 'HASH', 'data returns hashref');
    is($data->{id}, 4711, 'data id');
    is($data->{name}, 'netboot.xyz.iso', 'data name');
    is($data->{type}, 'public', 'data type');
    ok(exists $data->{deprecation}, 'data carries deprecation');
};

done_testing;

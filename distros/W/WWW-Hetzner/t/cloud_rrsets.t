#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use lib 't/lib';

use Test::WWW::Hetzner::Mock;

subtest 'list rrsets' => sub {
    my $fixture = load_fixture('rrsets_list');

    my $cloud = mock_cloud(
        'GET /zones/zone123456/rrsets' => $fixture,
    );

    my $rrsets = $cloud->zones->rrsets('zone123456');
    my $records = $rrsets->list;

    is(ref $records, 'ARRAY', 'returns array');
    is(scalar @$records, 5, 'five rrsets');
    is($records->[0]{name}, '@', 'first record name');
    is($records->[0]{type}, 'A', 'first record type');
};

subtest 'list rrsets with filter' => sub {
    my $fixture = load_fixture('rrsets_list');

    my $cloud = mock_cloud(
        'GET /zones/zone123456/rrsets' => $fixture,
    );

    my $rrsets = $cloud->zones->rrsets('zone123456');
    my $records = $rrsets->list(type => 'A');

    is(ref $records, 'ARRAY', 'returns array');
};

subtest 'get rrset' => sub {
    my $fixture = load_fixture('rrsets_get');

    my $cloud = mock_cloud(
        '/zones/zone123456/rrsets/www/A' => $fixture,
    );

    my $rrsets = $cloud->zones->rrsets('zone123456');
    my $record = $rrsets->get('www', 'A');

    is($record->{name}, 'www', 'record name');
    is($record->{type}, 'A', 'record type');
    is($record->{records}[0]{value}, '203.0.113.10', 'record value');
};

subtest 'create rrset' => sub {
    my $fixture = load_fixture('rrsets_create');

    my $cloud = mock_cloud(
        'POST /zones/zone123456/rrsets' => sub {
            my ($method, $path, %opts) = @_;
            my $body = $opts{body};

            is($body->{name}, 'api', 'name in request');
            is($body->{type}, 'A', 'type in request');
            is($body->{records}[0]{value}, '203.0.113.20', 'value in request');

            return $fixture;
        },
    );

    my $rrsets = $cloud->zones->rrsets('zone123456');
    my $record = $rrsets->create(
        name    => 'api',
        type    => 'A',
        records => [{ value => '203.0.113.20' }],
    );

    is($record->{name}, 'api', 'new record name');
    is($record->{type}, 'A', 'new record type');
};

subtest 'update rrset' => sub {
    my $fixture = load_fixture('rrsets_update');

    my $cloud = mock_cloud(
        'PUT /zones/zone123456/rrsets/www/A' => sub {
            my ($method, $path, %opts) = @_;
            is($opts{body}{ttl}, 600, 'ttl in request');
            return $fixture;
        },
    );

    my $rrsets = $cloud->zones->rrsets('zone123456');
    my $record = $rrsets->update('www', 'A',
        ttl     => 600,
        records => [{ value => '203.0.113.30' }],
    );

    is($record->{ttl}, 600, 'ttl updated');
};

subtest 'delete rrset' => sub {
    my $cloud = mock_cloud(
        'DELETE /zones/zone123456/rrsets/www/A' => {},
    );

    my $rrsets = $cloud->zones->rrsets('zone123456');
    my $result = $rrsets->delete('www', 'A');
    ok(1, 'delete succeeded');
};

subtest 'create rrset requires params' => sub {
    my $cloud = mock_cloud();
    my $rrsets = $cloud->zones->rrsets('zone123456');

    eval { $rrsets->create() };
    like($@, qr/name required/, 'name required');

    eval { $rrsets->create(name => 'test') };
    like($@, qr/type required/, 'type required');

    eval { $rrsets->create(name => 'test', type => 'A') };
    like($@, qr/records required/, 'records required');
};

subtest 'add_a convenience method' => sub {
    my $fixture = load_fixture('rrsets_create');

    my $cloud = mock_cloud(
        'POST /zones/zone123456/rrsets' => sub {
            my ($method, $path, %opts) = @_;
            my $body = $opts{body};

            is($body->{type}, 'A', 'type is A');
            is($body->{records}[0]{value}, '203.0.113.20', 'IP address');

            return $fixture;
        },
    );

    my $rrsets = $cloud->zones->rrsets('zone123456');
    my $record = $rrsets->add_a('api', '203.0.113.20');

    is($record->{type}, 'A', 'created A record');
};

subtest 'add_aaaa convenience method' => sub {
    my $fixture = {
        rrset => {
            name    => 'api',
            type    => 'AAAA',
            ttl     => 300,
            records => [{ value => '2001:db8::1' }],
        },
    };

    my $cloud = mock_cloud(
        'POST /zones/zone123456/rrsets' => sub {
            my ($method, $path, %opts) = @_;
            my $body = $opts{body};

            is($body->{type}, 'AAAA', 'type is AAAA');

            return $fixture;
        },
    );

    my $rrsets = $cloud->zones->rrsets('zone123456');
    my $record = $rrsets->add_aaaa('api', '2001:db8::1');

    is($record->{type}, 'AAAA', 'created AAAA record');
};

subtest 'add_cname convenience method' => sub {
    my $fixture = {
        rrset => {
            name    => 'blog',
            type    => 'CNAME',
            ttl     => 300,
            records => [{ value => 'www.example.com.' }],
        },
    };

    my $cloud = mock_cloud(
        'POST /zones/zone123456/rrsets' => sub {
            my ($method, $path, %opts) = @_;
            my $body = $opts{body};

            is($body->{type}, 'CNAME', 'type is CNAME');
            is($body->{records}[0]{value}, 'www.example.com.', 'target');

            return $fixture;
        },
    );

    my $rrsets = $cloud->zones->rrsets('zone123456');
    my $record = $rrsets->add_cname('blog', 'www.example.com.');

    is($record->{type}, 'CNAME', 'created CNAME record');
};

subtest 'add_mx convenience method' => sub {
    my $fixture = {
        rrset => {
            name    => '@',
            type    => 'MX',
            ttl     => 300,
            records => [{ value => '10 mail.example.com.' }],
        },
    };

    my $cloud = mock_cloud(
        'POST /zones/zone123456/rrsets' => sub {
            my ($method, $path, %opts) = @_;
            my $body = $opts{body};

            is($body->{type}, 'MX', 'type is MX');
            is($body->{records}[0]{value}, '10 mail.example.com.', 'priority and mailserver');

            return $fixture;
        },
    );

    my $rrsets = $cloud->zones->rrsets('zone123456');
    my $record = $rrsets->add_mx('@', 'mail.example.com.', 10);

    is($record->{type}, 'MX', 'created MX record');
};

subtest 'add_txt convenience method' => sub {
    my $fixture = {
        rrset => {
            name    => '@',
            type    => 'TXT',
            ttl     => 300,
            records => [{ value => 'v=spf1 ~all' }],
        },
    };

    my $cloud = mock_cloud(
        'POST /zones/zone123456/rrsets' => sub {
            my ($method, $path, %opts) = @_;
            my $body = $opts{body};

            is($body->{type}, 'TXT', 'type is TXT');

            return $fixture;
        },
    );

    my $rrsets = $cloud->zones->rrsets('zone123456');
    my $record = $rrsets->add_txt('@', 'v=spf1 ~all');

    is($record->{type}, 'TXT', 'created TXT record');
};

subtest 'get rrset requires name' => sub {
    my $cloud = mock_cloud();
    my $rrsets = $cloud->zones->rrsets('zone123456');

    eval { $rrsets->get() };
    like($@, qr/Record name required/, 'name required');
};

subtest 'get rrset requires type' => sub {
    my $cloud = mock_cloud();
    my $rrsets = $cloud->zones->rrsets('zone123456');

    eval { $rrsets->get('www') };
    like($@, qr/Record type required/, 'type required');
};

subtest 'delete rrset requires name' => sub {
    my $cloud = mock_cloud();
    my $rrsets = $cloud->zones->rrsets('zone123456');

    eval { $rrsets->delete() };
    like($@, qr/Record name required/, 'name required');
};

subtest 'delete rrset requires type' => sub {
    my $cloud = mock_cloud();
    my $rrsets = $cloud->zones->rrsets('zone123456');

    eval { $rrsets->delete('www') };
    like($@, qr/Record type required/, 'type required');
};

subtest 'update rrset requires name' => sub {
    my $cloud = mock_cloud();
    my $rrsets = $cloud->zones->rrsets('zone123456');

    eval { $rrsets->update() };
    like($@, qr/Record name required/, 'name required');
};

subtest 'update rrset requires type' => sub {
    my $cloud = mock_cloud();
    my $rrsets = $cloud->zones->rrsets('zone123456');

    eval { $rrsets->update('www') };
    like($@, qr/Record type required/, 'type required');
};

subtest 'add_a requires name' => sub {
    my $cloud = mock_cloud();
    my $rrsets = $cloud->zones->rrsets('zone123456');

    eval { $rrsets->add_a() };
    like($@, qr/name required/, 'name required');
};

subtest 'add_a requires ip' => sub {
    my $cloud = mock_cloud();
    my $rrsets = $cloud->zones->rrsets('zone123456');

    eval { $rrsets->add_a('www') };
    like($@, qr/IP address required/, 'ip required');
};

subtest 'add_aaaa requires name' => sub {
    my $cloud = mock_cloud();
    my $rrsets = $cloud->zones->rrsets('zone123456');

    eval { $rrsets->add_aaaa() };
    like($@, qr/name required/, 'name required');
};

subtest 'add_aaaa requires ip' => sub {
    my $cloud = mock_cloud();
    my $rrsets = $cloud->zones->rrsets('zone123456');

    eval { $rrsets->add_aaaa('www') };
    like($@, qr/IPv6 address required/, 'ipv6 required');
};

subtest 'add_cname requires name' => sub {
    my $cloud = mock_cloud();
    my $rrsets = $cloud->zones->rrsets('zone123456');

    eval { $rrsets->add_cname() };
    like($@, qr/name required/, 'name required');
};

subtest 'add_cname requires target' => sub {
    my $cloud = mock_cloud();
    my $rrsets = $cloud->zones->rrsets('zone123456');

    eval { $rrsets->add_cname('www') };
    like($@, qr/target required/, 'target required');
};

subtest 'add_mx requires name' => sub {
    my $cloud = mock_cloud();
    my $rrsets = $cloud->zones->rrsets('zone123456');

    eval { $rrsets->add_mx() };
    like($@, qr/name required/, 'name required');
};

subtest 'add_mx requires mailserver' => sub {
    my $cloud = mock_cloud();
    my $rrsets = $cloud->zones->rrsets('zone123456');

    eval { $rrsets->add_mx('@') };
    like($@, qr/mailserver required/, 'mailserver required');
};

subtest 'add_txt requires name' => sub {
    my $cloud = mock_cloud();
    my $rrsets = $cloud->zones->rrsets('zone123456');

    eval { $rrsets->add_txt() };
    like($@, qr/name required/, 'name required');
};

subtest 'add_txt requires value' => sub {
    my $cloud = mock_cloud();
    my $rrsets = $cloud->zones->rrsets('zone123456');

    eval { $rrsets->add_txt('@') };
    like($@, qr/value required/, 'value required');
};

subtest 'create with ttl' => sub {
    my $fixture = load_fixture('rrsets_create');

    my $cloud = mock_cloud(
        'POST /zones/zone123456/rrsets' => sub {
            my ($method, $path, %opts) = @_;
            my $body = $opts{body};

            is($body->{ttl}, 600, 'ttl in request');

            return $fixture;
        },
    );

    my $rrsets = $cloud->zones->rrsets('zone123456');
    my $record = $rrsets->create(
        name    => 'api',
        type    => 'A',
        ttl     => 600,
        records => [{ value => '203.0.113.20' }],
    );

    ok($record, 'record created with ttl');
};

subtest 'add_a with ttl' => sub {
    my $fixture = load_fixture('rrsets_create');

    my $cloud = mock_cloud(
        'POST /zones/zone123456/rrsets' => sub {
            my ($method, $path, %opts) = @_;
            my $body = $opts{body};

            is($body->{ttl}, 120, 'ttl in request');

            return $fixture;
        },
    );

    my $rrsets = $cloud->zones->rrsets('zone123456');
    my $record = $rrsets->add_a('api', '203.0.113.20', ttl => 120);

    ok($record, 'A record created with ttl');
};

done_testing;

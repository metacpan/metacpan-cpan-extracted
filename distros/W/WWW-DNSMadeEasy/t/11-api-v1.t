#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/lib";

use WWW::DNSMadeEasy;

my $dme;
my $using_mock = 0;
my $write_tests = $ENV{TEST_WWW_DNSMADEEASY_WRITE};

if ($ENV{TEST_WWW_DNSMADEEASY_API_KEY} && $ENV{TEST_WWW_DNSMADEEASY_API_SECRET}) {
    my $use_sandbox = $ENV{TEST_WWW_DNSMADEEASY_SANDBOX} ? 1 : 0;
    diag("Using LIVE API" . ($use_sandbox ? " (SANDBOX)" : ""));
    diag("Write tests: " . ($write_tests ? "ENABLED" : "disabled (set TEST_WWW_DNSMADEEASY_WRITE=1 to enable)"));

    $dme = WWW::DNSMadeEasy->new({
        api_key     => $ENV{TEST_WWW_DNSMADEEASY_API_KEY},
        secret      => $ENV{TEST_WWW_DNSMADEEASY_API_SECRET},
        api_version => '1.2',
        sandbox     => $use_sandbox,
    });
} else {
    diag("Using MockUA (set TEST_WWW_DNSMADEEASY_API_KEY and TEST_WWW_DNSMADEEASY_API_SECRET for live tests)");
    require MockUA;
    $using_mock = 1;

    $dme = WWW::DNSMadeEasy->new({
        api_key     => 'test-api-key',
        secret      => 'test-secret',
        api_version => '1.2',
    });
    $dme->{_http_agent} = MockUA->new(fixtures_dir => "$FindBin::Bin/fixtures");
}

isa_ok($dme, 'WWW::DNSMadeEasy');
is($dme->api_version, '1.2', 'api_version is 1.2');

# For live tests, we need a domain to test with
my $test_domain;
my $test_domain_name;
my $created_test_domain = 0;

if ($using_mock) {
    # Mock mode: use fixture domain
    $test_domain_name = 'example.com';
} elsif ($write_tests) {
    # Write mode: create a test domain
    $test_domain_name = 'test-' . time() . '.example';
    diag("Creating test domain: $test_domain_name");
    eval {
        $test_domain = $dme->create_domain($test_domain_name);
        $created_test_domain = 1;
        diag("Domain created");
    };
    if ($@) {
        diag("Failed to create test domain: $@");
        plan skip_all => "Cannot create test domain";
    }
} else {
    # Read-only mode: use first existing domain
    my @domains = $dme->all_domains;
    if (@domains) {
        $test_domain_name = $domains[0]->name;
        diag("Using existing domain for read tests: $test_domain_name");
    } else {
        plan skip_all => "No domains in account for read-only tests";
    }
}

# Cleanup handler for write tests
END {
    if ($created_test_domain && $test_domain) {
        diag("Cleaning up: deleting test domain $test_domain_name");
        eval { $test_domain->delete };
        if ($@) {
            diag("Cleanup error: $@");
        } else {
            diag("Test domain deleted successfully");
        }
    }
}

subtest 'all_domains' => sub {
    my @domains = $dme->all_domains;
    ok(@domains >= 0, 'all_domains returns list');
    if (@domains) {
        isa_ok($domains[0], 'WWW::DNSMadeEasy::Domain');
        ok(defined $domains[0]->name, 'domain has name');
    }
};

subtest 'domain' => sub {
    my $domain = $dme->domain($test_domain_name);
    isa_ok($domain, 'WWW::DNSMadeEasy::Domain');
    is($domain->name, $test_domain_name, 'domain name matches');

    # Save for later tests
    $test_domain = $domain unless $test_domain;
};

subtest 'domain attributes' => sub {
    my $domain = $dme->domain($test_domain_name);
    # These may or may not be defined depending on domain state
    ok($domain->can('name_server'), 'domain can name_server');
    ok($domain->can('gtd_enabled'), 'domain can gtd_enabled');
    ok($domain->can('vanity_name_servers'), 'domain can vanity_name_servers');
    ok($domain->can('vanity_id'), 'domain can vanity_id');
};

subtest 'domain records' => sub {
    my $domain = $dme->domain($test_domain_name);
    my @records = $domain->all_records;
    ok(@records >= 0, 'all_records returns list');
    if (@records) {
        isa_ok($records[0], 'WWW::DNSMadeEasy::Domain::Record');
        ok(defined $records[0]->id, 'record has id');
        ok(defined $records[0]->name, 'record has name');
        ok(defined $records[0]->type, 'record has type');
        ok(defined $records[0]->data, 'record has data');
        ok(defined $records[0]->ttl, 'record has ttl');
    }
};

subtest 'record attributes' => sub {
    plan skip_all => "No records to test" unless $using_mock;

    my $domain = $dme->domain($test_domain_name);
    my @records = $domain->all_records;

    plan skip_all => "No records in domain" unless @records;

    my $record = $records[0];

    # Test all accessor methods exist and don't crash
    ok($record->can('ttl'), 'record can ttl');
    ok($record->can('gtd_location'), 'record can gtd_location');
    ok($record->can('name'), 'record can name');
    ok($record->can('data'), 'record can data');
    ok($record->can('type'), 'record can type');
    ok($record->can('password'), 'record can password');
    ok($record->can('description'), 'record can description');
    ok($record->can('keywords'), 'record can keywords');
    ok($record->can('title'), 'record can title');
    ok($record->can('redirect_type'), 'record can redirect_type');
    ok($record->can('hard_link'), 'record can hard_link');
};

# Write tests - only run with TEST_WWW_DNSMADEEASY_WRITE=1
SKIP: {
    skip "Write tests disabled (set TEST_WWW_DNSMADEEASY_WRITE=1)", 1
        unless $write_tests || $using_mock;

    subtest 'create and delete record' => sub {
        my $domain = $dme->domain($test_domain_name);

        my $record = $domain->create_record({
            name        => 'test-record',
            type        => 'A',
            data        => '192.168.1.100',
            ttl         => 300,
            gtdLocation => 'DEFAULT',
        });

        isa_ok($record, 'WWW::DNSMadeEasy::Domain::Record');
        ok(defined $record->id, 'created record has id');

        # Clean up
        eval { $record->delete };
        ok(!$@, 'record deleted successfully');
    };
}

subtest 'request headers' => sub {
    my $headers = $dme->get_request_headers;
    ok(defined $headers->{'x-dnsme-apiKey'}, 'headers have apiKey');
    ok(defined $headers->{'x-dnsme-hmac'}, 'headers have hmac');
    ok(defined $headers->{'x-dnsme-requestDate'}, 'headers have requestDate');
};

subtest 'api endpoint' => sub {
    is($dme->api_endpoint, 'https://api.dnsmadeeasy.com/V1.2/', 'correct endpoint');

    my $sandbox_dme = WWW::DNSMadeEasy->new({
        api_key     => 'test',
        secret      => 'test',
        api_version => '1.2',
        sandbox     => 1,
    });
    is($sandbox_dme->api_endpoint, 'https://api.sandbox.dnsmadeeasy.com/V1.2/', 'correct sandbox endpoint');
};

done_testing;

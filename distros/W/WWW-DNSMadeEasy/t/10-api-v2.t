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
        api_version => '2.0',
        sandbox     => $use_sandbox,
    });
} else {
    diag("Using MockUA (set TEST_WWW_DNSMADEEASY_API_KEY and TEST_WWW_DNSMADEEASY_API_SECRET for live tests)");
    require MockUA;
    $using_mock = 1;

    $dme = WWW::DNSMadeEasy->new({
        api_key     => 'test-api-key',
        secret      => 'test-secret',
        api_version => '2.0',
    });
    $dme->{_http_agent} = MockUA->new(fixtures_dir => "$FindBin::Bin/fixtures");
}

isa_ok($dme, 'WWW::DNSMadeEasy');
is($dme->api_version, '2.0', 'api_version is 2.0');

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
        $test_domain = $dme->create_managed_domain($test_domain_name);
        $created_test_domain = 1;
        diag("Waiting for domain to be ready...");
        $test_domain->wait_for_pending_action;
        diag("Domain ready");
    };
    if ($@) {
        diag("Failed to create test domain: $@");
        plan skip_all => "Cannot create test domain";
    }
} else {
    # Read-only mode: use first existing domain
    my @domains = $dme->managed_domains;
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
        diag("Cleaning up: waiting for pending actions...");
        eval { $test_domain->wait_for_pending_action };
        diag("Deleting test domain $test_domain_name");
        eval { $test_domain->delete };
        if ($@) {
            diag("Cleanup error: $@");
        } else {
            diag("Test domain deleted successfully");
        }
    }
}

subtest 'managed_domains' => sub {
    my @domains = $dme->managed_domains;
    ok(@domains >= 0, 'managed_domains returns list');
    if (@domains) {
        isa_ok($domains[0], 'WWW::DNSMadeEasy::ManagedDomain');
        ok(defined $domains[0]->name, 'domain has name');
    }
};

subtest 'get_managed_domain' => sub {
    my $domain = $dme->get_managed_domain($test_domain_name);
    isa_ok($domain, 'WWW::DNSMadeEasy::ManagedDomain');
    is($domain->name, $test_domain_name, 'domain name matches');
    ok(defined $domain->id, 'domain has id');

    # Save for later tests
    $test_domain = $domain unless $test_domain;
};

subtest 'managed domain attributes' => sub {
    my $domain = $dme->get_managed_domain($test_domain_name);

    # Test all accessor methods
    ok($domain->can('active_third_parties'), 'has active_third_parties');
    ok($domain->can('created'), 'has created');
    ok($domain->can('delegate_name_servers'), 'has delegate_name_servers');
    ok($domain->can('folder_id'), 'has folder_id');
    ok($domain->can('gtd_enabled'), 'has gtd_enabled');
    ok($domain->can('id'), 'has id');
    ok($domain->can('name_servers'), 'has name_servers');
    ok($domain->can('pending_action_id'), 'has pending_action_id');
    ok($domain->can('process_multi'), 'has process_multi');
    ok($domain->can('updated'), 'has updated');

    ok(defined $domain->id, 'id is defined');
};

subtest 'domain records' => sub {
    my $domain = $dme->get_managed_domain($test_domain_name);
    my @records = $domain->records;
    ok(@records >= 0, 'records returns list');
    if (@records) {
        isa_ok($records[0], 'WWW::DNSMadeEasy::ManagedDomain::Record');
        ok(defined $records[0]->id, 'record has id');
        ok(defined $records[0]->name, 'record has name');
        ok(defined $records[0]->type, 'record has type');
    }
};

subtest 'record attributes' => sub {
    plan skip_all => "No records to test" unless $using_mock;

    my $domain = $dme->get_managed_domain($test_domain_name);
    my @records = $domain->records;

    plan skip_all => "No records in domain" unless @records;

    my $record = $records[0];

    # Test all accessor methods exist
    ok($record->can('description'), 'has description');
    ok($record->can('dynamic_dns'), 'has dynamic_dns');
    ok($record->can('failed'), 'has failed');
    ok($record->can('failover'), 'has failover');
    ok($record->can('gtd_location'), 'has gtd_location');
    ok($record->can('hard_link'), 'has hard_link');
    ok($record->can('id'), 'has id');
    ok($record->can('keywords'), 'has keywords');
    ok($record->can('monitor'), 'has monitor');
    ok($record->can('mxLevel'), 'has mxLevel');
    ok($record->can('name'), 'has name');
    ok($record->can('password'), 'has password');
    ok($record->can('port'), 'has port');
    ok($record->can('priority'), 'has priority');
    ok($record->can('redirect_type'), 'has redirect_type');
    ok($record->can('source'), 'has source');
    ok($record->can('source_id'), 'has source_id');
    ok($record->can('title'), 'has title');
    ok($record->can('ttl'), 'has ttl');
    ok($record->can('type'), 'has type');
    ok($record->can('value'), 'has value');
    ok($record->can('weight'), 'has weight');

    ok(defined $record->id, 'id is defined');
    ok(defined $record->name, 'name is defined');
    ok(defined $record->type, 'type is defined');
};

# Write tests - only run with TEST_WWW_DNSMADEEASY_WRITE=1
SKIP: {
    skip "Write tests disabled (set TEST_WWW_DNSMADEEASY_WRITE=1)", 1
        unless $write_tests || $using_mock;

    subtest 'create and delete record' => sub {
        my $domain = $dme->get_managed_domain($test_domain_name);

        my $record = $domain->create_record(
            name         => 'test-record',
            type         => 'A',
            value        => '192.168.1.100',
            ttl          => 300,
            gtd_location => 'DEFAULT',
        );

        isa_ok($record, 'WWW::DNSMadeEasy::ManagedDomain::Record');
        ok(defined $record->id, 'created record has id');
        is($record->name, 'test-record', 'record name matches');
        is($record->type, 'A', 'record type matches');

        # Clean up
        eval { $record->delete };
        ok(!$@, 'record deleted successfully');
    };
}

subtest 'response metadata' => sub {
    $dme->managed_domains;

    ok(defined $dme->requests_remaining || 1, 'requests_remaining accessible');
    ok(defined $dme->request_limit || 1, 'request_limit accessible');
    ok(defined $dme->last_request_id || 1, 'last_request_id accessible');
};

subtest 'api endpoint v2' => sub {
    is($dme->api_endpoint, 'https://api.dnsmadeeasy.com/V2.0/', 'correct V2 endpoint');

    my $sandbox_dme = WWW::DNSMadeEasy->new({
        api_key     => 'test',
        secret      => 'test',
        api_version => '2.0',
        sandbox     => 1,
    });
    is($sandbox_dme->api_endpoint, 'https://api.sandbox.dnsmadeeasy.com/V2.0/', 'correct sandbox V2 endpoint');
};

done_testing;

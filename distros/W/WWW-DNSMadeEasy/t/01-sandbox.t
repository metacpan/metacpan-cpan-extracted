#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/lib";

use WWW::DNSMadeEasy;

my $dme;

if ($ENV{TEST_WWW_DNSMADEEASY_API_KEY} && $ENV{TEST_WWW_DNSMADEEASY_API_SECRET}) {
    my $use_sandbox = $ENV{TEST_WWW_DNSMADEEASY_SANDBOX} ? 1 : 0;
    diag("Using LIVE API" . ($use_sandbox ? " (SANDBOX)" : ""));

    $dme = WWW::DNSMadeEasy->new({
        api_key => $ENV{TEST_WWW_DNSMADEEASY_API_KEY},
        secret  => $ENV{TEST_WWW_DNSMADEEASY_API_SECRET},
        sandbox => $use_sandbox,
    });
} else {
    diag("Using MockUA (set TEST_WWW_DNSMADEEASY_API_KEY and TEST_WWW_DNSMADEEASY_API_SECRET for live tests)");
    require MockUA;

    $dme = WWW::DNSMadeEasy->new({
        api_key => 'test-api-key',
        secret  => 'test-secret',
        sandbox => 1,
    });
    $dme->{_http_agent} = MockUA->new(fixtures_dir => "$FindBin::Bin/fixtures");
}

isa_ok($dme, 'WWW::DNSMadeEasy');

subtest 'V2 API - managed_domains (default)' => sub {
    my @domains = $dme->managed_domains;
    ok(@domains >= 0, 'managed_domains returns list');
    if (@domains) {
        isa_ok($domains[0], 'WWW::DNSMadeEasy::ManagedDomain');
    }
};

done_testing;

#!/usr/bin/env perl

use Test::Most;
use WWW::DNSMadeEasy;

SKIP: {

	skip "we need WWW_DNSMADEEASY_TEST_APIKEY and WWW_DNSMADEEASY_TEST_SECRET", 1
		unless defined $ENV{WWW_DNSMADEEASY_TEST_APIKEY} && 
               defined $ENV{WWW_DNSMADEEASY_TEST_SECRET};

    my $dme = WWW::DNSMadeEasy->new(
        api_key     => $ENV{WWW_DNSMADEEASY_TEST_APIKEY},
        secret      => $ENV{WWW_DNSMADEEASY_TEST_SECRET},
        sandbox     => 0,
        api_version => '1.2',
    );

    isa_ok($dme,'WWW::DNSMadeEasy');

    #use DDP;
    my @domains = $dme->all_domains;
    #p $domain;
    my $domain  = $dme->domain('boop.com');
    #p $domain;
    my @records = $domain->all_records;
    #p @records;
}
    

done_testing;

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
        sandbox     => 1,
        api_version => '2.0',
    );

    isa_ok($dme,'WWW::DNSMadeEasy');

    subtest setup => sub {
        my @domains = $dme->managed_domains;
        $_->delete          for @domains;
        $_->wait_for_delete for @domains;
        pass 'setup complete';
    };

    subtest 'managed domains' => sub {
        my @domains = $dme->managed_domains;
        is scalar @domains, 0, "no managed domains";

        my $domain  = $dme->create_managed_domain('boop.com');
        @domains = $dme->managed_domains;
        $_->wait_for_pending_action for @domains;
        is scalar @domains, 1, "created a domain";
    };

    my $record1;
    my $record2;
    subtest 'records' => sub {
        my $domain = $dme->get_managed_domain('boop.com');
        like $domain->created, qr/\d+/, 'get_managed_domain()';

        my @records1 = $domain->records;
        $_->delete for @records1;

        my %args = (
            name         => 'bang',
            type         => 'A',
            value        => '1.1.1.1',
            gtd_location => 'DEFAULT',
            ttl          => '30',
        );
        $record1 = $domain->create_record(%args);
        note "created record1";
        is $record1->$_, $args{$_}, $_ for keys %args;

        my %args2 = (
            name         => 'pow',
            type         => 'CNAME',
            value        => 'bang',
            gtd_location => 'DEFAULT',
            ttl          => '30',
        );
        $record2 = $domain->create_record(%args2);
        note "created record2";
        is $record2->$_, $args2{$_}, $_ for keys %args2;

        my @records2 = $domain->records(type => 'CNAME');
        is scalar @records2, 1, 'found 1 CNAME record';

        my %update = (
            value        => 'kapow',
            ttl          => '40',
        );
        $record2->update(%update);
        is $record2->$_, $update{$_}, $_ for keys %update;
    };

    subtest 'monitor' => sub {
        my %attrs = (
            auto_failover      => JSON::true, 
            failover           => JSON::true, 
            http_file          => '/foo', 
            http_fqdn          => 'boop.com', 
            http_query_string  => 'booper', 
            ip1                => '1.2.3.4', 
            ip2                => '2.3.4.5', 
            max_emails         => 1, 
            monitor            => JSON::true, 
            port               => 443, 
            protocol_id        => 6, 
            sensitivity        => 3,
            system_description => 'Test', 
        );
        $record1->create_monitor(%attrs);
        my $monitor = $record1->get_monitor;
        is $monitor->$_, $attrs{$_}, $_ for sort keys %attrs;

        note "disabled monitor and failover";
        $monitor->disable;
        ok !$monitor->failover,      '!failover';
        ok !$monitor->monitor,       '!monitor';
        ok !$monitor->auto_failover, '!auto_failover';
    };
}

done_testing;

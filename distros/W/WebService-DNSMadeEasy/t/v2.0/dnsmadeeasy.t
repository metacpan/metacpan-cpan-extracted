use strict;
use warnings;

use Test::More;
use WebService::DNSMadeEasy;
use JSON;

SKIP: {
    skip "This test requires WEBSERVICE_DNSMADEEASY_TEST_APIKEY and WEBSERVICE_DNSMADEEASY_TEST_SECRET environment variables", 1
        unless defined $ENV{WEBSERVICE_DNSMADEEASY_TEST_APIKEY} &&
               defined $ENV{WEBSERVICE_DNSMADEEASY_TEST_SECRET};

    my $domain_name = "stegasaurus0003.com";
    my $dns = WebService::DNSMadeEasy->new(
        api_key     => $ENV{WEBSERVICE_DNSMADEEASY_TEST_APIKEY},
        secret      => $ENV{WEBSERVICE_DNSMADEEASY_TEST_SECRET},
        sandbox     => 1,
    );

    isa_ok($dns,'WebService::DNSMadeEasy');

    #subtest 'managed domains' => sub {
    #    my @domains = $dns->managed_domains;
    #    ok scalar @domains > 0, "found some managed domains";

    #    my $domain = $dns->create_managed_domain($domain_name);
    #   #$domain->wait_for_pending_action; # can't test this in sandbox
    #    is $domain->name, $domain_name, "created $domain_name";
    #};

    my $record1;
    my $record2;
    my $record3;
    subtest 'records' => sub {
        my $domain = $dns->get_managed_domain($domain_name);
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
            name         => 'boom',
            type         => 'A',
            value        => '2.2.2.2',
            gtd_location => 'DEFAULT',
            ttl          => '30',
        );
        $record2 = $domain->create_record(%args2);
        note "created record2";
        is $record2->$_, $args2{$_}, $_ for keys %args2;

        my %args3 = (
            name         => 'pow',
            type         => 'CNAME',
            value        => 'bang',
            gtd_location => 'DEFAULT',
            ttl          => '30',
        );
        $record3 = $domain->create_record(%args3);
        note "created record3";
        is $record3->$_, $args3{$_}, $_ for keys %args3;

        my @records3 = $domain->records(type => 'CNAME');
        is scalar @records3, 1, 'found 1 CNAME record';

        my %update = (
            value        => 'kapow',
            ttl          => '40',
        );
        $record3->update(%update);
        is $record3->$_, $update{$_}, $_ for keys %update;
    };

    subtest 'monitor' => sub {
        my %attrs = (
            auto_failover      => JSON->true, 
            failover           => JSON->true, 
            http_file          => '/foo', 
            http_fqdn          => $domain_name, 
            http_query_string  => 'booper', 
            ip1                => '1.1.1.1', 
            ip2                => '2.2.2.2', 
            max_emails         => 1, 
            monitor            => JSON->true, 
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

    subtest cleanup => sub {
        note "deleting $domain_name in 5 seconds...";
        sleep 5;
        my $domain = $dns->get_managed_domain($domain_name);
        eval { $domain->delete };
        like $@, qr/Cannot delete a domain that is pending a create/;
        #$domain->wait_for_delete; # can't test this in sandbox
        pass 'cleanup complete';
    };
}

done_testing;

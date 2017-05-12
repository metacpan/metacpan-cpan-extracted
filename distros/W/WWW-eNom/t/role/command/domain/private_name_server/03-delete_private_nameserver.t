#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::Exception;

use FindBin;
use lib "$FindBin::Bin/../../../../lib";
use Test::WWW::eNom qw( create_api );
use Test::WWW::eNom::Domain qw( create_domain $UNREGISTERED_DOMAIN $NOT_MY_DOMAIN );

use WWW::eNom::PrivateNameServer;

subtest 'Delete Private Nameserver On Unregistered Domain' => sub {
    my $api = create_api();

    throws_ok {
        $api->delete_private_nameserver(
            domain_name             => $UNREGISTERED_DOMAIN->name,
            private_nameserver_name => 'ns1.' . $UNREGISTERED_DOMAIN->name,
        );
    } qr/Domain not found in your account/, 'Throws on unregistered domain';
};

subtest 'Delete Private Nameserver On Domain Registered To Someone Else' => sub {
    my $api = create_api();

    throws_ok {
        $api->delete_private_nameserver(
            domain_name             => $NOT_MY_DOMAIN->name,
            private_nameserver_name => 'ns1.' . $NOT_MY_DOMAIN->name,
        );
    } qr/Domain not found in your account/, 'Throws on domain registred to someone else';
};

subtest 'Delete Private Nameserver That Does Not Exist' => sub {
    my $api    = create_api();
    my $domain = create_domain();

    throws_ok {
        $api->delete_private_nameserver(
            domain_name             => $domain->name,
            private_nameserver_name => 'ns1.' . $domain->name,
        );
    } qr/Nameserver does not exist/, 'Throws on nameserver does not eist';
};

subtest 'Delete Private Nameserver - No Other Private Nameservers' => sub {
    my $api    = create_api();
    my $domain = create_domain();

    my $private_nameserver = WWW::eNom::PrivateNameServer->new(
        name => 'ns1.' . $domain->name,
        ip   => '4.2.2.1',
    );

    lives_ok {
        $domain = $api->create_private_nameserver(
            domain_name        => $domain->name,
            private_nameserver => $private_nameserver
        );
    } 'Lives through creation of private nameserver';

    lives_ok {
        $domain = $api->update_nameservers_for_domain_name({
            domain_name => $domain->name,
            ns          => [ $private_nameserver->name ],
        });
    } 'Lives through making the private nameserver the only one on the domain';

    throws_ok {
        $api->delete_private_nameserver(
            domain_name             => $domain->name,
            private_nameserver_name => $private_nameserver->name,
        );
    } qr/Blocked deletion - Deleting this would leave this domain with no nameservers!/, 'Throws on last private nameserver';
};

subtest 'Delete Private Nameserver - Remaining Private Nameservers' => sub {
    my $api    = create_api();
    my $domain = create_domain();

    my $private_nameserver_ns1 = WWW::eNom::PrivateNameServer->new(
        name => 'ns1.' . $domain->name,
        ip   => '4.2.2.1',
    );

    my $private_nameserver_ns2 = WWW::eNom::PrivateNameServer->new(
        name => 'ns2.' . $domain->name,
        ip   => '4.2.2.2',
    );

    lives_ok {
        $domain = $api->create_private_nameserver(
            domain_name        => $domain->name,
            private_nameserver => $private_nameserver_ns1
        );
    } 'Lives through creation of private nameserver';

    lives_ok {
        $domain = $api->create_private_nameserver(
            domain_name        => $domain->name,
            private_nameserver => $private_nameserver_ns2
        );
    } 'Lives through creation of private nameserver';

    lives_ok {
        $domain = $api->update_nameservers_for_domain_name({
            domain_name => $domain->name,
            ns          => [ $private_nameserver_ns1->name, $private_nameserver_ns2->name ],
        });
    } 'Lives through making the private nameservers the only ones on the domain';

    lives_ok {
        $api->delete_private_nameserver(
            domain_name             => $domain->name,
            private_nameserver_name => $private_nameserver_ns1->name,
        );
    } 'Lives through deleting of private nameservers';

    my $retrieved_domain = $api->get_domain_by_name( $domain->name );

    is_deeply( $retrieved_domain->ns, [ $private_nameserver_ns2->name ], 'Correct ns' );
    is_deeply( $retrieved_domain->private_nameservers, [ $private_nameserver_ns2 ] , 'Correct private_nameservers' );
};

done_testing;

#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::Exception;

use FindBin;
use lib "$FindBin::Bin/../../../../lib";
use Test::WWW::eNom qw( create_api mock_response );
use Test::WWW::eNom::Domain qw( create_domain mock_domain_retrieval mock_update_nameserver $UNREGISTERED_DOMAIN $NOT_MY_DOMAIN );

use WWW::eNom::PrivateNameServer;

subtest 'Delete Private Nameserver On Unregistered Domain' => sub {
    my $api        = create_api();
    my $mocked_api = mock_response(
        method   => 'GetDomainInfo',
        response => {
            ErrCount => 1,
            errors   => [ 'Domain name not found' ]
        }
    );

    throws_ok {
        $api->delete_private_nameserver(
            domain_name             => $UNREGISTERED_DOMAIN->name,
            private_nameserver_name => 'ns1.' . $UNREGISTERED_DOMAIN->name,
        );
    } qr/Domain not found in your account/, 'Throws on unregistered domain';

    $mocked_api->unmock_all;
};

subtest 'Delete Private Nameserver On Domain Registered To Someone Else' => sub {
    my $api        = create_api();
    my $mocked_api = mock_response(
        method   => 'GetDomainInfo',
        response => {
            ErrCount => 1,
            errors   => [ 'Domain name not found' ]
        }
    );

    throws_ok {
        $api->delete_private_nameserver(
            domain_name             => $NOT_MY_DOMAIN->name,
            private_nameserver_name => 'ns1.' . $NOT_MY_DOMAIN->name,
        );
    } qr/Domain not found in your account/, 'Throws on domain registred to someone else';

    $mocked_api->unmock_all;
};

subtest 'Delete Private Nameserver That Does Not Exist' => sub {
    my $api    = create_api();
    my $domain = create_domain();

    my $mocked_api = mock_domain_retrieval(
        name        => $domain->name,
        nameservers => $domain->ns,
    );

    mock_response(
        mocked_api => $mocked_api,
        method     => 'DeleteNameServer',
        response   => {
            ErrCount => 1,
            errors   => [ 'Nameserver registration failed due to error 545: Object does not exist' ],
        }
    );

    throws_ok {
        $api->delete_private_nameserver(
            domain_name             => $domain->name,
            private_nameserver_name => 'ns1.' . $domain->name,
        );
    } qr/Nameserver does not exist/, 'Throws on nameserver does not eist';

    $mocked_api->unmock_all;
};

subtest 'Delete Private Nameserver - No Other Private Nameservers' => sub {
    my $api    = create_api();
    my $domain = create_domain();

    my $private_nameserver = WWW::eNom::PrivateNameServer->new(
        name => 'ns1.' . $domain->name,
        ip   => '4.2.2.1',
    );

    my $mocked_api = mock_update_nameserver(
        domain      => $domain,
        nameservers => [ $private_nameserver ],
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

    $mocked_api->unmock_all;
};

subtest 'Delete Private Nameserver - Remaining Private Nameservers' => sub {
    my $api                 = create_api();
    my @initial_nameservers = ( 'ns1.enom.com', 'ns2.enom.com' );
    my $domain              = create_domain( ns => \@initial_nameservers );

    my $private_nameserver_ns1 = WWW::eNom::PrivateNameServer->new(
        name => 'ns1.' . $domain->name,
        ip   => '4.2.2.1',
    );

    my $private_nameserver_ns2 = WWW::eNom::PrivateNameServer->new(
        name => 'ns2.' . $domain->name,
        ip   => '4.2.2.2',
    );

    my $mocked_api = mock_update_nameserver(
        domain      => $domain,
        nameservers => [ @initial_nameservers, $private_nameserver_ns1 ],
    );

    lives_ok {
        $domain = $api->create_private_nameserver(
            domain_name        => $domain->name,
            private_nameserver => $private_nameserver_ns1
        );
    } 'Lives through creation of private nameserver';

    $mocked_api->unmock_all;

    $mocked_api = mock_update_nameserver(
        domain      => $domain,
        nameservers => [ @initial_nameservers, $private_nameserver_ns1, $private_nameserver_ns2 ],
    );

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

    $mocked_api->unmock_all;

    $mocked_api = mock_domain_retrieval(
        name        => $domain->name,
        nameservers => [ $private_nameserver_ns1->name, $private_nameserver_ns2->name ],
    );

    mock_response(
        mocked_api => $mocked_api,
        method     => 'ModifyNS',
        response   => {
            ErrCount => 0,
        }
    );

    $mocked_api->mock('CheckNSStatus', sub {
        my $self   = shift;
        my $params = shift;

        note( 'Mocked WWW::eNom->CheckNSStatus' );

        mock_domain_retrieval(
            mocked_api  => $mocked_api,
            name        => $domain->name,
            nameservers => [ $private_nameserver_ns2->name ],
        );

        if( $params->{CheckNSName} eq $private_nameserver_ns1->name ) {
            return {
                ErrCount      => 0,
                CheckNsStatus => {
                    name      => $private_nameserver_ns1->name,
                    ipaddress => $private_nameserver_ns1->ip,
                }
            };
        }
        else {
            return {
                ErrCount      => 0,
                CheckNsStatus => {
                    name      => $private_nameserver_ns2->name,
                    ipaddress => $private_nameserver_ns2->ip,
                }
            };
        }
    });

    lives_ok {
        $api->delete_private_nameserver(
            domain_name             => $domain->name,
            private_nameserver_name => $private_nameserver_ns1->name,
        );
    } 'Lives through deleting of private nameservers';

    $mocked_api->unmock_all;

    $mocked_api = mock_domain_retrieval(
        name        => $domain->name,
        nameservers => [ $private_nameserver_ns2->name ],
    );

    mock_response(
        mocked_api => $mocked_api,
        method     => 'CheckNSStatus',
        response   => {
            ErrCount      => 0,
            CheckNsStatus => {
                name      => $private_nameserver_ns2->name,
                ipaddress => $private_nameserver_ns2->ip,
            }
        }
    );

    my $retrieved_domain = $api->get_domain_by_name( $domain->name );

    $mocked_api->unmock_all;

    is_deeply( $retrieved_domain->ns, [ $private_nameserver_ns2->name ], 'Correct ns' );
    is_deeply( $retrieved_domain->private_nameservers, [ $private_nameserver_ns2 ] , 'Correct private_nameservers' );
};

done_testing;

#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::Exception;
use Test::MockModule;

use FindBin;
use lib "$FindBin::Bin/../../../../lib";
use Test::WWW::eNom qw( create_api mock_response );
use Test::WWW::eNom::Domain qw( create_domain mock_update_nameserver $UNREGISTERED_DOMAIN $NOT_MY_DOMAIN );

use WWW::eNom::PrivateNameServer;

subtest 'Retrieve Private Nameserver On Unregistered Domain' => sub {
    my $api = create_api();

    my $mocked_api = mock_response(
        method   => 'CheckNSStatus',
        response => {
            ErrCount => 1,
            errors   => [ 'Error 545 - Name server does not exist' ],
        }
    );

    throws_ok {
        $api->retrieve_private_nameserver_by_name(
            'ns1.' . $UNREGISTERED_DOMAIN->name
        );
    } qr/Nameserver does not exist/, 'Throws on unregistered domain';

    $mocked_api->unmock_all;
};

subtest 'Retrieve Private Nameserver On Domain Registered To Someone Else' => sub {
    my $api = create_api();

    my $mocked_api = mock_response(
        method   => 'CheckNSStatus',
        response => {
            ErrCount => 1,
            errors   => [ 'Error 531 - You are not authorized to receive information on this name server' ],
        }
    );

    throws_ok {
        $api->retrieve_private_nameserver_by_name(
            'ns1.' . $NOT_MY_DOMAIN->name
        );
    } qr/Nameserver not found in your account/, 'Throws on not my domain';

    $mocked_api->unmock_all;
};

subtest 'Retrieve Private Nameserver That Does Not Exist' => sub {
    my $api    = create_api();
    my $domain = create_domain();

    my $mocked_api = mock_response(
        method   => 'CheckNSStatus',
        response => {
            ErrCount => 1,
            errors   => [ 'Error 545 - Name server does not exist' ],
        }
    );

    throws_ok {
        $api->retrieve_private_nameserver_by_name(
            'ns1.' . $domain->name
        );
    } qr/Nameserver does not exist/, 'Throws on non existant nameserver';

    $mocked_api->unmock_all;
};

subtest 'Retrieve Private Nameserver - One IP Address' => sub {
    my $api    = create_api();
    my $domain = create_domain();

    my $private_nameserver = WWW::eNom::PrivateNameServer->new(
        name => 'ns1.' . $domain->name,
        ip   => '4.2.2.1',
    );

    my $mocked_api = mock_update_nameserver(
        domain      => $domain,
        nameservers => [ @{ $domain->ns }, $private_nameserver ],
    );

    lives_ok {
        $api->create_private_nameserver(
            domain_name        => $domain->name,
            private_nameserver => $private_nameserver,
        );
    } 'Lives through creation of private nameserver';

    my $retrieved_private_nameserver;
    lives_ok {
        $retrieved_private_nameserver = $api->retrieve_private_nameserver_by_name( $private_nameserver->name );
    } 'Lives through retrieving private nameserver';

    $mocked_api->unmock_all;

    is_deeply( $retrieved_private_nameserver, $private_nameserver, 'Correct private nameserver' );
};

subtest 'Retrieve Private Nameserver - Multiple IP Addresses' => sub {
    my $api        = create_api();
    my $mocked_api = mock_response(
        force_mock => 1,
        method     => 'CheckNSStatus',
        response   => {
            ErrCount      => 0,
            CheckNsStatus => {
                name      => 'ns1.testdomain.com',
                ipaddress => {
                    ipaddress => [ '4.2.2.1', '8.8.8.8' ],
                }
            }
        }
    );

    my $retrieved_private_nameserver;
    lives_ok {
        $retrieved_private_nameserver = $api->retrieve_private_nameserver_by_name( 'ns1.testdomain.com' );
    }
    'Lives through retrieving private nameserver';
    $mocked_api->unmock_all;

    if( isa_ok( $retrieved_private_nameserver, 'WWW::eNom::PrivateNameServer' ) ) {
        cmp_ok( $retrieved_private_nameserver->name, 'eq', 'ns1.testdomain.com', 'Correct name' );
        cmp_ok( $retrieved_private_nameserver->ip,   'eq', '4.2.2.1', 'Correct ip' );
    }
};

done_testing;

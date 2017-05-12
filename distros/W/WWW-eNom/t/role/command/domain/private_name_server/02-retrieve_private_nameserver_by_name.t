#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::Exception;
use Test::MockModule;

use FindBin;
use lib "$FindBin::Bin/../../../../lib";
use Test::WWW::eNom qw( create_api );
use Test::WWW::eNom::Domain qw( create_domain $UNREGISTERED_DOMAIN $NOT_MY_DOMAIN );

use WWW::eNom::PrivateNameServer;

subtest 'Retrieve Private Nameserver On Unregistered Domain' => sub {
    my $api = create_api();

    throws_ok {
        $api->retrieve_private_nameserver_by_name(
            'ns1.' . $UNREGISTERED_DOMAIN->name
        );
    } qr/Nameserver does not exist/, 'Throws on unregistered domain';
};

subtest 'Retrieve Private Nameserver On Domain Registered To Someone Else' => sub {
    my $api = create_api();

    throws_ok {
        $api->retrieve_private_nameserver_by_name(
            'ns1.' . $NOT_MY_DOMAIN->name
        );
    } qr/Nameserver not found in your account/, 'Throws on not my domain';
};

subtest 'Retrieve Private Nameserver That Does Not Exist' => sub {
    my $api    = create_api();
    my $domain = create_domain();

    throws_ok {
        $api->retrieve_private_nameserver_by_name(
            'ns1.' . $domain->name
        );
    } qr/Nameserver does not exist/, 'Throws on non existant nameserver';
};

subtest 'Retrieve Private Nameserver - One IP Address' => sub {
    my $api    = create_api();
    my $domain = create_domain();

    my $private_nameserver = WWW::eNom::PrivateNameServer->new(
        name => 'ns1.' . $domain->name,
        ip   => '4.2.2.1',
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

    is_deeply( $retrieved_private_nameserver, $private_nameserver, 'Correct private nameserver' );
};

subtest 'Retrieve Private Nameserver - Multiple IP Addresses' => sub {
    my $api      = create_api();
    my $response = {
        ErrCount      => 0,
        CheckNsStatus => {
            name      => 'ns1.testdomain.com',
            ipaddress => {
                ipaddress => [ '4.2.2.1', '8.8.8.8' ],
            }
        }
    };

    my $mocked_api = Test::MockModule->new('WWW::eNom');
    $mocked_api->mock( 'submit', sub { return $response } );

    my $retrieved_private_nameserver;
    lives_ok {
        $retrieved_private_nameserver = $api->retrieve_private_nameserver_by_name( 'ns1.testdomain.com' );
    } 'Lives through retrieving private nameserver';

    if( isa_ok( $retrieved_private_nameserver, 'WWW::eNom::PrivateNameServer' ) ) {
        cmp_ok( $retrieved_private_nameserver->name, 'eq', $response->{CheckNsStatus}{name}, 'Correct name' );
        cmp_ok( $retrieved_private_nameserver->ip,   'eq', $response->{CheckNsStatus}{ipaddress}{ipaddress}->[0], 'Correct ip' );
    }
};

done_testing;

#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::Exception;
use Test::MockModule;
use String::Random qw( random_string );

use FindBin;
use lib "$FindBin::Bin/../../../lib";
use Test::WWW::eNom qw( create_api mock_response );
use Test::WWW::eNom::Domain qw( create_domain mock_get_dns $UNREGISTERED_DOMAIN $NOT_MY_DOMAIN );

subtest 'Get Nameservers For Unregistered Domain' => sub {
    my $api = create_api();

    my $mocked_api = mock_response(
        method   => 'GetDNS',
        response => {
            ErrCount => 1,
            errors   => [ 'Domain name not found' ],
        }
    );

    throws_ok{
        $api->get_domain_name_servers_by_name( $UNREGISTERED_DOMAIN->name );
    } qr/Domain not found in your account/, 'Throws on unregistered domain';

    $mocked_api->unmock_all;
};

subtest 'Get Nameservers For Domain Registered To Somone Else' => sub {
    my $api = create_api();

    my $mocked_api = mock_response(
        method   => 'GetDNS',
        response => {
            ErrCount => 1,
            errors   => [ 'Domain name not found' ],
        }
    );

    throws_ok{
        $api->get_domain_name_servers_by_name( $NOT_MY_DOMAIN->name );
    } qr/Domain not found in your account/, 'Throws on domain registered to someone else';

    $mocked_api->unmock_all;
};

subtest 'Get Nameservers - Valid Domain' => sub {
    my $api         = create_api();
    my $nameservers = [ 'ns1.enom.com', 'ns2.enom.com' ];
    my $domain      = create_domain({
        ns => $nameservers,
    });

    my $mocked_api = mock_get_dns(
        nameservers => $nameservers
    );

    my $retrieved_nameservers;
    lives_ok {
        $retrieved_nameservers = $api->get_domain_name_servers_by_name( $domain->name );
    } 'Lives through getting nameservers';

    $mocked_api->unmock_all;

    is_deeply( $retrieved_nameservers, $nameservers, 'Correct nameservers' );
};

subtest 'Get Nameservers - Reactivation Period Domain' => sub {
    my $api = create_api();

    my $mocked_api = mock_response(
        force_mock => 1,
        method     => 'GetDNS',
        response   => {
            ErrCount => 1,
            errors   => [ 'This domain name is expired and cannot be updated' ],
        },
    );

    my $retrieved_nameservers;
    lives_ok {
        $retrieved_nameservers = $api->get_domain_name_servers_by_name( 'mocked-call.com' );
    } 'Lives through getting nameservers';

    $mocked_api->unmock_all;

    is_deeply( $retrieved_nameservers, [ ], 'Correct nameservers' );
};

done_testing;

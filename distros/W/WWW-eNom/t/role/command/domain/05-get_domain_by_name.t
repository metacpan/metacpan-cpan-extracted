#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::Exception;
use String::Random qw( random_string );

use FindBin;
use lib "$FindBin::Bin/../../../lib";
use Test::WWW::eNom qw( create_api mock_response );
use Test::WWW::eNom::Domain qw( create_domain mock_domain_retrieval $UNREGISTERED_DOMAIN $NOT_MY_DOMAIN );

subtest 'Get Domain By Name - Unregistered Domain' => sub {
    my $api = create_api();

    my $mocked_api = mock_response(
        method   => 'GetDomainInfo',
        response => {
            ErrCount => 1,
            errors   => [ 'Domain name not found' ],
        }
    );

    throws_ok{
        $api->get_domain_by_name( $UNREGISTERED_DOMAIN->name );
    } qr/Domain not found in your account/, 'Throws on unregistered domain';

    $mocked_api->unmock_all;
};

subtest 'Get Domain By Name - Domain Registered To Someone Else' => sub {
    my $api         = create_api();
    my $domain_name = 'enom.com';

    my $mocked_api = mock_response(
        method   => 'GetDomainInfo',
        response => {
            ErrCount => 1,
            errors   => [ 'Domain name not found' ],
        }
    );

    throws_ok{
        $api->get_domain_by_name( $NOT_MY_DOMAIN->name );
    } qr/Domain not found in your account/, 'Throws on domain registered to someone else';

    $mocked_api->unmock_all;
};

subtest 'Get Domain By Name - Valid Domain' => sub {
    my $api    = create_api();
    my $domain = create_domain();

    my $mocked_api = mock_domain_retrieval(
        name          => $domain->name,
        is_private    => $domain->is_private,
        is_locked     => $domain->is_locked,
        is_auto_renew => $domain->is_auto_renew,
        nameservers   => $domain->ns,
        registrant_contact => $domain->registrant_contact,
        admin_contact      => $domain->admin_contact,
        technical_contact  => $domain->technical_contact,
        billing_contact    => $domain->billing_contact,
    );

    my $retrieved_domain;
    lives_ok {
        $retrieved_domain = $api->get_domain_by_name( $domain->name );
    } 'Lives through fetching domain by name';

    $mocked_api->unmock_all;

    is_deeply( $retrieved_domain, $domain, 'Correct domain' );
};

done_testing;

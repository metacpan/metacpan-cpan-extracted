#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::Exception;

use FindBin;
use lib "$FindBin::Bin/../../../lib";
use Test::WWW::eNom qw( create_api mock_response );
use Test::WWW::eNom::Domain qw( create_domain mock_domain_retrieval $UNREGISTERED_DOMAIN $NOT_MY_DOMAIN );

subtest 'Renew Domain On Unregistered Domain' => sub {
    my $api        = create_api();
    my $mocked_api = mock_response(
        method   => 'Extend',
        response => {
            ErrCount => 1,
            errors   => [ 'Domain name not found' ],
        }
    );

    throws_ok {
        $api->renew_domain({
            domain_name => $UNREGISTERED_DOMAIN->name,
            years       => 1,
        });
    } qr/Domain not found in your account/, 'Throws on unregistered domain';

    $mocked_api->unmock_all
};

subtest 'Renew Domain On Domain Registered To Someone Else' => sub {
    my $api        = create_api();
    my $mocked_api = mock_response(
        method   => 'Extend',
        response => {
            ErrCount => 1,
            errors   => [ 'Domain name not found' ],
        }
    );

    throws_ok {
        $api->renew_domain({
            domain_name => $NOT_MY_DOMAIN->name,
            years       => 1,
        });
    } qr/Domain not found in your account/, 'Throws on domain registered to someone else';

    $mocked_api->unmock_all;
};

subtest 'Renew Domain - Too Long of a Renewal' => sub {
    my $api    = create_api();
    my $domain = create_domain(
        is_private => 1,
        years      => 3,
    );

    subtest '20 Years at Once' => sub {
        my $mocked_api = mock_response(
            method   => 'Extend',
            response => {
                ErrCount => 1,
                errors   => [ 'The number of years cannot' ],
            }
        );

        throws_ok {
            $api->renew_domain({
                domain_name => $domain->name,
                years       => 20,
            });
        } qr/Requested renewal too long/, 'Throws on too long of renewal';

        $mocked_api->unmock_all;
    };

    subtest '3 + 8' => sub {
        my $mocked_api = mock_response(
            method   => 'Extend',
            response => {
                ErrCount => 1,
                errors   => [ 'cannot be extended' ],
            }
        );

        throws_ok {
            $api->renew_domain({
                domain_name => $domain->name,
                years       => 8,
            });
        } qr/Requested renewal too long/, 'Throws on too long of renewal';

        $mocked_api->unmock_all;
    };
};

subtest 'Renew Domain - Valid Length of Time' => sub {
    my $api    = create_api();
    my $domain = create_domain( is_private => 1 );

    my $mocked_api = mock_response(
        method   => 'Extend',
        response => {
            ErrCount => 0,
            OrderID  => 42,
        }
    );

    mock_domain_retrieval(
        mocked_api      => $mocked_api,
        name            => $domain->name,
        expiration_date => $domain->expiration_date->clone->add( years => 1 ),
        is_private      => $domain->is_private,
        is_locked       => $domain->is_locked,,
        is_auto_renew   => $domain->is_auto_renew,
        nameservers     => $domain->ns,
        registrant_contact => $domain->registrant_contact,
        admin_contact      => $domain->admin_contact,
        technical_contact  => $domain->technical_contact,
        billing_contact    => $domain->billing_contact,
    );

    my $order_id;
    lives_ok {
        $order_id = $api->renew_domain({
            domain_name => $domain->name,
            years       => 1,
        });
    } 'Lives through renewal';

    like( $order_id, qr/^\d+$/, 'order_id looks numeric' );

    my $retrieved_domain = $api->get_domain_by_name( $domain->name );
    $mocked_api->unmock_all;

    cmp_ok( $retrieved_domain->expiration_date->year, '>', $domain->expiration_date->year, 'Correct expiration date' );
};

done_testing;

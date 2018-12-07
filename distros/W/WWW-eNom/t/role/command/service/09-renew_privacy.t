#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::Exception;

use FindBin;
use lib "$FindBin::Bin/../../../lib";
use Test::WWW::eNom qw( create_api mock_response );
use Test::WWW::eNom::Domain qw( create_domain $UNREGISTERED_DOMAIN $NOT_MY_DOMAIN );
use Test::WWW::eNom::Service qw( mock_renew_services mock_get_wpps_info );

subtest 'Renew Domain Privacy On Unregistered Domain' => sub {
    my $api        = create_api();
    my $mocked_api = mock_response(
        method   => 'RenewServices',
        response => {
            ErrCount => 1,
            errors   => [ 'Domain name not found' ],
        }
    );

    throws_ok {
        $api->renew_privacy({
            domain_name => $UNREGISTERED_DOMAIN->name,
            years       => 1,
        });
    } qr/Domain not found in your account/, 'Throws on unregistered domain';

    $mocked_api->unmock_all;
};

subtest 'Renew Domain Privacy On Domain Registered To Someone Else' => sub {
    my $api        = create_api();
    my $mocked_api = mock_response(
        method   => 'RenewServices',
        response => {
            ErrCount => 1,
            errors   => [ 'Domain name not found' ],
        }
    );

    throws_ok {
        $api->renew_privacy({
            domain_name => $NOT_MY_DOMAIN->name,
            years       => 1,
        });
    } qr/Domain not found in your account/, 'Throws on domain registered to someone else';

    $mocked_api->unmock_all;
};

subtest 'Renew Domain Privacy On Domain Without Privacy' => sub {
    my $api        = create_api();
    my $domain     = create_domain( is_private => 0 );
    my $mocked_api = mock_response(
        method   => 'RenewServices',
        response => {
            ErrCount => 1,
            errors   => [ 'Unable to renew ID Protect for this domain.' ],
        }
    );

    throws_ok {
        $api->renew_privacy({
            domain_name => $domain->name,
            years       => 1,
        });
    } qr/Domain does not have privacy/, 'Throws on domain without privacy';

    $mocked_api->unmock_all;
};

subtest 'Renew Domain Privacy - Too Long of a Renewal' => sub {
    my $api    = create_api();
    my $domain = create_domain(
        is_private => 1,
        years      => 1,
    );
    my $mocked_api = mock_response(
        method   => 'RenewServices',
        response => {
            ErrCount => 1,
            errors   => [ 'The number of years cannot' ],
        }
    );

    subtest '20 Years at Once' => sub {
        throws_ok {
            $api->renew_privacy({
                domain_name => $domain->name,
                years       => 20,
            });
        } qr/Requested renewal too long/, 'Throws on too long of renewal';
    };

    $mocked_api->unmock_all;
};

subtest 'Renew Domain Privacy - Valid Length of Time' => sub {
    my $api    = create_api();
    my $domain = create_domain( is_private => 1 );

    my $mocked_api = mock_get_wpps_info(
        is_auto_renew   => 1,
        expiration_date => $domain->expiration_date
    );

    mock_renew_services( mocked_api => $mocked_api );

    my $initial_privacy_expiration_date = $api->get_privacy_expiration_date_by_name( $domain->name );

    my $order_id;
    lives_ok {
        $order_id = $api->renew_privacy({
            domain_name => $domain->name,
            years       => 1,
        });
    } 'Lives through renewal';

    like( $order_id, qr/^\d+$/, 'order_id looks numeric' );

    $mocked_api->unmock_all;

    $mocked_api = mock_get_wpps_info(
        is_auto_renew   => 1,
        expiration_date => $domain->expiration_date->clone->add( years => 1 ),
    );

    my $updated_privacy_expiration_date = $api->get_privacy_expiration_date_by_name( $domain->name );

    cmp_ok( $updated_privacy_expiration_date->year, '>', $initial_privacy_expiration_date->year, 'Correct expiration date' );

    $mocked_api->unmock_all;
};

done_testing;

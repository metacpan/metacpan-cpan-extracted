#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::Exception;
use String::Random qw( random_string );

use FindBin;
use lib "$FindBin::Bin/../../../lib";
use Test::WWW::eNom qw( create_api mock_response );
use Test::WWW::eNom::Domain qw( create_domain $UNREGISTERED_DOMAIN $NOT_MY_DOMAIN );
use Test::WWW::eNom::Service qw( mock_get_wpps_info );

subtest 'Get Privacy Auto Renew For Unregistered Domain' => sub {
    my $api        = create_api();
    my $mocked_api = mock_response(
        method   => 'GetWPPSInfo',
        response => {
            ErrCount => 1,
            errors   => [ 'Domain name not found' ],
        }
    );

    throws_ok {
        $api->get_is_privacy_auto_renew_by_name( $UNREGISTERED_DOMAIN->name );
    } qr/Domain not found in your account/, 'Throws on unregistered domain';

    $mocked_api->unmock_all;
};

subtest 'Get Privacy Auto Renew For Domain Registered To Someone Else' => sub {
    my $api        = create_api();
    my $mocked_api = mock_response(
        method   => 'GetWPPSInfo',
        response => {
            ErrCount => 1,
            errors   => [ 'Domain name not found' ],
        }
    );


    throws_ok {
        $api->get_is_privacy_auto_renew_by_name( $NOT_MY_DOMAIN->name );
    } qr/Domain not found in your account/, 'Throws on domain registered to someone else';

    $mocked_api->unmock_all;
};

subtest 'Get Privacy Auto Renew For Domain That Lacks Privacy' => sub {
    my $api    = create_api();
    my $domain = create_domain( is_private => 0 );
    my $mocked_api = mock_response(
        method   => 'GetWPPSInfo',
        response => {
            ErrCount    => 0,
            GetWPPSInfo => {
                WPPSExists => 0
            }
        }
    );

    throws_ok {
        $api->get_is_privacy_auto_renew_by_name( $domain->name );
    } qr/Domain does not have privacy/, 'Throws on domain without privacy';

    $mocked_api->unmock_all;
};

subtest 'Get Privacy Auto Renew For Domain With Privacy' => sub {
    subtest 'Auto Renew Enabled' => sub {
        my $api    = create_api();
        my $domain = create_domain({
            is_private    => 1,
            is_auto_renew => 1,
        });

        my $mocked_api = mock_get_wpps_info(
            is_auto_renew   => 1,
            expiration_date => DateTime->now->add( years => 1 )
        );

        my $is_privacy_auto_renew;
        lives_ok {
            $is_privacy_auto_renew = $api->get_is_privacy_auto_renew_by_name( $domain->name );
        } 'Lives through retrieving privacy auto renew';

        $mocked_api->unmock_all;

        cmp_ok( $is_privacy_auto_renew, '==', 1, 'Correct privacy auto renew' );
    };

    subtest 'Auto Renew Disabled' => sub {
        my $api    = create_api();
        my $domain = create_domain({
            is_private    => 1,
            is_auto_renew => 0,
        });

        my $mocked_api = mock_get_wpps_info(
            is_auto_renew   => 0,
            expiration_date => DateTime->now->add( years => 1 )
        );

        my $is_privacy_auto_renew;
        lives_ok {
            $is_privacy_auto_renew = $api->get_is_privacy_auto_renew_by_name( $domain->name );
        } 'Lives through retrieving privacy auto renew';

        $mocked_api->unmock_all;

        cmp_ok( $is_privacy_auto_renew, '==', 0, 'Correct privacy auto renew' );
    };
};

done_testing;

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

use DateTime;

subtest 'Get Privacy Expiration Date For Unregistered Domain' => sub {
    my $api        = create_api();
    my $mocked_api = mock_response(
        method   => 'GetWPPSInfo',
        response => {
            ErrCount => 1,
            errors   => [ 'Domain name not found' ],
        }
    );

    throws_ok {
        $api->get_privacy_expiration_date_by_name( $UNREGISTERED_DOMAIN->name );
    } qr/Domain not found in your account/, 'Throws on unregistered domain';

    $mocked_api->unmock_all;
};

subtest 'Get Privacy Privacy Expiration For Domain Registered To Someone Else' => sub {
    my $api        = create_api();
    my $mocked_api = mock_response(
        method   => 'GetWPPSInfo',
        response => {
            ErrCount => 1,
            errors   => [ 'Domain name not found' ],
        }
    );

    throws_ok {
        $api->get_privacy_expiration_date_by_name( $NOT_MY_DOMAIN->name );
    } qr/Domain not found in your account/, 'Throws on domain registered to someone else';

    $mocked_api->unmock_all;
};

subtest 'Get Privacy Expiration Date For Domain That Lacks Privacy' => sub {
    my $api    = create_api();
    my $domain = create_domain( is_private => 0 );

    my $mocked_api = mock_response(
        method   => 'GetWPPSInfo',
        response => {
            ErrCount    => 0,
            GetWPPSInfo => {
                WPPSExists => 0,
            }
        }
    );

    throws_ok {
        $api->get_privacy_expiration_date_by_name( $domain->name );
    } qr/Domain does not have privacy/, 'Throws on domain without privacy';

    $mocked_api->unmock_all;
};

subtest 'Get Privacy Expiration Date For Domain With Privacy' => sub {
    my $api    = create_api();
    my $domain = create_domain( is_private => 1 );

    my $mocked_api = mock_get_wpps_info(
        is_auto_renew   => $domain->is_auto_renew,
        expiration_date => DateTime->now->add( years => 1 ),
    );

    my $privacy_expiration_date;
    lives_ok {
        $privacy_expiration_date = $api->get_privacy_expiration_date_by_name( $domain->name );
    } 'Lives through retrieving privacy expiration date';

    $mocked_api->unmock_all;

    cmp_ok( $privacy_expiration_date->year, '==', DateTime->now->add( years => 1 )->year, 'Correct privacy expiration date' );
};

done_testing;

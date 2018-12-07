#!/usr/bin/env perl

################################################################################
# NOTE - This filename does not match the method (unlike all other test files) #
# on purpose.  This is because a length of 40 characters in a file name is     #
# too long for VMS Systems                                                     #
################################################################################

use strict;
use warnings;

use Test::More;
use Test::Exception;
use String::Random qw( random_string );

use FindBin;
use lib "$FindBin::Bin/../../../lib";
use Test::WWW::eNom qw( create_api mock_response );
use Test::WWW::eNom::Domain qw( create_domain mock_domain_retrieval mock_set_renew $UNREGISTERED_DOMAIN $NOT_MY_DOMAIN );
use Test::WWW::eNom::Service qw( mock_get_wpps_info );

subtest 'Disable Domain Privacy Auto Renew On Unregistered Domain' => sub {
    my $api        = create_api();
    my $mocked_api = mock_response(
        method   => 'GetWPPSInfo',
        response => {
            ErrCount => 1,
            errors   => [ 'Domain name not found' ],
        }
    );

    throws_ok {
        $api->disable_privacy_auto_renew_for_domain( $UNREGISTERED_DOMAIN );
    } qr/Domain not found in your account/, 'Throws on unregistered domain';

    $mocked_api->unmock_all;
};

subtest 'Disable Domain Privacy Auto Renew On Domain Registered To Someone Else' => sub {
    my $api        = create_api();
    my $mocked_api = mock_response(
        method   => 'GetWPPSInfo',
        response => {
            ErrCount => 1,
            errors   => [ 'Domain name not found' ],
        }
    );

    throws_ok {
        $api->disable_privacy_auto_renew_for_domain( $NOT_MY_DOMAIN );
    } qr/Domain not found in your account/, 'Throws on unregistered domain';

    $mocked_api->unmock_all;
};

subtest 'Disable Domain Privacy Auto Renew On Domain Without Privacy' => sub {
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
        $api->disable_privacy_auto_renew_for_domain( $domain );
    } qr/Domain does not have privacy/, 'Throws on domain without privacy';

    $mocked_api->unmock_all;
};

subtest 'Disable Domain Privacy Auto Renew On Domain With Privacy Auto Renew On' => sub {
    my $api    = create_api();
    my $domain = create_domain({
        is_private    => 1,
        is_auto_renew => 1,
    });

    my $mocked_api = mock_get_wpps_info(
        is_auto_renew   => 1,
        expiration_date => DateTime->now->add( years => 1 ),
    );

    mock_set_renew( mocked_api => $mocked_api );
    mock_domain_retrieval(
        mocked_api    => $mocked_api,
        name          => $domain->name,
        is_auto_renew => 1,
    );

    cmp_ok( $api->get_is_privacy_auto_renew_by_name( $domain->name ), '==', 1, 'Original privacy auto renew' );

    my $retrieved_domain;
    lives_ok {
        $retrieved_domain = $api->disable_privacy_auto_renew_for_domain( $domain );
    } 'Lives through enabling privacy auto renew';

    $mocked_api->unmock_all;

    $mocked_api = mock_get_wpps_info(
        is_auto_renew   => 0,
        expiration_date => DateTime->now->add( years => 1 ),
    );

    cmp_ok( $api->get_is_privacy_auto_renew_by_name( $domain->name ), '==', 0, 'Privacy now not auto renew' );

    $mocked_api->unmock_all;
};

subtest 'Disable Domain Privacy Auto Renew On Domain With Privacy Auto Renew Off' => sub {
    my $api    = create_api();
    my $domain = create_domain({
        is_private    => 1,
        is_auto_renew => 0,
    });

    my $mocked_api = mock_get_wpps_info(
        is_auto_renew   => 0,
        expiration_date => DateTime->now->add( years => 1 ),
    );

    mock_set_renew( mocked_api => $mocked_api );
    mock_domain_retrieval(
        mocked_api    => $mocked_api,
        name          => $domain->name,
        is_auto_renew => 0,
    );

    cmp_ok( $api->get_is_privacy_auto_renew_by_name( $domain->name ), '==', 0, 'Original privacy not auto renew' );

    my $retrieved_domain;
    lives_ok {
        $retrieved_domain = $api->disable_privacy_auto_renew_for_domain( $domain );
    } 'Lives through enabling privacy auto renew';

    cmp_ok( $api->get_is_privacy_auto_renew_by_name( $domain->name ), '==', 0, 'Privacy now not auto renew' );
};

done_testing;

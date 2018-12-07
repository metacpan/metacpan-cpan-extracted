#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::Exception;
use String::Random qw( random_string );

use FindBin;
use lib "$FindBin::Bin/../../../lib";
use Test::WWW::eNom qw( create_api mock_response );
use Test::WWW::eNom::Domain qw( create_domain mock_get_reg_lock $UNREGISTERED_DOMAIN $NOT_MY_DOMAIN );

subtest 'Get Lock Status For Unregistered Domain' => sub {
    my $api = create_api();

    my $mocked_api = mock_response(
        method   => 'GetRegLock',
        response => {
            ErrCount => 1,
            RRPText  => 'Object does not exist',
        }
    );

    throws_ok{
        $api->get_is_domain_locked_by_name( $UNREGISTERED_DOMAIN->name );
    } qr/Domain is not registered/, 'Throws on unregistered domain';

    $mocked_api->unmock_all;
};

subtest 'Get Lock Status For Domain Registered To Someone Else' => sub {
    my $api = create_api();

    my $mocked_api = mock_response(
        method   => 'GetRegLock',
        response => {
            ErrCount => 1,
            RRPText  => 'Command blocked',
        }
    );

    throws_ok{
        $api->get_is_domain_locked_by_name( $NOT_MY_DOMAIN->name );
    } qr/Domain owned by someone else/, 'Throws on domain registered to someone else';

    $mocked_api->unmock_all;
};

subtest 'Get Lock Status - Unlocked Domain' => sub {
    my $api    = create_api();
    my $domain = create_domain({
        is_locked => 0,
    });

    my $mocked_api = mock_get_reg_lock( is_locked => $domain->is_locked );

    my $is_locked;
    lives_ok {
        $is_locked = $api->get_is_domain_locked_by_name( $domain->name );
    } 'Lives through getting domain lock status';

    $mocked_api->unmock_all;

    cmp_ok( $is_locked, '==', 0, 'Correctly not locked' );
};

subtest 'Get Lock Status - Locked Domain' => sub {
    my $api    = create_api();
    my $domain = create_domain({
        is_locked => 1,
    });

    my $mocked_api = mock_get_reg_lock( is_locked => $domain->is_locked );

    my $is_locked;
    lives_ok {
        $is_locked = $api->get_is_domain_locked_by_name( $domain->name );
    } 'Lives through getting domain lock status';

    $mocked_api->unmock_all;

    cmp_ok( $is_locked, '==', 1, 'Correctly locked' );
};

done_testing;

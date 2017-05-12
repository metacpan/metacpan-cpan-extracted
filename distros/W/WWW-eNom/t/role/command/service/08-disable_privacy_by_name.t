#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::Exception;
use String::Random qw( random_string );

use FindBin;
use lib "$FindBin::Bin/../../../lib";
use Test::WWW::eNom qw( create_api );
use Test::WWW::eNom::Domain qw( create_domain $UNREGISTERED_DOMAIN $NOT_MY_DOMAIN );

subtest 'Disable Privacy For Unregistered Domain' => sub {
    my $api = create_api();

    throws_ok {
        $api->disable_privacy_by_name( $UNREGISTERED_DOMAIN->name );
    } qr/Domain not found in your account/, 'Throws on unregistered domain';
};

subtest 'Disable Privacy For Domain Registered To Someone Else' => sub {
    my $api = create_api();

    throws_ok {
        $api->disable_privacy_by_name( $NOT_MY_DOMAIN->name );
    } qr/Domain not found in your account/, 'Throws on domain registered to someone else';
};

subtest 'Disable Privacy For Domain That Lacks Privacy' => sub {
    my $api    = create_api();
    my $domain = create_domain( is_private => 0 );

    cmp_ok( $api->get_is_privacy_purchased_by_name( $domain->name ), '==', 0, 'Original domain correctly lacks privacy' );

    my $retrieved_domain;
    lives_ok {
        $retrieved_domain = $api->disable_privacy_by_name( $domain->name );
    } 'Lives through disabling privacy';

    cmp_ok( $api->get_is_privacy_purchased_by_name( $domain->name ), '==', 0, 'Domain lacks privacy purchased' );
    cmp_ok( $retrieved_domain->is_private, '==', 0, 'Domain correctly not private' );
};

subtest 'Disable Privacy For Domain With Privacy' => sub {
    subtest 'Privacy Enabled' => sub {
        my $api    = create_api();
        my $domain = create_domain( is_private => 1 );

        my $retrieved_domain;
        lives_ok {
            $retrieved_domain = $api->disable_privacy_by_name( $domain->name );
        } 'Lives through disabling privacy';

        cmp_ok( $retrieved_domain->is_private, '==', 0, 'Domain correctly not private' );
    };

    subtest 'Privacy Disabled' => sub {
        my $api    = create_api();
        my $domain = create_domain( is_private => 1 );

        lives_ok {
            $api->disable_privacy_by_name( $domain->name );
        } 'Lives through disabling privacy';

        my $retrieved_domain;
        lives_ok {
            $retrieved_domain = $api->disable_privacy_by_name( $domain->name );
        } 'Lives through disabling privacy';

        cmp_ok( $retrieved_domain->is_private, '==', 0, 'Domain correctly not private' );
    };
};

done_testing;

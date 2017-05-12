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

subtest 'Get Is Privacy Purchased For Unregistered Domain' => sub {
    my $api = create_api();

    throws_ok {
        $api->get_is_privacy_purchased_by_name( $UNREGISTERED_DOMAIN->name );
    } qr/Domain not found in your account/, 'Throws on unregistered domain';
};

subtest 'Get Is Privacy Purchased For Domain Registered To Someone Else' => sub {
    my $api = create_api();

    throws_ok {
        $api->get_is_privacy_purchased_by_name( $NOT_MY_DOMAIN->name );
    } qr/Domain not found in your account/, 'Throws on domain registered to someone else';
};

subtest 'Get Is Privacy Purchased For Domain That Lacks Privacy' => sub {
    my $api    = create_api();
    my $domain = create_domain( is_private => 0 );

    my $is_privacy_purchased;
    lives_ok {
        $is_privacy_purchased = $api->get_is_privacy_purchased_by_name( $domain->name );
    } 'Lives through checking if privacy was purchased';

    ok( !$is_privacy_purchased, 'Correctly lacks privacy being purchased' );
};

subtest 'Get Privacy Auto Renew For Domain With Privacy' => sub {
    subtest 'Privacy Enabled' => sub {
        my $api    = create_api();
        my $domain = create_domain({
            is_private    => 1,
            is_auto_renew => 1,
        });

        my $is_privacy_purchased;
        lives_ok {
            $is_privacy_purchased = $api->get_is_privacy_purchased_by_name( $domain->name );
        } 'Lives through checking if privacy was purchased';

        ok( $is_privacy_purchased, 'Correctly shows privacy being purchased' );
    };

    subtest 'Privacy Disabled' => sub {
        my $api    = create_api();
        my $domain = create_domain({
            is_private    => 1,
            is_auto_renew => 1,
        });

        lives_ok {
            $api->disable_privacy_by_name( $domain->name );
        } 'Lives through disabling domain privacy';

        my $is_privacy_purchased;
        lives_ok {
            $is_privacy_purchased = $api->get_is_privacy_purchased_by_name( $domain->name );
        } 'Lives through checking if privacy was purchased';

        ok( $is_privacy_purchased, 'Correctly shows privacy being purchased' );
    };
};

done_testing;

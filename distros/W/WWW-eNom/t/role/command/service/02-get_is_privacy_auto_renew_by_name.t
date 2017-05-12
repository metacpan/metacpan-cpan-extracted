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

subtest 'Get Privacy Auto Renew For Unregistered Domain' => sub {
    my $api = create_api();

    throws_ok {
        $api->get_is_privacy_auto_renew_by_name( $UNREGISTERED_DOMAIN->name );
    } qr/Domain not found in your account/, 'Throws on unregistered domain';
};

subtest 'Get Privacy Auto Renew For Domain Registered To Someone Else' => sub {
    my $api = create_api();

    throws_ok {
        $api->get_is_privacy_auto_renew_by_name( $NOT_MY_DOMAIN->name );
    } qr/Domain not found in your account/, 'Throws on domain registered to someone else';
};

subtest 'Get Privacy Auto Renew For Domain That Lacks Privacy' => sub {
    my $api    = create_api();
    my $domain = create_domain( is_private => 0 );

    throws_ok {
        $api->get_is_privacy_auto_renew_by_name( $domain->name );
    } qr/Domain does not have privacy/, 'Throws on domain without privacy';
};

subtest 'Get Privacy Auto Renew For Domain With Privacy' => sub {
    subtest 'Auto Renew Enabled' => sub {
        my $api    = create_api();
        my $domain = create_domain({
            is_private    => 1,
            is_auto_renew => 1,
        });

        my $is_privacy_auto_renew;
        lives_ok {
            $is_privacy_auto_renew = $api->get_is_privacy_auto_renew_by_name( $domain->name );
        } 'Lives through retrieving privacy auto renew';

        cmp_ok( $is_privacy_auto_renew, '==', 1, 'Correct privacy auto renew' );
    };

    subtest 'Auto Renew Disabled' => sub {
        my $api    = create_api();
        my $domain = create_domain({
            is_private    => 1,
            is_auto_renew => 0,
        });

        my $is_privacy_auto_renew;
        lives_ok {
            $is_privacy_auto_renew = $api->get_is_privacy_auto_renew_by_name( $domain->name );
        } 'Lives through retrieving privacy auto renew';

        cmp_ok( $is_privacy_auto_renew, '==', 0, 'Correct privacy auto renew' );
    };
};

done_testing;

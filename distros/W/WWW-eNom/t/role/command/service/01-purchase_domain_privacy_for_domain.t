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

use DateTime;

subtest 'Purchase Domain Privacy For Unregistered Domain' => sub {
    my $api = create_api();

    throws_ok{
        $api->purchase_domain_privacy_for_domain({
            domain_name   => $UNREGISTERED_DOMAIN->name,
            years         => 1,
            is_auto_renew => 0,
        });
    } qr/Domain not found in your account/, 'Throws on unregistered domain';
};

subtest 'Purchase Domain Privacy For Domain Registered To Someone Else' => sub {
    my $api = create_api();

    throws_ok{
        $api->purchase_domain_privacy_for_domain({
            domain_name   => $NOT_MY_DOMAIN->name,
            years         => 1,
            is_auto_renew => 0,
        });
    } qr/Domain not found in your account/, 'Throws on domain registered to someone else';
};

subtest 'Purchase Domain Privacy For Domain - 1 Years - Manual Renew' => sub {
    my $api    = create_api();
    my $domain = create_domain( is_private => 0 );

    lives_ok {
        $api->purchase_domain_privacy_for_domain({
            domain_name   => $domain->name,
            years         => 1,
            is_auto_renew => 0,
        });
    } 'Lives through purchase of domain privacy';

    subtest 'Inspect Domain' => sub {
        my $retrieved_domain;
        lives_ok {
            $retrieved_domain = $api->get_domain_by_name( $domain->name );
        } 'Lives through retrieving domain';

        cmp_ok( $retrieved_domain->is_private, '==', 1, 'Correct is_private' );
    };

    subtest 'Inspect Privacy Service' => sub {
        my $is_privacy_auto_renew = $api->get_is_privacy_auto_renew_by_name( $domain->name );
        cmp_ok( $is_privacy_auto_renew, '==', 0, 'Correct privacy auto renew' );

        my $privacy_expiration_date = $api->get_privacy_expiration_date_by_name( $domain->name );
        cmp_ok( $privacy_expiration_date->year - DateTime->now->year, 'eq', 1, 'Correct years' );
    };
};

subtest 'Purchase Domain Privacy For Domain - 2 Years - Auto Renew' => sub {
    my $api    = create_api();
    my $domain = create_domain( is_private => 0 );

    lives_ok {
        $api->purchase_domain_privacy_for_domain({
            domain_name   => $domain->name,
            years         => 2,
            is_auto_renew => 1,
        });
    } 'Lives through purchase of domain privacy';

    subtest 'Inspect Domain' => sub {
        my $retrieved_domain;
        lives_ok {
            $retrieved_domain = $api->get_domain_by_name( $domain->name );
        } 'Lives through retrieving domain';

        cmp_ok( $retrieved_domain->is_private, '==', 1, 'Correct is_private' );
    };

    subtest 'Inspect Privacy Service' => sub {
        my $is_privacy_auto_renew = $api->get_is_privacy_auto_renew_by_name( $domain->name );
        cmp_ok( $is_privacy_auto_renew, '==', 1, 'Correct privacy auto renew' );

        my $privacy_expiration_date = $api->get_privacy_expiration_date_by_name( $domain->name );
        cmp_ok( $privacy_expiration_date->year - DateTime->now->year, 'eq', 2, 'Correct years' );
    };
};

subtest 'Purchase Domain privacy For Domain That Already Has It' => sub {
    my $api    = create_api();
    my $domain = create_domain( is_private => 1 );

    throws_ok {
        $api->purchase_domain_privacy_for_domain({
            domain_name   => $domain->name,
        });
    } qr/Domain privacy is already purchased for this domain/, 'Throws if domain privacy has already been purchased';
};

done_testing;

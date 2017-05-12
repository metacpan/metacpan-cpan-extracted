#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::Exception;

use FindBin;
use lib "$FindBin::Bin/../../../lib";
use Test::WWW::eNom qw( create_api );
use Test::WWW::eNom::Domain qw( create_domain $UNREGISTERED_DOMAIN $NOT_MY_DOMAIN );

subtest 'Renew Domain Privacy On Unregistered Domain' => sub {
    my $api = create_api();

    throws_ok {
        $api->renew_privacy({
            domain_name => $UNREGISTERED_DOMAIN->name,
            years       => 1,
        });
    } qr/Domain not found in your account/, 'Throws on unregistered domain';
};

subtest 'Renew Domain Privacy On Domain Registered To Someone Else' => sub {
    my $api = create_api();

    throws_ok {
        $api->renew_privacy({
            domain_name => $NOT_MY_DOMAIN->name,
            years       => 1,
        });
    } qr/Domain not found in your account/, 'Throws on domain registered to someone else';
};

subtest 'Renew Domain Privacy On Domain Without Privacy' => sub {
    my $api    = create_api();
    my $domain = create_domain( is_private => 0 );

    throws_ok {
        $api->renew_privacy({
            domain_name => $domain->name,
            years       => 1,
        });
    } qr/Domain does not have privacy/, 'Throws on domain without privacy';
};

subtest 'Renew Domain Privacy - Too Long of a Renewal' => sub {
    my $api    = create_api();
    my $domain = create_domain(
        is_private => 1,
        years      => 1,
    );

    subtest '20 Years at Once' => sub {
        throws_ok {
            $api->renew_privacy({
                domain_name => $domain->name,
                years       => 20,
            });
        } qr/Requested renewal too long/, 'Throws on too long of renewal';
    };
};

subtest 'Renew Domain Privacy - Valid Length of Time' => sub {
    my $api    = create_api();
    my $domain = create_domain( is_private => 1 );

    my $initial_privacy_expiration_date = $api->get_privacy_expiration_date_by_name( $domain->name );

    my $order_id;
    lives_ok {
        $order_id = $api->renew_privacy({
            domain_name => $domain->name,
            years       => 1,
        });
    } 'Lives through renewal';

    like( $order_id, qr/^\d+$/, 'order_id looks numeric' );

    my $updated_privacy_expiration_date = $api->get_privacy_expiration_date_by_name( $domain->name );

    cmp_ok( $updated_privacy_expiration_date->year, '>', $initial_privacy_expiration_date->year, 'Correct expiration date' );
};

done_testing;

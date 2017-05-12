#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::Exception;

use FindBin;
use lib "$FindBin::Bin/../../../lib";
use Test::WWW::eNom qw( create_api );
use Test::WWW::eNom::Domain qw( create_domain $UNREGISTERED_DOMAIN $NOT_MY_DOMAIN );

subtest 'Renew Domain On Unregistered Domain' => sub {
    my $api = create_api();

    throws_ok {
        $api->renew_domain({
            domain_name => $UNREGISTERED_DOMAIN->name,
            years       => 1,
        });
    } qr/Domain not found in your account/, 'Throws on unregistered domain';
};

subtest 'Renew Domain On Domain Registered To Someone Else' => sub {
    my $api = create_api();

    throws_ok {
        $api->renew_domain({
            domain_name => $NOT_MY_DOMAIN->name,
            years       => 1,
        });
    } qr/Domain not found in your account/, 'Throws on domain registered to someone else';
};

subtest 'Renew Domain - Too Long of a Renewal' => sub {
    my $api    = create_api();
    my $domain = create_domain(
        is_private => 1,
        years      => 3,
    );

    subtest '20 Years at Once' => sub {
        throws_ok {
            $api->renew_domain({
                domain_name => $domain->name,
                years       => 20,
            });
        } qr/Requested renewal too long/, 'Throws on too long of renewal';
    };

    subtest '3 + 8' => sub {
        throws_ok {
            $api->renew_domain({
                domain_name => $domain->name,
                years       => 8,
            });
        } qr/Requested renewal too long/, 'Throws on too long of renewal';
    };
};

subtest 'Renew Domain - Valid Length of Time' => sub {
    my $api    = create_api();
    my $domain = create_domain( is_private => 1 );

    my $order_id;
    lives_ok {
        $order_id = $api->renew_domain({
            domain_name => $domain->name,
            years       => 1,
        });
    } 'Lives through renewal';

    like( $order_id, qr/^\d+$/, 'order_id looks numeric' );

    my $retrieved_domain = $api->get_domain_by_name( $domain->name );

    cmp_ok( $retrieved_domain->expiration_date->year, '>', $domain->expiration_date->year, 'Correct expiration date' );
};

done_testing;

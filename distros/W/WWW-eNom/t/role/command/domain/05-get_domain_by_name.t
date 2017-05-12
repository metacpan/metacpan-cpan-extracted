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

subtest 'Get Domain By Name - Unregistered Domain' => sub {
    my $api = create_api();

    throws_ok{
        $api->get_domain_by_name( $UNREGISTERED_DOMAIN->name );
    } qr/Domain not found in your account/, 'Throws on unregistered domain';
};

subtest 'Get Domain By Name - Domain Registered To Somone Else' => sub {
    my $api         = create_api();
    my $domain_name = 'enom.com';

    throws_ok{
        $api->get_domain_by_name( $NOT_MY_DOMAIN->name );
    } qr/Domain not found in your account/, 'Throws on domain registered to someone else';
};

subtest 'Get Domain By Name - Valid Domain' => sub {
    my $api    = create_api();
    my $domain = create_domain();

    my $retrieved_domain;
    lives_ok {
        $retrieved_domain = $api->get_domain_by_name( $domain->name );
    } 'Lives through fetching domain by name';

    is_deeply( $retrieved_domain, $domain, 'Correct domain' );
};

done_testing;

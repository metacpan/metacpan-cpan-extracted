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

subtest 'Lock Unregistered Domain' => sub {
    my $api = create_api();

    throws_ok {
        $api->enable_domain_lock_by_name( $UNREGISTERED_DOMAIN->name );
    } qr/Domain not found in your account/, 'Throws on unregistered domain';
};

subtest 'Lock Domain Registered To Someone Else' => sub {
    my $api = create_api();

    throws_ok {
        $api->enable_domain_lock_by_name( $NOT_MY_DOMAIN->name );
    } qr/Domain not found in your account/, 'Throws on domain registered to someone else';
};

subtest 'Lock Domain That Is Not Locked' => sub {
    my $api    = create_api();
    my $domain = create_domain( is_locked => 0 );

    my $retrieved_domain;
    lives_ok {
        $retrieved_domain = $api->enable_domain_lock_by_name( $domain->name );
    } 'Lives through locking domain';

    cmp_ok( $domain->is_locked, '==', 0, 'Original domain was not locked' );
    cmp_ok( $retrieved_domain->is_locked, '==', 1, 'Domain now correctly locked' );
};

subtest 'Lock Domain That Is Locked' => sub {
    my $api    = create_api();
    my $domain = create_domain( is_locked => 1 );

    my $retrieved_domain;
    lives_ok {
        $retrieved_domain = $api->enable_domain_lock_by_name( $domain->name );
    } 'Lives through locking domain';

    cmp_ok( $domain->is_locked, '==', 1, 'Original domain was locked' );
    cmp_ok( $retrieved_domain->is_locked, '==', 1, 'Domain now correctly locked' );
};

done_testing;

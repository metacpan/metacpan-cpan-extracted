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

subtest 'Unlock Unregistered Domain' => sub {
    my $api = create_api();

    throws_ok {
        $api->disable_domain_lock_by_name( $UNREGISTERED_DOMAIN->name );
    } qr/Domain not found in your account/, 'Throws on unregistered domain';
};

subtest 'Unlock Domain Registered To Someone Else' => sub {
    my $api = create_api();

    throws_ok {
        $api->disable_domain_lock_by_name( $NOT_MY_DOMAIN->name );
    } qr/Domain not found in your account/, 'Throws on domain registered to someone else';
};

subtest 'Unlock Domain That Is Locked' => sub {
    my $api    = create_api();
    my $domain = create_domain( is_locked => 1 );

    my $retrieved_domain;
    lives_ok {
        $retrieved_domain = $api->disable_domain_lock_by_name( $domain->name );
    } 'Lives through unlocking domain';

    cmp_ok( $domain->is_locked, '==', 1, 'Original domain was locked' );
    cmp_ok( $retrieved_domain->is_locked, '==', 0, 'Domain now correctly unlocked' );
};

subtest 'Unlock Domain That Is Unlocked' => sub {
    my $api    = create_api();
    my $domain = create_domain( is_locked => 0 );

    my $retrieved_domain;
    lives_ok {
        $retrieved_domain = $api->disable_domain_lock_by_name( $domain->name );
    } 'Lives through unlocking domain';

    cmp_ok( $domain->is_locked, '==', 0, 'Original domain was unlocked' );
    cmp_ok( $retrieved_domain->is_locked, '==', 0, 'Domain now correctly unlocked' );
};

done_testing;

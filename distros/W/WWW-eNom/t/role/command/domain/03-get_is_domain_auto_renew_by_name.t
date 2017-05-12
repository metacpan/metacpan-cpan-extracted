#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::Exception;
use Test::MockModule;
use String::Random qw( random_string );

use FindBin;
use lib "$FindBin::Bin/../../../lib";
use Test::WWW::eNom qw( create_api );
use Test::WWW::eNom::Domain qw( create_domain $UNREGISTERED_DOMAIN $NOT_MY_DOMAIN );

subtest 'Get Auto Renew Status For Unregistered Domain' => sub {
    my $api         = create_api();

    throws_ok{
        $api->get_is_domain_auto_renew_by_name( $UNREGISTERED_DOMAIN->name );
    } qr/Domain not found in your account/, 'Throws on unregistered domain';
};

subtest 'Get Auto Renew Status For Domain Registered To Somone Else' => sub {
    my $api         = create_api();

    throws_ok{
        $api->get_is_domain_auto_renew_by_name( $NOT_MY_DOMAIN->name );
    } qr/Domain not found in your account/, 'Throws on domain registered to someone else';
};

subtest 'Get Auto Renew Status - Manual Renew Domain' => sub {
    my $api    = create_api();
    my $domain = create_domain({
        is_auto_renew => 0,
    });

    my $is_auto_renew;
    lives_ok {
        $is_auto_renew = $api->get_is_domain_auto_renew_by_name( $domain->name );
    } 'Lives through getting domain auto renew status';

    cmp_ok( $is_auto_renew, '==', 0, 'Correctly not auto renew' );
};

subtest 'Get Auto Renew Status - Auto Renew Domain' => sub {
    my $api    = create_api();
    my $domain = create_domain({
        is_auto_renew => 1,
    });

    my $is_auto_renew;
    lives_ok {
        $is_auto_renew = $api->get_is_domain_auto_renew_by_name( $domain->name );
    } 'Lives through getting domain auto renew status';

    cmp_ok( $is_auto_renew, '==', 1, 'Correctly auto renew' );
};

subtest 'Get Auto Renew Status - Reactivation Period Domain' => sub {
    my $api = create_api();

    my $mocked_enom = Test::MockModule->new('WWW::eNom');
    $mocked_enom->mock('submit', sub {
        return {
            ErrCount => 1,
            errors   => [ 'This domain name is expired and cannot be updated' ],
        };
    });

    my $is_autorenew;
    lives_ok {
        $is_autorenew = $api->get_is_domain_auto_renew_by_name( 'mocked-call.com' );
    } 'Lives through getting auto renew status';

    ok( !$is_autorenew, 'Correctly not auto renew' );
};

done_testing;

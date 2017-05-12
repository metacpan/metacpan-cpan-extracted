#!/usr/bin/env perl

################################################################################
# NOTE - This filename does not match the method (unlike all other test files) #
# on purpose.  This is because a length of 40 characters in a file name is     #
# too long for VMS Systems                                                     #
################################################################################

use strict;
use warnings;

use Test::More;
use Test::Exception;
use String::Random qw( random_string );

use FindBin;
use lib "$FindBin::Bin/../../../lib";
use Test::WWW::eNom qw( create_api );
use Test::WWW::eNom::Domain qw( create_domain $UNREGISTERED_DOMAIN $NOT_MY_DOMAIN );

subtest 'Disable Domain Privacy Auto Renew On Unregistered Domain' => sub {
    my $api = create_api();

    throws_ok {
        $api->disable_privacy_auto_renew_for_domain( $UNREGISTERED_DOMAIN );
    } qr/Domain not found in your account/, 'Throws on unregistered domain';
};

subtest 'Disable Domain Privacy Auto Renew On Domain Registered To Someone Else' => sub {
    my $api = create_api();

    throws_ok {
        $api->disable_privacy_auto_renew_for_domain( $NOT_MY_DOMAIN );
    } qr/Domain not found in your account/, 'Throws on unregistered domain';
};

subtest 'Disable Domain Privacy Auto Renew On Domain Without Privacy' => sub {
    my $api    = create_api();
    my $domain = create_domain( is_private => 0 );

    throws_ok {
        $api->disable_privacy_auto_renew_for_domain( $domain );
    } qr/Domain does not have privacy/, 'Throws on domain without privacy';
};

subtest 'Disable Domain Privacy Auto Renew On Domain With Privacy Auto Renew On' => sub {
    my $api    = create_api();
    my $domain = create_domain({
        is_private    => 1,
        is_auto_renew => 1,
    });

    cmp_ok( $api->get_is_privacy_auto_renew_by_name( $domain->name ), '==', 1, 'Original privacy auto renew' );

    my $retrieved_domain;
    lives_ok {
        $retrieved_domain = $api->disable_privacy_auto_renew_for_domain( $domain );
    } 'Lives through enabling privacy auto renew';

    cmp_ok( $api->get_is_privacy_auto_renew_by_name( $domain->name ), '==', 0, 'Privacy now not auto renew' );
};

subtest 'Disable Domain Privacy Auto Renew On Domain With Privacy Auto Renew Off' => sub {
    my $api    = create_api();
    my $domain = create_domain({
        is_private    => 1,
        is_auto_renew => 0,
    });

    cmp_ok( $api->get_is_privacy_auto_renew_by_name( $domain->name ), '==', 0, 'Original privacy not auto renew' );

    my $retrieved_domain;
    lives_ok {
        $retrieved_domain = $api->disable_privacy_auto_renew_for_domain( $domain );
    } 'Lives through enabling privacy auto renew';

    cmp_ok( $api->get_is_privacy_auto_renew_by_name( $domain->name ), '==', 0, 'Privacy now not auto renew' );
};

done_testing;

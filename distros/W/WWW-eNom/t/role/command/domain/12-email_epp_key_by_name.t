#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::Exception;

use FindBin;
use lib "$FindBin::Bin/../../../lib";
use Test::WWW::eNom qw( create_api mock_response );
use Test::WWW::eNom::Domain qw( create_domain $UNREGISTERED_DOMAIN $NOT_MY_DOMAIN );

subtest 'Email EPP Key On Unregistered Domain' => sub {
    my $api        = create_api();
    my $mocked_api = mock_response(
        method   => 'GetSubAccountPassword',
        response => {
            ErrCount => 1,
            errors   => [ 'Domain is not available to get password' ],
        }
    );

    throws_ok {
        $api->email_epp_key_by_name( $UNREGISTERED_DOMAIN->name );
    } qr/Domain not found in your account/, 'Throws on unregistered domain';

    $mocked_api->unmock_all;
};

subtest 'Email EPP Key On Domain Registered To Someone Else' => sub {
    my $api        = create_api();
    my $mocked_api = mock_response(
        method   => 'GetSubAccountPassword',
        response => {
            ErrCount => 1,
            errors   => [ 'Domain is not available to get password' ],
        }
    );

    throws_ok {
        $api->email_epp_key_by_name( $NOT_MY_DOMAIN->name );
    } qr/Domain not found in your account/, 'Throws on unregistered domain';

    $mocked_api->unmock_all;
};

subtest 'Email EPP Key On Domain' => sub {
    my $api        = create_api();
    my $domain     = create_domain();
    my $mocked_api = mock_response(
        method   => 'GetSubAccountPassword',
        response => {
            ErrCount => 0,
        }
    );

    lives_ok {
        $api->email_epp_key_by_name( $domain->name );
    } 'Lives through emailing epp key';

    $mocked_api->unmock_all;
};

done_testing;

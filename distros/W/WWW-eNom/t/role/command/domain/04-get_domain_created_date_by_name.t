#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::Exception;
use String::Random qw( random_string );

use FindBin;
use lib "$FindBin::Bin/../../../lib";
use Test::WWW::eNom qw( create_api mock_response );
use Test::WWW::eNom::Domain qw( create_domain mock_get_whois_contact $UNREGISTERED_DOMAIN $NOT_MY_DOMAIN );

use DateTime;

subtest 'Get Created Date For Unregistered Domain' => sub {
    my $api = create_api();

    my $mocked_api = mock_response(
        method   => 'GetWhoisContact',
        response => {
            ErrCount => 1,
            errors   => [ 'No results found' ]
        }
    );

    throws_ok{
        $api->get_domain_created_date_by_name( $UNREGISTERED_DOMAIN->name );
    } qr/Domain not found in your account/, 'Throws on unregistered domain';

    $mocked_api->unmock_all;
};

subtest 'Get Created Date For Domain Registered To Somone Else' => sub {
    my $api = create_api();

    my $mocked_api = mock_response(
        method   => 'GetWhoisContact',
        response => {
            ErrCount => 1,
            errors   => [ 'No results found' ]
        }
    );

    throws_ok{
        $api->get_domain_created_date_by_name( $NOT_MY_DOMAIN->name );
    } qr/Domain not found in your account/, 'Throws on domain registered to someone else';

    $mocked_api->unmock_all;
};

subtest 'Get Created Date for Valid Domain' => sub {
    my $api    = create_api();
    my $domain = create_domain();

    my $mocked_api = mock_get_whois_contact(
        created_date => DateTime->now( time_zone => 'UTC' )
    );

    my $created_date;
    lives_ok {
        $created_date = $api->get_domain_created_date_by_name( $domain->name );
    } 'Lives through retrieving created_date';

    $mocked_api->unmock_all;

    cmp_ok( $created_date->time_zone->name, 'eq', 'UTC', 'Correct time_zone' );
    cmp_ok( $created_date->ymd, 'eq', DateTime->now( time_zone => 'UTC' )->ymd, 'Correct created_date' );
};

done_testing;

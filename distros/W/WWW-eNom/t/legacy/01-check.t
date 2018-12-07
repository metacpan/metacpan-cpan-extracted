#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::Exception;

use FindBin;
use lib "$FindBin::Bin/../lib/";
use Test::WWW::eNom qw( create_api mock_response );

subtest 'Attempt to Check Status of Domain with Invalid Params' => sub {
    my $api        = create_api();
    my $mocked_api = mock_response(
        method   => 'Check',
        response => {
            ErrCount => 1,
            errors    => [ 'An SLD and TLD must be entered' ],
        }
    );

    my $response;
    lives_ok {
        $response = $api->Check( DomainFFFFFF => 'enom.*1' );
    } 'Lives through checking status of domain';

    cmp_ok( $response->{ErrCount},    '==', 1, 'Correct number of errors');
    cmp_ok( $response->{errors}->[0], 'eq', 'An SLD and TLD must be entered', 'Correct error message' );
};

subtest 'Attempt to Check Status of Malformed Domain' => sub {
    my $api = create_api();

    throws_ok {
        $api->Check( Domain => 'not-a-real-domain' );
    } qr/does not look like/, 'Throws on invalid domain';
};

subtest 'Get Status of Single SLD Single TLD using Domain' => sub {
    my $api        = create_api();
    my $mocked_api = mock_response(
        method   => 'Check',
        response => {
            ErrCount   => 0,
            DomainName => 'enom.com',
            RRPCode    => 211,
            RRPText    => 'Domain not available',
        }
    );

    my $response;
    lives_ok {
        $response = $api->Check( Domain => 'enom.com' );
    } 'Lives through checking status of domain';

    cmp_ok( $response->{ErrCount},   '==', 0,          'No errors' );
    cmp_ok( $response->{DomainName}, 'eq', 'enom.com', 'Correct DomainName' );
    cmp_ok( $response->{RRPCode},    '==', 211,        'Correct RRPCode Availability Response' );
    cmp_ok( $response->{RRPText},    'eq', 'Domain not available', 'Correct RRPText Availability Response' );
};

subtest 'Get Status of Single SLD Single TLD Using SLD and TLD' => sub {
    my $api        = create_api();
    my $mocked_api = mock_response(
        method   => 'Check',
        response => {
            ErrCount   => 0,
            DomainName => 'enom.com',
            RRPCode    => 211,
            RRPText    => 'Domain not available',
        }
    );

    my $response;
    lives_ok {
        $response = $api->Check(
            SLD  => 'enom',
            TLD => 'com',
        );
    } 'Lives through checking status of domain';

    cmp_ok( $response->{ErrCount},   '==', 0,          'No errors' );
    cmp_ok( $response->{DomainName}, 'eq', 'enom.com', 'Correct DomainName' );
    cmp_ok( $response->{RRPCode},    '==', 211,        'Correct RRPCode Availability Response' );
    cmp_ok( $response->{RRPText},    'eq', 'Domain not available', 'Correct RRPText Availability Response' );
};

subtest 'Get Status of Single SLD Multiple TLDs Using Domain' => sub {
    my $api = create_api();
    my $mocked_api = mock_response(
        method   => 'Check',
        response => {
            ErrCount => 0,
            Domain   => [ 'enom.com', 'enom.net', 'enom.org', 'enom.info', 'enom.biz', 'enom.ws', 'enom.us' ],
            RRPText  => [
                'Domain not available',
                'Domain not available',
                'Domain available',
                'No channels currently available',
                'No channels currently available',
                'Domain not available',
                'Domain not available'
            ],
            'RRPCode' => [ '211', '211', '210', '520', '520', '211', '211' ],
        }
    );

    my $response;
    lives_ok {
        $response = $api->Check( Domain => 'enom.*1' );
    } 'Lives through checking status of domain';

    cmp_ok( $response->{ErrCount}, '==', 0, 'No errors' );

    my @expected_responses = (
        { index => 0, domain => 'enom.com',  rrp_text => 'Domain not available',  rrp_code => 211 },
        { index => 1, domain => 'enom.net',  rrp_text => 'Domain not available',  rrp_code => 211 },
        { index => 2, domain => 'enom.org',  rrp_text => 'Domain available',      rrp_code => 210 },
        { index => 3, domain => 'enom.info', rrp_text => 'No channels currently available', rrp_code => 520 },
        { index => 4, domain => 'enom.biz',  rrp_text => 'No channels currently available', rrp_code => 520 },
        { index => 5, domain => 'enom.ws',   rrp_text => 'Domain not available',  rrp_code => 211 },
        { index => 6, domain => 'enom.us',   rrp_text => 'Domain not available',  rrp_code => 211 },
    );

    for my $expected_response ( @expected_responses ) {
        my $index = $expected_response->{index};

        subtest $expected_response->{domain} => sub {
            cmp_ok( $response->{Domain}->[ $index ],  'eq', $expected_response->{domain},   'Correct domain' );
            cmp_ok( $response->{RRPText}->[ $index ], 'eq', $expected_response->{rrp_text}, 'Correct rrp_text' );
            cmp_ok( $response->{RRPCode}->[ $index ], '==', $expected_response->{rrp_code}, 'Correct rrp_code' );
        };
    }
};

done_testing;

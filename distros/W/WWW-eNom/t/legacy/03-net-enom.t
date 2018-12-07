#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::Exception;
use Test::Warn;

use FindBin;
use lib "$FindBin::Bin/../lib/";
use Test::WWW::eNom qw( check_for_credentials $ENOM_USERNAME $ENOM_PASSWORD );

check_for_credentials();

subtest 'Deprecation Warning Is Emitted' => sub {
    warning_is {
        require Net::eNom;
    } 'This module is deprecated; use WWW::eNom instead.', 'Correct deprecation warning';
};

subtest 'Use Net::eNom instead of WWW::eNom' => sub {
    my $api;
    lives_ok {
        $api = Net::eNom->new({
            username => $ENOM_USERNAME,
            password => $ENOM_PASSWORD,
            test     => 1,
        });
    } 'Lives through creation of Net::eNom object';

    isa_ok( $api, 'Net::eNom' );

    my $mocked_api = Test::MockModule->new('Net::eNom');
    if( $ENV{USE_MOCK} ) {
        $mocked_api->mock( 'Check', sub {
            my $self = shift;

            note( 'Mocked Net::eNom->Check' );

            return {
                ErrCount   => 0,
                DomainName => 'enom.com',
                RRPCode    => 211,
                RRPText    => 'Domain not available',
            };
        });
    }

    my $response;
    lives_ok {
        $response = $api->Check( Domain => 'enom.com' );
    } 'Lives through checking status of domain';

    cmp_ok( $response->{ErrCount},   '==', 0,          'No errors' );
    cmp_ok( $response->{DomainName}, 'eq', 'enom.com', 'Correct DomainName' );
    cmp_ok( $response->{RRPCode},    '==', 211,        'Correct RRPCode Availability Response' );
    cmp_ok( $response->{RRPText},    'eq', 'Domain not available', 'Correct RRPText Availability Response' );
};

done_testing;

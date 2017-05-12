#!/usr/bin/env perl;

use strict;
use warnings;

use Data::GUID;
use LWP::ConsoleLogger::Easy qw( debug_ua );
use Test::Fatal qw( exception );
use Test::More;
use Test::RequiresInternet( 'pilot-payflowpro.paypal.com' => 443 );
use Try::Tiny;
use WebService::PayPal::PaymentsAdvanced;

use lib 't/lib';
use Util;

my $ua = LWP::UserAgent->new();
debug_ua($ua);

{
    foreach my $production_mode ( 0, 1 ) {
        my $payments = WebService::PayPal::PaymentsAdvanced->new(
            password        => 'seekrit',
            production_mode => $production_mode,
            ua              => $ua,
            user            => 'someuser',
            vendor          => 'PayPal',
        );

        isa_ok(
            $payments, 'WebService::PayPal::PaymentsAdvanced',
            'new object'
        );

        isa_ok(
            exception {
                my $res = $payments->create_secure_token( {} );
            },
            'WebService::PayPal::PaymentsAdvanced::Error::Authentication',
            ( $production_mode ? 'production' : 'sandbox' )
        );
    }
}

my $config;
try { $config = Util::config() };

SKIP: {
    skip 'config file required for live tests', 2, unless $config;

    my $payments = Util::ppa();

    my $token_id = Data::GUID->new->as_string;

    my $create_token = {
        AMT           => 100,
        BILLINGTYPE   => 'MerchantInitiatedBilling',
        CANCELURL     => 'http://example.com/cancel',
        ERRORURL      => 'http://example.com/error',
        LBILLINGTYPE0 => 'MerchantInitiatedBilling',
        NAME          => 'WebService::PayPal::PaymentsAdvanced',
        RETURNURL     => 'http://example.com/return',
        SECURETOKENID => $token_id,
        TRXTYPE       => 'S',
        VERBOSITY     => 'HIGH',
    };

    {
        my $res = $payments->create_secure_token($create_token);

        ok( $res, 'got response' );
        like( $res->message, qr{approved}i, 'approved' );
        ok( $res->secure_token, 'secure token' );
        cmp_ok(
            $res->secure_token_id, 'eq', $token_id,
            'token id unchanged'
        );
    }

    delete $create_token->{SECURETOKENID};

    {
        my $res = $payments->create_secure_token($create_token);
        ok( $res->secure_token, 'gets token when module generates own id' );

        my $uri = $res->hosted_form_uri;
        ok( $uri, 'got uri for hosted_form ' . $uri );
    }

    # zero dollar auth
    $create_token->{AMT} = 0;
    {
        my $res = $payments->create_secure_token($create_token);
        ok( $res->secure_token, 'gets token for zero dollar auth' );
    }

    {
        like(
            exception(
                sub {
                    $payments->post( { trxtype => 'V', origid => 'xfoox', } );
                }
            ),
            qr{Invalid tender}i,
            'Exception on voiding invalid transaction'
        );
    }

    # Some of these exception messages don't make a lot of sense.
    {
        like(
            exception(
                sub {
                    $payments->void_transaction('xfoox');
                }
            ),
            qr{Invalid tender}i,
            'Exception on voiding invalid transaction'
        );
    }

    {
        like(
            exception(
                sub {
                    $payments->inquiry_transaction(
                        { ORIGID => 'xfoox', TENDER => 'C', } );
                }
            ),
            qr{Field format error}i,
            'Exception on getting inquiry transaction for invalid id'
        );
    }
}

done_testing();

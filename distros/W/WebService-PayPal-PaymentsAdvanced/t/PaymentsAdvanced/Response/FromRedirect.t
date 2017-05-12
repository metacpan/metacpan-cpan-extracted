use strict;
use warnings;

use Test::More;
use Test::Fatal qw( exception );
use WebService::PayPal::PaymentsAdvanced;
use WebService::PayPal::PaymentsAdvanced::Response::FromRedirect;

my $payments = WebService::PayPal::PaymentsAdvanced->new(
    password => 'seekrit',
    user     => 'someuser',
    vendor   => 'PayPal',
);

my $params = {
    ACCT            => 9990,
    AMT             => 1.01,
    AUTHCODE        => 111111,
    AVSADDR         => 'Y',
    AVSDATA         => 'YYY',
    AVSZIP          => 'Y',
    BILLTOCOUNTRY   => 'US',
    BILLTOFIRSTNAME => 'Foo Bar',
    BILLTOLASTNAME  => 'Baz',
    BILLTONAME      => 'Foo Bar Baz',
    CARDTYPE        => 3,
    CORRELATIONID   => 'd064d8ae25107',
    COUNTRY         => 'US',
    COUNTRYTOSHIP   => 'US',
    CVV2MATCH       => 'Y',
    EXPDATE         => 1118,
    FIRSTNAME       => 'Foo Bar Baz',
    IAVS            => 'N',
    LASTNAME        => 'Baz',
    METHOD          => 'CC',
    NAME            => 'Foo Bar Baz',
    PNREF           => 'B73P7D8BB233',
    PPREF           => '75135880JY956953W',
    PROCAVS         => 'X',
    PROCCVV2        => 'M',
    RESPMSG         => 'Approved',
    RESULT          => 0,
    SECURETOKEN     => '8PbL3UE8NaUGOQdAtGzAY8wZf',
    SECURETOKENID   => 'DB034C3E-1914-11E5-9F6E-A581E074F348',
    SHIPTOCOUNTRY   => 'US',
    TAX             => 0.00,
    TENDER          => 'CC',
    TRANSTIME       => '2015-06-22 12:28:52',
    TRXTYPE         => 'S',
    TYPE            => 'S',
};

foreach my $method (
    'get_response_from_redirect',
    'get_response_from_silent_post'
    ) {
    {
        my $res = $payments->$method( { params => $params } );

        is( $res->message, 'Approved', 'response message' );
    }

    {
        my $res = $payments->$method(
            {
                ip_address => '173.0.81.1',
                params     => $params,
            }
        );

        is( $res->message, 'Approved', 'whitelisted IP' );
    }

    next unless $method eq 'get_response_from_silent_post';
    {
        isa_ok(
            exception {
                my $res = $payments->$method(
                    {
                        ip_address => '4.4.4.4',
                        params     => $params,
                    }
                );
            },
            'WebService::PayPal::PaymentsAdvanced::Error::IPVerification',
            'Bad IP exception'
        );

    }
}

done_testing();

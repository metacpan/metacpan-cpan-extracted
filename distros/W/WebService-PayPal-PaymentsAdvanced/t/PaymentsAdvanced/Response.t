use strict;
use warnings;

use WebService::PayPal::PaymentsAdvanced::Response;
use Test::Fatal;
use Test::More;

my %params = (
    RESPMSG       => 'Approved',
    RESPMSG       => 'User authentication failed',
    RESULT        => 1,
    SECURETOKEN   => 'token',
    SECURETOKENID => 'token_id',
);

{
    isa_ok(
        exception {
            WebService::PayPal::PaymentsAdvanced::Response->new(
                nonfatal_result_codes => [0],
                params                => \%params
            );
        },
        'WebService::PayPal::PaymentsAdvanced::Error::Authentication',
        'authentication exception'
    );

    isa_ok(
        WebService::PayPal::PaymentsAdvanced::Response->new(
            nonfatal_result_codes => [ 0, 1 ],
            params                => \%params,
        ),
        'WebService::PayPal::PaymentsAdvanced::Response',
        'no exception when result code is marked as non-fatal'
    );
}

done_testing();

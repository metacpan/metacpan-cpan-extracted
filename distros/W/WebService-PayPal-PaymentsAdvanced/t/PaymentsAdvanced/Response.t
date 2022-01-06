use strict;
use warnings;

use WebService::PayPal::PaymentsAdvanced::Response ();
use Test::Fatal qw( exception );
use Test::More;

my %params = (
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
    );

    isa_ok(
        WebService::PayPal::PaymentsAdvanced::Response->new(
            nonfatal_result_codes => [ 0, 1 ],
            params                => \%params,
        ),
        'WebService::PayPal::PaymentsAdvanced::Response',
    );
}

done_testing();

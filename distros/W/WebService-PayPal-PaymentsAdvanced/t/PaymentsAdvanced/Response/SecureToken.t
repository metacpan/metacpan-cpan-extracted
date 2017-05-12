use strict;
use warnings;

use Test::Fatal;
use Test::More;
use WebService::PayPal::PaymentsAdvanced::Response::SecureToken;

my %params = (
    RESULT        => 0,
    RESPMSG       => 'Approved',
    SECURETOKEN   => 'token',
    SECURETOKENID => 'token_id',
);

{
    my $res
        = WebService::PayPal::PaymentsAdvanced::Response::SecureToken->new(
        nonfatal_result_codes    => [0],
        params                   => \%params,
        payflow_link_uri         => 'http://example.com',
        validate_hosted_form_uri => 0,
        );

    is( $res->message,         'Approved', 'message' );
    is( $res->secure_token,    'token',    'token' );
    is( $res->secure_token_id, 'token_id', 'secure_token_id' );

    ok( $res,                  'can create response object' );
    ok( $res->hosted_form_uri, 'hosted_form_uri' );
}

done_testing();

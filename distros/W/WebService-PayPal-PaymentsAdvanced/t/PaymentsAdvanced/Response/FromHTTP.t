use strict;
use warnings;

use HTTP::Response;
use Test::Fatal qw( exception );
use Test::More;
use WebService::PayPal::PaymentsAdvanced::Response::FromHTTP;

subtest '200 status code' => sub {
    my $http_response = HTTP::Response->new( 200, undef, undef, 'RESULT=0' );

    my $payments_response
        = WebService::PayPal::PaymentsAdvanced::Response::FromHTTP->new(
        http_response => $http_response,
        request_uri   => 'http://www.paypal.com/',
        );

    ok( $payments_response, 'got response' );
};

subtest 'Maybe real 500' => sub {
    _test_error( undef, 'HTTP error (500): Server error' );
};

subtest 'Internal response 500' => sub {
    _test_error(
        [ 'Client-Warning' => 'Internal response' ],
        'User-agent internal error: Server error'
    );
};

subtest 'X-Died' => sub {
    _test_error(
        [ 'X-Died' => 'died' ],
        'User-agent died: died'
    );
};

subtest 'Aborted' => sub {
    _test_error(
        [ 'Client-Aborted' => 'died' ],
        'User-agent aborted: died'
    );
};

sub _test_error {
    my $headers          = shift;
    my $expected_message = shift;

    my $http_response
        = HTTP::Response->new( 500, undef, $headers, 'Server error' );

    my $ex = exception {
        WebService::PayPal::PaymentsAdvanced::Response::FromHTTP->new(
            http_response => $http_response,
            request_uri   => 'http://www.paypal.com/',
            )
    };

    isa_ok(
        $ex,
        'WebService::PayPal::PaymentsAdvanced::Error::HTTP',
        'HTTP error thrown'
    ) or return;

    is( $ex->message, $expected_message, qq{message of "$expected_message"} );
}

done_testing();

use strict;
use warnings;

use lib 't/lib';

use HTTP::Response ();
use Test::Fatal qw( exception );
use Test::LWP::UserAgent ();
use Test::More 0.88;
use Test::Warnings qw( :all );
use Test::WebService::MinFraud qw( read_data_file );
use WebService::MinFraud::Client          ();
use WebService::MinFraud::Model::Factors  ();
use WebService::MinFraud::Model::Insights ();
use WebService::MinFraud::Model::Score    ();

for my $service ( 'factors', 'insights', 'score' ) {
    subtest $service => sub {
        subtest 'test simple success' => sub {
            my $model = _run_request($service);

            is(
                $model->id, '27d26476-e2bc-11e4-92b8-962e705b4af5',
                'expected ID'
            );

            is(
                $model->ip_address->country->name, 'United Kingdom',
                'country name'
            ) if $service ne 'score';

        };

        subtest 'passing locales' => sub {
            my $model = _run_request(
                $service,
                { client_args => { locales => ['fr'] } }
            );
            is( $model->risk_score, 0.01, 'risk_score' );

            return if $service eq 'score';

            is(
                $model->ip_address->country->name, 'Royaume-Uni',
                'country name is in French'
            );
            is(
                $model->ip_address->city->name, 'Londres',
                'city name is in French'
            );

        };

        subtest '200 but invalid JSON' => sub {
            my $exception = exception {
                _run_request(
                    $service,
                    { response_content => '{1}' },
                    )
            };

            isa_ok(
                $exception, 'WebService::MinFraud::Error::Generic',
                'Correct exception type'
            );
            like(
                $exception,
                qr/but could not decode the response/,
                'Expected exception message'
            );
        };

        subtest 'INSUFFICIENT_FUNDS' => sub {
            _test_ws_error(
                $service,
                {
                    status_code => '402',
                    response_content =>
                        '{"code":"INSUFFICIENT_FUNDS","error":"out of funds"}',
                },
                qr/out of funds/,
            );
        };

        for my $error (
            'AUTHORIZATION_INVALID', 'LICENSE_KEY_REQUIRED',
            'USER_ID_REQUIRED'
        ) {
            subtest $error => sub {
                _test_ws_error(
                    $service,
                    {
                        status_code => '401',
                        response_content =>
                            qq{{"code":"$error","error":"Invalid auth"}},
                    },
                    qr/Invalid auth/,
                );
            };
        }

        subtest 'IP_ADDRESS_INVALID' => sub {
            _test_ws_error(
                $service,
                {
                    status_code => '400',
                    response_content =>
                        '{"code":"IP_ADDRESS_INVALID","error":"IP invalid"}',
                },
                qr/IP invalid/,
            );
        };

        subtest 'PERMISSION_REQUIRED' => sub {
            _test_ws_error(
                $service,
                {
                    status_code => '403',
                    response_content =>
                        '{"code":"PERMISSION_REQUIRED","error":"permission required"}',
                },
                qr/permission required/,
            );
        };

        subtest '400 with invalid JSON' => sub {
            _test_ws_error(
                $service,
                {
                    status_code      => '400',
                    response_content => '{0}',
                    exception_class  => 'WebService::MinFraud::Error::HTTP',
                },
                qr/with the following body: {0}/,
            );
        };

        subtest '400 with unexpected JSON' => sub {
            _test_ws_error(
                $service,
                {
                    status_code      => '400',
                    response_content => '{"unexpected": 1}',
                    exception_class => 'WebService::MinFraud::Error::Generic',
                },
                qr/Response contains JSON but it does not specify code or error keys/,
            );
        };

        subtest '300 status' => sub {
            _test_ws_error(
                $service,
                {
                    status_code     => '300',
                    exception_class => 'WebService::MinFraud::Error::HTTP',
                },
                qr/Received an unexpected HTTP status/,
            );
        };

        subtest '500 status' => sub {
            _test_ws_error(
                $service,
                {
                    status_code     => '500',
                    exception_class => 'WebService::MinFraud::Error::HTTP',
                },
                qr/Received a server error/,
            );
        };
    };
}

done_testing();

sub _test_ws_error {
    my $service          = shift;
    my $args             = shift;
    my $expected_message = shift;

    my $exception = exception {
        _run_request( $service, $args )
    };

    isa_ok(
        $exception,
        $args->{exception_class} || 'WebService::MinFraud::Error::WebService',
        'Correct exception type'
    );
    like(
        $exception,
        $expected_message,
        'Expected exception message'
    );
}

sub _run_request {
    my $service = shift;
    my $args = shift || {};

    my $request
        = $args->{requests} || { device => { ip_address => '1.1.1.1' } };

    my $ua = Test::LWP::UserAgent->new;
    $ua->map_response(
        sub { $_[0]->uri eq _uri_for($service) },
        HTTP::Response->new(
            $args->{status_code} || '200',
            'OK',
            [
                'Content-Type' =>
                    "application/vnd.maxmind.com-minfraud-${service}+json; charset=UTF-8; version=2.0"
            ],
            $args->{response_content}
                || read_data_file("${service}-response.json"),
        )
    );

    return WebService::MinFraud::Client->new(
        user_id     => 42,
        license_key => 'abcdef123456',
        ua          => $ua,
        %{ $args->{client_args} || {} }
    )->$service($request);
}

sub _uri_for {
    'https://minfraud.maxmind.com/minfraud/v2.0/' . $_[0];
}

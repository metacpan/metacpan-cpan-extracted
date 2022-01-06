use strict;
use warnings;

use HTTP::Response ();
use Test::Fatal qw( exception );
use Test::LWP::UserAgent ();
use Test::More;
use WebService::PayPal::PaymentsAdvanced::Response::SecureToken ();

my %params = (
    RESULT        => 0,
    RESPMSG       => 'Approved',
    SECURETOKEN   => 'token',
    SECURETOKENID => 'token_id',
);

{
    # validate_hosted_form_uri is 0, so we don't try an HTTP request.
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

subtest 'test success' => sub {
    my $ua = Test::LWP::UserAgent->new;

    $ua->map_response(
        'example.com',
        HTTP::Response->new(
            '200',                             'OK',
            [ 'Content-Type' => 'text/html' ], q{}
        )
    );

    my $res = _make_token_and_request( $ua, 1 );

    is(
        $res->{uri},
        'http://example.com?SECURETOKEN=token&SECURETOKENID=token_id',
        'uri is as expected'
    );
    is(
        $res->{callback_called_count}, 0,
        'callback called an expected number of times'
    );

    for my $mode ( 'LIVE', 'TEST' ) {
        $res = _make_token_and_request( $ua, 1, undef, $mode );

        is(
            $res->{uri},
            'http://example.com?SECURETOKEN=token&SECURETOKENID=token_id&MODE='
                . $mode,
            'hosted_form_mode set MODE=' . $mode,
        );
    }
};

subtest 'test error with no retries' => sub {
    my $ua = Test::LWP::UserAgent->new;

    $ua->map_response(
        'example.com',
        HTTP::Response->new(
            '500',                             'Internal Server Error',
            [ 'Content-Type' => 'text/html' ], q{}
        )
    );

    my $res = _make_token_and_request( $ua, 0 );

    isa_ok(
        $res->{exception},
        'WebService::PayPal::PaymentsAdvanced::Error::HTTP'
    );
    like(
        $res->{exception},
        qr{\QMade maximum number of HTTP requests. Tried 1 requests.\E},
        'received correct exception text'
    );
    is(
        $res->{callback_called_count}, 0,
        'callback called an expected number of times'
    );
};

subtest 'test error then success' => sub {
    my $ua = Test::LWP::UserAgent->new;

    my $should_succeed = 0;

    $ua->map_response(
        'example.com',
        sub {
            if ( !$should_succeed ) {
                return HTTP::Response->new(
                    '500', 'Internal Server Error',
                    [ 'Content-Type' => 'text/html' ], q{}
                );
            }
            return HTTP::Response->new(
                '200',                             'OK',
                [ 'Content-Type' => 'text/html' ], q{}
            );
        }
    );

    my $res = _make_token_and_request(
        $ua,
        1,

        # Get HTTP 200 after first HTTP 5xx.
        sub { $should_succeed = 1 }
    );

    is(
        $res->{uri},
        'http://example.com?SECURETOKEN=token&SECURETOKENID=token_id',
        'uri is as expected'
    );
    is(
        $res->{callback_called_count}, 1,
        'callback called an expected number of times'
    );
};

subtest 'test 4xx error' => sub {
    my $ua = Test::LWP::UserAgent->new;

    $ua->map_response(
        'example.com',
        HTTP::Response->new(
            '404',                             'Not Found',
            [ 'Content-Type' => 'text/html' ], q{}
        )
    );

    my $res = _make_token_and_request( $ua, 1 );

    isa_ok(
        $res->{exception},
        'WebService::PayPal::PaymentsAdvanced::Error::HTTP'
    );
    like(
        $res->{exception},
        qr{\Qhosted_form URI does not validate (http://example.com?SECURETOKEN=token&SECURETOKENID=token_id)\E},
        'received correct exception text'
    );
    is(
        $res->{callback_called_count}, 0,
        'callback called an expected number of times'
    );
};

sub _make_token_and_request {
    my $ua             = shift;
    my $retry_attempts = shift;
    my $callback       = shift;
    my $mode           = shift;

    my $callback_called_count = 0;

    # validate_hosted_form_uri == 1 means to make an HTTP request.
    my $res
        = WebService::PayPal::PaymentsAdvanced::Response::SecureToken->new(
        nonfatal_result_codes    => [0],
        params                   => \%params,
        payflow_link_uri         => 'http://example.com',
        validate_hosted_form_uri => 1,
        ua                       => $ua,
        retry_attempts           => $retry_attempts,
        retry_callback           => sub {
            is( scalar(@_), 1, 'expected number of parameters to callback' );
            my $res2 = shift;
            isa_ok(
                $res2, 'HTTP::Response',
                'parameter to callback is expected type'
            );
            $callback_called_count++;
            $callback->($res2) if defined $callback;
        },
        ( $mode ? ( hosted_form_mode => $mode ) : () ),
        );

    my $uri;
    my $ex = exception { $uri = $res->hosted_form_uri };

    return {
        uri                   => $uri,
        exception             => $ex,
        callback_called_count => $callback_called_count,
    };
}

done_testing();

use strict;
use warnings;

use Test::More 0.88;
use Test::Warnings 0.009 ':no_end_test', ':all';
use Test::Deep;
use Test::Fatal;
use Scalar::Util 'refaddr';

use Test::LWP::UserAgent;
use HTTP::Request::Common;

{
    my $useragent = Test::LWP::UserAgent->new;

    $useragent->map_response(qr/generic_error/, sub { die 'network error!' }); my $line = __LINE__;
    $useragent->map_response(qr/http_response_error/, sub { die HTTP::Response->new('504') });
    $useragent->map_response(qr/no_response_returned/, sub { return 'hi!' });

    my $file = __FILE__;

    test_send_request(
        'unexpected death',
        $useragent,
        GET('http://localhost/generic_error'),
        '500',
        [
            'Client-Warning' => 'Internal response',
            'Content-Type' => 'text/plain',
        ],
        (LWP::UserAgent->VERSION < 6.00
            ? "500 network error!\n"
            : re(qr/\Qnetwork error! at $file line $line.\E/)
        ),
    );

    test_send_request(
        'HTTP::Response death',
        $useragent,
        GET('http://localhost/http_response_error'),
        '504',
        [ ],
        '',
        undef,
    );

    test_send_request(
        'no death, but did not return HTTP::Response',
        $useragent,
        GET('http://localhost/no_response_returned'),
        '500',
        [],
        "500 Internal Server Error\n",
        qr/response from coderef is not a HTTP::Response, it's a non-reference at /,
    );
}

{
    note "\nNot capturing exceptions when processing the request, via use_eval => 0";

    my $useragent = Test::LWP::UserAgent->new(use_eval => 0);

    $useragent->map_response(qr/generic_error/, sub { die 'network error!' }); my $line = __LINE__;

    my $file = __FILE__;
    like(
        exception { $useragent->request(GET 'http://localhost/generic_error') },
        qr/\Qnetwork error! at $file line $line.\E/,
        'exception was not caught when processing request',
    );
}


sub test_send_request
{
    my ($name, $useragent, $request, $expected_code, $expected_headers, $expected_content, $expected_warning) = @_;

    note "\n$name";

    my $response;
    is(
        ($expected_warning
            ? exception {
                like(warning { $response = $useragent->request($request) },
                    $expected_warning, 'expected warning')
                }
            : exception { $response = $useragent->request($request) }),
        undef,
        'no exceptions when processing request',
    );

    isa_ok($response, 'HTTP::Response');
    is(
        refaddr($useragent->last_http_response_received),
        refaddr($response),
        'last_http_response_received',
    );

    my %header_spec = @$expected_headers;

    cmp_deeply(
        $response,
        methods(
            code => $expected_code,
            ( map { [ header => $_ ] => $header_spec{$_} } keys %header_spec ),
            content => $expected_content,
            request => $useragent->last_http_request_sent,
        ),
        'response',
    );

    is(
        refaddr($useragent->last_http_request_sent),
        refaddr($response->request),
        'request was stored in response',
    );

    ok(
        HTTP::Date::parse_date($response->header('Client-Date')),
        'Client-Date is a timestamp',
    );
}

had_no_warnings if $ENV{AUTHOR_TESTING};
done_testing;

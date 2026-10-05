use strict;
use warnings;
use Test::More;

use Uniform::HTTP::Request;
use Unblock::HTTP1::_Wire;

{
    package Unblock::HTTP1::UnsafeRequest;

    sub new {
        my ($class, %arg) = @_;
        return bless {
            method  => $arg{method} || 'GET',
            target  => $arg{target} || '/',
            headers => $arg{headers} || [ [ Host => 'example.test' ] ],
        }, $class;
    }
    sub method { $_[0]{method} }
    sub target { $_[0]{target} }
    sub version { '1.1' }
    sub protocol { undef }
    sub authority { undef }
    sub has_buffered_body { 0 }
    sub body { undef }
    sub trailer_count { 0 }
    sub header_count { scalar @{ $_[0]{headers} } }
    sub header_name { $_[0]{headers}[ $_[1] ][0] }
    sub header_value { $_[0]{headers}[ $_[1] ][1] }
}

{
    package Unblock::HTTP1::UnsafeResponse;

    sub new {
        my ($class, %arg) = @_;
        return bless {
            status  => exists($arg{status}) ? $arg{status} : 200,
            reason  => $arg{reason},
            headers => $arg{headers} || [],
        }, $class;
    }
    sub status { $_[0]{status} }
    sub reason { $_[0]{reason} }
    sub version { undef }
    sub has_buffered_body { 0 }
    sub body { undef }
    sub trailer_count { 0 }
    sub header_count { scalar @{ $_[0]{headers} } }
    sub header_name { $_[0]{headers}[ $_[1] ][0] }
    sub header_value { $_[0]{headers}[ $_[1] ][1] }
}

subtest 'request serializer rejects start-line and header injection' => sub {
    my @case = (
        [
            'method injection',
            Unblock::HTTP1::UnsafeRequest->new(
                method => "GET\r\nX-Evil:",
            ),
            qr/request method must be an HTTP token/,
        ],
        [
            'header name injection',
            Unblock::HTTP1::UnsafeRequest->new(
                headers => [
                    [ Host => 'example.test' ],
                    [ "X-Test\r\nInjected", 'value' ],
                ],
            ),
            qr/invalid header field name/,
        ],
        [
            'header value injection',
            Unblock::HTTP1::UnsafeRequest->new(
                headers => [
                    [ Host => 'example.test' ],
                    [ 'X-Test', "safe\r\nInjected: yes" ],
                ],
            ),
            qr/invalid header field value/,
        ],
    );

    for my $case (@case) {
        my ($name, $request, $pattern) = @$case;
        my $ok = eval {
            Unblock::HTTP1::_Wire::request_plan($request);
            1;
        };
        ok(!$ok, "$name is rejected");
        like($@, $pattern, "$name has an explicit error");
    }
};

subtest 'response serializer rejects header and reason injection' => sub {
    my $request = Uniform::HTTP::Request->new(
        method  => 'GET',
        target  => '/',
        headers => [ [ Host => 'example.test' ] ],
    );

    my @case = (
        [
            'response header name injection',
            Unblock::HTTP1::UnsafeResponse->new(
                headers => [ [ "X-Test\r\nInjected", 'value' ] ],
            ),
            qr/invalid header field name/,
        ],
        [
            'response header value injection',
            Unblock::HTTP1::UnsafeResponse->new(
                headers => [ [ 'X-Test', "safe\r\nInjected: yes" ] ],
            ),
            qr/invalid header field value/,
        ],
        [
            'reason phrase injection',
            Unblock::HTTP1::UnsafeResponse->new(
                reason => "OK\r\nInjected: yes",
            ),
            qr/invalid HTTP\/1 response reason phrase/,
        ],
        [
            'invalid HTTP status',
            Unblock::HTTP1::UnsafeResponse->new(
                status => 600,
            ),
            qr/response status must be a three-digit integer from 100 through 599/,
        ],
    );

    for my $case (@case) {
        my ($name, $response, $pattern) = @$case;
        my $ok = eval {
            Unblock::HTTP1::_Wire::response_plan($request, $response);
            1;
        };
        ok(!$ok, "$name is rejected");
        like($@, $pattern, "$name has an explicit error");
    }
};

done_testing;

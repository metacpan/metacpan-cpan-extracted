use strict;
use warnings;

use Scalar::Util qw(refaddr);
use Test::More;

use Uniform::HTTP::FastPath;
use Uniform::HTTP::Request;
use Uniform::HTTP::Response;
use Unblock::HTTP1::_Native;
use Unblock::HTTP1::_Wire;

my $request_wire =
    "GET /fast HTTP/1.1\r\n" .
    "Host: example.test\r\n" .
    "X-Test: one\r\n" .
    "X-Test: two\r\n" .
    "\r\n";

my $request_head =
    Unblock::HTTP1::_Native->parse_request_head($request_wire, 0, 100);
ok $request_head && $request_head->{ok}, 'request head parsed';

my $parsed_request_headers = $request_head->{headers};
my $request =
    Unblock::HTTP1::_Wire::_request_from_validated_head($request_head);

isa_ok $request, 'Uniform::HTTP::Request';
ok $request->is_complete, 'bodyless trusted request is complete';
ok !$request->is_mutable, 'bodyless trusted request is frozen';

my $request_view = Uniform::HTTP::FastPath::view($request);
is refaddr($request_view->[Uniform::HTTP::FastPath::SLOT_HEADERS()]),
    refaddr($parsed_request_headers),
    'trusted request adopts parser header storage';

my $borrowed_request_fields =
    Unblock::HTTP1::_Wire::_fields($request, 'header', $request_view);
is refaddr($borrowed_request_fields),
    refaddr($parsed_request_headers),
    'serializer borrows canonical request headers';

my $request_plan = Unblock::HTTP1::_Wire::request_plan($request);
like $request_plan->{wire}, qr/\AGET \/fast HTTP\/1\.1\r\n/,
    'canonical request serializes through fast path';
is refaddr(Uniform::HTTP::FastPath::view($request)
        ->[Uniform::HTTP::FastPath::SLOT_HEADERS()]),
    refaddr($parsed_request_headers),
    'request serialization does not replace borrowed headers';

my $body_request_wire =
    "POST /body HTTP/1.1\r\n" .
    "Host: example.test\r\n" .
    "Content-Length: 4\r\n" .
    "\r\n";

my $body_request_head =
    Unblock::HTTP1::_Native->parse_request_head($body_request_wire, 0, 100);
ok $body_request_head && $body_request_head->{ok}, 'body request head parsed';

my $body_request =
    Unblock::HTTP1::_Wire::_request_from_validated_head($body_request_head);
ok !$body_request->is_complete, 'body-bearing trusted request starts incomplete';
ok !$body_request->initial_is_mutable, 'trusted request initial section is frozen';
ok $body_request->body_is_mutable, 'trusted request body remains mutable';
ok $body_request->trailers_are_mutable, 'trusted request trailers remain mutable';

my $response_wire =
    "HTTP/1.1 200 OK\r\n" .
    "Content-Type: text/plain\r\n" .
    "Content-Length: 5\r\n" .
    "\r\n";

my $response_head =
    Unblock::HTTP1::_Native->parse_response_head($response_wire, 0, 100);
ok $response_head && $response_head->{ok}, 'response head parsed';

my $parsed_response_headers = $response_head->{headers};
my $response =
    Unblock::HTTP1::_Wire::_response_from_validated_head($response_head, 0);

isa_ok $response, 'Uniform::HTTP::Response';
ok !$response->is_complete, 'ordinary trusted response starts incomplete';
ok !$response->initial_is_mutable, 'trusted response initial section is frozen';
ok $response->body_is_mutable, 'trusted response body remains mutable';
ok $response->trailers_are_mutable, 'trusted response trailers remain mutable';

my $response_view = Uniform::HTTP::FastPath::view($response);
is refaddr($response_view->[Uniform::HTTP::FastPath::SLOT_HEADERS()]),
    refaddr($parsed_response_headers),
    'trusted response adopts parser header storage';

my $informational_head =
    Unblock::HTTP1::_Native->parse_response_head(
        "HTTP/1.1 103 Early Hints\r\nLink: </style.css>; rel=preload\r\n\r\n",
        0,
        100,
    );
ok $informational_head && $informational_head->{ok},
    'informational response head parsed';

my $informational =
    Unblock::HTTP1::_Wire::_response_from_validated_head(
        $informational_head, 1,
    );
ok $informational->is_complete, 'informational trusted response is complete';
ok !$informational->is_mutable, 'informational trusted response is frozen';

my $out_request = Uniform::HTTP::Request->new(
    method  => 'GET',
    target  => '/',
    headers => [ [ Host => 'example.test' ] ],
);
my $out_response = Uniform::HTTP::Response->new(
    status  => 200,
    headers => [ [ 'Content-Type' => 'text/plain' ] ],
    body    => 'hello',
);

ok Unblock::HTTP1::_Wire::_fast_request_view($out_request),
    'canonical request gets a fast-path view';
ok Unblock::HTTP1::_Wire::_fast_response_view($out_response),
    'canonical response gets a fast-path view';

my $response_plan =
    Unblock::HTTP1::_Wire::response_plan($out_request, $out_response);
like $response_plan->{wire}, qr/\AHTTP\/1\.1 200 OK\r\n/,
    'canonical response serializes through fast path';

{
    package Local::PortableRequest;
    use parent 'Uniform::HTTP::Request';

    package Local::PortableResponse;
    use parent 'Uniform::HTTP::Response';
}

my $portable_request = Local::PortableRequest->new(
    method  => 'GET',
    target  => '/',
    headers => [ [ Host => 'example.test' ] ],
);
my $portable_response = Local::PortableResponse->new(
    status => 200,
    body   => 'hello',
);

ok !Unblock::HTTP1::_Wire::_fast_request_view($portable_request),
    'request subclass does not use canonical fast path';
ok !Unblock::HTTP1::_Wire::_fast_response_view($portable_response),
    'response subclass does not use canonical fast path';

like Unblock::HTTP1::_Wire::request_plan($portable_request)->{wire},
    qr/\AGET \/ HTTP\/1\.1\r\n/,
    'request subclass still uses portable serializer';
like Unblock::HTTP1::_Wire::response_plan(
        $portable_request, $portable_response,
    )->{wire},
    qr/\AHTTP\/1\.1 200 OK\r\n/,
    'response subclass still uses portable serializer';

done_testing;

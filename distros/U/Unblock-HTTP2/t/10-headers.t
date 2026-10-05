use strict;
use warnings;
use Test::More;

use Uniform::HTTP::Request;
use Uniform::HTTP::Response;
use Unblock::HTTP2::_Headers;

my $request = Unblock::HTTP2::_Headers->request_from_headers(
    [
        [ ':method',    'POST' ],
        [ ':scheme',    'https' ],
        [ ':authority', 'example.test' ],
        [ ':path',      '/items' ],
        [ 'x-test',     'one' ],
        [ 'x-test',     'two' ],
    ],
    end_stream => 0,
);

isa_ok $request, 'Uniform::HTTP::Request';
is $request->method, 'POST', 'method maps from :method';
is $request->target, '/items', 'target maps from :path';
is $request->scheme, 'https', 'scheme maps from :scheme';
is $request->authority, 'example.test', 'authority maps from :authority';
is $request->protocol, undef, 'ordinary request has no protocol metadata';
is $request->version, '2', 'received request reports HTTP version 2';
ok !$request->initial_is_mutable,
    'received initial request metadata is frozen';
ok $request->trailers_are_mutable,
    'received open request can still acquire trailers';
ok $request->is_mutable,
    'open received request remains partially mutable';
ok !$request->is_complete, 'open request body is incomplete';
is_deeply $request->header_values('x-test'), [ 'one', 'two' ],
    'normal duplicate fields remain lossless';

Unblock::HTTP2::_Headers->apply_trailers(
    $request,
    [
        [ 'x-checksum', 'abc' ],
        [ 'x-checksum', 'def' ],
    ],
);
is_deeply $request->trailer_values('x-checksum'), [ 'abc', 'def' ],
    'incoming trailers remain ordered and duplicate preserving';
ok !$request->trailers_are_mutable,
    'received trailer section freezes after the trailing block';

$request->mark_complete->freeze;
ok $request->is_complete, 'message completeness advances independently';
ok !$request->is_mutable, 'completed received message can be fully frozen';

my $outgoing = Uniform::HTTP::Request->new(
    method    => 'GET',
    target    => '/',
    scheme    => 'https',
    authority => 'example.test',
    headers   => [
        [ 'X-Test', 'one' ],
        [ 'x-test', 'two' ],
    ],
);

is $outgoing->version, undef,
    'application-created request can remain version neutral';
is_deeply(
    Unblock::HTTP2::_Headers->request_headers($outgoing),
    [
        [ ':method',    'GET' ],
        [ ':scheme',    'https' ],
        [ ':authority', 'example.test' ],
        [ ':path',      '/' ],
        [ 'x-test',     'one' ],
        [ 'x-test',     'two' ],
    ],
    'version-neutral outgoing fields map to HTTP/2',
);
is $outgoing->version, undef,
    'HTTP/2 mapping does not mutate the application request version';

my $ordinary_connect = Uniform::HTTP::Request->new(
    method    => 'CONNECT',
    target    => 'example.test:443',
    authority => 'example.test:443',
);
is_deeply(
    Unblock::HTTP2::_Headers->request_headers($ordinary_connect),
    [
        [ ':method',    'CONNECT' ],
        [ ':authority', 'example.test:443' ],
    ],
    'ordinary CONNECT omits scheme and path',
);

my $extended = Unblock::HTTP2::_Headers->request_from_headers(
    [
        [ ':method',    'CONNECT' ],
        [ ':protocol',  'websocket' ],
        [ ':scheme',    'https' ],
        [ ':authority', 'example.test' ],
        [ ':path',      '/chat' ],
    ],
    end_stream => 0,
);
is $extended->protocol, 'websocket',
    'extended CONNECT maps :protocol';
is $extended->target, '/chat',
    'extended CONNECT keeps exact :path as target';
is $extended->scheme, 'https',
    'extended CONNECT keeps scheme';

my $outgoing_extended = Uniform::HTTP::Request->new(
    method    => 'CONNECT',
    protocol  => 'connect-udp',
    scheme    => 'https',
    authority => 'proxy.example',
    target    => '/.well-known/masque/udp/example.test/443/',
);
is_deeply(
    Unblock::HTTP2::_Headers->request_headers($outgoing_extended),
    [
        [ ':method',    'CONNECT' ],
        [ ':protocol',  'connect-udp' ],
        [ ':scheme',    'https' ],
        [ ':authority', 'proxy.example' ],
        [ ':path',      '/.well-known/masque/udp/example.test/443/' ],
    ],
    'generic Extended CONNECT protocol metadata maps to HTTP/2',
);

my $response = Unblock::HTTP2::_Headers->response_from_headers(
    [
        [ ':status',      '204' ],
        [ 'content-type', 'text/plain' ],
    ],
    end_stream => 1,
);

isa_ok $response, 'Uniform::HTTP::Response';
is $response->status, 204, 'status maps from :status';
is $response->reason, undef, 'HTTP/2 does not synthesize a reason phrase';
is $response->version, '2', 'received response reports HTTP version 2';
ok $response->is_complete, 'END_STREAM response is complete';
ok !$response->is_mutable, 'completed received response is fully frozen';

my $with_trailers = Uniform::HTTP::Response->new(
    status => 200,
    trailers => [
        [ 'X-One', 'a' ],
        [ 'x-one', 'b' ],
    ],
);
is_deeply(
    Unblock::HTTP2::_Headers->trailer_fields('test trailers', $with_trailers),
    [
        [ 'x-one', 'a' ],
        [ 'x-one', 'b' ],
    ],
    'outgoing trailers are lowercased and preserve duplicates',
);

my $ok = eval {
    Unblock::HTTP2::_Headers->request_from_headers(
        [
            [ ':method',    'GET' ],
            [ ':scheme',    'https' ],
            [ ':authority', 'example.test' ],
            [ ':path',      '/' ],
            [ 'Connection', 'close' ],
        ],
        end_stream => 1,
    );
    1;
};
ok !$ok, 'uppercase HTTP/2 field names are rejected';
like $@, qr/field names must be lowercase/,
    'uppercase field rejection is explicit';

$ok = eval {
    Unblock::HTTP2::_Headers->request_from_headers(
        [
            [ ':method',    'GET' ],
            [ ':scheme',    'https' ],
            [ ':authority', 'example.test' ],
            [ ':path',      '/' ],
            [ 'connection', 'close' ],
        ],
        end_stream => 1,
    );
    1;
};
ok !$ok, 'connection-specific fields are rejected';
like $@, qr/forbids connection-specific field/,
    'connection-specific rejection is explicit';

$ok = eval {
    Unblock::HTTP2::_Headers->request_from_headers(
        [
            [ ':method',    'GET' ],
            [ ':protocol',  'websocket' ],
            [ ':scheme',    'https' ],
            [ ':authority', 'example.test' ],
            [ ':path',      '/' ],
        ],
        end_stream => 1,
    );
    1;
};
ok !$ok, ':protocol on a non-CONNECT request is rejected';
like $@, qr/:protocol requires CONNECT/,
    'non-CONNECT protocol rejection is explicit';

$ok = eval {
    my $bad = Uniform::HTTP::Request->new(
        method    => 'GET',
        target    => '',
        scheme    => 'https',
        authority => 'example.test',
    );
    Unblock::HTTP2::_Headers->request_headers($bad);
    1;
};
ok !$ok, 'outgoing non-CONNECT request cannot emit an empty :path';
like $@, qr/nonempty path target|target/i,
    'empty outbound path rejection is explicit';

$ok = eval {
    my $bad = Uniform::HTTP::Request->new(
        method    => 'CONNECT',
        protocol  => '',
        scheme    => 'https',
        authority => 'example.test',
        target    => '/chat',
    );
    Unblock::HTTP2::_Headers->request_headers($bad);
    1;
};
ok !$ok, 'outgoing Extended CONNECT requires a nonempty :protocol';
like $@, qr/nonempty protocol|protocol/i,
    'empty outbound protocol rejection is explicit';

done_testing;

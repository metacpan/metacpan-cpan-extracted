use strict;
use warnings;

use Test2::V0;
use Uniform::HTTP 0.06;
use Uniform::HTTP::FastPath;
use Uniform::HTTP::Request;
use Uniform::HTTP::Response;

is($Uniform::HTTP::VERSION, '0.06',
    'Unblock HTTP3 contract tests use Uniform HTTP 0.06');

my $request = Uniform::HTTP::Request->new(
    method    => 'CONNECT',
    target    => '/chat',
    scheme    => 'https',
    authority => 'example.com',
    protocol  => 'webtransport',
    headers   => [
        [ 'X-First',  'one' ],
        [ 'X-Test',   'one' ],
        [ 'x-test',   'two' ],
        [ 'Priority', 'u=2, i' ],
    ],
    trailers => [
        [ 'X-Trailer', 'one' ],
        [ 'x-trailer', 'two' ],
    ],
);

is(ref($request), 'Uniform::HTTP::Request',
    'request is the exact canonical Uniform request class');
isa_ok($request, ['Uniform::HTTP::Request']);
isa_ok($request, ['Uniform::HTTP::Message']);

is($request->method, 'CONNECT', 'Uniform method is directly available');
is($request->target, '/chat', 'Uniform target is directly available');
is($request->scheme, 'https', 'Uniform scheme is directly available');
is($request->authority, 'example.com', 'Uniform authority is directly available');
is($request->protocol, 'webtransport',
    'Uniform Extended CONNECT protocol metadata is directly available');
ok($request->target_is_exact, 'canonical target remains exact');

is($request->header_values('x-test'), ['one', 'two'],
    'Uniform duplicate header behavior is preserved');
is(
    [ map { $request->header_name($_) } 0 .. $request->header_count - 1 ],
    [ 'X-First', 'X-Test', 'x-test', 'Priority' ],
    'Uniform header order and spelling are preserved',
);
is($request->header('priority'), 'u=2, i',
    'RFC 9218 priority remains an ordinary Uniform header');
ok($request->headers_are_lossless, 'request headers are lossless');

is($request->trailer_values('X-TRAILER'), ['one', 'two'],
    'Uniform trailer behavior is preserved');
is($request->trailer_count, 2, 'Uniform trailer count is preserved');
ok($request->has_trailers, 'Uniform trailer presence is preserved');
ok($request->trailers_are_lossless, 'request trailers are lossless');

ok(Uniform::HTTP::FastPath::can_view($request),
    'canonical request is eligible for FastPath');
my $request_view = Uniform::HTTP::FastPath::view($request);
is(
    $request_view->[Uniform::HTTP::FastPath::SLOT_KIND()],
    Uniform::HTTP::FastPath::KIND_REQUEST(),
    'FastPath identifies canonical request kind',
);
is(
    $request_view->[Uniform::HTTP::FastPath::SLOT_HEADERS()],
    [
        [ 'X-First',  'one' ],
        [ 'X-Test',   'one' ],
        [ 'x-test',   'two' ],
        [ 'Priority', 'u=2, i' ],
    ],
    'FastPath exposes ordered request headers',
);
ok(
    $request_view->[Uniform::HTTP::FastPath::SLOT_FLAGS()]
        & Uniform::HTTP::FastPath::FLAG_TARGET_EXACT(),
    'FastPath records exact request-target fidelity',
);

$request->mark_incomplete;
$request->freeze_initial;

ok(!$request->is_complete,
    'Uniform completeness remains independent of initial section freeze');
ok(!$request->initial_is_mutable,
    'Uniform initial message section can be frozen independently');
ok($request->trailers_are_mutable,
    'Uniform trailers remain mutable after initial freeze');
ok($request->body_is_mutable,
    'Uniform buffered body remains mutable after initial freeze');

like(
    dies { $request->header('X-New', 'no') },
    qr/initial message data is immutable/,
    'initial header mutation is blocked after freeze_initial',
);

is($request->add_trailer('X-Late', 'yes'), $request,
    'trailers may still advance after initial fields are fixed');

$request->freeze_trailers;
ok(!$request->trailers_are_mutable,
    'Uniform trailer section can be frozen independently');

like(
    dies { $request->add_trailer('X-Too-Late', 'no') },
    qr/trailers are immutable/,
    'trailer mutation is blocked after freeze_trailers',
);

$request->mark_complete;
ok($request->is_complete,
    'Uniform completeness can advance after section freezes');

my $trusted_request = Uniform::HTTP::FastPath::request_from_validated([
    Uniform::HTTP::FastPath::ABI_VERSION(),
    Uniform::HTTP::FastPath::KIND_REQUEST(),
    Uniform::HTTP::FastPath::FLAG_COMPLETE()
        | Uniform::HTTP::FastPath::FLAG_HEADERS_LOSSLESS()
        | Uniform::HTTP::FastPath::FLAG_TRAILERS_LOSSLESS()
        | Uniform::HTTP::FastPath::FLAG_TARGET_EXACT(),
    '3',
    'GET',
    '/trusted',
    'https',
    'example.com',
    undef,
    undef,
    undef,
    [ [ 'x-fast', 'yes' ] ],
    [],
    undef,
]);

is(ref($trusted_request), 'Uniform::HTTP::Request',
    'trusted construction returns exact canonical request');
is($trusted_request->header('x-fast'), 'yes',
    'trusted request adopts validated header storage');
ok($trusted_request->is_complete, 'trusted complete request remains complete');
ok(!$trusted_request->is_mutable, 'trusted immutable request remains immutable');

my $response = Uniform::HTTP::Response->new(
    status  => 200,
    headers => [ [ 'X-Test', 'yes' ] ],
    trailers => [
        [ 'Content-Digest', 'sha-256=:abc:' ],
    ],
);

is(ref($response), 'Uniform::HTTP::Response',
    'response is the exact canonical Uniform response class');
isa_ok($response, ['Uniform::HTTP::Message']);
is($response->status, 200, 'Uniform response status is directly available');
is($response->reason, undef,
    'HTTP3 response does not invent a reason phrase');
is($response->trailer('content-digest'), 'sha-256=:abc:',
    'Uniform response trailers are directly available');
ok(Uniform::HTTP::FastPath::can_view($response),
    'canonical response is eligible for FastPath');

my $trusted_response = Uniform::HTTP::FastPath::response_from_validated([
    Uniform::HTTP::FastPath::ABI_VERSION(),
    Uniform::HTTP::FastPath::KIND_RESPONSE(),
    Uniform::HTTP::FastPath::FLAG_MUTABLE()
        | Uniform::HTTP::FastPath::FLAG_BODY_MUTABLE()
        | Uniform::HTTP::FastPath::FLAG_TRAILERS_MUTABLE()
        | Uniform::HTTP::FastPath::FLAG_HEADERS_LOSSLESS()
        | Uniform::HTTP::FastPath::FLAG_TRAILERS_LOSSLESS(),
    '3',
    undef,
    undef,
    undef,
    undef,
    undef,
    204,
    undef,
    [ [ 'x-received', 'yes' ] ],
    [],
    undef,
]);

is(ref($trusted_response), 'Uniform::HTTP::Response',
    'trusted construction returns exact canonical response');
ok(!$trusted_response->is_complete,
    'trusted in-progress response remains incomplete');
ok(!$trusted_response->initial_is_mutable,
    'trusted received initial response fields are frozen');
ok($trusted_response->trailers_are_mutable,
    'trusted received response trailers remain mutable');

$response->freeze;
ok(!$response->is_mutable, 'full Uniform freeze makes response immutable');
like(
    dies { $response->status(404) },
    qr/message is immutable/,
    'Uniform response mutation fails after full freeze',
);

done_testing;

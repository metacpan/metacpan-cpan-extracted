use strict;
use warnings;
use Test::More;
use Scalar::Util qw(refaddr);

use Uniform::HTTP::FastPath;
use Uniform::HTTP::Message;
use Uniform::HTTP::Request;
use Uniform::HTTP::Response;

my $abi = Uniform::HTTP::FastPath::ABI_VERSION();
is $abi, 1, 'fast-path ABI starts at version 1';
is Uniform::HTTP::FastPath::SLOT_COUNT(), 14, 'ABI 1 slot count fixed';

my $request = Uniform::HTTP::Request->new(
    method    => 'POST',
    target    => '/items?id=42',
    scheme    => 'https',
    authority => 'example.com',
    protocol  => 'future',
    version   => '3',
    headers   => [
        [ 'X-Test', 'one' ],
        [ 'X-Test', 'two' ],
    ],
    trailers => [
        [ 'Content-Digest', 'sha-256=:abc:' ],
    ],
    body => '',
)->mark_incomplete->freeze_initial;

ok Uniform::HTTP::FastPath::can_view($request), 'canonical request supports fast path';

my $view = Uniform::HTTP::FastPath::view($request);
is $view->[Uniform::HTTP::FastPath::SLOT_ABI()], 1, 'view carries ABI';
is $view->[Uniform::HTTP::FastPath::SLOT_KIND()],
    Uniform::HTTP::FastPath::KIND_REQUEST(), 'request kind';
is $view->[Uniform::HTTP::FastPath::SLOT_METHOD()], 'POST', 'method exposed';
is $view->[Uniform::HTTP::FastPath::SLOT_TARGET()], '/items?id=42', 'target exposed';
is $view->[Uniform::HTTP::FastPath::SLOT_SCHEME()], 'https', 'scheme exposed';
is $view->[Uniform::HTTP::FastPath::SLOT_AUTHORITY()], 'example.com', 'authority exposed';
is $view->[Uniform::HTTP::FastPath::SLOT_PROTOCOL()], 'future', 'protocol exposed';
is $view->[Uniform::HTTP::FastPath::SLOT_VERSION()], '3', 'version exposed';
is $view->[Uniform::HTTP::FastPath::SLOT_BODY()], '', 'empty buffered body preserved';

my $flags = $view->[Uniform::HTTP::FastPath::SLOT_FLAGS()];
ok $flags & Uniform::HTTP::FastPath::FLAG_HAS_BUFFERED_BODY(), 'buffered body flag';
ok !($flags & Uniform::HTTP::FastPath::FLAG_COMPLETE()), 'incomplete flag preserved';
ok $flags & Uniform::HTTP::FastPath::FLAG_MUTABLE(), 'message remains partly mutable';
ok !($flags & Uniform::HTTP::FastPath::FLAG_INITIAL_MUTABLE()), 'initial section frozen';
ok $flags & Uniform::HTTP::FastPath::FLAG_BODY_MUTABLE(), 'body section mutable';
ok $flags & Uniform::HTTP::FastPath::FLAG_TRAILERS_MUTABLE(), 'trailers mutable';
ok $flags & Uniform::HTTP::FastPath::FLAG_HEADERS_LOSSLESS(), 'headers lossless';
ok $flags & Uniform::HTTP::FastPath::FLAG_TRAILERS_LOSSLESS(), 'trailers lossless';
ok $flags & Uniform::HTTP::FastPath::FLAG_TARGET_EXACT(), 'request target exact';

is refaddr($view->[Uniform::HTTP::FastPath::SLOT_HEADERS()]),
    refaddr($request->{headers}), 'header array is borrowed';
is refaddr($view->[Uniform::HTTP::FastPath::SLOT_TRAILERS()]),
    refaddr($request->{trailers}), 'trailer array is borrowed';

my $adopted_request = Uniform::HTTP::FastPath::request_from_validated($view);
isa_ok $adopted_request, 'Uniform::HTTP::Request';
is $adopted_request->method, 'POST', 'trusted request keeps method';
is $adopted_request->target, '/items?id=42', 'trusted request keeps target';
is $adopted_request->header_count, 2, 'trusted request keeps duplicate fields';
is_deeply $adopted_request->header_values('X-Test'), [ 'one', 'two' ],
    'trusted request keeps field order';
ok !$adopted_request->initial_is_mutable, 'trusted request keeps initial lock';
ok $adopted_request->body_is_mutable, 'trusted request keeps body mutability';
ok $adopted_request->trailers_are_mutable, 'trusted request keeps trailer mutability';
ok !$adopted_request->is_complete, 'trusted request keeps completeness';

my $adopted_view = Uniform::HTTP::FastPath::view($adopted_request);
is refaddr($adopted_view->[Uniform::HTTP::FastPath::SLOT_HEADERS()]),
    refaddr($view->[Uniform::HTTP::FastPath::SLOT_HEADERS()]),
    'trusted request adopts header storage';
is refaddr($adopted_view->[Uniform::HTTP::FastPath::SLOT_TRAILERS()]),
    refaddr($view->[Uniform::HTTP::FastPath::SLOT_TRAILERS()]),
    'trusted request adopts trailer storage';

my $response = Uniform::HTTP::Response->new(
    status  => 204,
    reason  => 'No Content',
    version => '1.1',
    headers => [ [ 'X-Test', 'ok' ] ],
)->freeze;

my $response_view = Uniform::HTTP::FastPath::view($response);
is $response_view->[Uniform::HTTP::FastPath::SLOT_KIND()],
    Uniform::HTTP::FastPath::KIND_RESPONSE(), 'response kind';
is $response_view->[Uniform::HTTP::FastPath::SLOT_STATUS()], 204, 'status exposed';
is $response_view->[Uniform::HTTP::FastPath::SLOT_REASON()], 'No Content',
    'reason exposed';
is $response_view->[Uniform::HTTP::FastPath::SLOT_METHOD()], undef,
    'request slots unused for response';

my $response_flags = $response_view->[Uniform::HTTP::FastPath::SLOT_FLAGS()];
ok !($response_flags & Uniform::HTTP::FastPath::FLAG_MUTABLE()),
    'frozen response immutable in view';
ok !($response_flags & Uniform::HTTP::FastPath::FLAG_INITIAL_MUTABLE()),
    'frozen response initial section immutable';
ok !($response_flags & Uniform::HTTP::FastPath::FLAG_BODY_MUTABLE()),
    'frozen response body immutable';
ok !($response_flags & Uniform::HTTP::FastPath::FLAG_TRAILERS_MUTABLE()),
    'frozen response trailers immutable';
ok !($response_flags & Uniform::HTTP::FastPath::FLAG_TARGET_EXACT()),
    'response does not advertise request target fidelity';

my $adopted_response =
    Uniform::HTTP::FastPath::response_from_validated($response_view);
isa_ok $adopted_response, 'Uniform::HTTP::Response';
is $adopted_response->status, 204, 'trusted response keeps status';
is $adopted_response->reason, 'No Content', 'trusted response keeps reason';
ok !$adopted_response->is_mutable, 'trusted response keeps frozen state';

my $message = Uniform::HTTP::Message->new(headers => [ [ 'X', 'y' ] ]);
ok Uniform::HTTP::FastPath::can_view($message), 'canonical base message supported';
is Uniform::HTTP::FastPath::view($message)
    ->[Uniform::HTTP::FastPath::SLOT_KIND()],
    Uniform::HTTP::FastPath::KIND_MESSAGE(), 'base message kind';

{
    package Local::RequestSubclass;
    use parent 'Uniform::HTTP::Request';
}
my $subclass = Local::RequestSubclass->new(method => 'GET', target => '/');
ok !Uniform::HTTP::FastPath::can_view($subclass), 'subclass must use portable API';
eval { Uniform::HTTP::FastPath::view($subclass) };
like $@, qr/exact canonical/, 'view rejects subclass';

eval { Uniform::HTTP::FastPath::view($request, 2) };
like $@, qr/unsupported/, 'unsupported ABI rejected';

my $bad = [ @$view ];
$bad->[Uniform::HTTP::FastPath::SLOT_ABI()] = 2;
eval { Uniform::HTTP::FastPath::request_from_validated($bad) };
like $@, qr/unsupported/, 'trusted constructor rejects wrong ABI';

$bad = [ @$view ];
$bad->[Uniform::HTTP::FastPath::SLOT_KIND()] =
    Uniform::HTTP::FastPath::KIND_RESPONSE();
eval { Uniform::HTTP::FastPath::request_from_validated($bad) };
like $@, qr/wrong message kind/, 'trusted constructor rejects wrong kind';

$bad = [ @$view ];
$bad->[Uniform::HTTP::FastPath::SLOT_HEADERS()] = {};
eval { Uniform::HTTP::FastPath::request_from_validated($bad) };
like $@, qr/headers must be an array/, 'trusted constructor checks structural storage';

$bad = [ @$view ];
$bad->[Uniform::HTTP::FastPath::SLOT_FLAGS()] &=
    ~Uniform::HTTP::FastPath::FLAG_TARGET_EXACT();
eval { Uniform::HTTP::FastPath::request_from_validated($bad) };
like $@, qr/exact target fidelity/, 'trusted request requires canonical fidelity';

my $normal = Uniform::HTTP::Request->new(method => 'GET', target => '/');
eval { $normal->method('not valid') };
like $@, qr/method must be an HTTP token/,
    'normal public validation remains unchanged';

done_testing;

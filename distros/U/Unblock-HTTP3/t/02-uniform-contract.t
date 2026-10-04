use strict;
use warnings;

use Test2::V0;
use Uniform::HTTP 0.04;
use Uniform::HTTP::Request;
use Uniform::HTTP::Response;

use Unblock::HTTP3::Request;
use Unblock::HTTP3::Response;

is($Uniform::HTTP::VERSION, '0.04',
    'Unblock HTTP3 contract tests use Uniform HTTP 0.04');

my $request = Unblock::HTTP3::Request->new(
    method    => 'CONNECT',
    target    => '/chat',
    scheme    => 'https',
    authority => 'example.com',
    protocol  => 'webtransport',
    headers   => [
        [ 'X-First', 'one' ],
        [ 'X-Test',  'one' ],
        [ 'x-test',  'two' ],
    ],
    trailers => [
        [ 'X-Trailer', 'one' ],
        [ 'x-trailer', 'two' ],
    ],
    priority => {
        urgency     => 2,
        incremental => 1,
    },
);

isa_ok($request, ['Unblock::HTTP3::Request']);
isa_ok($request, ['Uniform::HTTP::Request']);
isa_ok($request, ['Uniform::HTTP::Message']);

is($request->method, 'CONNECT', 'Uniform method is inherited');
is($request->target, '/chat', 'Uniform target is inherited');
is($request->scheme, 'https', 'Uniform scheme is inherited');
is($request->authority, 'example.com', 'Uniform authority is inherited');
is($request->protocol, 'webtransport',
    'Uniform Extended CONNECT protocol metadata is inherited');
ok($request->target_is_exact, 'canonical target remains exact');

is($request->header_values('x-test'), ['one', 'two'],
    'Uniform duplicate header behavior is inherited');
is(
    [ map { $request->header_name($_) } 0 .. $request->header_count - 1 ],
    [ 'X-First', 'X-Test', 'x-test', 'Priority' ],
    'Uniform header order and spelling are preserved with Priority convenience',
);
ok($request->headers_are_lossless, 'request headers are lossless');

is($request->trailer_values('X-TRAILER'), ['one', 'two'],
    'Uniform trailer behavior is inherited');
is($request->trailer_count, 2, 'Uniform trailer count is inherited');
ok($request->has_trailers, 'Uniform trailer presence is inherited');
ok($request->trailers_are_lossless, 'request trailers are lossless');

is(
    $request->priority,
    {
        urgency     => 2,
        incremental => 1,
    },
    'Unblock priority helper is layered over the Uniform Priority field',
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

my $neutral = Unblock::HTTP3::Request->new(
    method   => 'GET',
    target   => '/',
    protocol => 'future-protocol',
);

is($neutral->protocol, 'future-protocol',
    'Uniform keeps protocol metadata neutral until an HTTP sender validates it');
is($neutral->method('CONNECT'), $neutral,
    'Uniform request fields remain independently editable before commitment');
is($neutral->method, 'CONNECT', 'method mutation is inherited from Uniform');

my $response = Unblock::HTTP3::Response->new(
    status  => 200,
    headers => [ [ 'X-Test', 'yes' ] ],
    trailers => [
        [ 'Content-Digest', 'sha-256=:abc:' ],
    ],
);

isa_ok($response, ['Unblock::HTTP3::Response']);
isa_ok($response, ['Uniform::HTTP::Response']);
isa_ok($response, ['Uniform::HTTP::Message']);
is($response->status, 200, 'Uniform response status is inherited');
is($response->reason, undef,
    'HTTP3 response does not invent a reason phrase');
is($response->trailer('content-digest'), 'sha-256=:abc:',
    'Uniform response trailers are directly available');

$response->freeze;
ok(!$response->is_mutable, 'full Uniform freeze makes response immutable');
like(
    dies { $response->status(404) },
    qr/message is immutable/,
    'Uniform response mutation fails after full freeze',
);

my $aborted = Unblock::HTTP3::Response->new(status => 200);
$aborted->_mark_reset(0x10c);
is($aborted->reset_code, 0x10c,
    'Unblock response retains HTTP3 reset diagnostics');
ok($aborted->is_aborted, 'HTTP3 reset marks response aborted');
ok(!$aborted->is_complete,
    'aborted HTTP3 response is incomplete under Uniform completeness');
ok(!$aborted->is_mutable,
    'aborted HTTP3 response is frozen');

for my $class (qw(Unblock::HTTP3::Request Unblock::HTTP3::Response)) {
    for my $method (qw(
        version header header_values header_count header_name header_value
        add_header remove_header trailer trailer_values trailer_count
        trailer_name trailer_value add_trailer remove_trailer has_trailers
        body has_buffered_body is_complete is_mutable initial_is_mutable
        body_is_mutable trailers_are_mutable headers_are_lossless
        trailers_are_lossless freeze freeze_initial freeze_trailers
        mark_incomplete mark_complete
    )) {
        ok($class->can($method), "$class inherits Uniform method $method");
    }
}

done_testing;

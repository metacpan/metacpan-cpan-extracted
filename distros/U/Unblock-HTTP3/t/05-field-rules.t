use strict;
use warnings;

use Test2::V0;

use Unblock::HTTP3::Connection;
use Uniform::HTTP::FastPath;
use Uniform::HTTP::Request;
use Uniform::HTTP::Response;


sub wire_headers {
    my ($message, $context) = @_;
    my $view = Uniform::HTTP::FastPath::view($message);

    return Unblock::HTTP3::Connection::_wire_headers(
        $view->[Uniform::HTTP::FastPath::SLOT_HEADERS()],
        $context,
    );
}

sub wire_trailers {
    my ($message) = @_;
    my $view = Uniform::HTTP::FastPath::view($message);

    return Unblock::HTTP3::Connection::_wire_trailers(
        $view->[Uniform::HTTP::FastPath::SLOT_TRAILERS()],
    );
}

for my $name (
    'Connection',
    'Keep-Alive',
    'Proxy-Connection',
    'Transfer-Encoding',
    'Upgrade',
) {
    my $request = Uniform::HTTP::Request->new(
        method  => 'GET',
        target  => '/',
        headers => [ [ $name, 'test' ] ],
    );

    like(
        dies {
            wire_headers(
                $request,
                'request',
            );
        },
        qr/connection-specific field/,
        "$name is rejected before HTTP/3 encoding",
    );
}

my $good_te = Uniform::HTTP::Request->new(
    method  => 'GET',
    target  => '/',
    headers => [ [ 'TE', 'trailers' ] ],
);

is(
    wire_headers(
        $good_te,
        'request',
    ),
    [ [ 'te', 'trailers' ] ],
    'request TE trailers is allowed and field name is lowercased',
);

my $bad_te = Uniform::HTTP::Request->new(
    method  => 'GET',
    target  => '/',
    headers => [ [ 'TE', 'gzip' ] ],
);

like(
    dies {
        wire_headers(
            $bad_te,
            'request',
        );
    },
    qr/may contain only 'trailers'/,
    'request TE with another value is rejected',
);

my $response_te = Uniform::HTTP::Response->new(
    status  => 200,
    headers => [ [ 'TE', 'trailers' ] ],
);

like(
    dies {
        wire_headers(
            $response_te,
            'response',
        );
    },
    qr/only allowed in request headers/,
    'response TE is rejected',
);

my $trailer_te = Uniform::HTTP::Response->new(
    status   => 200,
    trailers => [ [ 'TE', 'trailers' ] ],
);

like(
    dies {
        wire_trailers(
            $trailer_te,
        );
    },
    qr/only allowed in request headers|not allowed in trailers/,
    'TE is rejected in trailers',
);

for my $name ('Content-Length', 'Host') {
    my $message = Uniform::HTTP::Response->new(
        status   => 200,
        trailers => [ [ $name, '1' ] ],
    );

    like(
        dies {
            wire_trailers(
                $message,
            );
        },
        qr/not allowed in trailers/,
        "$name is rejected in trailers",
    );
}

my $ordinary = Uniform::HTTP::Response->new(
    status  => 200,
    headers => [
        [ 'Content-Type', 'text/plain' ],
        [ 'X-Test', 'yes' ],
    ],
);

is(
    wire_headers(
        $ordinary,
        'response',
    ),
    [
        [ 'content-type', 'text/plain' ],
        [ 'x-test', 'yes' ],
    ],
    'ordinary HTTP/3 field names are encoded lowercase',
);

my $neutral_version = Uniform::HTTP::Request->new(
    method => 'GET',
    target => '/',
);

is(
    Unblock::HTTP3::Connection::_assert_http3_version(
        $neutral_version,
        'test',
    ),
    undef,
    'HTTP/3 accepts an unspecified Uniform message version',
);

my $http3_version = Uniform::HTTP::Request->new(
    method  => 'GET',
    target  => '/',
    version => '3',
);

is(
    Unblock::HTTP3::Connection::_assert_http3_version(
        $http3_version,
        'test',
    ),
    undef,
    'HTTP/3 accepts an explicit version 3',
);

my $wrong_version = Uniform::HTTP::Request->new(
    method  => 'GET',
    target  => '/',
    version => '2',
);

like(
    dies {
        Unblock::HTTP3::Connection::_assert_http3_version(
            $wrong_version,
            'test',
        );
    },
    qr/explicit message version must be 3/,
    'HTTP/3 rejects an explicitly incompatible Uniform version',
);

my $extended_request = Uniform::HTTP::Request->new(
    method    => 'CONNECT',
    protocol  => 'test-protocol',
    scheme    => 'https',
    authority => 'example.com',
    target    => '/extended',
);

is($extended_request->protocol, 'test-protocol',
    'Extended CONNECT Request exposes its protocol');

like(
    dies {
        Uniform::HTTP::Request->new(
            method    => 'CONNECT',
            protocol  => 'bad protocol',
            scheme    => 'https',
            authority => 'example.com',
            target    => '/extended',
        );
    },
    qr/protocol must be an HTTP token/,
    'Extended CONNECT protocol must be an HTTP token',
);

my $neutral_protocol_request = Uniform::HTTP::Request->new(
    method   => 'GET',
    protocol => 'test-protocol',
    target   => '/',
);

is($neutral_protocol_request->protocol, 'test-protocol',
    'Uniform Request preserves protocol metadata before sender validation');

is($extended_request->method('GET'), $extended_request,
    'Uniform Request permits independent method mutation before sending');
is($extended_request->protocol, 'test-protocol',
    'method mutation does not rewrite protocol metadata');

is(
    Unblock::HTTP3::Connection::_request_semantic_error(
        method      => 'CONNECT',
        protocol    => 'test-protocol',
        scheme      => 'https',
        authority   => 'example.com',
        target      => '/extended',
        host_values => [],
    ),
    undef,
    'Extended CONNECT uses ordinary authority and path semantics',
);

like(
    Unblock::HTTP3::Connection::_request_semantic_error(
        method      => 'CONNECT',
        protocol    => 'test-protocol',
        scheme      => undef,
        authority   => 'example.com',
        target      => '/extended',
        host_values => [],
    ),
    qr/requires :scheme/,
    'Extended CONNECT requires :scheme',
);

like(
    Unblock::HTTP3::Connection::_request_semantic_error(
        method      => 'CONNECT',
        protocol    => 'test-protocol',
        scheme      => 'https',
        authority   => 'example.com',
        target      => undef,
        host_values => [],
    ),
    qr/requires :path/,
    'Extended CONNECT requires :path',
);

like(
    Unblock::HTTP3::Connection::_request_semantic_error(
        method      => 'GET',
        protocol    => 'test-protocol',
        scheme      => 'https',
        authority   => 'example.com',
        target      => '/',
        host_values => [],
    ),
    qr/:protocol is only valid with CONNECT/,
    ':protocol is rejected on non-CONNECT requests',
);

my $host_mismatch = Unblock::HTTP3::Connection::_request_semantic_error(
    method      => 'GET',
    scheme      => 'https',
    authority   => 'example.com',
    target      => '/',
    host_values => [ 'other.example' ],
);

like(
    $host_mismatch,
    qr/Host field must match :authority/,
    'Host must match :authority',
);

is(
    Unblock::HTTP3::Connection::_request_semantic_error(
        method      => 'GET',
        scheme      => 'https',
        authority   => 'EXAMPLE.com',
        target      => '/',
        host_values => [ 'example.COM' ],
    ),
    undef,
    'Host and :authority comparison is ASCII case-insensitive',
);

like(
    Unblock::HTTP3::Connection::_request_semantic_error(
        method      => 'GET',
        scheme      => 'https',
        authority   => 'user\@example.com',
        target      => '/',
        host_values => [],
    ),
    qr/must not contain userinfo/,
    'http authority rejects userinfo',
);

like(
    Unblock::HTTP3::Connection::_request_semantic_error(
        method      => 'GET',
        scheme      => 'https',
        authority   => 'example.com',
        target      => 'relative',
        host_values => [],
    ),
    qr/must start with \/, except OPTIONS \*/,
    'http path must be absolute',
);

like(
    Unblock::HTTP3::Connection::_request_semantic_error(
        method      => 'GET',
        scheme      => 'https',
        authority   => 'example.com',
        target      => '*',
        host_values => [],
    ),
    qr/must start with \/, except OPTIONS \*/,
    'asterisk target is not valid for GET',
);

is(
    Unblock::HTTP3::Connection::_request_semantic_error(
        method      => 'OPTIONS',
        scheme      => 'https',
        authority   => 'example.com',
        target      => '*',
        host_values => [],
    ),
    undef,
    'OPTIONS asterisk target is allowed',
);

like(
    Unblock::HTTP3::Connection::_request_semantic_error(
        method      => 'GET',
        scheme      => 'https',
        authority   => 'example.com',
        target      => '/path#fragment',
        host_values => [],
    ),
    qr/must not contain a fragment/,
    'HTTP/3 path rejects URI fragments',
);

for my $authority (
    'example.com',
    'example.com:',
    'example.com:0',
    'example.com:65536',
) {
    like(
        Unblock::HTTP3::Connection::_request_semantic_error(
            method      => 'CONNECT',
            scheme      => undef,
            authority   => $authority,
            target      => $authority,
            host_values => [],
        ),
        qr/port|host and explicit port/,
        "CONNECT rejects invalid authority $authority",
    );
}

is(
    Unblock::HTTP3::Connection::_request_semantic_error(
        method      => 'CONNECT',
        scheme      => undef,
        authority   => '[::1]:443',
        target      => '[::1]:443',
        host_values => [],
    ),
    undef,
    'CONNECT accepts bracketed IPv6 with an explicit port',
);

is(
    Unblock::HTTP3::Connection::_request_semantic_error(
        method      => 'CONNECT',
        scheme      => undef,
        authority   => 'example.com:443',
        target      => 'EXAMPLE.COM:443',
        host_values => [],
    ),
    undef,
    'CONNECT target and authority compare host case-insensitively',
);

my $incoming_host_error =
    Unblock::HTTP3::Connection::_request_semantic_error(
        method      => 'GET',
        scheme      => 'https',
        authority   => 'example.com',
        target      => '/',
        protocol    => undef,
        host_values => [ 'other.example' ],
    );

like(
    $incoming_host_error,
    qr/Host field must match :authority/,
    'incoming Host mismatch uses the shared semantic validation',
);

my $missing_extended_path_error =
    Unblock::HTTP3::Connection::_request_semantic_error(
        method      => 'CONNECT',
        scheme      => 'https',
        authority   => 'example.com',
        target      => undef,
        protocol    => 'test-protocol',
        host_values => [],
    );

like(
    $missing_extended_path_error,
    qr/Extended CONNECT requires :path/,
    'missing Extended CONNECT :path has a useful rejection reason',
);

my $missing_extended_scheme_error =
    Unblock::HTTP3::Connection::_request_semantic_error(
        method      => 'CONNECT',
        scheme      => undef,
        authority   => 'example.com',
        target      => '/extended',
        protocol    => 'test-protocol',
        host_values => [],
    );

like(
    $missing_extended_scheme_error,
    qr/Extended CONNECT requires :scheme/,
    'missing Extended CONNECT :scheme uses shared semantic validation',
);

done_testing;

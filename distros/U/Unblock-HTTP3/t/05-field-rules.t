use strict;
use warnings;

use Test2::V0;

use Unblock::HTTP3::Connection;
use Unblock::HTTP3::Request;
use Unblock::HTTP3::Response;

for my $name (
    'Connection',
    'Keep-Alive',
    'Proxy-Connection',
    'Transfer-Encoding',
    'Upgrade',
) {
    my $request = Unblock::HTTP3::Request->new(
        method  => 'GET',
        target  => '/',
        headers => [ [ $name, 'test' ] ],
    );

    like(
        dies {
            Unblock::HTTP3::Connection::_wire_headers(
                $request,
                'request',
            );
        },
        qr/connection-specific field/,
        "$name is rejected before HTTP/3 encoding",
    );
}

my $good_te = Unblock::HTTP3::Request->new(
    method  => 'GET',
    target  => '/',
    headers => [ [ 'TE', 'trailers' ] ],
);

is(
    Unblock::HTTP3::Connection::_wire_headers(
        $good_te,
        'request',
    ),
    [ [ 'te', 'trailers' ] ],
    'request TE trailers is allowed and field name is lowercased',
);

my $bad_te = Unblock::HTTP3::Request->new(
    method  => 'GET',
    target  => '/',
    headers => [ [ 'TE', 'gzip' ] ],
);

like(
    dies {
        Unblock::HTTP3::Connection::_wire_headers(
            $bad_te,
            'request',
        );
    },
    qr/may contain only 'trailers'/,
    'request TE with another value is rejected',
);

my $response_te = Unblock::HTTP3::Response->new(
    status  => 200,
    headers => [ [ 'TE', 'trailers' ] ],
);

like(
    dies {
        Unblock::HTTP3::Connection::_wire_headers(
            $response_te,
            'response',
        );
    },
    qr/only allowed in request headers/,
    'response TE is rejected',
);

my $trailer_te = Unblock::HTTP3::Response->new(
    status   => 200,
    trailers => [ [ 'TE', 'trailers' ] ],
);

like(
    dies {
        Unblock::HTTP3::Connection::_wire_trailers(
            $trailer_te,
        );
    },
    qr/only allowed in request headers|not allowed in trailers/,
    'TE is rejected in trailers',
);

for my $name ('Content-Length', 'Host') {
    my $message = Unblock::HTTP3::Response->new(
        status   => 200,
        trailers => [ [ $name, '1' ] ],
    );

    like(
        dies {
            Unblock::HTTP3::Connection::_wire_trailers(
                $message,
            );
        },
        qr/not allowed in trailers/,
        "$name is rejected in trailers",
    );
}

my $ordinary = Unblock::HTTP3::Response->new(
    status  => 200,
    headers => [
        [ 'Content-Type', 'text/plain' ],
        [ 'X-Test', 'yes' ],
    ],
);

is(
    Unblock::HTTP3::Connection::_wire_headers(
        $ordinary,
        'response',
    ),
    [
        [ 'content-type', 'text/plain' ],
        [ 'x-test', 'yes' ],
    ],
    'ordinary HTTP/3 field names are encoded lowercase',
);

my $neutral_version = Unblock::HTTP3::Request->new(
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

my $http3_version = Unblock::HTTP3::Request->new(
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

my $wrong_version = Unblock::HTTP3::Request->new(
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

my $extended_request = Unblock::HTTP3::Request->new(
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
        Unblock::HTTP3::Request->new(
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

my $neutral_protocol_request = Unblock::HTTP3::Request->new(
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

{
    package Local::RejectingConnection;
    our @ISA = ('Unblock::HTTP3::Connection');

    sub _reject_message_stream {
        my ($self, $id, $reason) = @_;
        $self->{rejected} = [ $id, $reason ];
        return;
    }
}

my $incoming = bless {
    role => 'server',
    building => {
        0 => {
            pseudo => {
                ':method'    => 'GET',
                ':scheme'    => 'https',
                ':authority' => 'example.com',
                ':path'      => '/',
            },
            headers => [
                [ host => 'other.example' ],
            ],
        },
    },
}, 'Local::RejectingConnection';

$incoming->_finish_headers(0, 1);

is(
    $incoming->{rejected}[0],
    0,
    'incoming Host mismatch rejects only the request stream',
);

like(
    $incoming->{rejected}[1],
    qr/Host field must match :authority/,
    'incoming Host mismatch uses the shared semantic validation',
);

my $missing_extended_path = bless {
    role                    => 'server',
    enable_extended_connect => 1,
    building => {
        4 => {
            pseudo => {
                ':method'    => 'CONNECT',
                ':protocol'  => 'test-protocol',
                ':scheme'    => 'https',
                ':authority' => 'example.com',
            },
            headers => [],
        },
    },
}, 'Local::RejectingConnection';

$missing_extended_path->_finish_headers(4, 0);

is(
    $missing_extended_path->{rejected}[0],
    4,
    'Extended CONNECT missing :path rejects only the request stream',
);

like(
    $missing_extended_path->{rejected}[1],
    qr/Extended CONNECT requires :path/,
    'missing Extended CONNECT :path has a useful rejection reason',
);

my $missing_extended_scheme = bless {
    role                    => 'server',
    enable_extended_connect => 1,
    building => {
        8 => {
            pseudo => {
                ':method'    => 'CONNECT',
                ':protocol'  => 'test-protocol',
                ':authority' => 'example.com',
                ':path'      => '/extended',
            },
            headers => [],
        },
    },
}, 'Local::RejectingConnection';

$missing_extended_scheme->_finish_headers(8, 0);

is(
    $missing_extended_scheme->{rejected}[0],
    8,
    'Extended CONNECT missing :scheme rejects only the request stream',
);

like(
    $missing_extended_scheme->{rejected}[1],
    qr/requires :scheme/,
    'missing Extended CONNECT :scheme uses shared semantic validation',
);

done_testing;

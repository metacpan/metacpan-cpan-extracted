use strict;
use warnings;
use Test::More;

use Uniform::HTTP::Request;
use Uniform::HTTP::Response;
use Unblock::HTTP1::Client;
use Unblock::HTTP1::NativeABI;
use Unblock::HTTP1::Server;
use Unblock::HTTP1::_Native;

my $definition = Unblock::HTTP1::NativeABI::definition();
is $definition->{abi_version}, 1, 'borrowed input ABI version is 1';
ok $definition->{struct_size},
    'borrowed input ABI exposes its structure size';
ok $definition->{operations_address},
    'borrowed input ABI exposes native operations';

my $include_dir = Unblock::HTTP1::NativeABI::native_include_dir();
ok -d $include_dir, 'native ABI exposes an installed include directory';
my $header_path = Unblock::HTTP1::NativeABI::header_path();
ok -f $header_path, 'native ABI exposes an installed header path';

my $installed_header = Unblock::HTTP1::NativeABI::c_header();
like $installed_header,
    qr/ub_http1_input_ops_v1/,
    'native ABI publishes its installed C layout';
my @common_order = map { index($installed_header, $_) }
    ('void *(*create)', 'int (*input)', 'int (*eof)', 'void (*destroy)');
ok $common_order[0] < $common_order[1]
    && $common_order[1] < $common_order[2]
    && $common_order[2] < $common_order[3],
    'native input ABI keeps the common create/input/eof/destroy order';

my @events;
my $native_request;
my $server = Unblock::HTTP1::Server->new(
    on_request => sub {
        my ($tx, $request) = @_;
        $native_request = $request;
        push @events, 'request';
        $tx->respond(Uniform::HTTP::Response->new(
            status => 200,
            body   => 'ok',
        ));
    },
    on_request_end => sub { push @events, 'request_end' },
);

my $partial = "GET /borrowed HTTP/1.1\r\nHost: example.test\r\n";
my ($status, $consumed) =
    Unblock::HTTP1::_Native::_borrowed_input_once($server, $partial);
is $status, Unblock::HTTP1::NativeABI::INPUT_MORE(),
    'incomplete borrowed request asks host for more bytes';
is $consumed, 0, 'incomplete head leaves borrowed prefix with host';

my $request_wire = $partial . "\r\n";
($status, $consumed) =
    Unblock::HTTP1::_Native::_borrowed_input_once($server, $request_wire);
is $status, Unblock::HTTP1::NativeABI::INPUT_OK(),
    'complete borrowed request is consumed';
is $consumed, length($request_wire), 'complete request reports exact consumed prefix';
is_deeply \@events, [qw(request request_end)],
    'borrowed request follows ordinary server lifecycle';
is ref($native_request), 'Uniform::HTTP::Request',
    'native receive constructs the canonical Uniform request class';
is $native_request->target, '/borrowed',
    'native receive preserves the request target';
is $native_request->header('Host'), 'example.test',
    'native receive preserves canonical header values';
like $server->output, qr/\AHTTP\/1\.1 200 OK\r\n/,
    'borrowed request produces ordinary response output';

my $body = '';
my $body_server = Unblock::HTTP1::Server->new(
    on_request => sub { push @events, 'body_request' },
    on_body => sub {
        $body .= $_[2];
    },
    on_request_end => sub {
        my ($tx) = @_;
        $tx->respond(Uniform::HTTP::Response->new(status => 204));
    },
);

my $head =
    "POST /body HTTP/1.1\r\n" .
    "Host: example.test\r\n" .
    "Content-Length: 5\r\n\r\n";

($status, $consumed) =
    Unblock::HTTP1::_Native::_borrowed_input_once($body_server, $head . 'he');
is $status, Unblock::HTTP1::NativeABI::INPUT_OK(),
    'borrowed fixed body consumes available prefix';
is $consumed, length($head) + 2,
    'borrowed fixed body reports head plus delivered body bytes';
is $body, 'he', 'first borrowed body fragment delivered';

($status, $consumed) =
    Unblock::HTTP1::_Native::_borrowed_input_once($body_server, 'llo');
is $status, Unblock::HTTP1::NativeABI::INPUT_OK(),
    'borrowed fixed body completes on later window';
is $consumed, 3, 'later fixed body window fully consumed';
is $body, 'hello', 'borrowed fixed body preserves content';

my $chunked = '';
my $chunked_server = Unblock::HTTP1::Server->new(
    on_request => sub { },
    on_body => sub { $chunked .= $_[2] },
    on_request_end => sub {
        my ($tx) = @_;
        $tx->respond(Uniform::HTTP::Response->new(status => 204));
    },
);
my $chunk_head =
    "POST /chunked HTTP/1.1\r\n" .
    "Host: example.test\r\n" .
    "Transfer-Encoding: chunked\r\n\r\n";

($status, $consumed) =
    Unblock::HTTP1::_Native::_borrowed_input_once(
        $chunked_server, $chunk_head . "4\r\nWi"
    );
is $status, Unblock::HTTP1::NativeABI::INPUT_OK(),
    'fragmented borrowed chunk framing consumes its native window';
is $consumed, length($chunk_head) + 5,
    'chunked borrowed path reports consumed window';

($status, $consumed) =
    Unblock::HTTP1::_Native::_borrowed_input_once(
        $chunked_server, "ki\r\n0\r\n\r\n"
    );
is $status, Unblock::HTTP1::NativeABI::INPUT_OK(),
    'borrowed chunked body completes';
is $consumed, length("ki\r\n0\r\n\r\n"),
    'completed chunked window fully consumed';
is $chunked, 'Wiki', 'borrowed chunk decoder preserves payload';

my $native_response;
my $client_body = '';
my $native_client = Unblock::HTTP1::Client->new;
my $client_driver =
    Unblock::HTTP1::_Native::BorrowedDriver->new($native_client);
my $native_tx = $native_client->request(
    Uniform::HTTP::Request->new(
        method    => 'GET',
        target    => '/native-response',
        authority => 'example.test',
    ),
    on_response => sub {
        my ($tx, $response) = @_;
        $native_response = $response;
    },
    on_body => sub {
        $client_body .= $_[2];
    },
);
$native_client->output;

my $partial_response =
    "HTTP/1.1 200 OK\r\n" .
    "Content-Length: 5\r\n" .
    "X-Native: yes\r\n";
($status, $consumed) = $client_driver->feed($partial_response);
is $status, Unblock::HTTP1::NativeABI::INPUT_MORE(),
    'incomplete borrowed response asks host for more bytes';
is $consumed, 0,
    'incomplete response head leaves borrowed prefix with host';

my $response_head = $partial_response . "\r\n";
($status, $consumed) = $client_driver->feed($response_head . 'he');
is $status, Unblock::HTTP1::NativeABI::INPUT_OK(),
    'borrowed client consumes response head and available fixed body';
is $consumed, length($response_head) + 2,
    'borrowed client reports exact response prefix consumption';
is ref($native_response), 'Uniform::HTTP::Response',
    'native client receive constructs the canonical Uniform response class';
is $native_response->status, 200,
    'native client response preserves status';
is $native_response->header('X-Native'), 'yes',
    'native client response preserves canonical header values';
is $client_body, 'he',
    'native client delivers first fixed response body fragment';

($status, $consumed) = $client_driver->feed('llo');
is $status, Unblock::HTTP1::NativeABI::INPUT_OK(),
    'borrowed client completes fixed response on later window';
is $consumed, 3,
    'later response body window is fully consumed';
is $client_body, 'hello',
    'borrowed client preserves fixed response body';
ok $native_tx->is_complete,
    'borrowed native response completes client transaction';

my ($informational, $final_response);
my $info_tx = $native_client->request(
    Uniform::HTTP::Request->new(
        method    => 'GET',
        target    => '/informational',
        authority => 'example.test',
    ),
    on_informational => sub {
        $informational = $_[1];
    },
    on_response => sub {
        $final_response = $_[1];
    },
);
$native_client->output;

my $early =
    "HTTP/1.1 103 Early Hints\r\n" .
    "Link: </style.css>; rel=preload\r\n\r\n";
($status, $consumed) = $client_driver->feed($early);
is $status, Unblock::HTTP1::NativeABI::INPUT_OK(),
    'persistent client driver accepts informational response';
is $consumed, length($early),
    'informational response is fully consumed';
is ref($informational), 'Uniform::HTTP::Response',
    'informational native response is canonical';
is $informational->status, 103,
    'informational native response preserves status';

my $final = "HTTP/1.1 204 No Content\r\n\r\n";
($status, $consumed) = $client_driver->feed($final);
is $status, Unblock::HTTP1::NativeABI::INPUT_OK(),
    'persistent client driver accepts final response after informational';
is $consumed, length($final),
    'final response is fully consumed';
is ref($final_response), 'Uniform::HTTP::Response',
    'final native response is canonical';
is $final_response->status, 204,
    'final native response preserves status';
ok $info_tx->is_complete,
    'informational exchange completes normally';

my @switch;
my $switch_server = Unblock::HTTP1::Server->new(
    on_request => sub {
        my ($tx) = @_;
        $tx->respond(Uniform::HTTP::Response->new(
            status => 101,
            headers => [
                [ Connection => 'Upgrade' ],
                [ Upgrade    => 'test-proto' ],
            ],
        ));
    },
    on_switch => sub { push @switch, 'server' },
);
my $switch_request =
    "GET /switch HTTP/1.1\r\n" .
    "Host: example.test\r\n" .
    "Connection: Upgrade\r\n" .
    "Upgrade: test-proto\r\n\r\n";

($status, $consumed) =
    Unblock::HTTP1::_Native::_borrowed_input_once(
        $switch_server, $switch_request . 'PING'
    );
is $status, Unblock::HTTP1::NativeABI::INPUT_SWITCH(),
    'borrowed server reports protocol switch';
is $consumed, length($switch_request),
    'post-switch bytes remain owned by native host';
is $switch_server->take_remainder, '',
    'borrowed switch does not copy native tail into Perl remainder';

my $client = Unblock::HTTP1::Client->new;
my $tx = $client->request(
    Uniform::HTTP::Request->new(
        method    => 'GET',
        target    => '/switch',
        authority => 'example.test',
        headers   => [
            [ Connection => 'Upgrade' ],
            [ Upgrade    => 'test-proto' ],
        ],
    ),
    on_switch => sub { push @switch, 'client' },
);
$client->output;

my $switch_response =
    "HTTP/1.1 101 Switching Protocols\r\n" .
    "Connection: Upgrade\r\n" .
    "Upgrade: test-proto\r\n\r\n";

($status, $consumed) =
    Unblock::HTTP1::_Native::_borrowed_input_once(
        $client, $switch_response . 'PONG'
    );
is $status, Unblock::HTTP1::NativeABI::INPUT_SWITCH(),
    'borrowed client reports protocol switch';
is $consumed, length($switch_response),
    'client leaves post-switch bytes with native host';
ok $tx->is_complete, 'borrowed switch completes client transaction';
is_deeply \@switch, [qw(server client)], 'switch callbacks still fire';

my $driver_hits = 0;
my $driver_server = Unblock::HTTP1::Server->new(
    on_request => sub {
        my ($tx) = @_;
        ++$driver_hits;
        $tx->respond(Uniform::HTTP::Response->new(status => 204));
    },
);
my $driver =
    Unblock::HTTP1::_Native::BorrowedDriver->new($driver_server);

for (1 .. 2) {
    my ($driver_status, $driver_consumed) = $driver->feed(
        "GET /driver HTTP/1.1\r\nHost: example.test\r\n\r\n"
    );
    is $driver_status, Unblock::HTTP1::NativeABI::INPUT_OK(),
        'persistent native driver consumes request';
    is $driver_consumed,
        length("GET /driver HTTP/1.1\r\nHost: example.test\r\n\r\n"),
        'persistent native driver reports exact consumed prefix';
    $driver_server->output;
}
is $driver_hits, 2, 'one native ABI context serves repeated requests';

is Unblock::HTTP1::NativeABI::c_header(), $installed_header,
    'c_header returns the installed public header text';

done_testing;

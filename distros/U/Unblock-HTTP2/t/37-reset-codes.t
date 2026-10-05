use strict;
use warnings;
use Test::More;
use lib 't/lib';

use Test::UnblockHTTP2 qw(pump_until pump_until_idle);
use Uniform::HTTP::Request;
use Unblock::HTTP2;
use Unblock::HTTP2::Client;
use Unblock::HTTP2::Server;

is Unblock::HTTP2::REFUSED_STREAM(), 7,
    'REFUSED_STREAM constant has the RFC value';
is Unblock::HTTP2::CANCEL(), 8,
    'CANCEL constant has the RFC value';
is(
    Unblock::HTTP2->error_name(7),
    'REFUSED_STREAM',
    'error_name maps known HTTP/2 error codes',
);
ok !defined(Unblock::HTTP2->error_name(999)),
    'error_name returns undef for unknown codes';

my @server_errors;
my @client_errors;
my $refused_server_stream;

my $server = Unblock::HTTP2::Server->new(
    on_request => sub {
        my ($stream, $request) = @_;

        if ($request->target eq '/refused') {
            $refused_server_stream = $stream;
            $stream->reset(Unblock::HTTP2::REFUSED_STREAM());
        }
    },

    on_error => sub {
        my ($stream, $error, $error_code) = @_;
        push @server_errors, [ $stream, $error, $error_code ];
    },
);

my $client = Unblock::HTTP2::Client->new;
pump_until_idle($client, $server);

my $client_callback_code;
my $refused = $client->request(
    Uniform::HTTP::Request->new(
        method    => 'GET',
        target    => '/refused',
        scheme    => 'https',
        authority => 'example.test',
    ),

    on_error => sub {
        my ($stream, $error, $error_code) = @_;
        $client_callback_code = $error_code;
    },
);

pump_until($client, $server, sub { $refused->is_terminal });

ok $refused_server_stream,
    'server created the stream it explicitly refused';
ok $refused_server_stream->is_cancelled,
    'local explicit reset terminates the server stream locally';
is $refused_server_stream->error_code, Unblock::HTTP2::REFUSED_STREAM(),
    'local stream records the submitted RST_STREAM error code';
is $refused_server_stream->error_name, 'REFUSED_STREAM',
    'local stream exposes the symbolic error name';
is $refused_server_stream->reset_by_peer, 0,
    'local stream identifies its reset as locally initiated';

ok $refused->is_terminal,
    'client terminates after peer RST_STREAM';
is $refused->error_code, Unblock::HTTP2::REFUSED_STREAM(),
    'client preserves peer RST_STREAM error code';
is $refused->error_name, 'REFUSED_STREAM',
    'client maps peer reset code to symbolic name';
is $refused->reset_by_peer, 1,
    'client identifies peer-initiated reset';
is $client_callback_code, Unblock::HTTP2::REFUSED_STREAM(),
    'client on_error receives the numeric reset code';

my $cancel_server_stream;
my $cancel_server_code;

my $server2 = Unblock::HTTP2::Server->new(
    on_request => sub {
        my ($stream, $request) = @_;
        $cancel_server_stream = $stream;
    },

    on_error => sub {
        my ($stream, $error, $error_code) = @_;
        $cancel_server_code = $error_code if $stream;
    },
);

my $client2 = Unblock::HTTP2::Client->new;
pump_until_idle($client2, $server2);

my $cancelled = $client2->request(
    Uniform::HTTP::Request->new(
        method    => 'GET',
        target    => '/cancelled',
        scheme    => 'https',
        authority => 'example.test',
    ),
);

pump_until($client2, $server2, sub { $cancel_server_stream });

$cancelled->cancel;

ok $cancelled->is_cancelled,
    'cancel remains the local CANCEL convenience operation';
is $cancelled->error_code, Unblock::HTTP2::CANCEL(),
    'cancel records CANCEL as its reset code';
is $cancelled->reset_by_peer, 0,
    'cancel is recorded as locally initiated';

pump_until($client2, $server2, sub { $cancel_server_stream->is_terminal });

is $cancel_server_stream->error_code, Unblock::HTTP2::CANCEL(),
    'server preserves client CANCEL reset code';
is $cancel_server_stream->reset_by_peer, 1,
    'server identifies client reset as peer initiated';
is $cancel_server_code, Unblock::HTTP2::CANCEL(),
    'server on_error receives client reset code';

my $invalid_ok = eval {
    my $server3 = Unblock::HTTP2::Server->new;
    my $client3 = Unblock::HTTP2::Client->new;
    pump_until_idle($client3, $server3);

    my $stream = $client3->request(
        Uniform::HTTP::Request->new(
            method    => 'GET',
            target    => '/invalid',
            scheme    => 'https',
            authority => 'example.test',
        ),
    );

    $stream->reset(4_294_967_296);
    1;
};
ok !$invalid_ok,
    'reset rejects values outside the HTTP/2 32-bit error-code field';
like $@, qr/unsigned 32-bit integer/,
    'invalid reset-code failure is explicit';

done_testing;

use strict;
use warnings;
use 5.014;

use Test::Most;
use ZMQx::RPC::Message::Request;
use ZMQx::RPC::Header;
use JSON::XS;

subtest 'defaults' => sub {
    my $msg = ZMQx::RPC::Message::Request->new( command => 'cmd', );
    my $packed = $msg->pack('hello world');
    is( $packed->[0], 'cmd',         'command' );
    is( $packed->[1], 'string;500',  'header' );
    is( $packed->[2], 'hello world', 'payload' );
};

subtest 'custom header' => sub {
    my $msg = ZMQx::RPC::Message::Request->new(
        command => 'cmd',
        header  => ZMQx::RPC::Header->new(
            timeout => 42,
            type    => 'JSON',
        ),
    );
    my $packed = $msg->pack( [ 'hello', 'world' ] );
    is( $packed->[0], 'cmd',               'command' );
    is( $packed->[1], 'JSON;42',           'header' );
    is( $packed->[2], '["hello","world"]', 'payload is JSON' );

    my $unpacked = ZMQx::RPC::Message::Request->unpack($packed);
    is( $unpacked->command,         'cmd', 'unpack: command' );
    is( $unpacked->header->timeout, 42,    'unpack: header.timeout' );
    my ($payload) = @{ $unpacked->payload };
    is( $payload->[1], 'world', 'unpack: payload is a data structure' );
    explain $unpacked->payload;
};

subtest 'new_response' => sub {
    my $msg = ZMQx::RPC::Message::Request->new( command => 'cmd', );
    my $res = $msg->new_response( ["hase"] );
    is( $res->header->type, 'string', 'new response: header.type' );
};

subtest 'new_response JSON' => sub {
    my $msg = ZMQx::RPC::Message::Request->new(
        command => 'cmd',
        header  => ZMQx::RPC::Header->new(
            type => 'JSON',
        ),
    );
    my $res = $msg->new_response( [ { hash => 'ref' } ] );
    is( $res->header->type, 'JSON', 'new response: header.type' );

    my $packed = $res->pack;
    is( $packed->[0], 200, 'response status ok' );
    is( $packed->[2], '{"hash":"ref"}',
        'response packed payload is JSON string' );

};

subtest 'new_error_response' => sub {
    my $msg = ZMQx::RPC::Message::Request->new( command => 'cmd', );
    my $res = $msg->new_error_response( 500, 'err' );
    is( $res->status,       500,      'new error response: status' );
    is( $res->header->type, 'string', 'new error response: header.type' );
};

subtest 'new_error_response JSON' => sub {
    my $msg = ZMQx::RPC::Message::Request->new(
        command => 'cmd',
        header  => ZMQx::RPC::Header->new(
            type => 'JSON',
        ),
    );
    my $res = $msg->new_error_response( 500, 'err' );
    is( $res->status, 500, 'new error response: status' );
    is( $res->header->type, 'string',
        'new error response: header.type still string' );
};

subtest 'passthrough JSON ' => sub {
    my $msg = ZMQx::RPC::Message::Request->new(
        command => 'ZWEEN',
        header  => ZMQx::RPC::Header->new(
            timeout => 42,
            type    => 'JSON',
        ),
    );
    my $packed = $msg->pack( [ 'hello', 'world' ], '["Goodbye","World"]' );
    is( $packed->[0], 'ZWEEN',               'command' );
    is( $packed->[1], 'JSON;42',             'header' );
    is( $packed->[2], '["hello","world"]',   'payload is JSON' );
    is( $packed->[3], '["Goodbye","World"]', 'passthrough payload is JSON' );

    my $unpacked = ZMQx::RPC::Message::Request->unpack($packed);

    is( $unpacked->command,         'ZWEEN', 'unpack: command' );
    is( $unpacked->header->timeout, 42,      'unpack: header.timeout' );
    my $payload = $unpacked->payload;
    is( $payload->[0][1], 'world',   'unpack: payload is a data structure' );
    is( $payload->[1][0], 'Goodbye', 'unpack: payload is a data structure' );

    $packed = $msg->pack( [ 'hello', 'world' ], 'bogus' );
    is( $packed->[0], 'ZWEEN',             'command' );
    is( $packed->[1], 'JSON;42',           'header' );
    is( $packed->[2], '["hello","world"]', 'payload is JSON' );
    is( $packed->[3], 'bogus',
        'rightly or wrongly, passthrough payload is trusted to be valid' );

    $unpacked = eval { ZMQx::RPC::Message::Request->unpack($packed) };
    is( $unpacked, undef, 'unpack of bogus data fails' );
    like(
        $@,
        qr/Problem deserialising parameter 1 for ZWEEN as JSON.*\bbogus\b/,
        'Error message reports diagnostics for decoding fail'
    );
};

done_testing();


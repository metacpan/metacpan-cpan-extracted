use strict;
use warnings;
use Test::More;
use lib 't/lib';

use Test::UnblockHTTP2 qw(pump_until_idle);
use Unblock::HTTP2::Client;
use Unblock::HTTP2::Server;

sub frame {
    my ($type, $flags, $stream_id, $payload) = @_;
    $payload = '' unless defined $payload;
    my $length = length $payload;
    return pack(
        'C3CCN',
        ($length >> 16) & 0xff,
        ($length >> 8) & 0xff,
        $length & 0xff,
        $type,
        $flags,
        $stream_id,
    ) . $payload;
}

{
    my @server_invalid;

    my $server = Unblock::HTTP2::Server->new(
        on_invalid_frame => sub {
            my ($engine, $received, $lib_error_code) = @_;
            push @server_invalid, [ $received, $lib_error_code ];
        },
    );
    my $client = Unblock::HTTP2::Client->new;

    pump_until_idle($client, $server);

    my $unknown = frame(0xf0, 0, 0, 'abc');
    is $server->input($unknown), length($unknown),
        'server consumes an unknown extension frame';
    ok !$server->is_closed,
        'unknown extension frame does not close server connection';
    is scalar(@server_invalid), 0,
        'unknown extension frame is ignored rather than reported invalid';

    my $bad_ping = frame(6, 0, 1, '12345678');
    is $server->input($bad_ping), length($bad_ping),
        'server consumes invalid PING frame input';

    is scalar(@server_invalid), 1,
        'server reports invalid non-DATA frame';

    my ($received, $lib_error_code) = @{ $server_invalid[0] };
    is $received->{type}, 6,
        'invalid-frame callback preserves frame type';
    is $received->{stream_id}, 1,
        'invalid-frame callback preserves illegal stream id';
    is $received->{length}, 8,
        'invalid-frame callback preserves frame length';
    ok defined($lib_error_code) && $lib_error_code < 0,
        'invalid-frame callback preserves nghttp2 library error code';

    ok $server->want_write,
        'nghttp2 queues protocol response for invalid frame';
}

{
    my @client_invalid;

    my $server = Unblock::HTTP2::Server->new;
    my $client = Unblock::HTTP2::Client->new(
        on_invalid_frame => sub {
            my ($engine, $received, $lib_error_code) = @_;
            push @client_invalid, [ $received, $lib_error_code ];
        },
    );

    pump_until_idle($client, $server);

    my $unknown = frame(0xf1, 0, 0, 'xyz');
    is $client->input($unknown), length($unknown),
        'client consumes an unknown extension frame';
    ok !$client->is_closed,
        'unknown extension frame does not close client connection';
    is scalar(@client_invalid), 0,
        'client ignores unknown extension frame';

    my $bad_ping = frame(6, 0, 3, 'abcdefgh');
    is $client->input($bad_ping), length($bad_ping),
        'client consumes invalid PING frame input';

    is scalar(@client_invalid), 1,
        'client reports invalid non-DATA frame';
    is $client_invalid[0][0]{stream_id}, 3,
        'client callback preserves invalid frame details';
    ok $client->want_write,
        'client queues protocol response to invalid frame';
}

{
    my $server = Unblock::HTTP2::Server->new(
        on_invalid_frame => sub {
            die "application invalid-frame callback failed\n";
        },
    );
    my $client = Unblock::HTTP2::Client->new;

    pump_until_idle($client, $server);

    my $bad_ping = frame(6, 0, 1, '87654321');
    my $ok = eval {
        $server->input($bad_ping);
        1;
    };

    ok $ok,
        'invalid-frame callback failure is contained by connection layer';
    ok $server->is_closed,
        'failing invalid-frame callback closes the local engine';
}

done_testing;

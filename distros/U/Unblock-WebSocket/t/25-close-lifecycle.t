use strict;
use warnings;
use Test::More;

use Unblock::WebSocket;
use Unblock::WebSocket::Client;
use Unblock::WebSocket::Server;

sub backends {
    my @backend = ('perl');
    push @backend, 'native' if Unblock::WebSocket->native_available;
    return @backend;
}

sub client_options {
    my ($backend, %option) = @_;
    $option{backend} = $backend;
    $option{random_bytes} = sub { "\x01\x02\x03\x04" }
        if $backend eq 'perl';
    return %option;
}

for my $backend (backends()) {
    subtest "$backend abrupt EOF" => sub {
        my @close;
        my $client = Unblock::WebSocket::Client->new(
            client_options(
                $backend,
                on_close => sub {
                    my ($ws, $code, $reason) = @_;
                    push @close, [ $code, $reason ];
                },
            ),
        );

        $client->input_eof;
        $client->input_eof;

        is(scalar(@close), 1, 'abrupt EOF reports close exactly once');
        ok(!defined($close[0][0]), 'abrupt EOF has no WebSocket close code');
        is($close[0][1], 'transport EOF',
            'abrupt EOF identifies transport closure');
        ok(!$client->close_sent, 'abrupt EOF sends no WebSocket Close frame');
        ok(!$client->close_received,
            'abrupt EOF receives no WebSocket Close frame');
        ok($client->is_closed, 'abrupt EOF closes protocol object');
    };

    subtest "$backend simultaneous close" => sub {
        my (@server_close, @client_close);

        my $server = Unblock::WebSocket::Server->new(
            backend => $backend,
            on_close => sub {
                my ($ws, $code, $reason) = @_;
                push @server_close, [ $code, $reason ];
            },
        );
        my $client = Unblock::WebSocket::Client->new(
            client_options(
                $backend,
                on_close => sub {
                    my ($ws, $code, $reason) = @_;
                    push @client_close, [ $code, $reason ];
                },
            ),
        );

        $server->close(code => 1000, reason => 'server done');
        $client->close(code => 1000, reason => 'client done');

        my $server_wire = $server->output;
        my $client_wire = $client->output;
        $server->input($client_wire);
        $client->input($server_wire);

        is_deeply(\@server_close, [ [ 1000, 'client done' ] ],
            'server sees client close exactly once');
        is_deeply(\@client_close, [ [ 1000, 'server done' ] ],
            'client sees server close exactly once');
        ok($server->close_sent && $server->close_received,
            'server records both close directions');
        ok($client->close_sent && $client->close_received,
            'client records both close directions');
        ok($server->close_complete, 'server close handshake complete');
        ok($client->close_complete, 'client close handshake complete');
    };

    subtest "$backend peer loss during local close" => sub {
        my @close;
        my $client = Unblock::WebSocket::Client->new(
            client_options(
                $backend,
                on_close => sub {
                    my ($ws, $code, $reason) = @_;
                    push @close, [ $code, $reason ];
                },
            ),
        );

        $client->close(code => 1000, reason => 'local close');
        ok($client->close_sent, 'local Close was queued');
        ok(!$client->close_received, 'no peer Close received yet');

        $client->input_eof;

        is(scalar(@close), 1,
            'peer loss during local close reports close exactly once');
        ok(!defined($close[0][0]),
            'peer loss before Close response has no peer close code');
        is($close[0][1], 'transport EOF',
            'peer loss during close reports transport EOF');
        ok($client->close_sent,
            'local Close state remains recorded after peer loss');
        ok(!$client->close_received,
            'peer loss does not invent a received Close frame');
        ok($client->is_closed, 'peer loss closes protocol object');
    };
}

done_testing;

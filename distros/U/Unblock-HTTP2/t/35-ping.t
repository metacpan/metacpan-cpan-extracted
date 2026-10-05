use strict;
use warnings;
use Test::More;
use lib 't/lib';

use Test::UnblockHTTP2 qw(pump_until_idle);
use Unblock::HTTP2::Client;
use Unblock::HTTP2::Server;

my @client_ping;
my @client_ack;
my @server_ping;
my @server_ack;

my $server = Unblock::HTTP2::Server->new(
    on_ping => sub {
        my ($engine, $opaque) = @_;
        push @server_ping, $opaque;
    },
    on_ping_ack => sub {
        my ($engine, $opaque) = @_;
        push @server_ack, $opaque;
    },
);

my $client = Unblock::HTTP2::Client->new(
    on_ping => sub {
        my ($engine, $opaque) = @_;
        push @client_ping, $opaque;
    },
    on_ping_ack => sub {
        my ($engine, $opaque) = @_;
        push @client_ack, $opaque;
    },
);

pump_until_idle($client, $server);

my $client_payload = '12345678';
is $client->ping($client_payload), $client,
    'ping returns the client engine for chaining';

pump_until_idle($client, $server);

is_deeply \@server_ping, [ $client_payload ],
    'server receives client PING opaque bytes';
is_deeply \@client_ack, [ $client_payload ],
    'client receives automatic PING ACK with identical bytes';
is_deeply \@client_ping, [],
    'client does not mistake its ACK for a new PING';
is_deeply \@server_ack, [],
    'server does not receive an ACK for the peer-originated PING';

my $server_payload = pack('C*', 0, 1, 2, 3, 254, 255, 65, 90);
is length($server_payload), 8,
    'binary test payload is exactly eight bytes';

is $server->ping($server_payload), $server,
    'ping returns the server engine for chaining';

pump_until_idle($client, $server);

is_deeply \@client_ping, [ $server_payload ],
    'client receives binary server PING without text conversion';
is_deeply \@server_ack, [ $server_payload ],
    'server receives binary ACK with identical opaque bytes';

for my $bad (
    [ undef, 'undefined payload' ],
    [ '', 'empty payload' ],
    [ '1234567', 'seven-byte payload' ],
    [ '123456789', 'nine-byte payload' ],
    [ [], 'reference payload' ],
) {
    my ($payload, $label) = @$bad;
    my $ok = eval {
        $client->ping($payload);
        1;
    };
    ok !$ok, "ping rejects $label";
    like $@, qr/(?:required|scalar|exactly 8 bytes)/,
        "$label failure is explicit";
}

$client->close;
my $ok = eval {
    $client->ping('abcdefgh');
    1;
};
ok !$ok, 'ping rejects a closed connection';
like $@, qr/connection is closed/,
    'closed-connection PING failure is explicit';

done_testing;

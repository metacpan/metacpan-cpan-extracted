use strict;
use warnings;
use Test::More;

BEGIN {
    eval {
        require Unblock::HTTP1::Client;
        require Unblock::HTTP1::Server;
        require Unblock::WebSocket::Handshake;
        1;
    } or plan skip_all => 'Unblock::HTTP1 is an optional integration dependency';
}

use Unblock::WebSocket::Client;
use Unblock::WebSocket::Server;

{
    package Local::UpgradeHost;
    sub new { bless { queue => [], order => [], finished => 0, aborted => [] }, shift }
    sub unblock_send {
        my ($self, $bytes) = @_;
        push @{ $self->{queue} }, $bytes;
        push @{ $self->{order} }, $bytes;
        return;
    }
    sub unblock_finish { ++$_[0]{finished}; return }
    sub unblock_abort { push @{ $_[0]{aborted} }, $_[1]; return }
    sub take { join '', splice @{ $_[0]{queue} } }
}

my ($client_handshake, $request) =
    Unblock::WebSocket::Handshake->client_request(
        'ws://example.test/chat',
        http_version => '1.1',
    );

my $host = Local::UpgradeHost->new;
my ($server_handshake, $ws_server);
my @server_messages;
my @server_events;
my $http_server = Unblock::HTTP1::Server->new(
    transport => $host,
    on_request => sub {
        my ($tx, $incoming) = @_;
        push @server_events, 'request';
        $server_handshake =
            Unblock::WebSocket::Handshake->server_accept($incoming);
        $tx->respond($server_handshake->server_response);
    },
    on_switch => sub {
        push @server_events, 'switch';
        ok @{ $host->{queue} }, '101 response already accepted before on_switch';
        $ws_server = Unblock::WebSocket::Server->new(
            %{ $server_handshake->connection_options },
            backend   => 'perl',
            transport => $host,
            on_message => sub {
                my ($ws, $payload, $type) = @_;
                push @server_messages, [$payload, $type];
                $ws->send_text("echo:$payload");
            },
        );
    },
);

my @client_events;
my $http_client = Unblock::HTTP1::Client->new;
$http_client->request(
    $request,
    on_response => sub {
        my ($tx, $response) = @_;
        $client_handshake->validate_client_response($response);
        push @client_events, 'response';
    },
    on_switch => sub { push @client_events, 'switch' },
);

my @client_messages;
my $ws_client = Unblock::WebSocket::Client->new(
    backend => 'perl',
    on_message => sub { push @client_messages, $_[1] },
);
$ws_client->send_text('immediately-after-upgrade');
my $request_and_first_frame = $http_client->output . $ws_client->output;
$http_server->input($request_and_first_frame);
ok $http_server->is_switched, 'HTTP1 server switched to WebSocket';
ok $ws_server, 'server constructs established protocol in on_switch';
is_deeply \@server_events, [qw(request switch)],
    '101 handshake precedes transition callback';

my $remainder = $http_server->take_remainder;
ok length($remainder), 'HTTP1 preserved the same-input post-upgrade bytes';
$ws_server->input(substr($remainder, 0, 1));
$ws_server->input(substr($remainder, 1));
is_deeply \@server_messages,
    [['immediately-after-upgrade', 'text']],
    'chopped upgrade remainder decoded exactly once';

my $wire = $host->take;
$http_client->input($wire);
ok $http_client->is_switched, 'HTTP1 client switched to WebSocket';
is_deeply \@client_events, [qw(response switch)],
    'client accepted 101 before switching';
my $client_tail = $http_client->take_remainder;
ok length($client_tail), 'client preserved WebSocket bytes after 101';
$ws_client->input($client_tail);
is_deeply \@client_messages, ['echo:immediately-after-upgrade'],
    'WebSocket response followed 101 without crossing protocol boundaries';

$ws_server->send_text('later');
$ws_client->input($host->take);
is_deeply \@client_messages,
    ['echo:immediately-after-upgrade', 'later'],
    'attached WebSocket can send after HTTP processing finished';

is $host->{finished}, 0, 'opening handshake does not finish host';
is scalar @{ $host->{aborted} }, 0, 'upgrade does not abort host';

done_testing;

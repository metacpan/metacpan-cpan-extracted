use strict;
use warnings;
use Test::More;
use Scalar::Util qw(refaddr);

BEGIN {
    eval {
        require Unblock::HTTP1::Client;
        require Unblock::HTTP1::_Native;
        require Unblock::HTTP1::NativeABI;
        require Unblock::WebSocket::Client;
        require Unblock::WebSocket::Handshake;
        1;
    } or plan skip_all => 'HTTP1 native borrowed input and WebSocket are required';
}

use Unblock::HTTP::Server;

{
    package Local::BorrowedHost;
    sub new { bless { sent => [], upgrades => 0, order => [], errors => [] }, shift }
    sub unblock_send {
        my ($self, $bytes) = @_;
        push @{ $self->{sent} }, $bytes;
        push @{ $self->{order} }, 'write';
        return 1;
    }
    sub unblock_finish { ++$_[0]{finished} }
    sub unblock_abort { push @{ $_[0]{errors} }, $_[1] }
    sub unblock_upgrade {
        my ($self, $ws) = @_;
        ++$self->{upgrades};
        push @{ $self->{order} }, 'switch';
        $self->{consumer} = $ws;
    }
    sub take { join '', splice @{ $_[0]{sent} } }
}

my (@events, @seen, @client_messages, $opened_tx);
my $definition = Unblock::HTTP::Server->new(
    http1 => { websocket => 1 },
    on_request => sub { die 'native upgrade reached ordinary request' },
    on_websocket => sub {
        my ($tx, $request) = @_;
        push @events, 'offer';
        return {
            backend => 'perl',
            on_message => sub {
                my ($ws, $payload, $type) = @_;
                push @seen, [$payload, $type];
                $ws->send_text("echo:$payload");
            },
            on_open => sub {
                my ($ws, $transaction, $req) = @_;
                push @events, 'open';
                $opened_tx = $transaction;
                isa_ok($req, 'Uniform::HTTP::Request');
            },
        };
    },
);
my $host = Local::BorrowedHost->new;
my $server = $definition->attach_stream(transport => $host, protocol => 'http/1.1');
my $driver = Unblock::HTTP1::_Native::BorrowedDriver->new($server);

my ($handshake, $request) =
    Unblock::WebSocket::Handshake->client_request('ws://example.test/native');
my $http_client = Unblock::HTTP1::Client->new;
$http_client->request(
    $request,
    on_response => sub { $handshake->validate_client_response($_[1]) },
);

my $client_ws = Unblock::WebSocket::Client->new(
    backend => 'perl',
    on_message => sub { push @client_messages, $_[1] },
);
$client_ws->send_text('first');
my $upgrade_wire = $http_client->output;
my $native_window = $upgrade_wire . $client_ws->output;

# A native provider owns its contiguous input window. On INPUT_SWITCH
# it must transfer exactly the unconsumed suffix to its new consumer.
my ($status, $used) = $driver->feed($native_window);
is($status, Unblock::HTTP1::NativeABI::INPUT_SWITCH(),
    'real native borrowed input reports HTTP1 switch');
is($used, length($upgrade_wire), 'HTTP1 consumes exactly its handshake bytes');
ok($used < length($native_window), 'WebSocket frame remains in borrowed window');
is_deeply(\@events, ['offer', 'open'], 'application opens after handshake');
is_deeply($host->{order}, ['write', 'switch'], 'host accepts 101 before switching');
is($host->{upgrades}, 1, 'transport consumer changed exactly once');
isa_ok($host->{consumer}, 'Unblock::WebSocket::Server');
isa_ok($opened_tx, 'Unblock::HTTP1::Transaction');
is($server->take_remainder, '', 'native window did not leak into Perl remainder');

my $remaining = substr($native_window, $used);
$host->{consumer}->input($remaining);
is_deeply(\@seen, [['first', 'text']],
    'borrowed native remainder delivered exactly once to WebSocket');
is($server->take_remainder, '', 'no buffered HTTP tail to deliver twice');

my $outbound = $host->take;
like($outbound, qr/\AHTTP\/1\.1 101\b/,
    'native handshake and WebSocket output share ordered host queue');
$http_client->input($outbound);
ok($http_client->is_switched, 'HTTP client received successful upgrade');
$client_ws->input($http_client->take_remainder);
is_deeply(\@client_messages, ['echo:first'],
    'first native handoff message echoed on upgraded stream');

$client_ws->send_text('second');
$host->{consumer}->input($client_ws->output);
$client_ws->input($host->take);
is_deeply(\@seen, [['first', 'text'], ['second', 'text']],
    'future frames use successor directly, without the HTTP driver');
is_deeply(\@client_messages, ['echo:first', 'echo:second'],
    'later native-handoff output remains functional');
is(scalar @{ $host->{errors} }, 0, 'no transport abort during native handoff');

# A partial borrowed head is not copied or lost. Its owning provider
# resubmits the incomplete prefix before switching consumers.
my $partial_host = Local::BorrowedHost->new;
my $partial_server = $definition->attach_stream(transport => $partial_host);
my $partial_driver = Unblock::HTTP1::_Native::BorrowedDriver->new($partial_server);
my $cut = length($upgrade_wire) - 3;
my $prefix = substr($native_window, 0, $cut);
($status, $used) = $partial_driver->feed($prefix);
is($status, Unblock::HTTP1::NativeABI::INPUT_MORE(),
    'partial borrowed upgrade remains with native provider');
is($used, 0, 'partial head reports zero consumed bytes');
($status, $used) = $partial_driver->feed($native_window);
is($status, Unblock::HTTP1::NativeABI::INPUT_SWITCH(),
    'resubmitted native window completes upgrade');
is($used, length($upgrade_wire), 'resubmission consumes only HTTP bytes');
is($partial_host->{upgrades}, 1, 'partial native handshake upgrades only once');
$partial_host->{consumer}->input(substr($native_window, $used));
is_deeply(\@seen, [['first', 'text'], ['second', 'text'], ['first', 'text']],
    'partial native handshake preserves successor frame without duplication');

done_testing;

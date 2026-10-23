use strict;
use warnings;
use Test::More;

BEGIN {
    package Unblock::HTTP1::Transaction;
    sub on_data { }
    sub on_finish { }
    package Unblock::HTTP2::Transaction;
    sub on_data { }
    sub on_finish { }
    package Unblock::HTTP3::Transaction;
    sub on_data { }
    sub on_finish { }
    package main;

    $INC{'Net/QUIC/Driver.pm'} = __FILE__;
    package Net::QUIC::Driver;
    sub server { my ($class, %opt) = @_; bless { options => \%opt, fresh => [], events => [] }, $class }
    sub client { my ($class, %opt) = @_; bless { options => \%opt, client => TestQuic->new, events => [] }, $class }
    sub connection { $_[0]{client} }
    sub next_connection { shift @{ $_[0]{fresh} } }
    sub start { push @{ $_[0]{events} }, 'start'; $_[0] }
    sub receive { push @{ $_[0]{events} }, 'receive' }
    sub timeout { push @{ $_[0]{events} }, 'timeout' }
    sub writable { push @{ $_[0]{events} }, 'writable' }

    $INC{'Unblock/HTTP3/Client.pm'} = __FILE__;
    $INC{'Unblock/HTTP3/Server.pm'} = __FILE__;
    package Unblock::HTTP3::Client;
    sub new { my ($class, %opt) = @_; bless { opt => \%opt }, $class }
    sub start { $_[0]{started}++; $_[0] }
    sub started { $_[0]{started} || 0 }
    sub request { my ($self, @arg) = @_; $self->{request} = \@arg; return 'fake tx' }
    package Unblock::HTTP3::Server;
    our $ON_START;
    sub new { my ($class, %opt) = @_; bless { opt => \%opt }, $class }
    sub start { $_[0]{started}++; $ON_START->($_[0]) if $ON_START; $_[0] }
    sub started { $_[0]{started} || 0 }
}

{
    package TestQuic;
    sub new { bless { ready => 0, closed => 0 }, shift }
    sub ready { $_[0]{ready} }
    sub closed { $_[0]{closed} }
}

use Unblock::HTTP::QUIC;
use Unblock::HTTP::Server;

my @server_ready;
my $callback = sub {};
my $definition = Unblock::HTTP::Server->new(http3 => {}, on_request => $callback);
my $server = Unblock::HTTP::QUIC->server(
    certificate_file => 'cert', private_key_file => 'key',
    server => $definition,
    send => sub {}, set_timeout => sub {},
    on_ready => sub { push @server_ready, shift },
);
isa_ok($server->driver, 'Net::QUIC::Driver');
is($server->driver->{options}{alpn}, 'h3', 'server sets correct ALPN');
ok(!exists $server->driver->{options}{on_request}, 'request handler stays on HTTP side');
$server->start;
my $q1 = TestQuic->new;
my $q2 = TestQuic->new;
push @{ $server->driver->{fresh} }, $q1, $q2;
$server->receive('packet', 'local', 'peer');
is(scalar $server->sessions, 0, 'new connections await handshake');
$q1->{ready} = 1;
$server->timeout;
is(scalar $server->sessions, 1, 'ready connection gets HTTP/3 Server');
is(scalar @server_ready, 1, 'on_ready invoked once');
is($server_ready[0]->{opt}{on_request_end}, $callback, 'completed handler forwarded to HTTP/3');
is($server_ready[0]->{started}, 1, 'HTTP/3 started once');
$server->writable;
is(scalar @server_ready, 1, 'no duplicate on_ready');
$q2->{ready} = 1;
$server->receive('next', 'local', 'peer');
is(scalar @server_ready, 2, 'second server session starts after handshake');
$q1->{closed} = 1;
$server->timeout;
is(scalar $server->sessions, 1, 'closed server session is released');
is_deeply($server->driver->{events}, [qw(start receive timeout writable receive timeout)], 'driver events forwarded');

my @client_ready;
my $client = Unblock::HTTP::QUIC->client(
    local => 'local', peer => 'peer', server_name => 'example.test',
    send => sub {}, set_timeout => sub {},
    on_ready => sub { push @client_ready, shift },
);
$client->start;
ok(!defined $client->session, 'client initially not ready');
$client->driver->{client}{ready} = 1;
$client->receive('packet', 'local', 'peer');
isa_ok($client->session, 'Unblock::HTTP3::Client');
is($client->session->{started}, 1, 'HTTP/3 client engine started');
is(scalar @client_ready, 1, 'client on_ready invoked');
$client->session->request(method => 'GET', target => '/');
is_deeply($client->session->{request}, [ method => 'GET', target => '/' ], 'client request passes through');
$client->timeout;
is(scalar @client_ready, 1, 'client handler not repeated');
$client->driver->{client}{closed} = 1;
$client->writable;
ok(!defined $client->session, 'closed client session released');

my $reentrant = TestQuic->new;
$reentrant->{ready} = 1;
push @{ $server->driver->{fresh} }, $reentrant;
my $start_calls = 0;
{
    local $Unblock::HTTP3::Server::ON_START = sub {
        $start_calls++;
        $server->writable if $start_calls == 1;
    };
    $server->receive('ready', 'local', 'peer');
}
is($start_calls, 1, 'reentrant Driver progress does not attach twice');
is(scalar @server_ready, 3, 'one ready callback for reentrant attachment');

my $closing = TestQuic->new;
$closing->{ready} = 1;
push @{ $server->driver->{fresh} }, $closing;
{
    local $Unblock::HTTP3::Server::ON_START = sub { $closing->{closed} = 1 };
    $server->receive('closing', 'local', 'peer');
}
is(scalar @server_ready, 3, 'connection closed during start is not announced ready');
is(scalar $server->sessions, 2, 'connection closed during start is released');

for my $bad (
    [ sub { Unblock::HTTP::QUIC->server(send => sub {}, set_timeout => sub {}) }, qr/server must be/ ],
    [ sub { Unblock::HTTP::QUIC->client(alpn => 'h2', send => sub {}, set_timeout => sub {}) }, qr/Only the h3 ALPN/ ],
    [ sub { Unblock::HTTP::QUIC->server(server => $definition, on_request => sub {}) }, qr/configure on_request/ ],
    [ sub { Unblock::HTTP::QUIC->client(http3 => { quic => 1 }) }, qr/managed/ ],
    [ sub { Unblock::HTTP::QUIC->client(http3 => 0) }, qr/hash reference/ ],
    [ sub { Unblock::HTTP::QUIC->server(server => Unblock::HTTP::Server->new(http1 => {}, on_request => sub {})) }, qr/disabled/ ],
) {
    ok(!eval { $bad->[0]->(); 1 }, 'invalid manager options rejected');
    like($@, $bad->[1], 'actionable error');
}

done_testing;

use strict;
use warnings;
use Test::More;
use Scalar::Util qw(refaddr weaken);

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

    package TestEngine;
    sub new {
        my ($class, %options) = @_;
        bless { options => \%options, started => 0 }, $class;
    }
    sub start { $_[0]{started}++; $_[0] }
    sub input {
        my ($self, $tx, $request) = @_;
        $self->{options}{on_request}->($tx, $request);
        $self->{options}{on_request_end}->($tx, $request);
    }
    for my $version (1 .. 3) {
        my $package = "Unblock::HTTP${version}::Server";
        (my $file = "$package.pm") =~ s{::}{/}g;
        $INC{$file} = __FILE__;
        no strict 'refs';
        @{"${package}::ISA"} = ('TestEngine');
    }
}

{
    package TestTransport;
    sub new { bless {}, shift }
    sub unblock_send { 1 }
    sub unblock_finish { }
    sub unblock_abort { }
}
{
    package TestQuic;
    sub new { my ($class, %options) = @_; bless { ready => 1, closed => 0, %options }, $class }
    sub ready { $_[0]{ready} }
    sub closed { $_[0]{closed} }
}

use Unblock::HTTP::Server;

my @seen;
my $callback = sub { push @seen, [@_] };
my $settings = { 3 => 20 };
my $server = Unblock::HTTP::Server->new(
    http1 => { websocket => 0 },
    http2 => { settings => $settings },
    http3 => {},
    on_request => $callback,
);
is_deeply([$server->protocols], ['http/1.1', 'h2', 'h3'], 'enabled wire protocols');
is_deeply([$server->alpn_protocols], ['h2', 'http/1.1'], 'TLS list excludes QUIC');
ok($server->supports('h3'), 'H3 enabled');
ok(!$server->supports('spdy/3'), 'unknown protocol is not supported');
ok(!$server->supports(undef), 'undefined protocol is not supported');
ok(!$server->supports([]), 'reference is not a protocol');

my $host1 = TestTransport->new;
my $host2 = TestTransport->new;
my $h1 = $server->attach_stream(transport => $host1);
my $second = $server->attach_stream(transport => $host2, alpn => '');
isa_ok($h1, 'Unblock::HTTP1::Server');
isnt(refaddr($h1), refaddr($second), 'separate engines for separate connections');
is($h1->{options}{transport}, $host1, 'first transport retained by its engine');
is($second->{options}{transport}, $host2, 'second transport independent');
is($h1->{options}{on_request_end}, $callback, 'completed callback identity retained without a trampoline');
is($h1->{options}{receive_body}, 'buffered', 'bounded buffering selected');
is($h1->{options}{max_buffered_body_bytes}, 1_048_576, 'one MiB default limit');
ok(!exists $h1->{options}{websocket}, 'upper-layer policy is not an engine option');
ok(!$server->can('input'), 'definition is not on byte input path');
ok(!$server->can('backend'), 'definition is not a connection wrapper');
my $tx = bless {}, 'TestTransaction';
my $request = bless {}, 'TestRequest';
$h1->input($tx, $request);
is_deeply($seen[0], [$tx, $request], 'engine transaction and request identity preserved');

$settings->{3} = 99;
my $h2 = $server->attach_stream(transport => $host1, alpn => 'h2');
isa_ok($h2, 'Unblock::HTTP2::Server');
is($h2->{options}{settings}{3}, 20, 'caller changes do not mutate stored policy');
is($h2->{options}{enable_connect_protocol}, 0, 'disabled WebSocket does not advertise CONNECT');
$h2->{options}{settings}{3} = 55;
my $h2b = $server->attach_stream(transport => $host2, protocol => 'h2');
is($h2b->{options}{settings}{3}, 20, 'engine changes do not mutate another connection');
ok(!exists $h2->{options}{alpn}, 'selection metadata is consumed at attachment');

my $quic = TestQuic->new;
my $h3 = $server->attach_quic(connection => $quic);
isa_ok($h3, 'Unblock::HTTP3::Server');
is($h3->{options}{quic}, $quic, 'ready connection passed directly');
is($h3->{started}, 1, 'HTTP/3 started once before attachment returns');
is($h3->{options}{enable_extended_connect}, 0, 'H3 CONNECT advertisement disabled');

my $h2only = Unblock::HTTP::Server->new(http2 => {}, on_request => $callback);
is_deeply([$h2only->alpn_protocols], ['h2'], 'disabled H1 omitted from ALPN choices');
my $h3only = Unblock::HTTP::Server->new(http3 => {}, on_request => $callback);
is_deeply([$h3only->alpn_protocols], [], 'H3-only definition offers no TCP protocols');

for my $case (
    [ sub { $h2only->attach_stream(transport => $host1) }, qr/disabled/ ],
    [ sub { $h2only->attach_stream(transport => $host1, alpn => 'http/1.1') }, qr/disabled/ ],
    [ sub { $h2only->attach_quic(connection => $quic) }, qr/disabled/ ],
    [ sub { $server->attach_stream(transport => $host1, alpn => 'spdy/3') }, qr/unsupported/ ],
    [ sub { $server->attach_stream(transport => $host1, alpn => 'h3') }, qr/byte-stream/ ],
    [ sub { $server->attach_stream(transport => $host1, protocol => 'h2', alpn => undef) }, qr/either protocol or alpn/ ],
    [ sub { $server->attach_stream(transport => $host1, alpn => []) }, qr/scalars/ ],
    [ sub { $server->attach_stream() }, qr/transport must be an object/ ],
    [ sub { $server->attach_stream(transport => bless({}, 'IncompleteTransport')) }, qr/unblock_send/ ],
    [ sub { $server->attach_stream(transport => $host1, on_request => $callback) }, qr/unknown option/ ],
    [ sub { $server->attach_stream(transport => $host1, quic => $quic) }, qr/unknown option/ ],
    [ sub { $server->attach_stream('transport') }, qr/named arguments/ ],
    [ sub { $server->attach_quic(connection => TestQuic->new(ready => 0)) }, qr/not ready/ ],
    [ sub { $server->attach_quic(connection => TestQuic->new(closed => 1)) }, qr/closed/ ],
    [ sub { $server->attach_quic(connection => {}) }, qr/connection object/ ],
    [ sub { $server->attach_quic(connection => $quic, transport => $host1) }, qr/unknown option/ ],
    [ sub { $server->attach_quic('connection') }, qr/named arguments/ ],
) {
    ok(!eval { $case->[0]->(); 1 }, 'invalid attachment rejected');
    like($@, $case->[1], 'actionable attachment error');
}

my $circular = {};
$circular->{self} = $circular;
for my $case (
    [ { http1 => $circular }, qr/circular/ ],
    [ {}, qr/enable at least one/ ],
    [ { http1 => undef }, qr/hash reference/ ],
    [ { http2 => 0 }, qr/hash reference/ ],
    [ { http3 => [] }, qr/hash reference/ ],
    [ { http1 => { websocket => 2 } }, qr/0 or 1/ ],
    [ { http1 => { websocket => 1 } }, qr/on_websocket callback is required/ ],
    [ { http2 => { websocket => 1 } }, qr/on_websocket callback is required/ ],
    [ { http3 => { websocket => 1 } }, qr/on_websocket callback is required/ ],
    [ { http1 => { transport => $host1 } }, qr/managed/ ],
    [ { http2 => { on_request => $callback } }, qr/managed/ ],
    [ { http2 => { settings => [] } }, qr/settings must be/ ],
    [ { http1 => {}, transport => $host1 }, qr/unknown option/ ],
    [ { http1 => {}, on_body => $callback }, qr/unknown option/ ],
    [ { http1 => {}, on_request_end => $callback }, qr/unknown option/ ],
    [ { http1 => { receive_body => 'stream' } }, qr/managed/ ],
    [ { http2 => { max_buffered_body_bytes => 0 } }, qr/positive integer/ ],
    [ { http1 => {}, on_request => undef }, qr/coderef/ ],
) {
    ok(!eval { Unblock::HTTP::Server->new(on_request => $callback, %{ $case->[0] }); 1 }, 'invalid definition rejected');
    like($@, $case->[1], 'actionable definition error');
}

# Extended CONNECT is protocol-neutral, not inherently WebSocket-only.
my $generic_h2 = Unblock::HTTP::Server->new(
    http2 => { enable_connect_protocol => 1 },
    on_request => $callback,
);
my $generic_h3 = Unblock::HTTP::Server->new(
    http3 => { enable_extended_connect => 1 },
    on_request => $callback,
);
ok($generic_h2->supports('h2'), 'generic H2 CONNECT policy enabled without WebSocket');
ok($generic_h3->supports('h3'), 'generic H3 CONNECT policy enabled without WebSocket');
my $h2_generic_engine = $generic_h2->attach_stream(
    transport => TestTransport->new, protocol => 'h2',
);
is($h2_generic_engine->{options}{enable_connect_protocol}, 1,
    'H2 generic CONNECT advertisement reaches underlying engine');
my $h3_generic_engine = $generic_h3->attach_quic(connection => TestQuic->new);
is($h3_generic_engine->{options}{enable_extended_connect}, 1,
    'H3 generic CONNECT advertisement reaches underlying engine');

delete $circular->{self};

# The definition itself does not retain attached engines or transports.
my $weak;
{
    my $temporary = $server->attach_stream(transport => TestTransport->new);
    $weak = $temporary;
    weaken($weak);
}
ok(!defined $weak, 'definition does not retain inactive engines');
done_testing;

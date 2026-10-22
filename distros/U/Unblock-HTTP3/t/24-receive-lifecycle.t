use strict;
use warnings;

use FindBin ();
use IO::Select;
use IO::Socket::INET;
use Scalar::Util qw(refaddr);
use Test2::V0;
use Time::HiRes qw(time);

use Unblock::HTTP3::Capsule;
use Unblock::HTTP3::Client;
use Unblock::HTTP3::Connection;
use Unblock::HTTP3::Server;
use Net::QUIC;
use Net::QUIC::Driver;
use Uniform::HTTP::Request;
use Uniform::HTTP::Response;

ok($Net::QUIC::VERSION >= 0.05, 'vertical slice requires Net::QUIC 0.05 or newer');

my $cert_file = "$FindBin::Bin/fixtures/localhost-cert.pem";
my $key_file = "$FindBin::Bin/fixtures/localhost-key.pem";

-f $cert_file or die "missing bundled loopback TLS certificate: $cert_file";
-f $key_file or die "missing bundled loopback TLS private key: $key_file";

sub make_udp_socket {
    my $socket = IO::Socket::INET->new(
        LocalAddr => '127.0.0.1',
        LocalPort => 0,
        Proto     => 'udp',
    );

    die "could not create loopback UDP socket: $!"
        unless defined $socket;

    return $socket;
}

sub send_datagram {
    my ($socket, $datagram) = @_;

    my $bytes = $datagram->data;
    my $sent = send(
        $socket,
        $bytes,
        0,
        $datagram->peer,
    );

    die "loopback UDP send failed: $!"
        unless defined $sent;
    die "loopback UDP send was partial"
        if $sent != length($bytes);

    return 1;
}

my $server_socket = make_udp_socket();
my $client_socket = make_udp_socket();

my $server_local = getsockname($server_socket);
my $client_local = getsockname($client_socket);

my ($server_deadline, $client_deadline);

my $server_driver = Net::QUIC::Driver->server(
    alpn             => 'h3',
    certificate_file => $cert_file,
    private_key_file => $key_file,

    send => sub {
        my ($datagram) = @_;
        return send_datagram($server_socket, $datagram);
    },

    set_timeout => sub {
        my ($after) = @_;
        $server_deadline = defined($after)
            ? time() + $after
            : undef;
        return;
    },
);

my $client_driver = Net::QUIC::Driver->client(
    local       => $client_local,
    peer        => $server_local,
    alpn        => 'h3',
    server_name => 'localhost',
    ca_file     => $cert_file,

    send => sub {
        my ($datagram) = @_;
        return send_datagram($client_socket, $datagram);
    },

    set_timeout => sub {
        my ($after) = @_;
        $client_deadline = defined($after)
            ? time() + $after
            : undef;
        return;
    },
);

my $client_quic = $client_driver->connection;
my $selector = IO::Select->new($client_socket, $server_socket);

sub service_once {
    my ($hard_deadline) = @_;

    my $now = time();

    if (defined($server_deadline) && $server_deadline <= $now) {
        $server_deadline = undef;
        $server_driver->timeout;
    }

    $now = time();

    if (defined($client_deadline) && $client_deadline <= $now) {
        $client_deadline = undef;
        $client_driver->timeout;
    }

    $now = time();

    my $wait = 0.05;

    for my $deadline ($server_deadline, $client_deadline, $hard_deadline) {
        next unless defined $deadline;

        my $remaining = $deadline - $now;
        $remaining = 0 if $remaining < 0;
        $wait = $remaining if $remaining < $wait;
    }

    for my $socket ($selector->can_read($wait)) {
        my $bytes = '';
        my $peer = recv($socket, $bytes, 65535, 0);

        die "loopback UDP receive failed: $!"
            unless defined $peer;

        my $local = getsockname($socket);
        die "could not read loopback UDP local address: $!"
            unless defined $local;

        if (fileno($socket) == fileno($server_socket)) {
            $server_driver->receive($bytes, $local, $peer);
        } else {
            $client_driver->receive($bytes, $local, $peer);
        }
    }

    return;
}

sub run_until {
    my ($condition) = @_;

    my $hard_deadline = time() + 10;

    while (time() < $hard_deadline) {
        return 1 if $condition->();
        service_once($hard_deadline);
    }

    return $condition->() ? 1 : 0;
}

$server_driver->start;
$client_driver->start;

my $server_quic;

ok(
    run_until(sub {
        $server_quic ||= $server_driver->next_connection;

        return $server_quic
            && $client_quic->ready
            && $server_quic->ready;
    }),
    'real QUIC/TLS handshake completes with h3 ALPN',
);


my (%transactions, %events, %data, %requests);
my $server_h3 = Unblock::HTTP3::Server->new(
    quic => $server_quic,
    receive_body => 'buffered', max_buffered_body_bytes => 3,
    on_request => sub {
        my ($tx, $request) = @_;
        my $path = $request->target;
        $transactions{$path} = $tx;
        $requests{$path} = $request;
        push @{$events{$path}}, 'headers';
        $tx->on_finish(sub {
            is(refaddr($_[0]), refaddr($tx), 'same terminal transaction');
            push @{$events{$path}}, 'finish:' . $_[0]->state;
            $_[0]->cancel;
        });
        if ($path eq '/stream' || $path eq '/cancel-data') {
            $tx->on_data(sub {
                is(refaddr($_[0]), refaddr($tx), 'same streaming transaction');
                $data{$path} .= $_[1];
                is($tx->_buffered_body_bytes('request'), 0, 'stream does not accumulate');
                if ($path eq '/cancel-data') {
                    $tx->cancel;
                    push @{$events{$path}}, 'data-return';
                }
            });
        }
        if ($path eq '/cancel-headers') {
            $tx->cancel;
            push @{$events{$path}}, 'headers-return';
        }
    },
    on_request_end => sub {
        my ($tx, $request) = @_;
        my $path = $request->target;
        ok($request->is_complete && !$request->is_mutable, 'message complete and frozen at request end');
        is(refaddr($request), refaddr($requests{$path}), 'same request identity');
        if ($path eq '/stream') {
            is($data{$path}, 'abcdef', 'stream exceeds buffer limit');
            ok(!$request->has_buffered_body, 'streamed payload not installed as full body');
        } else {
            is($request->body, $path eq '/empty' ? '' : 'abc', 'engine installs final buffer');
        }
        push @{$events{$path}}, 'end';
        if ($path eq '/cancel-end') {
            $tx->cancel;
        } else {
            $tx->respond(status => 200, body => 'ok');
        }
        push @{$events{$path}}, 'end-return';
    },
    on_error => sub {
        my ($tx) = @_;
        push @{$events{$tx->request->target}}, 'error';
    },
);
my $client_h3 = Unblock::HTTP3::Client->new(quic => $client_quic);
$server_h3->start;
$client_h3->start;
my %client_tx;
for my $path (qw(/buffer /stream /empty /overflow /cancel-headers /cancel-data /cancel-end)) {
    $client_tx{$path} = $client_h3->request(
        method => 'POST', target => $path, scheme => 'https', authority => 'localhost',
        body => $path eq '/empty' ? '' : $path eq '/stream' ? 'abcdef' : $path eq '/overflow' ? 'abcd' : 'abc',
        on_finish => sub { push @{$events{"client$path"}}, $_[0]->state },
    );
}
ok(run_until(sub {
    return scalar(keys %transactions) == 7
        && !grep { !$_->is_terminal } values %transactions;
}), 'all server streams reach terminal state');
ok(run_until(sub { return !grep { !$_->is_terminal } values %client_tx }), 'all client streams terminate');
for my $path (qw(/buffer /stream /empty)) {
    is($events{$path}, ['headers','end','end-return','finish:complete'], "$path lifecycle order");
    is($events{"client$path"}, ['complete'], 'client finishes once');
    is($client_tx{$path}->response->body, 'ok', 'buffered client response');
}
is($events{'/overflow'}, ['headers','error','finish:error'], 'overflow has no successful completion');
is($transactions{'/overflow'}->_buffered_body_bytes('request'), 0, 'overflow buffer released');
for my $where (qw(headers data)) {
    is($events{"/cancel-$where"}, ['headers', "$where-return", 'finish:cancelled'], "cancel during $where");
}
is($events{'/cancel-end'}, ['headers','end','end-return','finish:cancelled'], 'cancel during request end');
ok(!$server_h3->failed && !$client_h3->failed, 'overflow preserves multiplexed connection');

# Registration before synchronous response arrival, and body fragmentation.
my (@client_events, $response_data);
my $fragmented = $client_h3->request(
    method => 'POST', target => '/fragmented', scheme => 'https', authority => 'localhost',
    stream_body => 1,
    on_data => sub { $response_data .= $_[1]; push @client_events, 'data' },
    on_complete => sub { push @client_events, 'complete' },
    on_finish => sub { push @client_events, 'finish' },
);
$fragmented->write('a');
ok(run_until(sub { return $transactions{'/fragmented'} && $transactions{'/fragmented'}->_buffered_body_bytes('request') == 1 }), 'first fragment retained');
like(dies { $transactions{'/fragmented'}->on_data(sub {}) }, qr/already started/, 'late receive mode change rejected');
$fragmented->end('bc');
ok(run_until(sub { $fragmented->is_complete }), 'fragmented request completes');
is($response_data, 'ok', 'client on_data receives payload');
is($client_events[-2], 'complete', 'client completion before finish');
is($client_events[-1], 'finish', 'client finish last');
like(dies { $fragmented->on_finish(sub {}) }, qr/terminal/, 'late finish registration rejected');


my @cancel_response_events;
my $cancel_response = $client_h3->request(
    method=>'POST', target=>'/cancel-response', scheme=>'https', authority=>'localhost', body=>'abc',
    on_response=>sub { $_[0]->cancel; push @cancel_response_events,'returned' },
    on_data=>sub { fail('cancelled response must not deliver queued DATA') },
    on_error=>sub { fail('intentional response cancellation is not error') },
    on_finish=>sub { push @cancel_response_events,$_[0]->state },
);
ok(run_until(sub { $cancel_response->is_terminal }), 'client cancellation during response headers terminates');
is(\@cancel_response_events,['returned','cancelled'],'queued DATA after cancellation does not escape');

done_testing;

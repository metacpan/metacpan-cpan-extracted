use strict;
use warnings;
use Test::More;
use Scalar::Util qw(isweak weaken);
use Uniform::HTTP::Request;
use Uniform::HTTP::Response;
use Unblock::HTTP1::Client;
use Unblock::HTTP1::Server;

{
    package Local::Host;
    sub new {
        my ($class, %arg) = @_;
        bless {
            bytes   => '',
            writes  => 0,
            finish  => 0,
            abort   => [],
            returns => $arg{returns} || [],
            throw   => $arg{throw},
            on_send => $arg{on_send},
        }, $class;
    }
    sub unblock_send {
        my ($self, $bytes) = @_;
        ++$self->{writes};
        if (my $callback = $self->{on_send}) {
            $callback->();
        }
        die $self->{throw} if $self->{throw};
        $self->{bytes} .= $bytes;
        return shift @{ $self->{returns} } if @{ $self->{returns} };
        return;
    }
    sub unblock_finish { ++$_[0]{finish}; return }
    sub unblock_abort { push @{ $_[0]{abort} }, $_[1]; return }
}

my $get = "GET / HTTP/1.1\r\nHost: example.test\r\n\r\n";

subtest 'server named fields and output handoff' => sub {
    my $host = Local::Host->new;
    my $request;
    my $server = Unblock::HTTP1::Server->new(
        transport => $host,
        on_request => sub {
            my ($tx, $req) = @_;
            $request = $req;
            $tx->respond(status => 200, body => "hello\n");
        },
    );
    ok(isweak($server->{transport}), 'host reference is weak');
    $server->input($get);
    isa_ok($request, 'Uniform::HTTP::Request');
    like($host->{bytes}, qr/\AHTTP\/1\.1 200 OK\r\n/, 'response delivered automatically');
    like($host->{bytes}, qr/hello\n\z/, 'body delivered');
    is($host->{finish}, 0, 'persistent connection not closed');
    my $ok = eval { $server->output; 1 };
    ok(!$ok, 'manual output forbidden in attached mode');
    like($@, qr/manual output/, 'manual/automatic ownership error is explicit');
};

subtest 'late response after read EOF is still delivered' => sub {
    my $host = Local::Host->new;
    my $pending;
    my $errors = 0;
    my $server = Unblock::HTTP1::Server->new(
        transport  => $host,
        on_request => sub { $pending = $_[0] },
        on_error   => sub { ++$errors },
    );
    $server->input($get);
    $server->input_eof;
    is($errors, 0, 'clean half-close does not reject complete request');
    is($host->{finish}, 0, 'read EOF does not close before pending reply');
    $pending->respond(status => 200, body => 'late');
    like($host->{bytes}, qr/late\z/, 'timer-style delayed reply sent immediately');
    is($host->{finish}, 1, 'close requested after output handoff');
    is($errors, 0, 'late response caused no HTTP error');
    $server->input_eof;
    is($host->{finish}, 1, 'repeated EOF is idempotent');
};

subtest 'client named request and response callbacks' => sub {
    my $host = Local::Host->new;
    my ($response, $complete);
    my $client = Unblock::HTTP1::Client->new(transport => $host);
    my $tx = $client->request(
        method => 'GET', target => '/news', authority => 'example.test',
        on_response => sub { $response = $_[1] },
        on_complete => sub { ++$complete },
    );
    isa_ok($tx->request, 'Uniform::HTTP::Request');
    like($host->{bytes}, qr/\AGET \/news HTTP\/1\.1\r\n/, 'request auto-sent');
    $client->input("HTTP/1.1 200 OK\r\nContent-Length: 2\r\n\r\nOK");
    isa_ok($response, 'Uniform::HTTP::Response');
    is($complete, 1, 'request completed');
    ok($tx->is_complete, 'Transaction completed');
};

subtest 'existing Uniform objects stay supported' => sub {
    my $host = Local::Host->new;
    my $server = Unblock::HTTP1::Server->new(
        transport => $host,
        on_request => sub {
            $_[0]->respond(Uniform::HTTP::Response->new(
                status => 201, body => 'created',
            ));
        },
    );
    $server->input($get);
    like($host->{bytes}, qr/\AHTTP\/1\.1 201 /, 'canonical response accepted');
    my $client_host = Local::Host->new;
    my $client = Unblock::HTTP1::Client->new(transport => $client_host);
    $client->request(Uniform::HTTP::Request->new(
        method => 'GET', target => '/', authority => 'example.test',
    ));
    like($client_host->{bytes}, qr/\AGET \/ HTTP\/1\.1/, 'canonical request accepted');
};

subtest 'transport congestion blocks body producer until resume' => sub {
    my $host = Local::Host->new(returns => [ 0, undef, undef ]);
    my ($tx, $drains);
    my $server = Unblock::HTTP1::Server->new(
        transport => $host,
        on_request => sub {
            $tx = $_[0];
            $tx->respond(
                status => 200, stream_body => 1,
                on_drain => sub { ++$drains },
            );
        },
    );
    $server->input($get);
    ok(!$tx->write('abc'), 'congestion signaled after accepting body');
    is($drains || 0, 0, 'no early drain');
    $server->resume_output;
    is($drains, 1, 'producer notified after resume');
    like($host->{bytes}, qr/3\r\nabc\r\n/, 'body delivered once');
    ok($tx->end(''), 'final body accepted');
    like($host->{bytes}, qr/0\r\n\r\n\z/, 'chunked body ended');
};

subtest 'graceful close behind congestion preserves data' => sub {
    my $host = Local::Host->new(returns => [ 0, undef ]);
    my $server = Unblock::HTTP1::Server->new(
        transport => $host,
        on_request => sub {
            $_[0]->respond(status => 200, body => 'bye');
        },
    );
    $server->input("GET / HTTP/1.1\r\nHost: example.test\r\nConnection: close\r\n\r\n");
    is($host->{finish}, 1, 'accepted whole response before graceful finish');
    like($host->{bytes}, qr/bye\z/, 'body retained');
};

subtest 'fatal send exception aborts the host' => sub {
    my $host = Local::Host->new(throw => 'disk gone');
    my $error;
    my $server = Unblock::HTTP1::Server->new(
        transport => $host,
        on_request => sub { $_[0]->respond(status => 200, body => 'x') },
        on_error => sub { $error = $_[1] },
    );
    $server->input($get);
    ok($server->is_closed, 'engine closes on host send exception');
    is(scalar @{ $host->{abort} }, 1, 'abort signaled once');
    like($host->{abort}[0], qr/disk gone/, 'reason preserved');
    like($error, qr/disk gone/, 'failure delivered to error callback');
    is($host->{finish}, 0, 'fatal failure is not graceful');
};

subtest 'recursive input from host send is rejected and aborted' => sub {
    my $server;
    my $host = Local::Host->new(on_send => sub { $server->input($get) });
    $server = Unblock::HTTP1::Server->new(
        transport => $host,
        on_request => sub { $_[0]->respond(status => 200, body => 'hi') },
    );
    $server->input($get);
    is(scalar @{ $host->{abort} }, 1, 'reentrant input aborts once');
    like($host->{abort}[0], qr/recursively/, 'reentry diagnosed');
};

subtest '101 switch fires after handshake is accepted, with remainder' => sub {
    my $host = Local::Host->new(returns => [ 0, undef ]);
    my @events;
    my $pending;
    my $server = Unblock::HTTP1::Server->new(
        transport => $host,
        on_request => sub { $pending = $_[0] },
        on_switch => sub {
            push @events, 'switch';
            like($host->{bytes}, qr/HTTP\/1\.1 101 /,
                'switch callback observes accepted handshake');
        },
    );
    $server->input("GET / HTTP/1.1\r\nHost: example.test\r\nConnection: Upgrade\r\nUpgrade: test-proto\r\n\r\nTAIL");
    $pending->send_informational(status => 103);
    $pending->respond(
        status => 101,
        headers => [
            [ Connection => 'Upgrade' ],
            [ Upgrade => 'test-proto' ],
        ],
    );
    is_deeply(\@events, [], 'pending handshake delays callback');
    ok($server->is_switched, 'HTTP parsing has stopped');
    is($server->take_remainder, 'TAIL', 'post-upgrade bytes preserved');
    $server->resume_output;
    is_deeply(\@events, ['switch'], 'switch fires after resumed send');
};

subtest 'dropped host is treated as transport failure' => sub {
    my $host = Local::Host->new;
    my $server = Unblock::HTTP1::Server->new(
        transport => $host,
        on_request => sub { $_[0]->respond(status => 200, body => 'test') },
    );
    undef $host;
    $server->input($get);
    ok($server->is_closed, 'weak host no longer exists; engine closes');
};


subtest 'pipelined requests preserve ordering through host output' => sub {
    my $host = Local::Host->new;
    my @seen;
    my $server = Unblock::HTTP1::Server->new(
        transport => $host,
        on_request => sub {
            my ($tx, $request) = @_;
            push @seen, $request->target;
            $tx->respond(status => 200, body => $request->target);
        },
    );
    my $wire = "GET /one HTTP/1.1\r\nHost: example.test\r\n\r\n"
        . "GET /two HTTP/1.1\r\nHost: example.test\r\n\r\n";
    $server->input($wire);
    is_deeply(\@seen, [qw(/one /two)], 'requests delivered in order');
    my @status = $host->{bytes} =~ /HTTP\/1\.1 200 OK/g;
    is(scalar @status, 2, 'two responses handed to host');
    like($host->{bytes}, qr/\/oneHTTP\/1\.1 200 OK/s,
        'response boundaries stay ordered');
    is($host->{writes}, 1, 'parser coalesces response output on read');
};


subtest 'named and object response forms reject malformed objects' => sub {
    my $host = Local::Host->new;
    my $pending;
    my $server = Unblock::HTTP1::Server->new(
        transport => $host,
        on_request => sub { $pending = $_[0] },
    );
    $server->input($get);
    my $ok = eval { $pending->respond({ status => 200 }); 1 };
    ok(!$ok, 'hash reference is not a Uniform response');
    like($@, qr/requires a Uniform HTTP response object/,
        'response validation error is explicit');
    $ok = eval { $pending->send_informational({ status => 103 }); 1 };
    ok(!$ok, 'informational response checks object');
    like($@, qr/requires a Uniform HTTP response object/,
        'informational validation error is explicit');
    $pending->respond(status => 200, body => 'valid');
    like($host->{bytes}, qr/valid\z/, 'valid named response remains usable');
};

subtest 'graceful close waits behind congested host' => sub {
    my $host = Local::Host->new(returns => [ 0, undef ]);
    my $pending;
    my $server = Unblock::HTTP1::Server->new(
        transport => $host,
        on_request => sub { $pending = $_[0] },
    );
    $server->input(
        "GET / HTTP/1.1\r\nHost: example.test\r\nConnection: close\r\n\r\n"
    );
    $pending->send_informational(status => 103);
    $pending->respond(status => 200, body => 'final');
    is($host->{finish}, 0, 'close deferred while final body still buffered');
    unlike($host->{bytes}, qr/final/, 'final response not yet accepted');
    $server->resume_output;
    like($host->{bytes}, qr/final\z/, 'final response accepted on resume');
    is($host->{finish}, 1, 'close follows complete output handoff');
};

subtest 'failed switch callback aborts rather than leaves an orphan host' => sub {
    my $host = Local::Host->new;
    my $server = Unblock::HTTP1::Server->new(
        transport => $host,
        on_request => sub {
            $_[0]->respond(
                status => 101,
                headers => [
                    [ Connection => 'Upgrade' ],
                    [ Upgrade => 'test-proto' ],
                ],
            );
        },
        on_switch => sub { die 'upgrade adapter failed' },
    );
    $server->input(
        "GET / HTTP/1.1\r\nHost: example.test\r\n"
        . "Connection: Upgrade\r\nUpgrade: test-proto\r\n\r\n"
    );
    is(scalar @{ $host->{abort} }, 1, 'switch callback failure aborts host');
    like($host->{abort}[0], qr/upgrade adapter failed/,
        'switch callback failure reason preserved');
    is($host->{finish}, 0, 'no graceful finish after fatal switch');
};

done_testing;

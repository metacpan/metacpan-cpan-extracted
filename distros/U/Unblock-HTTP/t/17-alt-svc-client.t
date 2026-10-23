use strict;
use warnings;
use Test::More;
use Scalar::Util qw(refaddr);

BEGIN {
    package Uniform::HTTP::Request;
    sub new { my ($class, %arg) = @_; bless \%arg, $class }
    sub authority { $_[0]{authority} }
    sub target { $_[0]{target} }
    $INC{'Uniform/HTTP/Request.pm'} = __FILE__;

    package AltTest::Response;
    sub new { my ($class, @alt) = @_; bless { alt => \@alt }, $class }
    sub header_values { $_[1] eq 'alt-svc' ? $_[0]{alt} : [] }
    sub header { return }

    package AltTest::Transaction;
    sub new {
        my ($class, $engine, $request, $cb) = @_;
        bless { engine => $engine, request => $request,
                cb => $cb, state => 'active' }, $class;
    }
    sub is_error { $_[0]{state} eq 'error' }
    sub is_cancelled { $_[0]{state} eq 'cancelled' }
    sub is_complete { $_[0]{state} eq 'complete' }
    sub response { $_[0]{response} }
    sub error { $_[0]{error} }
    sub cancel {
        my ($self) = @_;
        $self->{state} = 'cancelled';
        $self->{cb}{on_finish}->($self);
    }
    sub finish {
        my ($self, $response) = @_;
        $self->{response} = $response;
        $self->{cb}{on_response}->($self, $response) if $self->{cb}{on_response};
        $self->{cb}{on_complete}->($self) if $self->{cb}{on_complete};
        $self->{state} = 'complete';
        $self->{cb}{on_finish}->($self);
    }
    sub fail {
        my ($self, $reason) = @_;
        $self->{error} = $reason;
        $self->{state} = 'error';
        $self->{cb}{on_error}->($self, $reason) if $self->{cb}{on_error};
        $self->{cb}{on_finish}->($self);
    }

    package AltTest::Engine;
    sub new { my ($class, %args) = @_; bless { args => \%args, closed => 0 }, $class }
    sub request {
        my ($self, $request, %callbacks) = @_;
        return AltTest::Transaction->new($self, $request, \%callbacks);
    }
    sub is_closed { $_[0]{closed} }
    sub failed { $_[0]{closed} }
    sub close { $_[0]{closed} = 1 }
    sub can_open_transaction { 1 }
    sub start { $_[0]{started}++; $_[0] }

    for my $num (1 .. 3) {
        my $package = 'Unblock::HTTP' . $num . '::Client';
        (my $file = $package) =~ s{::}{/}g;
        $INC{$file . '.pm'} = __FILE__;
        no strict 'refs';
        @{$package . '::ISA'} = ('AltTest::Engine');
    }

    package AltTest::Host;
    sub new { bless {}, shift }
    sub unblock_send { 1 }
    sub unblock_finish {}
    sub unblock_abort {}
    package AltTest::Quic;
    sub new { bless { ready => 1, closed => 0 }, shift }
    sub ready { $_[0]{ready} }
    sub closed { $_[0]{closed} }
}

use Unblock::HTTP::Client;

my (@tcp, @udp, @deferred, @responses, @errors);
my $now = 100;
my $client = Unblock::HTTP::Client->new(
    http1 => {}, http2 => {}, http3 => {},
    alt_svc_clock => sub { $now },
    connect_stream => sub { push @tcp, [@_] },
    connect_quic => sub { push @udp, [@_] },
    defer => sub { push @deferred, $_[0] },
);
my $flush = sub {
    my $limit = 100;
    while (@deferred && $limit--) { shift(@deferred)->() }
    die 'defer did not settle' unless $limit;
};

my $first = $client->request(
    url => 'https://example.test/first',
    on_response => sub { push @responses, [@_] },
);
is(scalar(@tcp), 1, 'cold request connects through TCP');
is(scalar(@udp), 0, 'cold request does not race QUIC');
my $h2 = $tcp[0][2]->(
    transport => AltTest::Host->new, alpn => 'h2', verified_origin => 1,
);
isa_ok($h2, 'Unblock::HTTP2::Client');
$first->transaction->finish(AltTest::Response->new('h3=":7443"; ma=30'));
is(refaddr($responses[0][0]), refaddr($first->transaction),
    'buffered response passes real transaction');

my $second = $client->request(url => 'https://example.test/second');
is(scalar(@udp), 1, 'fresh advertisement selects QUIC');
is($udp[0][0]{port}, 443, 'origin port retained');
is($udp[0][0]{alternative_port}, 7443, 'alternative UDP port supplied separately');
is($udp[0][0]{authority}, 'example.test', 'original authority retained');
is($second->state, 'connecting', 'transaction waits for QUIC');
my $h3 = $udp[0][1]->(
    connection => AltTest::Quic->new, verified_origin => 1,
);
isa_ok($h3, 'Unblock::HTTP3::Client');
is($h3->{started}, 1, 'H3 engine started');
is($second->transaction->{request}->authority, 'example.test',
    'request uses original origin authority');
$second->transaction->finish(AltTest::Response->new());

$now += 31;
my $expired = $client->request(url => 'https://example.test/expired');
ok($expired->transaction, 'expired Alt-Svc uses existing TCP engine');
is(scalar(@udp), 1, 'expired Alt-Svc does not reconnect QUIC');
$expired->transaction->finish(AltTest::Response->new());

my $insecure = $client->request(url => 'https://insecure.test/first');
$tcp[1][2]->(transport => AltTest::Host->new, alpn => 'h2');
$insecure->transaction->finish(AltTest::Response->new('h3=":8443"'));
my $uncached = $client->request(url => 'https://insecure.test/second');
ok($uncached->transaction, 'unverified TLS does not cache alternative');
is(scalar(@udp), 1, 'insecure advertisement ignored');
$uncached->transaction->finish(AltTest::Response->new());

my $strict = $client->request(
    url => 'https://example.test/strict', http_version => '3',
);
isa_ok($strict->transaction->{engine}, 'Unblock::HTTP3::Client');
$strict->transaction->finish(AltTest::Response->new());

my $h1op = $client->request(
    url => 'https://example.test/h1', http_version => '1.1',
);
is(scalar(@tcp), 3, 'strict H1 requires new connection');
$tcp[2][2]->(transport => AltTest::Host->new, alpn => 'http/1.1');
isa_ok($h1op->transaction->{engine}, 'Unblock::HTTP1::Client');
$h1op->transaction->finish(AltTest::Response->new());

my $seed = $client->request(url => 'https://fallback.test/seed');
$tcp[3][2]->(
    transport => AltTest::Host->new, alpn => 'h2', verified_origin => 1,
);
$seed->transaction->finish(AltTest::Response->new('h3=":7999"'));
my $post = $client->request(
    method => 'POST', url => 'https://fallback.test/upload',
    on_error => sub { push @errors, $_[1] },
);
is(scalar(@udp), 2, 'advertised QUIC attempted for POST');
$udp[1][1]->(error => 'UDP unavailable');
ok($post->transaction, 'unsent POST safely falls back to TCP');
isa_ok($post->transaction->{engine}, 'Unblock::HTTP2::Client');
is(scalar(@errors), 0, 'pre-dispatch fallback does not signal transaction error');
$post->transaction->finish(AltTest::Response->new());
my $after = $client->request(url => 'https://fallback.test/after');
is(scalar(@udp), 2, 'failed alternative invalidated');
$after->transaction->finish(AltTest::Response->new());

my $authseed = $client->request(url => 'https://cert.test/seed');
$tcp[4][2]->(
    transport => AltTest::Host->new, alpn => 'h2', verified_origin => 1,
);
$authseed->transaction->finish(AltTest::Response->new('h3=":7444"'));
my $auth = $client->request(url => 'https://cert.test/next');
is(scalar(@udp), 3, 'fresh alternative attempted');
$udp[2][1]->(connection => AltTest::Quic->new);
isa_ok($auth->transaction->{engine}, 'Unblock::HTTP2::Client');
$auth->transaction->finish(AltTest::Response->new());

my $seed2 = $client->request(url => 'https://no-replay.test/seed');
$tcp[5][2]->(
    transport => AltTest::Host->new, alpn => 'h2', verified_origin => 1,
);
$seed2->transaction->finish(AltTest::Response->new('h3=":7445"'));
my $dispatched = $client->request(
    url => 'https://no-replay.test/get',
    on_error => sub { push @errors, $_[1] },
);
$udp[3][1]->(connection => AltTest::Quic->new, verified_origin => 1);
my $before = scalar(@tcp);
$dispatched->transaction->fail('stream reset after request was sent');
is($dispatched->state, 'error', 'terminal error reported');
is(scalar(@tcp), $before, 'already-dispatched GET is not replayed');
is(scalar(@errors), 1, 'exactly one dispatched error delivered');

$flush->();
done_testing;

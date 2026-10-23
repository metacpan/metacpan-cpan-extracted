use strict;
use warnings;
use Test::More;
use Scalar::Util qw(refaddr);

BEGIN {
    package Uniform::HTTP::Request;
    sub new { my ($class, %f) = @_; bless \%f, $class }
    $INC{'Uniform/HTTP/Request.pm'} = __FILE__;

    package NetworkTest::Response;
    sub new { my ($class, $alt) = @_; bless { alt => $alt }, $class }
    sub header_values { $_[1] eq 'alt-svc' ? [$_[0]{alt}] : [] }
    sub header { return }

    package NetworkTest::Transaction;
    sub new {
        my ($class, $engine, $cb) = @_;
        bless { engine => $engine, cb => $cb, state => 'active' }, $class;
    }
    sub is_error { $_[0]{state} eq 'error' }
    sub is_cancelled { $_[0]{state} eq 'cancelled' }
    sub is_complete { $_[0]{state} eq 'complete' }
    sub error { $_[0]{error} }
    sub response { $_[0]{response} }
    sub finish {
        my ($self, $response) = @_;
        return unless $self->{state} eq 'active';
        $self->{response} = $response if $response;
        $self->{cb}{on_response}->($self, $response)
            if $response && $self->{cb}{on_response};
        $self->{state} = 'complete';
        $self->{engine}{active}--;
        $self->{cb}{on_finish}->($self);
    }
    sub cancel {
        my ($self) = @_;
        return unless $self->{state} eq 'active';
        $self->{state} = 'cancelled';
        $self->{engine}{active}--;
        $self->{cb}{on_finish}->($self);
    }

    package NetworkTest::Engine;
    our $REFUSE_H3;
    sub new {
        my ($class, %option) = @_;
        bless { option => \%option, active => 0, closed => 0 }, $class;
    }
    sub request {
        my ($self, $request, %cb) = @_;
        return if $REFUSE_H3 && $self->isa('Unblock::HTTP3::Client');
        $self->{active}++;
        return NetworkTest::Transaction->new($self, \%cb);
    }
    sub is_closed { $_[0]{closed} }
    sub failed { $_[0]{closed} }
    sub draining { 0 }
    sub can_open_transaction { 1 }
    sub remote_shutdown_id { undef }
    sub shutdown_started { 0 }
    sub start { $_[0]{started}++ }
    sub close { $_[0]{closed}++ }
    for my $n (1..3) {
        my $package = 'Unblock::HTTP' . $n . '::Client';
        (my $file = $package) =~ s{::}{/}g;
        $INC{$file . '.pm'} = __FILE__;
        no strict 'refs';
        @{$package . '::ISA'} = ('NetworkTest::Engine');
    }

    package NetworkTest::Host;
    sub new { bless { closed => 0, ready => 1 }, shift }
    sub unblock_send { 1 }
    sub unblock_finish {}
    sub unblock_abort {}
    sub ready { 1 }
    sub closed { $_[0]{closed} }
    sub close { $_[0]{closed}++ }
}
use Unblock::HTTP::Client;

my (@later, @releases, @timers);
my $defer = sub { push @later, $_[0] };
my $flush = sub {
    my $limit = 100;
    while (@later && $limit--) { shift(@later)->() }
    die 'unexpected repeated scheduling' unless $limit > 0;
};
my $release = sub {
    my ($host, $engine, $protocol, $reason) = @_;
    push @releases, [$engine, $protocol, $reason];
    $engine->close;
    $host->close;
};
my $timer = sub {
    my ($seconds, $fire) = @_;
    my $state = { seconds => $seconds, fire => $fire, cancelled => 0 };
    push @timers, $state;
    return sub { $state->{cancelled}++ };
};

{
    my (@pending, @cancelled, @errors, @finished);
    my $client = Unblock::HTTP::Client->new(
        http1 => {},
        connect_stream => sub {
            my ($info, $alpn, $ready) = @_;
            my $attempt = { ready => $ready, canceled => 0 };
            push @pending, $attempt;
            return sub { $attempt->{canceled}++ };
        },
        defer => $defer,
        release_connection => $release,
    );
    my $before = $client->pool_stats;
    is_deeply($before, {
        origins => 0, connections => 0, active => 0, idle => 0,
        retiring => 0, credit_blocked => 0, connecting => 0,
        pending => 0, by_origin => [],
    }, 'empty client snapshot contains only counts');

    my $one = $client->request(url => 'http://pending.test/one',
        on_error => sub { push @errors, 'error' },
        on_finish => sub { push @finished, 'one' },
    );
    my $two = $client->request(url => 'http://pending.test/two',
        on_finish => sub { push @finished, 'two' },
    );
    is($client->pool_stats->{connecting}, 1, 'one factory pending');
    is($client->pool_stats->{pending}, 2, 'two queued operations');
    is($client->pool_stats->{by_origin}[0]{host}, 'pending.test',
        'per-origin stats include host without a transport reference');
    $client->pool_stats->{by_origin}[0]{pending} = -123;
    is($client->pool_stats->{by_origin}[0]{pending}, 2,
        'stats are copied, not mutable scheduler internals');

    $client->network_changed;
    is($pending[0]{canceled}, 1, 'network switch cancels in-flight factory');
    is($one->state, 'queued', 'initiator reverts to queue without failure');
    is($two->state, 'queued', 'other queued operation preserved');
    is($client->pending_count, 2, 'queue still holds both original requests');
    $client->network_changed;
    is($pending[0]{canceled}, 1, 'repeat network switch does not cancel twice');
    $flush->();
    is(scalar(@pending), 2, 'a new factory starts after deferral');
    ok(!defined $pending[0]{ready}->(transport => NetworkTest::Host->new),
        'stale ready callback never attaches old network transport');
    is($one->state, 'connecting', 'current request waits for fresh network');
    $pending[1]{ready}->(transport => NetworkTest::Host->new,
        alpn => 'http/1.1');
    is($one->state, 'active', 'same operation dispatched on fresh connection');
    $one->transaction->finish;
    $flush->();
    is($two->state, 'active', 'queued successor dispatched once');
    $two->transaction->finish;
    $flush->();
    is_deeply(\@errors, [], 'no error or automatic request replay reported');
    is_deeply(\@finished, ['one', 'two'], 'each transaction finishes exactly once');
}

{
    my (@ready, @local_release);
    my $client = Unblock::HTTP::Client->new(
        http2 => {}, max_connections_per_origin => 1,
        defer => $defer,
        release_connection => sub { push @local_release, [@_] },
        connect_stream => sub {
            push @ready, $_[2];
        },
    );
    my $first = $client->request(url => 'https://active.test/one');
    $ready[0]->(transport => NetworkTest::Host->new, alpn => 'h2',
        verified_origin => 1);
    my $original = $first->transaction->{engine};
    $client->network_changed;
    is($client->pool_stats->{active}, 1, 'active H2 remains alive across network change');
    is($client->pool_stats->{retiring}, 1, 'active old H2 marked for retirement');
    is($client->pool_stats->{idle}, 0, 'old H2 is not reusable');
    is(scalar(@local_release), 0, 'active transaction not closed prematurely');
    my $next = $client->request(url => 'https://active.test/next');
    is($next->state, 'queued', 'new request waits for safe capacity');
    is(scalar(@ready), 1, 'origin cap respected while old engine is active');
    $first->transaction->finish(NetworkTest::Response->new('h3=":7443"'));
    $flush->();
    is(scalar(@local_release), 1, 'old H2 released after last transaction');
    is($local_release[0][3], 'network_changed',
        'retirement preserves network-change reason');
    is(scalar(@ready), 2, 'new transport requested after safe retirement');
    is($next->state, 'connecting', 'next operation waits for fresh transport');
    ok(!$client->{alt_svc}->lookup('https|active.test|443'),
        'old network active H2 cannot repopulate Alt-Svc');
    $ready[1]->(transport => NetworkTest::Host->new, alpn => 'h2',
        verified_origin => 1);
    is($next->state, 'active', 'new operation uses fresh H2');
    isnt(refaddr($next->transaction->{engine}), refaddr($original),
        'old engine identity never reused');
    $next->transaction->finish;
    $flush->();
}

{
    my @local_release;
    my $client = Unblock::HTTP::Client->new(
        http1 => {}, defer => $defer, idle_timeout => 3,
        schedule_timer => $timer,
        release_connection => sub { push @local_release, [@_] },
        connect_stream => sub {
            $_[2]->(transport => NetworkTest::Host->new);
        },
    );
    my $op = $client->request(url => 'http://idle.test/');
    $op->transaction->finish;
    $flush->();
    my $old_timer = $timers[-1];
    is($client->pool_stats->{idle}, 1, 'completed H1 is idle');
    is($client->pool_stats->{origins}, 1, 'idle origin present before change');
    $client->network_changed;
    is($old_timer->{cancelled}, 1, 'network switch cancels idle timer once');
    is(scalar(@local_release), 1, 'idle connection released immediately');
    is($local_release[0][3], 'network_changed', 'idle release reason');
    is($client->pool_stats->{origins}, 0, 'empty idle origin removed');
    $old_timer->{fire}->();
    is(scalar(@local_release), 1, 'stale idle timer cannot double release');
}

# Learned HTTP/3 alternatives from old networks are invalidated globally,
# including cache entries for origins whose socket pool was already removed.
{
    my (@quic, @tcp);
    my $client = Unblock::HTTP::Client->new(
        http1 => {}, http3 => {}, defer => $defer,
        connect_stream => sub { push @tcp, $_[2] },
        connect_quic => sub {
            my ($info, $ready) = @_;
            push @quic, { info => $info, ready => $ready, cancels => 0 };
            my $attempt = $quic[-1];
            return sub { $attempt->{cancels}++ };
        },
    );
    my $origin = 'https|alt.test|443';
    $client->{alt_svc}->observe($origin,
        NetworkTest::Response->new('h3=":7443"; ma=200'));
    my $op = $client->request(url => 'https://alt.test/preferred');
    is(scalar @quic, 1, 'fresh Alt-Svc chooses H3');
    is($op->state, 'connecting', 'H3 advertisement is connecting');
    $client->network_changed;
    ok(!$client->{alt_svc}->lookup($origin), 'all old Alt-Svc entries cleared');
    is($quic[0]{cancels}, 1, 'advertised H3 connection attempt abandoned');
    is($op->{version}, 'tcp', 'unsent advertised H3 request returns to TCP policy');
    $flush->();
    is(scalar @tcp, 1, 'fresh TCP connection initiated');
    ok(!defined $quic[0]{ready}->(connection => NetworkTest::Host->new),
        'old H3 readiness cannot attach');
    $tcp[0]->(transport => NetworkTest::Host->new);
    is($op->state, 'active', 'same operation dispatched over TCP');
    $op->transaction->finish;
    $flush->();
    my $later = $client->request(url => 'https://alt.test/later');
    is(scalar @quic, 1, 'following request cannot use old Alt-Svc entry');
    $later->transaction->finish;
    $flush->();
}

# H3 stream-credit wait must not keep a pre-network-change QUIC session.
{
    local $NetworkTest::Engine::REFUSE_H3 = 1;
    my (@quic, @local_release);
    my $client = Unblock::HTTP::Client->new(
        http3 => {}, defer => $defer, max_connections_per_origin => 1,
        release_connection => sub { push @local_release, [@_] },
        connect_quic => sub { push @quic, $_[1] },
    );
    my $op = $client->request(url => 'https://credit.test/',
        http_version => '3');
    $quic[0]->(connection => NetworkTest::Host->new);
    is($op->state, 'queued', 'unadmitted H3 stays queued');
    is($client->pool_stats->{credit_blocked}, 1, 'H3 credit block visible');
    $client->network_changed;
    is(scalar @local_release, 1, 'old idle QUIC released despite blocked demand');
    is($client->pool_stats->{connections}, 0, 'stale QUIC removed from pool');
    is($client->pending_count, 1, 'unadmitted operation preserved');
    $flush->();
    is(scalar @quic, 2, 'new network gets a new QUIC factory');
    $NetworkTest::Engine::REFUSE_H3 = 0;
    $quic[1]->(connection => NetworkTest::Host->new);
    is($op->state, 'active', 'original unsent H3 request admitted on fresh QUIC');
    $op->transaction->finish;
    $flush->();
}

done_testing;

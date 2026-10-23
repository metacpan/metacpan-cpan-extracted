use strict;
use warnings;
use Test::More;
use Scalar::Util qw(refaddr);

BEGIN {
    package Uniform::HTTP::Request;
    sub new { my ($class, %f) = @_; bless \%f, $class }
    $INC{'Uniform/HTTP/Request.pm'} = __FILE__;

    package AdmissionTest::Transaction;
    sub new { my ($class, $engine, $cb) = @_; bless { engine => $engine, cb => $cb, state => 'active' }, $class }
    sub is_error { $_[0]{state} eq 'error' }
    sub is_cancelled { $_[0]{state} eq 'cancelled' }
    sub error { $_[0]{error} }
    sub finish {
        my ($self) = @_;
        return unless $self->{state} eq 'active';
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

    package AdmissionTest::Engine;
    our ($INITIAL_LIMIT, $INITIAL_DRAIN, $NO_H3_STREAM);
    sub new {
        my ($class, %option) = @_;
        bless {
            option => \%option, active => 0, closed => 0, failed => 0,
            peer_limit => defined($INITIAL_LIMIT) ? $INITIAL_LIMIT : 100,
            draining => $INITIAL_DRAIN ? 1 : 0,
            no_stream => $NO_H3_STREAM ? 1 : 0,
            remote_shutdown_id => undef,
        }, $class;
    }
    sub is_closed { $_[0]{closed} }
    sub failed { $_[0]{failed} }
    sub close { $_[0]{closed} = 1 }
    sub draining { $_[0]{draining} }
    sub remote_shutdown_id { $_[0]{remote_shutdown_id} }
    sub shutdown_started { 0 }
    sub start { $_[0]{started}++; $_[0] }
    sub can_open_transaction {
        my ($self) = @_;
        return !$self->{closed} && !$self->{draining}
            && $self->{active} < $self->{peer_limit};
    }
    sub peer_limit {
        my ($self, $value) = @_;
        $self->{peer_limit} = $value;
        my $callback = $self->{option}{on_settings};
        $callback->($self, { max_concurrent_streams => $value },
            { max_concurrent_streams => $value }) if $callback;
    }
    sub request {
        my ($self, $request, %cb) = @_;
        return if $self->{no_stream};
        die 'peer refuses streams' if $self->isa('Unblock::HTTP2::Client')
            && !$self->can_open_transaction;
        $self->{active}++;
        return AdmissionTest::Transaction->new($self, \%cb);
    }
    for my $num (1..3) {
        my $package = 'Unblock::HTTP' . $num . '::Client';
        (my $path = $package) =~ s{::}{/}g;
        $INC{$path . '.pm'} = __FILE__;
        no strict 'refs';
        @{$package . '::ISA'} = ('AdmissionTest::Engine');
    }

    package AdmissionTest::Host;
    sub new { bless {}, shift }
    sub unblock_send { 1 }
    sub unblock_finish {}
    sub unblock_abort {}
    package AdmissionTest::Quic;
    sub new { bless { ready => 1, closed => 0 }, shift }
    sub ready { $_[0]{ready} }
    sub closed { $_[0]{closed} }
}

use Unblock::HTTP::Client;
my @deferred;
my $defer = sub { push @deferred, $_[0] };
my $flush = sub {
    my $budget = 100;
    while (@deferred && $budget--) { shift(@deferred)->() }
    die 'unbounded deferred churn' unless $budget > 0;
};

# SETTINGS concurrency zero is temporary: do not churn live connections.
{
    local $AdmissionTest::Engine::INITIAL_LIMIT = 0;
    my ($calls, @engines) = (0);
    my $client = Unblock::HTTP::Client->new(
        http2 => {}, max_connections_per_origin => 1, defer => $defer,
        connect_stream => sub {
            my ($origin, $alpn, $ready) = @_;
            $calls++;
            push @engines, $ready->(transport => AdmissionTest::Host->new, alpn => 'h2');
        },
    );
    my $one = $client->request(url => 'https://zero.test/one');
    my $two = $client->request(url => 'https://zero.test/two');
    is($calls, 1, 'H2 peer limit zero does not cause connection churn');
    is($one->state, 'queued', 'connected request waits for peer stream capacity');
    is($two->state, 'queued', 'second request queued');
    is($client->pending_count, 2, 'unadmitted work occupies bounded queue');
    ok(!$engines[0]{closed}, 'idle zero-credit H2 remains open');
    $engines[0]->peer_limit(1);
    $flush->();
    is($one->state, 'active', 'SETTINGS increase admits first request');
    is($two->state, 'queued', 'peer limit of one is respected');
    $one->transaction->finish;
    $flush->();
    is($two->state, 'active', 'second request starts after stream release');
    is($calls, 1, 'same H2 engine reused');
    $two->transaction->finish;
    $flush->();
}

# A drained active connection retains its slot until the last stream ends.
{
    local $AdmissionTest::Engine::INITIAL_LIMIT = 1;
    my @created;
    my $client = Unblock::HTTP::Client->new(
        http2 => {}, max_connections_per_origin => 1, defer => $defer,
        connect_stream => sub {
            push @created, $_[2]->(
                transport => AdmissionTest::Host->new, alpn => 'h2',
            );
        },
    );
    my $one = $client->request(url => 'https://drain.test/one');
    my $old = $one->transaction->{engine};
    $old->{draining} = 1;
    my $two = $client->request(url => 'https://drain.test/two');
    is($two->state, 'queued', 'draining active engine not replaced prematurely');
    is(scalar(@created), 1, 'active connection counts toward cap');
    $one->transaction->finish;
    $flush->();
    is(scalar(@created), 2, 'drained idle engine replaced');
    is($two->state, 'active', 'pending work dispatched to replacement H2');
    isnt(refaddr($two->transaction->{engine}), refaddr($old), 'retired engine not reused');
    $two->transaction->finish;
    $flush->();
}

# Synchronous factory yielding an immediately draining engine must not spin.
{
    local $AdmissionTest::Engine::INITIAL_DRAIN = 1;
    my $calls = 0;
    my $client = Unblock::HTTP::Client->new(
        http2 => {}, max_connections_per_origin => 2, defer => $defer,
        connect_stream => sub {
            $calls++;
            $_[2]->(transport => AdmissionTest::Host->new, alpn => 'h2');
        },
    );
    my $op = $client->request(url => 'https://reentrant.test/');
    ok($calls > 0 && $calls <= 2, 'synchronous factory attempts bounded per pump');
    ok($client->pending_count <= 1, 'no duplicate queue entries created');
    $op->cancel;
    $flush->();
}

# The HTTP/3 engine returns undef when QUIC has no bidi stream credit.
# The Client must queue the UNTRANSMITTED operation and wake only after
# a new bidi availability notification, with no fake transaction or retry.
{
    local $AdmissionTest::Engine::NO_H3_STREAM = 1;
    my $connections = 0;
    my $client = Unblock::HTTP::Client->new(
        http3 => {}, defer => $defer, max_connections_per_origin => 1,
        connect_quic => sub {
            $connections++;
            $_[1]->(connection => AdmissionTest::Quic->new);
        },
    );
    my (@errors, @finishes);
    my $op = $client->request(url => 'https://h3.test/', http_version => '3',
        on_error => sub { push @errors, [@_] },
        on_finish => sub { push @finishes, $_[0] },
    );
    is($op->state, 'queued', 'H3 no-stream result preserves unsent operation');
    ok(!defined($op->transaction), 'no phantom transaction created');
    is($client->pending_count, 1, 'unsent H3 request is counted in queue');
    is(scalar(@errors), 0, 'lack of temporary bidi credit is not an HTTP error');
    is(scalar(@finishes), 0, 'temporary block does not finish operation');
    my $conn = $op->{origin}{connections}[0];
    is($conn->{active}, 0, 'H3 unavailable stream does not occupy active slot');
    ok($conn->{credit_blocked}, 'connection waits for one-shot bidi notification');
    is($connections, 1, 'bounded pool does not keep opening QUIC connections');

    my $second = $client->request(
        url => 'https://h3.test/second', http_version => '3',
    );
    is($second->state, 'queued', 'later request waits behind first unsent request');
    is($client->pending_count, 2, 'both unsent requests remain bounded');

    my $engine = $conn->{engine};
    $engine->{no_stream} = 0;
    $engine->{option}{on_request_available}->($engine);
    is($op->state, 'queued', 'availability callback never dispatches inline');
    $flush->();
    is($op->state, 'active', 'deferred notification admits original operation');
    is($second->state, 'active', 'other queued H3 request also admitted within cap');
    is($connections, 1, 'H3 reuses original QUIC connection');
    is($client->pending_count, 0, 'queued H3 operations released at dispatch');
    $op->transaction->finish;
    $second->transaction->finish;
    $flush->();
    is(scalar(@errors), 0, 'successful recovery did not invent error');
    is(scalar(@finishes), 1, 'original transaction finishes once');
}

# Cancelled unadmitted H3 work may not be resurrected by later credit.
{
    local $AdmissionTest::Engine::NO_H3_STREAM = 1;
    my $client = Unblock::HTTP::Client->new(
        http3 => {}, defer => $defer, max_connections_per_origin => 1,
        connect_quic => sub { $_[1]->(connection => AdmissionTest::Quic->new) },
    );
    my (@errors, @finishes);
    my $op = $client->request(url => 'https://cancelcredit.test/', http_version => '3',
        on_error => sub { push @errors, 1 },
        on_finish => sub { push @finishes, 1 },
    );
    my $engine = $op->{origin}{connections}[0]{engine};
    ok($op->cancel, 'blocked H3 request can be cancelled');
    is($op->state, 'cancelled', 'cancel before QUIC credit stays cancellation');
    is($client->pending_count, 0, 'cancel removes blocked queue entry');
    $engine->{no_stream} = 0;
    $engine->{option}{on_request_available}->($engine);
    $flush->();
    ok(!defined $op->transaction, 'availability cannot dispatch cancelled operation');
    is(scalar @errors, 0, 'intentional cancellation has no on_error');
    is(scalar @finishes, 1, 'cancelled H3 operation finishes exactly once');
}

# A deadline may expire while waiting for QUIC credit; later readiness
# must not resurrect the expired operation or manufacture a transaction.
{
    local $AdmissionTest::Engine::NO_H3_STREAM = 1;
    my $fire;
    my $timer_cancels = 0;
    my $client = Unblock::HTTP::Client->new(
        http3 => {}, defer => $defer, max_connections_per_origin => 1,
        connect_quic => sub { $_[1]->(connection => AdmissionTest::Quic->new) },
        schedule_timer => sub {
            $fire = $_[1];
            return sub { $timer_cancels++ };
        },
    );
    my (@errors, @finishes);
    my $op = $client->request(url => 'https://timeoutcredit.test/',
        http_version => '3', timeout => 0.5,
        on_error => sub { push @errors, [@_] },
        on_finish => sub { push @finishes, $_[0] },
    );
    is($op->state, 'queued', 'H3 credit-blocked operation waits with timer');
    my $engine = $op->{origin}{connections}[0]{engine};
    $fire->();
    is($op->state, 'error', 'deadline expires credit-blocked request');
    like($op->error, qr/timed out/, 'timeout reason retained');
    is($client->pending_count, 0, 'deadline removes H3 blocked queue entry');
    is($timer_cancels, 1, 'terminal timer cancellation is exactly once');
    is(scalar(@errors), 1, 'timeout produces one on_error');
    is(refaddr($errors[0][0]), refaddr($op), 'pre-dispatch timeout uses operation identity');
    is(scalar(@finishes), 1, 'timeout produces one on_finish');
    $engine->{no_stream} = 0;
    $engine->{option}{on_request_available}->($engine);
    $flush->();
    ok(!defined($op->transaction), 'late bidi credit does not dispatch timed-out request');
    is(scalar(@finishes), 1, 'late notification does not repeat terminal callback');
}

# A GOAWAY-marked idle H3 is not reused.
{
    my @engines;
    my $client = Unblock::HTTP::Client->new(
        http3 => {}, defer => $defer, max_connections_per_origin => 1,
        connect_quic => sub { push @engines, $_[1]->(connection => AdmissionTest::Quic->new) },
    );
    my $one = $client->request(url => 'https://goaway.test/', http_version => '3');
    my $old = $one->transaction->{engine};
    $one->transaction->finish;
    $old->{remote_shutdown_id} = 0;
    my $two = $client->request(url => 'https://goaway.test/next', http_version => '3');
    is(scalar(@engines), 2, 'GOAWAY id zero retires idle H3');
    is($two->state, 'active', 'replacement H3 serves next request');
    isnt(refaddr($two->transaction->{engine}), refaddr($old), 'GOAWAY engine not reused');
    $two->transaction->finish;
    $flush->();
}

# Six independent origins progress without a global head-of-line stall.
{
    my @ready;
    my $client = Unblock::HTTP::Client->new(
        http1 => {}, defer => $defer,
        max_connections_per_origin => 1, max_pending_requests => 12,
        connect_stream => sub { push @ready, $_[2] },
    );
    my @ops;
    for my $i (1..6) {
        push @ops, $client->request(url => 'http://origin' . $i . '.test/one');
        push @ops, $client->request(url => 'http://origin' . $i . '.test/two');
    }
    is(scalar(@ready), 6, 'six independent connection factories started');
    is($client->pending_count, 12, 'global pending limit enforced');
    ok(!eval { $client->request(url => 'http://overflow.test/'); 1 }, 'queue overflow rejected');
    for my $cb (@ready) { $cb->(transport => AdmissionTest::Host->new) }
    is($client->pending_count, 6, 'one H1 request per origin dispatched');
    for (my $i=0; $i < @ops; $i+=2) {
        is($ops[$i]->state, 'active', 'first request active');
        $ops[$i]->transaction->finish;
    }
    $flush->();
    for (my $i=1; $i < @ops; $i+=2) {
        is($ops[$i]->state, 'active', 'second request active');
        $ops[$i]->transaction->finish;
    }
    $flush->();
    is($client->pending_count, 0, 'all independent queues drained');
}

done_testing;

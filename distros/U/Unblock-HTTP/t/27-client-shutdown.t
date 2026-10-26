use strict;
use warnings;
use Test::More;

BEGIN {
    package Uniform::HTTP::Request;
    sub new { my ($class, %f) = @_; bless \%f, $class }
    $INC{'Uniform/HTTP/Request.pm'} = __FILE__;

    package ShutdownTest::Tx;
    sub new { my ($class, $engine, $cb) = @_; bless {
        engine => $engine, cb => $cb, state => 'active',
    }, $class }
    sub is_cancelled { $_[0]{state} eq 'cancelled' }
    sub is_error { $_[0]{state} eq 'error' }
    sub error { undef }
    sub finish {
        my ($self) = @_;
        die 'double finish' unless $self->{state} eq 'active';
        $self->{state} = 'complete';
        $self->{cb}{on_finish}->($self);
    }
    sub cancel {
        my ($self) = @_;
        return unless $self->{state} eq 'active';
        $self->{state} = 'cancelled';
        $self->{cb}{on_finish}->($self);
    }

    package ShutdownTest::Engine;
    sub new { bless { closed => 0 }, shift }
    sub is_closed { $_[0]{closed} }
    sub failed { $_[0]{closed} }
    sub can_open_transaction { 1 }
    sub start { $_[0] }
    sub shutdown_started { 0 }
    sub remote_shutdown_id { undef }
    sub close { $_[0]{closed}++ }
    sub request {
        my ($self, $req, %cb) = @_;
        ShutdownTest::Tx->new($self, \%cb);
    }
    for my $n (1 .. 3) {
        my $pkg = 'Unblock::HTTP' . $n . '::Client';
        (my $file = $pkg) =~ s{::}{/}g;
        $INC{"$file.pm"} = __FILE__;
        no strict 'refs';
        @{$pkg . '::ISA'} = ('ShutdownTest::Engine');
    }

    package ShutdownTest::Host;
    sub new { bless { closed => 0 }, shift }
    sub unblock_send { 1 }
    sub unblock_finish { 1 }
    sub unblock_abort { 1 }
    sub ready { 1 }
    sub closed { $_[0]{closed} }
    sub close { $_[0]{closed}++ }
}
use Unblock::HTTP::Client;
my @deferred;
my $defer = sub { push @deferred, $_[0] };
my $flush = sub {
    my $limit = 30;
    while (@deferred && $limit--) { shift(@deferred)->() }
    die 'unbounded scheduling' unless $limit > 0;
};

{
    my (@ready, @canceled, @events, @released);
    my $client = Unblock::HTTP::Client->new(
        http1 => {}, defer => $defer,
        connect_stream => sub {
            push @ready, $_[2];
            my $i = $#ready;
            return sub { $canceled[$i]++ };
        },
        release_connection => sub { push @released, [@_] },
    );
    my $a = $client->request(
        url => 'http://pending-shutdown.test/a',
        on_finish => sub {
            push @events, 'a';
            ok(!eval { $client->request(url => 'http://pending-shutdown.test/new'); 1 },
                'reentrant admission prevented');
        },
        on_error => sub { push @events, 'unexpected_error' },
    );
    my $b = $client->request(
        url => 'http://pending-shutdown.test/b',
        on_finish => sub { push @events, 'b' },
    );
    is($client->pending_count, 2, 'two queued operations');
    is($client->is_shutdown, 0, 'initially open');
    is($client->shutdown, $client, 'shutdown returns original client');
    is($client->is_shutdown, 1, 'shutdown observable');
    is($a->state, 'cancelled', 'connecting operation cancelled');
    is($b->state, 'cancelled', 'queued operation cancelled');
    is_deeply(\@events, ['a','b'], 'callbacks exactly once without on_error');
    is($canceled[0], 1, 'one factory cancellation');
    is($client->pending_count, 0, 'pending queue empty');
    is(scalar keys %{$client->{pools}}, 0, 'origin reclaimed');
    ok(!defined($ready[0]->(transport => ShutdownTest::Host->new)),
        'late factory callback ignored');
    is(scalar @released, 0, 'no phantom transport release');
    $client->shutdown;
    is($canceled[0], 1, 'repeat shutdown does not cancel again');
    $client->network_changed;
    is(scalar @deferred, 0, 'closed Client cannot schedule new work');
}

{
    my @released;
    my $client = Unblock::HTTP::Client->new(
        http2 => {}, defer => $defer,
        max_connections_per_origin => 1,
        connect_stream => sub {
            $_[2]->(transport => ShutdownTest::Host->new, alpn => 'h2');
        },
        release_connection => sub { push @released, [@_] },
    );
    my $a = $client->request(url => 'https://h2-shutdown.test/a');
    my $b = $client->request(url => 'https://h2-shutdown.test/b');
    is($client->pool_stats->{active}, 2, 'H2 has two active transactions');
    $client->shutdown;
    is($a->state, 'active', 'first transaction survives shutdown');
    is($b->state, 'active', 'second transaction survives shutdown');
    is(scalar @released, 0, 'active H2 engine not released');
    $a->transaction->finish;
    is(scalar @released, 0, 'first finish cannot release other stream');
    $b->transaction->finish;
    is($b->state, 'complete', 'second transaction completes');
    is(scalar @released, 1, 'final finish releases engine once');
    is($released[0][3], 'shutdown', 'shutdown release reason');
    is($client->pool_stats->{origins}, 0, 'empty H2 pool removed');
}

{
    my (@timers, @released);
    my $client = Unblock::HTTP::Client->new(
        http1 => {}, defer => $defer, idle_timeout => 2,
        connect_stream => sub {
            $_[2]->(transport => ShutdownTest::Host->new);
        },
        schedule_timer => sub {
            my $record = { fire => $_[1], cancels => 0 };
            push @timers, $record;
            return sub { $record->{cancels}++ };
        },
        release_connection => sub { push @released, [@_] },
    );
    my $a = $client->request(url => 'http://idle-shutdown.test/');
    $a->transaction->finish;
    $flush->();
    is(scalar @timers, 1, 'idle timer armed');
    $client->shutdown;
    is($timers[0]{cancels}, 1, 'idle timer cancelled');
    is(scalar @released, 1, 'idle connection released');
    is($released[0][3], 'shutdown', 'idle release reason');
    $timers[0]{fire}->();
    is(scalar @released, 1, 'stale timer cannot release twice');
    is($client->pool_stats->{origins}, 0, 'idle pool removed');
}

{
    my @released;
    my $client = Unblock::HTTP::Client->new(
        http3 => {}, defer => $defer,
        connect_quic => sub {
            $_[1]->(connection => ShutdownTest::Host->new);
        },
        release_connection => sub { push @released, [@_] },
    );
    my $a = $client->request(
        url => 'https://h3-shutdown.test/', http_version => '3',
    );
    $client->shutdown;
    is($a->state, 'active', 'H3 transaction drains normally');
    is(scalar @released, 0, 'active QUIC retained');
    $a->transaction->finish;
    is($a->state, 'complete', 'H3 finishes successfully');
    is($released[0][3], 'shutdown', 'H3 release reason');
}

# A peer can temporarily exhaust H3 bidi stream credit. Its existing QUIC
# connection may regain credit after another factory has started for the
# same queued operation. The unused factory must be cancelled exactly once.
{
    my (@ready, @cancel, @released);
    my $client = Unblock::HTTP::Client->new(
        http3 => {}, defer => $defer, max_connections_per_origin => 2,
        connect_quic => sub {
            push @ready, $_[1];
            my $index = $#ready;
            return sub { ++$cancel[$index] };
        },
        release_connection => sub { push @released, [@_] },
    );
    my $first = $client->request(
        url => 'https://credit-recovered.test/first', http_version => '3',
    );
    is(scalar @ready, 1, 'first QUIC factory started');
    $ready[0]->(connection => ShutdownTest::Host->new);
    is($first->state, 'active', 'first request admitted');
    my $pool = $first->{origin};
    my $conn = $pool->{connections}[0];
    $conn->{credit_blocked} = 1;
    my $second = $client->request(
        url => 'https://credit-recovered.test/second', http_version => '3',
    );
    is(scalar @ready, 2, 'speculative connection started while credit blocked');
    is($pool->{connecting}, 1, 'speculative factory is live');
    $conn->{credit_blocked} = 0;
    $client->_pump($pool);
    is($second->state, 'active', 'same queued request admitted after credit recovery');
    is($cancel[1], 1, 'unused speculative connector cancelled exactly once');
    is($pool->{connecting}, 0, 'no orphaned connecting attempt');
    ok(!$pool->{attempt}, 'connection attempt bookkeeping cleared');
    ok(!defined $ready[1]->(connection => ShutdownTest::Host->new),
        'late factory readiness cannot add a phantom connection');
    is(scalar @{ $pool->{connections} }, 1, 'recovered QUIC connection reused');
    $first->transaction->finish;
    $second->transaction->finish;
    $client->shutdown;
    is(scalar @released, 1, 'one pooled connection released at shutdown');
    is($cancel[1], 1, 'speculative factory not cancelled twice');
    $flush->();
}

# Shutdown must also clean up an orphaned in-progress factory if its
# initiating operation is no longer in the pending list.
{
    my $cancels = 0;
    my $client = Unblock::HTTP::Client->new(
        http3 => {}, defer => $defer,
        connect_quic => sub {},
    );
    my $op = $client->request(
        url => 'https://orphan-connect.test/', http_version => '3',
    );
    my $pool = $op->{origin};
    $pool->{attempt}{cancel} = sub { ++$cancels };
    $pool->{pending} = [];
    $pool->{connecting} = 1;
    $client->shutdown;
    is($cancels, 1, 'shutdown cancels a connector without a pending operation');
    is($client->pool_stats->{connecting}, 0, 'shutdown clears orphaned factory state');
    $flush->();
}
done_testing;

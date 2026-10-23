use strict;
use warnings;
use Test::More;
use Scalar::Util qw(refaddr);

BEGIN {
    package Uniform::HTTP::Request;
    sub new { my ($class, %args) = @_; bless \%args, $class }
    $INC{'Uniform/HTTP/Request.pm'} = __FILE__;

    package IdleTest::Transaction;
    sub new {
        my ($class, $engine, $callbacks) = @_;
        bless { engine => $engine, cb => $callbacks, state => 'active' }, $class;
    }
    sub is_cancelled { $_[0]{state} eq 'cancelled' }
    sub is_error { $_[0]{state} eq 'error' }
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

    package IdleTest::Engine;
    our $PEER_LIMIT = 64;
    sub new {
        my ($class, %options) = @_;
        bless { options => \%options, active => 0, closed => 0 }, $class;
    }
    sub request {
        my ($self, $message, %cb) = @_;
        $self->{active}++;
        return IdleTest::Transaction->new($self, \%cb);
    }
    sub is_closed { $_[0]{closed} }
    sub failed { $_[0]{closed} }
    sub draining { 0 }
    sub can_open_transaction {
        $_[0]{active} < $PEER_LIMIT && !$_[0]{closed}
    }
    sub start { $_[0]{started}++; $_[0] }
    sub close { $_[0]{closed}++; }
    for my $n (1 .. 3) {
        my $class = 'Unblock::HTTP' . $n . '::Client';
        (my $file = $class) =~ s{::}{/}g;
        $INC{$file . '.pm'} = __FILE__;
        no strict 'refs';
        @{$class . '::ISA'} = ('IdleTest::Engine');
    }

    package IdleTest::Host;
    sub new { bless { closed => 0, ready => 1 }, shift }
    sub unblock_send { 1 }
    sub unblock_finish {}
    sub unblock_abort {}
    sub ready { $_[0]{ready} }
    sub closed { $_[0]{closed} }
    sub close { $_[0]{closed}++; }
}

use Unblock::HTTP::Client;

my (@timers, @deferred, @releases, @connected);
my $clock = sub {
    my ($seconds, $fire) = @_;
    my $timer = { seconds => $seconds, fire => $fire, cancelled => 0 };
    push @timers, $timer;
    return sub { $timer->{cancelled}++ };
};
my $defer = sub { push @deferred, $_[0] };
my $flush = sub {
    my $budget = 100;
    while (@deferred && $budget--) {
        shift(@deferred)->();
    }
    die 'deferred work did not settle' unless $budget > 0;
};
my $close = sub {
    my ($host, $engine, $protocol, $reason) = @_;
    push @releases, [$host, $engine, $protocol, $reason];
    $engine->close;
    $host->close;
};

{
    my $client = Unblock::HTTP::Client->new(
        http1 => {}, max_connections_per_origin => 1,
        idle_timeout => 0.5,
        schedule_timer => $clock, release_connection => $close,
        connect_stream => sub {
            my $host = IdleTest::Host->new;
            push @connected, $host;
            $_[2]->(transport => $host, alpn => 'http/1.1');
        }, defer => $defer,
    );
    my $one = $client->request(url => 'http://idle.test/one');
    is(scalar(@timers), 0, 'no idle timer during active H1 request');
    my $first_engine = $one->transaction->{engine};
    $one->transaction->finish;
    $flush->();
    is(scalar(@timers), 1, 'idle timer armed after H1 completion');
    is($timers[0]{seconds}, 0.5, 'idle timeout accepts fractional seconds');
    my $two = $client->request(url => 'http://idle.test/two');
    is(refaddr($two->transaction->{engine}), refaddr($first_engine),
        'idle H1 engine reused before expiry');
    is($timers[0]{cancelled}, 1, 'reuse cancels idle timer once');
    $timers[0]{fire}->();
    is(scalar(@releases), 0, 'stale cancelled timer cannot close in-use engine');
    $two->transaction->finish;
    $flush->();
    is(scalar(@timers), 2, 'idle period restarted after next completion');
    $timers[1]{fire}->();
    is(scalar(@releases), 1, 'idle expiry releases connection once');
    is($releases[0][2], 'http/1.1', 'release gets protocol');
    is($releases[0][3], 'idle_timeout', 'release reason identifies expiry');
    ok($first_engine->{closed}, 'engine was closed by framework release hook');
    is(scalar(keys %{$client->{pools}}), 0, 'last idle connection removes origin pool');
    $timers[1]{fire}->();
    is(scalar(@releases), 1, 'fired idle timer cannot release again');

    my $three = $client->request(url => 'http://idle.test/three');
    isnt(refaddr($three->transaction->{engine}), refaddr($first_engine),
        'request after expiry opens a new H1 engine');
    is(scalar(@connected), 2, 'fresh socket factory used after expiry');
    $three->transaction->finish;
    $flush->();
    $timers[2]{fire}->();
    is(scalar(@releases), 2, 'second idle lifecycle cleans up separately');
}

# Multiplexed streams keep the H2 connection active until the final finish.
{
    local $IdleTest::Engine::PEER_LIMIT = 2;
    my @local_timers;
    my $client = Unblock::HTTP::Client->new(
        http2 => {}, idle_timeout => 3,
        schedule_timer => sub {
            my ($seconds, $cb) = @_;
            my $t = { seconds => $seconds, fire => $cb, cancelled => 0 };
            push @local_timers, $t;
            return sub { $t->{cancelled}++ };
        },
        connect_stream => sub {
            $_[2]->(transport => IdleTest::Host->new, alpn => 'h2');
        }, defer => $defer, max_connections_per_origin => 1,
        release_connection => $close,
    );
    my $a = $client->request(url => 'https://multi.test/a');
    my $b = $client->request(url => 'https://multi.test/b');
    is(refaddr($a->transaction->{engine}), refaddr($b->transaction->{engine}),
        'H2 multiplexes on one engine');
    $a->transaction->finish;
    $flush->();
    is(scalar(@local_timers), 0, 'first of two H2 streams cannot start idle clock');
    $b->transaction->finish;
    $flush->();
    is(scalar(@local_timers), 1, 'last completed H2 stream starts one timer');
    $local_timers[0]{fire}->();
    is($releases[-1][2], 'h2', 'idle H2 session released');
}

# Queued demand waiting for peer stream capacity is NOT idle.
{
    local $IdleTest::Engine::PEER_LIMIT = 0;
    my @local_timers;
    my $client = Unblock::HTTP::Client->new(
        http2 => {}, idle_timeout => 4,
        schedule_timer => sub {
            my ($seconds, $fire) = @_;
            push @local_timers, $fire;
            return sub {};
        },
        connect_stream => sub {
            $_[2]->(transport => IdleTest::Host->new, alpn => 'h2');
        }, defer => $defer, max_connections_per_origin => 1,
    );
    my $queued = $client->request(url => 'https://zeroidle.test/x');
    is($queued->state, 'queued', 'peer-zero-credit operation waits in queue');
    $flush->();
    is(scalar(@local_timers), 0, 'queue suppresses idle expiry despite zero active');
    $queued->cancel;
    $flush->();
    is(scalar(@local_timers), 1, 'idle timer starts when last queue item cancelled');
    $local_timers[0]->();
    is(scalar(keys %{$client->{pools}}), 0, 'idle zero-credit connection can retire once no demand');
}

# Incompatible idle engine at connection cap must be released, not leaked.
{
    my @local_releases;
    my $client = Unblock::HTTP::Client->new(
        http1 => {}, http2 => {},
        max_connections_per_origin => 1,
        connect_stream => sub {
            my ($origin, $alpn, $ready) = @_;
            $ready->(transport => IdleTest::Host->new,
                alpn => (grep { $_ eq 'h2' } @$alpn) ? 'h2' : 'http/1.1');
        },
        release_connection => sub { push @local_releases, [@_] },
        defer => $defer,
    );
    my $first = $client->request(
        url => 'https://strictidle.test/', http_version => '2',
    );
    $first->transaction->finish;
    $flush->();
    my $second = $client->request(
        url => 'https://strictidle.test/next', http_version => '1.1',
    );
    is($second->state, 'active', 'new strict version starts after idle eviction');
    is(scalar(@local_releases), 1, 'capacity eviction calls release hook');
    is($local_releases[0][3], 'evicted', 'release explains eviction');
    $second->transaction->finish;
    $flush->();
}

# HTTP/3 engine has no close() in the real implementation. Without a hook,
# the Client must close the underlying QUIC connection at idle expiry.
{
    my ($fire, $quic, $engine);
    my $client = Unblock::HTTP::Client->new(
        http3 => {}, idle_timeout => 1,
        schedule_timer => sub { $fire = $_[1]; return sub {} },
        connect_quic => sub {
            $quic = IdleTest::Host->new;
            $_[1]->(connection => $quic);
        },
        defer => $defer,
    );
    my $op = $client->request(url => 'https://quicidle.test/', http_version => '3');
    $engine = $op->transaction->{engine};
    $op->transaction->finish;
    $flush->();
    ok($fire, 'QUIC idle clock armed after H3 completion');
    $fire->();
    ok($engine->{closed}, 'fallback closes engine when implemented by mock');
    is(scalar(keys %{$client->{pools}}), 0, 'H3 origin removed after idle expiry');
}

# Constructor validation and no breaking requirement for clients not using TTL.
{
    my $base = sub {
        Unblock::HTTP::Client->new(
            http1 => {}, defer => $defer,
            connect_stream => sub {},
            @_,
        );
    };
    for my $bad (0, -1, 'NaN', '1e4', []) {
        ok(!eval { $base->(idle_timeout => $bad); 1 },
            'invalid idle timeout rejected');
        like($@, qr/idle_timeout/, 'idle timeout validation explains error');
    }
    ok(!eval { $base->(idle_timeout => 1); 1 },
        'idle timeout requires framework timer factory');
    like($@, qr/schedule_timer/, 'missing timer callback diagnosed');
    ok(eval { $base->(); 1 },
        'clients without idle timeout do not require timer factory');
}

done_testing;

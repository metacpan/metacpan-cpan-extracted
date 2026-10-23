use strict;
use warnings;
use Test::More;
use Scalar::Util qw(refaddr weaken isweak);

BEGIN {
    package Uniform::HTTP::Request;
    sub new { my ($class, %fields) = @_; bless \%fields, $class }
    $INC{'Uniform/HTTP/Request.pm'} = __FILE__;

    package LifetimeTest::Transaction;
    sub new {
        my ($class, $engine, $callbacks) = @_;
        my $self = bless {
            engine => $engine, callbacks => $callbacks, state => 'active',
        }, $class;
        Scalar::Util::weaken($self->{engine});
        return $self;
    }
    sub is_cancelled { $_[0]{state} eq 'cancelled' }
    sub is_error { $_[0]{state} eq 'error' }
    sub error { $_[0]{error} }
    sub finish {
        my ($self) = @_;
        return if $self->{state} ne 'active';
        $self->{state} = 'complete';
        delete $self->{engine}{live}{ Scalar::Util::refaddr($self) };
        $self->{callbacks}{on_finish}->($self);
    }
    sub cancel {
        my ($self) = @_;
        return if $self->{state} ne 'active';
        $self->{state} = 'cancelled';
        delete $self->{engine}{live}{ Scalar::Util::refaddr($self) };
        $self->{callbacks}{on_finish}->($self);
    }

    package LifetimeTest::Engine;
    our $NO_H3_CREDIT = 0;
    sub new {
        my ($class, %options) = @_;
        bless { options => \%options, live => {}, closed => 0 }, $class;
    }
    sub request {
        my ($self, $request, %callbacks) = @_;
        return if $NO_H3_CREDIT && $self->isa('Unblock::HTTP3::Client');
        my $tx = LifetimeTest::Transaction->new($self, \%callbacks);
        $self->{live}{ Scalar::Util::refaddr($tx) } = $tx;
        return $tx;
    }
    sub can_open_transaction { 1 }
    sub is_closed { $_[0]{closed} }
    sub failed { $_[0]{closed} }
    sub start { $_[0] }
    sub close { $_[0]{closed} = 1 }
    for my $number (1..3) {
        my $package = "Unblock::HTTP${number}::Client";
        (my $path = $package) =~ s{::}{/}g;
        $INC{"$path.pm"} = __FILE__;
        no strict 'refs';
        @{"${package}::ISA"} = ('LifetimeTest::Engine');
    }

    package LifetimeTest::Transport;
    sub new { bless {}, shift }
    sub unblock_send { 1 }
    sub unblock_finish {}
    sub unblock_abort {}

    package LifetimeTest::Quic;
    sub new { bless {}, shift }
    sub ready { 1 }
    sub closed { 0 }
}

use Unblock::HTTP::Client;

for my $protocol (qw(http1 http2 http3)) {
    my @deferred;
    my %factory = (
        $protocol => {},
        defer => sub { push @deferred, $_[0] },
    );
    if ($protocol eq 'http3') {
        $factory{connect_quic} = sub {
            $_[1]->(connection => LifetimeTest::Quic->new);
        };
    } else {
        $factory{connect_stream} = sub {
            $_[2]->(transport => LifetimeTest::Transport->new,
                alpn => $protocol eq 'http2' ? 'h2' : 'http/1.1');
        };
    }
    my $client = Unblock::HTTP::Client->new(%factory);
    my $url = "https://lifetime-$protocol.test/";
    my $finished = 0;
    my $weak_op;
    {
        my $op = $client->request(
            url => $url,
            on_finish => sub { $finished++ },
        );
        is($op->state, 'active', "$protocol: dispatched");
        $weak_op = $op;
        weaken($weak_op);
    }
    ok(defined $weak_op, "$protocol: client owns active operation without caller handle");
    my ($engine) = map { $_->{engine} }
        map { @{ $_->{connections} } } values %{ $client->{pools} };
    is(scalar(keys %{ $engine->{live} }), 1, "$protocol: engine has one live transaction");
    my ($tx) = values %{ $engine->{live} };
    my $weak_tx = $tx;
    weaken($weak_tx);
    $tx->finish;
    $tx->finish;
    is($finished, 1, "$protocol: on_finish is exactly once");
    ok(!defined($weak_op), "$protocol: completed unretained operation reclaimed");
    is(scalar(keys %{ $client->{active_operations} }), 0,
        "$protocol: active operation ownership released");
    undef $tx;
    ok(!defined($weak_tx), "$protocol: completed unretained transaction reclaimed");

    my $kept = $client->request(url => $url);
    my $kept_tx = $kept->transaction;
    my $kept_weak_tx = $kept_tx;
    weaken($kept_weak_tx);
    $kept_tx->finish;
    is($kept->state, 'complete', "$protocol: caller handle sees completed state");
    is(refaddr($kept->transaction), refaddr($kept_tx),
        "$protocol: caller handle keeps the real engine transaction");
    undef $kept_tx;
    ok(defined $kept_weak_tx, "$protocol: retained handle preserves transaction");
    undef $kept;
    ok(!defined($kept_weak_tx), "$protocol: releasing handle frees transaction");

    if ($protocol eq 'http3') {
        local $LifetimeTest::Engine::NO_H3_CREDIT = 1;
        my $queued = $client->request(url => $url);
        is($queued->state, 'queued', 'H3: unavailable stream credit queues operation');
        is(scalar(keys %{ $client->{active_operations} }), 0,
            'H3: no unadmitted operation left in active registry');
        $LifetimeTest::Engine::NO_H3_CREDIT = 0;
        $engine->{options}{on_request_available}->();
        shift(@deferred)->() while @deferred;
        is($queued->state, 'active', 'H3: credited operation dispatches');
        $queued->transaction->finish;
        is($queued->state, 'complete', 'H3: queued operation finishes normally');
    }

    # A reused connection must not accumulate completed callback operations.
    for (1..128) {
        my $op = $client->request(url => $url);
        $op->transaction->finish;
    }
    is(scalar(keys %{ $client->{active_operations} }), 0,
        "$protocol: completed pool does not retain an operation registry");
    is(scalar(keys %{ $engine->{live} }), 0,
        "$protocol: fake engine has no unfinished transactions");

    # Caller-held terminal handles intentionally retain their actual
    # Transaction, NOT the entire shared origin pool and other sockets.
    my ($pool) = values %{ $client->{pools} };
    my $weak_pool = $pool;
    weaken($weak_pool);
    my $kept_after_client = $client->request(url => $url);
    my $retained_transaction = $kept_after_client->transaction;
    $retained_transaction->finish;
    is($kept_after_client->state, 'complete',
        "$protocol: retained handle stays terminal");
    ok(isweak($kept_after_client->{origin}),
        "$protocol: private operation origin is not an owning reference");
    my $retained_tx_id = refaddr($retained_transaction);
    undef $retained_transaction;
    undef $pool;
    undef $engine;
    undef $client;
    ok(!defined($weak_pool),
        "$protocol: completed handle cannot pin unrelated pooled connections");
    is(refaddr($kept_after_client->transaction), $retained_tx_id,
        "$protocol: real engine transaction survives Client disposal");
    is($kept_after_client->cancel, 0,
        "$protocol: completed detached operation is still terminal");
}

done_testing;

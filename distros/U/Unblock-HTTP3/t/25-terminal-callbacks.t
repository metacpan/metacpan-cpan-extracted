use strict;
use warnings;
use Test::More;
use Unblock::HTTP3::Transaction;
use Unblock::HTTP3::Body::Reader;
use Uniform::HTTP::Request;

# These tests exercise transaction/Reader behavior without a QUIC transport.
# The real QUIC/TLS boundary is exercised in t/24-receive-lifecycle.t.
{
    package Unblock::HTTP3::Connection;
    our $TEST_DOUBLE;
    package ReceiveLifecycleConnection;
    our @ISA = ('Unblock::HTTP3::Connection');
    sub role { 'server' }
    sub _consume_received_body { $_[0]{consumed} += $_[3] }
    sub _maybe_complete_transaction { }
    sub _reject_message_stream { $_[0]{rejected}++ }
    sub _cancel_transaction { $_[1]->_mark_cancelled }
}
sub transaction {
    my ($connection) = @_;
    return Unblock::HTTP3::Transaction->_new(
        connection => $connection, stream_id => 0,
        request => Uniform::HTTP::Request->new(method=>'POST',target=>'/',authority=>'test'),
    );
}
for my $outcome (qw(complete error cancelled)) {
    subtest "terminal $outcome" => sub {
        my $connection = bless {}, 'ReceiveLifecycleConnection';
        my $tx = transaction($connection);
        my @events;
        $tx->on_finish(sub { push @events, $_[0]->state; $_[0]->cancel; die 'terminal observer' });
        $tx->_set_callback($outcome eq 'complete' ? 'on_complete' : 'on_error', sub {
            push @events, 'callback'; $_[0]->cancel; die 'earlier observer';
        }) unless $outcome eq 'cancelled';
        my $ok = eval {
            $outcome eq 'error' ? $tx->_mark_error('failed')
                : $outcome eq 'complete' ? $tx->_mark_complete : $tx->_mark_cancelled;
            1;
        };
        is($tx->state, $outcome, 'state committed before reentrant cancel');
        is_deeply(\@events, $outcome eq 'cancelled' ? [$outcome] : ['callback',$outcome], 'finish after earlier callback, exactly once');
        ok(!$ok, 'earlier callback exception preserved') unless $outcome eq 'cancelled';
        $tx->cancel;
        eval { $tx->on_finish(sub {}) };
        like($@, qr/terminal/, 'late registration rejected');
    };
}
subtest 'streaming selection reuses Reader and returns credit' => sub {
    my $connection = bless { consumed=>0 }, 'ReceiveLifecycleConnection';
    my $tx = transaction($connection);
    my @events;
    $tx->on_data(sub { is($_[0],$tx,'same transaction'); push @events, $_[1] });
    $tx->on_finish(sub { push @events, 'finish' });
    my $reader = $tx->_ensure_receive_reader('request');
    $reader->_push_owned('abc');
    is_deeply(\@events,['abc'],'payload delivered');
    is($connection->{consumed},3,'delivered bytes credited');
    is($tx->_buffered_body_bytes('request'),0,'no full-body buffer');
    $tx->{receive_started}=1;
    eval { $tx->on_data(sub {}) };
    like($@,qr/already started/,'cannot change mode after body starts');
    $tx->_mark_cancelled;
    is_deeply(\@events,['abc','finish'],'cancel notifies once');
};
subtest 'cancelling a queued Reader releases receive credit' => sub {
    my $connection = bless { consumed=>0 }, 'ReceiveLifecycleConnection';
    my $tx = transaction($connection);
    $tx->_configure_receive_body('request','stream',{});
    my $reader=$tx->_ensure_receive_reader('request');
    $reader->_push_owned('abc');
    is($reader->pending_bytes,3,'queued bytes retained');
    $tx->_mark_cancelled;
    is($reader->pending_bytes,0,'queue released');
    is($connection->{consumed},3,'discarded bytes credited');
};
subtest 'data callback exception fails transaction and releases body' => sub {
    my $connection = bless { consumed=>0 }, 'ReceiveLifecycleConnection';
    my $tx=transaction($connection);
    my @events;
    $tx->on_data(sub { die 'data failed' });
    $tx->_set_callback('on_error',sub { push @events,'error'; die 'error observer failed' });
    $tx->on_finish(sub { push @events,'finish' });
    my $reader=$tx->_ensure_receive_reader('request');
    eval { $reader->_push_owned('abc') };
    like($@,qr/data failed/,'original callback error propagates');
    is($tx->state,'error','transaction failed');
    is_deeply(\@events,[qw(error finish)],'finish survives throwing error observer');
    is($reader->pending_bytes,0,'failed callback releases Reader');
    is($connection->{consumed},3,'failed callback credits discarded body');
};

subtest 'Reader end callback unwinds before terminal notification' => sub {
    my $connection=bless {},'ReceiveLifecycleConnection';
    my $tx=transaction($connection);
    my @events;
    $tx->on_data(sub {});
    $tx->on_finish(sub { push @events,'finish' });
    $tx->_set_callback('on_request_end',sub { push @events,'request-end' });
    my $reader=$tx->_ensure_receive_reader('request');
    $reader->_configure(on_end=>sub { $tx->cancel; push @events,'reader-end' });
    $reader->_mark_end;
    is_deeply(\@events,[qw(request-end reader-end finish)],'all body completion callbacks precede finish');
};
done_testing;

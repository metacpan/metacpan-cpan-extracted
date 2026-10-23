use strict;
use warnings;
use Test::More;
use Unblock::HTTP::_WebSocketH2Body;

{
    package Local::H2Tx;
    sub new { bless { sent => [], ready => [], ended => 0, cancelled => 0 }, shift }
    sub write {
        my ($self, $bytes) = @_;
        push @{ $self->{sent} }, $bytes;
        return @{ $self->{ready} } ? shift @{ $self->{ready} } : 1;
    }
    sub end { ++$_[0]{ended}; return $_[0] }
    sub cancel { ++$_[0]{cancelled}; return $_[0] }
    sub is_terminal { $_[0]{terminal} ? 1 : 0 }
}

my @later;
my $defer = sub { push @later, $_[0] };
sub tick {
    my @callbacks = splice @later;
    $_->() for @callbacks;
}

my $tx = Local::H2Tx->new;
my $bridge = Unblock::HTTP::_WebSocketH2Body->new(
    transaction => $tx, defer => $defer,
);
is($bridge->unblock_send('hello'), 1, 'complete frame accepted into bridge');
is_deeply($tx->{sent}, [], 'no reentrant HTTP2 write during WebSocket callback');
is(scalar @later, 1, 'one deferred flush scheduled');
is($bridge->unblock_send('world'), 1, 'second frame accepted');
is(scalar @later, 1, 'multiple writes coalesce into one deferred turn');
tick();
is_deeply($tx->{sent}, ['hello', 'world'], 'ordered whole buffers reach H2 later');
is(scalar @later, 0, 'bridge requires no spurious later turn');

my $stalled = Local::H2Tx->new;
$stalled->{ready} = [0, 1];
my $waiting = Unblock::HTTP::_WebSocketH2Body->new(
    transaction => $stalled, defer => $defer,
);
$waiting->unblock_send('a');
$waiting->unblock_send('b');
tick();
is_deeply($stalled->{sent}, ['a'], 'false H2 write pauses further frames');
is(scalar @later, 0, 'blocked bridge does not spin on deferred callbacks');
$waiting->unblock_finish;
tick();
is($stalled->{ended}, 0, 'END_STREAM waits for the accepted output to drain');
$waiting->resume;
tick();
is_deeply($stalled->{sent}, ['a', 'b'], 'resume sends remaining frame once');
is($stalled->{ended}, 1, 'END_STREAM follows the final frame');
$waiting->resume;
tick();
is($stalled->{ended}, 1, 'repeated resume never sends END_STREAM twice');

my $oversized = Local::H2Tx->new;
my $large = Unblock::HTTP::_WebSocketH2Body->new(
    transaction => $oversized, defer => $defer,
);
is($large->unblock_send('x' x 65_536), 0,
    'false bridge result signals congestion after whole-frame acceptance');
tick();
is(length($oversized->{sent}[0]), 65_536,
    'entire accepted frame forwarded without splitting or replay');
$large->detach;

my $bad = Local::H2Tx->new;
my $abort = Unblock::HTTP::_WebSocketH2Body->new(
    transaction => $bad, defer => $defer,
);
$abort->unblock_send('pending');
$abort->unblock_abort('protocol error');
tick();
is($bad->{cancelled}, 1, 'WebSocket failure cancels only its H2 Transaction');
is_deeply($bad->{sent}, [], 'frames queued before abort are discarded');
$abort->detach;
$abort->unblock_abort('late error');
is($bad->{cancelled}, 1, 'detached bridge ignores repeated failures');

done_testing;

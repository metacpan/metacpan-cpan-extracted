use strict;
use warnings;

use Config;
use Test::More;

BEGIN {
    plan skip_all => 'this Perl is not built with ithreads'
        unless $Config{useithreads};
}

use threads;

use WiringPi::API qw(worker);

# A thread worker has no pipe channels: worker() rejects {results}/{shared} under
# {mechanism => 'thread'}, so read()/fh()/value() have nothing to return. They
# must croak with a guiding message (consistent with the BackgroundInterrupts
# sibling), NOT silently return undef.

my $w = worker(sub { select(undef, undef, undef, 0.05) },
    { mechanism => 'thread' });

isa_ok($w, 'WiringPi::API::WorkerThread', 'thread worker handle');

my $re = qr/no pipe channels.*pi_lock/s;

eval { $w->read };
like($@, $re, 'read() croaks under thread mode');

eval { $w->fh };
like($@, $re, 'fh() croaks under thread mode');

eval { $w->value };
like($@, $re, 'value() croaks under thread mode');

# The croak must blame the caller's line (this file), not WorkerThread.pm.
eval { $w->read };
like($@, qr/\bat \Q$0\E line \d+/, 'croak is reported from the caller, not the module');

ok($w->stop, 'thread worker stop() returns true');
ok(! $w->running, 'running() false after stop');

# B8: the join is guarded (is_joinable + eval, detach under global destruction),
# so these reaping paths must never die.

# A second stop() must not double-join (would die unguarded).
ok($w->stop, 'stop() is idempotent - no double-join die');

# A {once} thread exits on its own. running() must reap it without dying, and a
# follow-up stop() on the already-exited thread must stay safe.
{
    my $once = worker(sub { 1 }, { mechanism => 'thread', once => 1 });

    my $reaped;
    for (1 .. 200) {
        if (! $once->running) {
            $reaped = 1;
            last;
        }
        select(undef, undef, undef, 0.005);
    }

    ok($reaped, '{once} thread running() reaped the self-exited thread');
    ok(! $once->running, '{once} running() stays false (guarded join, no die)');
    ok($once->stop, 'stop() on a self-exited {once} thread is safe');
}

done_testing();

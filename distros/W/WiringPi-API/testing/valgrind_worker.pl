use warnings;
use strict;

# V8 leak/behaviour harness for worker(). Drives every worker() lifecycle path
# the t/ suite touches, on a loop, so a leaked pipe fd, an unreaped child, or a
# leaked SV shows up in valgrind's summary (and a zombie shows up in waitpid).
# Hardware: requires a Pi (setup_gpio + real pins). Drives BCM 17/27/22 as
# OUTPUTs - electrically safe with nothing wired.
#
# {mechanism=>'thread'} is intentionally NOT exercised here: it needs a threaded
# Perl ('use threads'), and this Perl is built without ithreads. The fork path
# below is the default and the one the dist must keep leak-clean.

use WiringPi::API qw(setup_gpio pin_mode read_pin write_pin worker);
use Time::HiRes qw(usleep);

my $iters = $ENV{ITERS} || 10;     # lower under valgrind (every fork is traced)
my @pins  = (17, 27, 22);

our @KEEP;          # handles deliberately left for the END reaper

setup_gpio();
for my $pin (@pins) {
    pin_mode($pin, 1);      # OUTPUT
    write_pin($pin, 0);
}

exercise_distinct_pin_workers();
exercise_interval_worker();
exercise_once_worker();
exercise_shared_sampler();
exercise_stop_and_reap();
exercise_forgotten_stop();

write_pin($_, 0) for @pins;

print "valgrind_worker.pl: all worker scenarios exercised ($iters iters each)\n";

# Distinct-pin workers: three children each owning their own pin, running
# concurrently with the parent. stop() each, then prove no zombie remains.
sub exercise_distinct_pin_workers {
    for (1 .. $iters) {
        my @w;
        for my $pin (@pins) {
            push @w, worker(sub {
                write_pin($pin, 1); usleep 5_000;
                write_pin($pin, 0); usleep 5_000;
            });
        }

        usleep 40_000;
        $_->stop for @w;

        for my $w (@w) {
            die "distinct-pin: zombie left for pid " . $w->pid
                if waitpid($w->pid, 1) != -1;            # WNOHANG
        }
    }
}

# Forgotten stop: spawn workers and never stop them, keeping the handles alive
# so the END reaper in WiringPi::API (not DESTROY) is the thing that cleans them
# up at process exit. Runs last; valgrind + a manual `ps` confirm no leak/zombie.
sub exercise_forgotten_stop {
    for (1 .. 3) {
        push @KEEP, worker(sub { usleep 20_000 });
    }

    print "forgotten-stop: spawned " . scalar(@KEEP)
        . " workers; END must reap pids " . join(", ", map { $_->pid } @KEEP) . "\n";
}

# {interval => $secs}: the helper paces the loop and the body carries no sleep.
# Drain the results channel and require that pacing produced bounded passes.
sub exercise_interval_worker {
    for (1 .. $iters) {
        my $i = 0;
        my $w = worker(sub { return $i++; }, { interval => 0.01, results => 1 });

        usleep 100_000;
        $w->stop;

        my $n = 0;
        $n++ while defined $w->read;
        die "interval: no passes streamed" if $n < 1;
    }
}

# {once => 1}: body runs exactly once, the child exits on its own, running()
# goes false, and the single value arrives on the results channel.
sub exercise_once_worker {
    for (1 .. $iters) {
        my $w = worker(sub { return 42; }, { once => 1, results => 1 });

        for (1 .. 200) {
            last if ! $w->running;
            usleep 2_000;
        }
        die "once: child still running" if $w->running;

        my $got = $w->read;
        die "once: no value produced" if ! defined $got || $got != 42;

        $w->stop;       # Idempotent on an already-exited child
    }
}

# {shared => 1}: a sampler reads a pin the parent drives and publishes the latest
# level; the parent reads it back through value(). Exercises the lossy channel.
sub exercise_shared_sampler {
    for (1 .. $iters) {
        write_pin(17, 1);
        my $s = worker(sub { return read_pin(17); }, { shared => 1, interval => 0.01 });

        my $v;
        for (1 .. 100) {
            usleep 5_000;
            $v = $s->value;
            last if defined $v && $v == 1;
        }
        die "shared: sampler never saw HIGH" if ! defined $v || $v != 1;

        $s->stop;
    }
}

# Lifecycle: running() true while alive, stop() reaps with no zombie, stop() is
# idempotent and running() false afterwards.
sub exercise_stop_and_reap {
    for (1 .. $iters) {
        my $w   = worker(sub { usleep 10_000 });
        my $pid = $w->pid;

        die "stop/reap: not running after spawn" if ! $w->running;

        $w->stop;
        die "stop/reap: still running after stop" if $w->running;
        die "stop/reap: zombie left for pid $pid" if waitpid($pid, 1) != -1;

        $w->stop;       # Idempotent
    }
}

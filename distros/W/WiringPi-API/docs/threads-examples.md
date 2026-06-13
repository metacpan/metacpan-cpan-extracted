# WiringPi::API — concurrency & background-worker examples

> **Status — implemented and shipping.** The `worker()` helper described here is
> implemented in `WiringPi::API` 3.18 and verified on Pi 5 hardware; the snippets
> run as written. `worker()` is **fork-based by default and needs no `use threads`
> and no threaded Perl** — an ithread mechanism is a documented opt-in only. For
> reacting to GPIO *edges* in the background, see `interrupt-examples.md`
> (`background_interrupt`).

## Table of contents

- [About these examples](#about-these-examples)
- [Decision guide](#decision-guide)
- [Background workers (`worker`)](#background-workers-worker)
  - [1. Heartbeat LED — a worker on its own pin](#1-heartbeat-led--a-worker-on-its-own-pin)
  - [2. Periodic sampler handing data back (`interval` + `shared`)](#2-periodic-sampler-handing-data-back-interval--shared)
  - [3. Streaming every result (`results`)](#3-streaming-every-result-results)
  - [4. A one-shot background task (`once`)](#4-a-one-shot-background-task-once)
  - [5. Several workers on distinct pins](#5-several-workers-on-distinct-pins)
  - [6. Shared memory — the opt-in ithread mechanism](#6-shared-memory--the-opt-in-ithread-mechanism)
- [Reacting to interrupts in the background](#reacting-to-interrupts-in-the-background)
- [The setup-once-in-main contract](#the-setup-once-in-main-contract)
- [Under the hood](#under-the-hood)
  - [7. Manual fork](#7-manual-fork)
  - [8. Raw ithreads (`threads->create`)](#8-raw-ithreads-threads-create)
  - [9. Periodic work with `Async::Event::Interval`](#9-periodic-work-with-asynceventinterval)
- [Anti-patterns to avoid](#anti-patterns-to-avoid)
- [API reference for these examples](#api-reference-for-these-examples)

## About these examples

This doc covers running work **concurrently** with the main program — distinct
from reacting to interrupts (that's `interrupt-examples.md`).

- **Prefer `worker()`.** It hides the spawn mechanism, the loop **and** the
  lifecycle: your body carries no `fork`, no `use threads`, no `detach`, no
  `while (1)` and no cleanup. It is the general-purpose sibling of
  `background_interrupt` in `interrupt-examples.md`.
- **No threads required.** `worker()` forks by default and works on **any** Perl,
  threaded or not. The ithread mechanism (scenario 6) is an opt-in for users who
  specifically want shared-memory ergonomics on a threaded Perl.
- **Pin numbering** follows whichever setup you call: `setup()` = wiringPi
  numbering, `setup_gpio()` = BCM. Examples use `setup()`.
- **Mode constants** for `pin_mode`: `INPUT` and `OUTPUT` — exported by
  `WiringPi::API` and used by name throughout (no bare `0`/`1`).
- **The setup-once-in-main contract:** call `setup()`/`pin_mode` **once, in the
  parent, before** starting a worker (see
  [that section](#the-setup-once-in-main-contract)). A fork worker inherits the
  configuration; you drive pins from inside the body.
- Sections 7–9 ([Under the hood](#under-the-hood)) show the raw `fork` /
  `threads->create` / `Async::Event::Interval` plumbing that `worker()` packages
  up — read them to understand what happens beneath the helper, but **most
  programs only need `worker()`.**

## Decision guide

None of these need `use threads` except scenario 6. To hide the most plumbing,
use `worker()` (scenarios 1–5).

> **fork vs thread in one line:** the default `fork` worker is crash-isolated and
> works on any Perl but **can't touch main's variables** (hand data back with
> `results`/`shared`); a `mechanism => 'thread'` worker shares memory directly but
> needs a threaded Perl and `pi_lock` discipline. No shared-memory need? Use the
> default fork.

| What you want | Scenario |
|---|---|
| Run a background task and forget it (its own GPIO) | [1](#1-heartbeat-led--a-worker-on-its-own-pin) (`worker`) |
| Sample periodically; main reads the latest value | [2](#2-periodic-sampler-handing-data-back-interval--shared) (`worker` + `interval`/`shared`) |
| Stream every value the worker produces back to main | [3](#3-streaming-every-result-results) (`worker` + `results`) |
| Do one background job once, then exit | [4](#4-a-one-shot-background-task-once) (`worker` + `once`) |
| Several independent workers, each on its own pin | [5](#5-several-workers-on-distinct-pins) (`worker`) |
| Share memory directly between main and the worker | [6](#6-shared-memory--the-opt-in-ithread-mechanism) (`worker` + `mechanism => 'thread'`) |
| React to a pin edge in the background | [`background_interrupt`](#reacting-to-interrupts-in-the-background) (in `interrupt-examples.md`) |
| Understand/hand-roll the raw mechanism | [7](#7-manual-fork), [8](#8-raw-ithreads-threads-create), [9](#9-periodic-work-with-asynceventinterval) |

---

## Background workers (`worker`)

### 1. Heartbeat LED — a worker on its own pin

**Why/when:** Run a self-contained background task on its own GPIO while main
does its own work; the simplest possible case.

**Real-world:** A status heartbeat LED blinking on its own cadence while the main
program does its real work.

**Main & background:** The helper owns the loop and the lifecycle. You write only
the body; `worker()` repeats it until you `stop`.

```perl
use strict;
use warnings;
use WiringPi::API qw(setup pin_mode write_pin worker OUTPUT);

setup();
pin_mode(2, OUTPUT);              # once in main

my $w = worker(sub {
    write_pin(2, 1); sleep 1;
    write_pin(2, 0); sleep 1;
});

# ... main does its own work ...

$w->stop;                         # idempotent; END reaps if you forget
```

No `use threads`, no `fork`, no `detach`, no `while (1)`, no `waitpid`.

### 2. Periodic sampler handing data back (`interval` + `shared`)

**Why/when:** Timer-driven sampling where main only ever wants the **latest**
reading, not every sample.

**Real-world:** Polling a sensor every second into a value the main app (a web
handler or display loop) reads on demand.

**Main & background:** `{ interval => $secs }` paces the loop (the body needs no
`sleep`); `{ shared => 1 }` publishes the body's return value as a lossy latest
value the parent reads with `$w->value`.

```perl
use strict;
use warnings;
use WiringPi::API qw(setup pin_mode analog_read worker INPUT);

setup();
pin_mode(0, INPUT);               # once in main

my $w = worker(sub { analog_read(0) }, { interval => 1, shared => 1 });

while (1) {
    my $latest = $w->value;       # most recent sample, or undef until the first
    print "latest: ", (defined $latest ? $latest : 'n/a'), "\n";
    sleep 5;
}

$w->stop;
```

The channel is **lossy** — the worker never blocks on a slow reader, so `value()`
gives you the most recent sample and discards the ones you didn't read.

### 3. Streaming every result (`results`)

**Why/when:** When you need **every** value the worker produces, in order, not
just the latest.

**Real-world:** A logger that records each reading, or a counter feeding an
event-loop via `select`.

**Main & background:** `{ results => 1 }` length-frames every defined return value
back over a pipe. Drain it with `$w->read` (non-blocking), or select on `$w->fh`.

```perl
use strict;
use warnings;
use WiringPi::API qw(setup pin_mode analog_read worker INPUT);

setup();
pin_mode(0, INPUT);               # once in main

my $w = worker(sub { analog_read(0) }, { interval => 0.5, results => 1 });

for (1 .. 20) {
    while (defined(my $v = $w->read)) {   # drain everything pending
        print "sample: $v\n";
    }
    sleep 1;
}

$w->stop;
```

This is identical to `background_interrupt`'s `{ results => 1 }` channel — see
`interrupt-examples.md`.

### 4. A one-shot background task (`once`)

**Why/when:** A single background job — run it off the main path and let it exit
on its own.

**Real-world:** Firing a one-shot solenoid pulse, or taking a single sensor
reading, without blocking main.

**Main & background:** `{ once => 1 }` runs the body exactly once; the child then
exits and `$w->running` becomes false. You can still `stop` (idempotent) or just
let the END reaper clean up.

```perl
use strict;
use warnings;
use WiringPi::API qw(setup pin_mode write_pin worker OUTPUT);

setup();
pin_mode(5, OUTPUT);              # once in main

my $w = worker(sub {
    write_pin(5, 1);
    select(undef, undef, undef, 0.2);     # 200ms pulse
    write_pin(5, 0);
}, { once => 1 });

# ... main carries on; the pulse fires in the background ...

$w->stop if $w->running;          # usually already finished
```

### 5. Several workers on distinct pins

**Why/when:** Multiple independent background tasks at once, each owning its own
pin.

**Real-world:** A multi-channel relay board where each channel toggles on its own
cadence while main runs the control logic.

**Main & background:** Configure every pin **once in main**, then start one worker
per pin. Each runs independently; each returns its own handle.

```perl
use strict;
use warnings;
use WiringPi::API qw(setup pin_mode write_pin worker OUTPUT);

setup();
pin_mode($_, OUTPUT) for (2, 3, 4);    # all config in main, up front

my @workers = (
    worker(sub { write_pin(2, 1); sleep 1; write_pin(2, 0); sleep 1 }),
    worker(sub { write_pin(3, 1); sleep 2; write_pin(3, 0); sleep 2 }),
    worker(sub { write_pin(4, 1); sleep 3; write_pin(4, 0); sleep 3 }),
);

# ... main's own work ...

$_->stop for @workers;
```

Workers must drive **distinct** pins — see
[the setup-once-in-main contract](#the-setup-once-in-main-contract).

### 6. Shared memory — the opt-in ithread mechanism

**Why/when:** You specifically want to share memory directly between main and the
worker (no IPC), and you have a threaded Perl.

**Real-world:** A counter or state machine the worker mutates and main reads in
the same address space.

**Main & background:** `{ mechanism => 'thread' }` runs the body in an ithread
instead of a fork. It **requires `use threads`** (croaks otherwise) and rejects
the `results`/`shared` pipe channels — share a `:shared` variable and serialize
it with `pi_lock`/`pi_unlock` (keys 0–3) instead. `stop` sets the stop flag and
joins the thread.

```perl
use strict;
use warnings;
use threads;                      # required for mechanism => 'thread'
use threads::shared;
use WiringPi::API qw(setup worker pi_lock pi_unlock);

setup();

my $count :shared = 0;

my $w = worker(sub {
    pi_lock(0);
    $count++;
    pi_unlock(0);
    select(undef, undef, undef, 0.1);
}, { mechanism => 'thread' });

while (1) {
    pi_lock(0);
    my $n = $count;
    pi_unlock(0);
    print "count: $n\n";
    sleep 1;
}

$w->stop;                         # sets the stop flag and joins
```

Check for a threaded Perl with `perl -V:useithreads` (Raspberry Pi OS ships one).

---

## Reacting to interrupts in the background

`worker()` is for *running* background work, not for reacting to GPIO **edges**.
To handle an edge in the background — fire a callback even while main is blocked —
use **`background_interrupt`**, the interrupt-side sibling of `worker()`. It
forks a child that arms the interrupt and runs your callback on each edge, and
returns a handle with the same `stop`/`pid`/`running` shape:

```perl
use WiringPi::API qw(setup pin_mode background_interrupt INPUT INT_EDGE_RISING);

setup();
pin_mode(0, INPUT);

my $h = background_interrupt(0, INT_EDGE_RISING, sub {
    my ($edge, $ts_us) = @_;
    # runs in the background on each rising edge
});

# ... main does its own work; the handler fires on its own ...

$h->stop;
```

The full interrupt story (cooperative dispatch, `auto_dispatch_interrupts`,
`background_interrupt`, `background_interrupts`) is in `interrupt-examples.md`.

## The setup-once-in-main contract

The rule that keeps concurrent GPIO safe: do all configuration **once, in main,
before** starting any worker; afterwards each context does only steady-state I/O
on **distinct** pins.

- Call `setup()`/`setup_gpio()`, every `pin_mode`, and any device `*Setup`
  **once, in the parent, before** the first `worker()`.
- A fork worker inherits that configuration; a thread worker shares it.
- Afterwards, workers may freely `read_pin`/`write_pin` on **distinct**
  pins. **Never** call `setup()`/`pin_mode`/device `*Setup` concurrently — they
  read-modify-write shared registers.
- For shared Perl data under `mechanism => 'thread'`, guard every access with
  `pi_lock`/`pi_unlock` (or `threads::shared`'s `lock`).

---

## Under the hood

These are the raw mechanisms `worker()` packages up. You rarely need them
directly; they are here to show what the helper does and to cover cases it
doesn't.

### 7. Manual fork

**Why/when:** The fork worker (scenario 1) without the helper — full control over
the child, at the cost of writing the loop, the signal handling and the reaping
yourself.

**Main & background:** The child is a separate process: truly concurrent and
crash-isolated, but it **cannot** touch main's variables — pass data back via a
pipe, and reap it yourself.

```perl
use strict;
use warnings;
use WiringPi::API qw(setup pin_mode write_pin OUTPUT);

setup();
pin_mode(2, OUTPUT);                     # before fork

my $pid = fork // die "fork: $!";

if ($pid == 0) {
    while (1) {                          # child: heartbeat forever
        write_pin(2, 1); sleep 1;
        write_pin(2, 0); sleep 1;
    }
    exit 0;
}

# ... parent's own work ...

kill 'TERM', $pid;                       # on shutdown
waitpid $pid, 0;
```

`worker(sub {...})` is exactly this — the fork, the loop, the `TERM` handler and
the `waitpid` — done for you, with an idempotent `stop` and an END-block reaper.

### 8. Raw ithreads (`threads->create`)

**Why/when:** The thread worker (scenario 6) without the helper — when you want to
manage the thread object yourself.

**Main & background:** The body runs in its **own** interpreter; it can't see
main's lexicals — share only via `:shared` variables guarded by `pi_lock`/`lock`.

```perl
use strict;
use warnings;
use threads;
use threads::shared;
use WiringPi::API qw(setup pin_mode read_pin pi_lock pi_unlock INPUT);

setup();
pin_mode(3, INPUT);

my $latest :shared = 0;

my $thr = threads->create(sub {
    while (1) {
        my $v = read_pin(3);
        pi_lock(0); $latest = $v; pi_unlock(0);
        select(undef, undef, undef, 0.05);
    }
});

# ... main reads $latest under pi_lock(0) ...

# To stop a hand-rolled thread you need your own shared flag + join;
# worker({mechanism=>'thread'}) provides exactly that.
$thr->detach;
```

`worker(sub {...}, { mechanism => 'thread' })` wraps this with a shared stop flag
and a clean `stop`/join, so you don't hand-roll the lifecycle.

### 9. Periodic work with `Async::Event::Interval`

**Why/when:** A fork-based CPAN module for *periodic* tasks with crash
detection/restart and a shared scalar for the latest value. `worker()` with
`{ interval, shared }` (scenario 2) covers most of this without a dependency; reach
for `Async::Event::Interval` when you specifically want its restart-on-crash.

**Main & background:** The callback runs in a forked child every interval; main
reads the latest value via the module's `shared_scalar` (lossy).

```perl
use strict;
use warnings;
use Async::Event::Interval;
use WiringPi::API qw(setup pin_mode read_pin INPUT);

setup();
pin_mode(3, INPUT);                          # before the event forks

my $event  = Async::Event::Interval->new(1, \&sample);   # forks; runs every 1s
my $latest = $event->shared_scalar;
$event->start;

while (1) {
    print "latest: ", (defined $$latest ? $$latest : 'n/a'), "\n";
    $event->restart if $event->error;        # auto-recover a crashed sampler
    sleep 2;
}

sub sample {
    $$latest = read_pin(3);
}
```

**Honest fit:** this is a *timer* with **latest-value (lossy)** shared state —
ideal for periodic sampling, wrong for **edge interrupts** (don't drop edges —
keep those on the self-pipe, `interrupt-examples.md`). Note
`Async::Event::Interval` sets `$SIG{CHLD} = 'IGNORE'` and uses SysV shared memory
at load time, so it does not compose with a hand-rolled `fork`/`waitpid` or with
`worker()`.

## Anti-patterns to avoid

- **Reaching for `use threads` first.** `worker()` is fork-based and needs no
  threaded Perl. Only use `mechanism => 'thread'` when you specifically want
  shared memory.
- **Putting a loop inside the body.** `worker()` owns the loop — the body is one
  pass. Use `{ interval => $secs }` for pacing and `{ once => 1 }` for a single
  pass; a `while (1)` inside the body defeats `stop`/`once`/`interval`.
- **Concurrent `pin_mode` / `setup` / device `*Setup`.** Read-modify-write on
  shared registers; do them once, in main, before starting any worker. Only
  `read_pin`/`write_pin` on distinct pins are safe concurrently.
- **Expecting a fork worker to see main's variables.** Separate memory — hand data
  back with `{ results => 1 }` / `{ shared => 1 }`, not a shared Perl variable.
- **Touching `:shared` data without a lock (thread mode).** Guard every access
  with `pi_lock`/`pi_unlock` (or `lock`). A bare `$shared++` from two threads
  races.
- **Combining `mechanism => 'thread'` with `results`/`shared`.** Those are fork
  pipe channels and are rejected under thread mode — share a `:shared` variable
  with `pi_lock` instead.
- **Mixing a hand-rolled `fork`/`waitpid` with `Async::Event::Interval`.** It sets
  `$SIG{CHLD} = 'IGNORE'` at load, which auto-reaps children — your own `waitpid`
  then fails. Pick one process-management model.

## API reference for these examples

| Call | Purpose | Returns |
|---|---|---|
| `setup()` / `setup_gpio()` | init (wiringPi / BCM numbering); once, in main | int status (`0` = ok) |
| `pin_mode($pin, $mode)` | `0`=INPUT, `1`=OUTPUT | — |
| `write_pin($pin, $val)` / `read_pin($pin)` | pin I/O | — / pin level (`0`/`1`) |
| `worker(\&body [, \%opts])` | run `\&body` in the background. `\%opts`: `{once, interval, results, shared, mechanism}` | handle `$w` (`stop` / `pid` / `running` / `read` / `fh` / `value`) |
| `pi_lock($key)` / `pi_unlock($key)` | mutex (keys 0–3) for shared state under thread mode | — |
| `background_interrupt(...)` | background **edge** handler (see `interrupt-examples.md`) | handle `$h` |

> See the `WiringPi::API` POD ("CONCURRENCY / BACKGROUND WORKERS") for the
> authoritative per-function documentation, and `lib/WiringPi/API/WORKERS.pod`
> (`perldoc WiringPi::API::WORKERS`) for this guide in `perldoc` form. For
> interrupts, see `interrupt-examples.md`.

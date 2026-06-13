# WiringPi::API — interrupt (ISR) usage examples

> **Status — implemented and shipping.** The self-pipe interrupt API described
> here is implemented in `WiringPi::API` 3.18 and verified on Pi 5 hardware; the
> snippets run as written. This doc is **ISR-only and uses no `use threads`** —
> general concurrency/worker examples (`worker()`) live in `threads-examples.md`.
> Callbacks fire in your own interpreter when you service dispatch, so they work
> on **any** Perl, threaded or not.

## Table of contents

- [About these examples](#about-these-examples)
- [Decision guide](#decision-guide)
- [Reacting to interrupts](#reacting-to-interrupts)
  - [1. Cooperative dispatch in your main loop](#1-cooperative-dispatch-in-your-main-loop)
  - [2. Blocking wait loop](#2-blocking-wait-loop)
  - [3. Event-loop integration with the interrupt fd](#3-event-loop-integration-with-the-interrupt-fd)
  - [4. Multiple pins and callbacks](#4-multiple-pins-and-callbacks)
  - [5. Edge types and debounce](#5-edge-types-and-debounce)
  - [6. Teardown and re-arming](#6-teardown-and-re-arming)
- [Hands-off handling (no dispatch loop)](#hands-off-handling-no-dispatch-loop)
  - [7. Fire with no loop (auto_dispatch_interrupts)](#7-fire-with-no-loop-auto_dispatch_interrupts)
  - [8. A background process (background_interrupt)](#8-a-background-process-background_interrupt)
  - [9. Under the hood: manual fork](#9-under-the-hood-manual-fork)
  - [10. Many pins in one background child (background_interrupts)](#10-many-pins-in-one-background-child-background_interrupts)
- [Non-threaded Perl](#non-threaded-perl)
- [Anti-patterns to avoid](#anti-patterns-to-avoid)
- [API reference for these examples](#api-reference-for-these-examples)
- [Code flow — Perl → API.pm → API.xs → wiringPi](#code-flow--perl--apipm--apixs--wiringpi)

## About these examples

- **Interrupts never require `use threads`.** wiringPi runs its own C threads
  internally and writes events to a pipe; your Perl reads that pipe. Hands-off
  handling uses an in-process signal (scenario 7) or a forked process (scenario 8)
  — never threads.
- **Callbacks receive `($edge, $timestamp_us)`** — the edge that fired
  (`INT_EDGE_FALLING`=1 / `INT_EDGE_RISING`=2) and a microsecond timestamp.
- **Pin numbering** follows whichever setup you call: `setup()` = wiringPi
  numbering, `setup_gpio()` = BCM. Examples use `setup()`.
- **Mode constants** for `pin_mode`: `INPUT` and `OUTPUT` — exported by
  `WiringPi::API` and used by name throughout (no bare `0`/`1`).
- **To hide the most work, prefer the hands-off options.** `auto_dispatch_interrupts`
  (scenario 7) fires callbacks in your own process with no loop; `background_interrupt`
  (scenario 8) runs an independent handler in its own process. Scenario 9 is the
  manual version of 8. Sections 1–6 (cooperative) explain the explicit dispatch
  model that 7 and 8 hide — read them to understand what happens under the
  hands-off calls, but **most programs only need 7 or 8.**
- **If you fork yourself** (scenario 9): call `setup()` and `pin_mode` in the
  parent **before** forking, and arm the interrupt in the child that dispatches it.
- For **running** background work (not reacting to edges), see `worker()` in
  `threads-examples.md`. An **ithread**-based alternative lives there too.

## Decision guide

None of these need `use threads`. To hide the most plumbing, prefer the first two
(hands-off) rows.

> **7 vs 8 in one line:** `auto_dispatch_interrupts` (7) gives you lock-free shared state but
> *defers* during a long non-yielding C call; `background_interrupt` (8) fires
> regardless of what main is doing but **can't touch main's variables**. No long C
> calls? Pick 7. Long C calls? Pick 8.

| What you want | Scenario |
|---|---|
| Attach a handler and forget it; it updates my program's state | [7](#7-fire-with-no-loop-auto_dispatch_interrupts) (`auto_dispatch_interrupts`) |
| Independent handler that fires even during long/blocking work | [8](#8-a-background-process-background_interrupt) (`background_interrupt`) |
| The same, but several pins in one background process | [10](#10-many-pins-in-one-background-child-background_interrupts) (`background_interrupts`) |
| React to a pin while running my own loop, on my terms | [1](#1-cooperative-dispatch-in-your-main-loop), [3](#3-event-loop-integration-with-the-interrupt-fd) |
| A program whose only job is reacting to pins | [2](#2-blocking-wait-loop) |
| Several pins, each with its own handler | [4](#4-multiple-pins-and-callbacks) |
| Specific edges / debounce a noisy input | [5](#5-edge-types-and-debounce) |
| Tear down or re-arm a pin | [6](#6-teardown-and-re-arming) |
| Deliver edges back to the parent to handle there | [9](#9-under-the-hood-manual-fork) |

---

## Reacting to interrupts

### 1. Cooperative dispatch in your main loop

**Why/when:** You already have a main loop and want to control exactly when
callbacks run. Simplest model, works on any Perl — but a callback only fires when
you call `dispatch_interrupts()`, so keep the loop snappy. (Want it fully
hands-off? See scenario 7.)

**Real-world:** A rover whose main loop steers and reads sensors every tick, while
a front bumper microswitch triggers an obstacle-avoidance routine — serviced once
per loop pass.

**Main & interrupt:** One thread. The callback runs *inside* `dispatch_interrupts()`,
so it can read/write any of main's variables with no locking — but it only fires
when main calls dispatch, and it blocks main while it runs.

Do your own work, and fire any pending interrupt callbacks each pass.

```perl
use strict;
use warnings;
use WiringPi::API qw(setup pin_mode set_interrupt dispatch_interrupts INPUT INT_EDGE_RISING);

setup();
pin_mode(0, INPUT);

set_interrupt(0, INT_EDGE_RISING, sub {
    my ($edge, $ts_us) = @_;
    print "pin 0 rising at ${ts_us}us\n";
});

while (1) {
    do_other_work();
    dispatch_interrupts();  # non-blocking: runs callbacks for any events that arrived
}

sub do_other_work {
    # ... your periodic work ...
}
```

Tradeoff: if `do_other_work()` blocks for a long time, callbacks wait until the
next `dispatch_interrupts()`. Conversely, if `do_other_work()` returns instantly
with nothing to do, this loop **busy-spins at 100% CPU** — pace it with real
periodic work, a short `sleep`, or by `select`ing on `interrupt_fd` with a timeout
(scenario 3).

### 2. Blocking wait loop

**Why/when:** Reacting to pins *is* the whole job — there's no other work to do.
The process sleeps efficiently until an edge arrives.

**Real-world:** A doorbell or panic button — the Pi idles at near-zero CPU until
the button fires, then sends a notification.

**Main & interrupt:** One thread. Main is blocked in `wait_interrupts()` until an
edge, then runs the callback inline (full access to program state). Main does no
other work while it waits.

When reacting to pins *is* the program. `wait_interrupts` blocks until an event
arrives (or the timeout), then dispatches.

```perl
use strict;
use warnings;
use WiringPi::API qw(setup pin_mode set_interrupt wait_interrupts INPUT INT_EDGE_BOTH);

setup();
pin_mode(0, INPUT);

set_interrupt(0, INT_EDGE_BOTH, \&on_change);

while (1) {
    wait_interrupts(1000);  # block up to 1000ms, dispatch whatever fired
}

sub on_change {
    my ($edge, $ts_us) = @_;
    print "edge $edge at ${ts_us}us\n";
}
```

**Shortcut.** If the loop is literally just `wait_interrupts while 1`, call the
built-in helper instead of writing it yourself:

```perl
run_interrupt_loop(1000);             # blocks, dispatching, forever
run_interrupt_loop(1000, 50);         # ... or until 50 events have fired
```

It returns the number of events dispatched and stops when `stop_interrupt_loop()`
is called (from inside a callback, or a signal handler) or after the optional
event cap. When nothing is armed it sleeps the poll interval instead of
busy-spinning.

### 3. Event-loop integration with the interrupt fd

**Why/when:** You already run an event loop (AnyEvent/IO::Async) or juggle
sockets/timers, and want GPIO to be just another fd in it.

**Real-world:** A home-automation daemon already running an `IO::Async` loop for
MQTT/HTTP that also publishes a message when a PIR motion sensor trips.

**Main & interrupt:** One thread (the loop). The callback runs inline when the loop
reaches the fd — full shared access; latency depends on the loop, and main must not
block it elsewhere.

`interrupt_fd()` returns a read fd you can `select`/poll alongside your other
descriptors — so one loop handles sockets, timers, and GPIO together.

```perl
use strict;
use warnings;
use WiringPi::API qw(setup pin_mode set_interrupt dispatch_interrupts interrupt_fd INPUT INT_EDGE_RISING);

setup();
pin_mode(0, INPUT);
set_interrupt(0, INT_EDGE_RISING, \&on_edge);

my $fd = interrupt_fd();
vec(my $mask = '', $fd, 1) = 1;

while (1) {
    select(my $ready = $mask, undef, undef, undef);  # block until readable
    if (vec($ready, $fd, 1)) {
        dispatch_interrupts();
    }
}

sub on_edge {
    my ($edge, $ts_us) = @_;
    print "edge!\n";
}
```

The same `$fd` plugs into `AnyEvent->io` or `IO::Async::Handle`.

### 4. Multiple pins and callbacks

**Why/when:** Several inputs, each with its own handler, serviced by one loop.
(Same mechanics as 1–3; this just shows the fan-out.)

**Real-world:** A control panel with Start/Stop/Up/Down buttons, each wired to its
own handler.

**Main & interrupt:** Still one servicing thread — callbacks run one at a time with
full access to main's state; no callback runs concurrently with another or with
main.

One pipe, one loop, many pins — each with its own callback.

```perl
use strict;
use warnings;
use WiringPi::API qw(setup pin_mode set_interrupt wait_interrupts
                     INPUT INT_EDGE_RISING INT_EDGE_FALLING INT_EDGE_BOTH);

setup();
pin_mode($_, INPUT) for (0, 2, 3);

set_interrupt(0, INT_EDGE_RISING,  sub { print "button A\n" });
set_interrupt(2, INT_EDGE_FALLING, sub { print "button B\n" });
set_interrupt(3, INT_EDGE_BOTH,    \&sensor);

while (1) {
    wait_interrupts(1000);
}

sub sensor {
    my ($edge, $ts_us) = @_;
    print "sensor edge=$edge\n";
}
```

**One shared handler for several pins.** The callback only receives
`($edge, $ts_us)`, not the pin. If you arm the *same* coderef on multiple pins,
call `last_interrupt()` inside it to recover which pin (and the BCM number)
fired:

```perl
my $cb = sub {
    my $i = last_interrupt();   # { pin, pin_bcm, edge, status, ts_us }
    printf "pin %d (BCM %d) edge %d\n", $i->{pin}, $i->{pin_bcm}, $i->{edge};
};
set_interrupt($_, INT_EDGE_BOTH, $cb) for (0, 2, 3);
```

`last_interrupt()` returns a hash reference describing the most recently
dispatched event (or `undef` if none yet); it is published *before* the callback
runs, so the callback can read it.

### 5. Edge types and debounce

**Why/when:** You care about a specific edge, or the input is electrically noisy
(a button) and you want the kernel to suppress bounce so the callback fires once
per press.

**Real-world:** Counting items on a conveyor with a microswitch (or reading a
rotary encoder) — debounce gives one event per actuation instead of a burst from
contact bounce.

**Main & interrupt:** Orthogonal to where the callback runs — debounce drops bounce
edges in the kernel before they're ever queued, so fewer events reach your dispatch
point.

Edge constants: `INT_EDGE_FALLING`=1, `INT_EDGE_RISING`=2, `INT_EDGE_BOTH`=3.
An optional 4th argument sets a **kernel debounce period** in **microseconds**
(default 0 = off). wiringPi applies it as a Linux **GPIO-v2 line attribute**
(`GPIO_V2_LINE_ATTR_ID_DEBOUNCE`) at arm time (`wiringPi.c`, in
`interruptHandlerInit`), so the kernel drops bounce edges before they reach the
pipe — it is *not* a hardware debounce. The attribute's field is a `u32`, so the
effective maximum is ~2³² µs (≈ 71 minutes) — unlimited for any real use.

```perl
use WiringPi::API qw(setup pin_mode set_interrupt wait_interrupts INPUT INT_EDGE_FALLING);

setup();
pin_mode(0, INPUT);

# Debounce a noisy button: ignore repeat edges within 5ms

set_interrupt(0, INT_EDGE_FALLING, \&pressed, 5 * 1000); # micros -> millis

wait_interrupts(1000) while 1;

sub pressed {
    print "clean press\n";
}
```

### 6. Teardown and re-arming

**Why/when:** You need to stop watching a pin, swap a handler at runtime, or clean
up on exit.

**Real-world:** A handheld with a mode button — swap its handler when switching
screens, and `stop_interrupts()` on shutdown to release the lines.

**Main & interrupt:** `stop_interrupt`/re-arm run in main and edit the registration;
after a stop the callback can't fire, and re-arming swaps it cleanly (the old
listener is stopped first).

```perl
set_interrupt(0, INT_EDGE_RISING, \&handler_a);

# Re-arm the same pin with a different handler — the old listener is stopped
# automatically first, so no stacked/duplicate registration

set_interrupt(0, INT_EDGE_RISING, \&handler_b);

stop_interrupt(0);    # stop one pin, forget its callback
stop_interrupts();    # stop every pin, drain + close the pipe
```

**Bursts and dropped edges.** Edges are FIFO-queued in a kernel pipe until you
dispatch them. If a fast source outruns your dispatching the queue fills, and the
overflowing edges are **dropped — never merged, never blocked** — and counted, so
loss is never silent:

```perl
my $lost = interrupt_dropped();       # 0 unless the pipe overflowed
```

If you expect bursts, enlarge the queue with `interrupt_buffer($bytes)` (it may
be set before arming and persists across teardown):

```perl
interrupt_buffer(1 << 20);            # ~1 MiB of queue; returns the granted size
my $size = interrupt_buffer;          # read the current capacity
```

The kernel rounds up to a page and caps at `/proc/sys/fs/pipe-max-size`. Other
mitigations: dispatch faster, use `background_interrupt` (a dedicated process
keeps the pipe drained), or debounce (scenario 5) to cut the edge rate.

---

## Hands-off handling (no dispatch loop)

### 7. Fire with no loop (auto_dispatch_interrupts)

**Why/when:** The most hands-off in-process option — "attach a handler and forget
it," closest to Arduino's `attachInterrupt`. The callback runs in *your* program
(it can read/update your variables, no locking) and fires on its own while your
code runs, with no dispatch loop. Best when a handler must touch your program's
state. Caveat: a long non-yielding C/XS call can delay it (see `isr-migration.md`).

**Real-world:** A weather station counting anemometer/rain-gauge pulses into a
counter your main loop reads and uploads every few seconds — the handler updates
your in-program state directly.

**Main & interrupt:** The callback runs in **main's interpreter** at op boundaries
(and on interrupted sleeps), so it can read/write main's variables with **no
locking** — but a long non-yielding C call defers it until that call returns.

`auto_dispatch_interrupts(1)` wires the interrupt fd to a signal and installs the handler for
you, so `set_interrupt` callbacks fire **automatically, in your own process**, with
no `dispatch_interrupts`/`wait_interrupts` loop. Perl runs them at safe points
(between ops, and on interrupted sleeps), so the callback can touch your variables
with **no locking**.

```perl
use strict;
use warnings;
use WiringPi::API qw(setup pin_mode set_interrupt auto_dispatch_interrupts INPUT INT_EDGE_RISING);

setup();
pin_mode(0, INPUT);

auto_dispatch_interrupts(1);          # callbacks now fire on their own — no loop to write

my $count = 0;
set_interrupt(0, INT_EDGE_RISING, sub { $count++ });   # updates your own variable

while (1) {
    do_main_work();        # the callback fires between ops, and during the sleep
    print "edges so far: $count\n";
    sleep 1;
}

sub do_main_work {
    # ...
}
```

No dispatch loop, no fork, no threads — and the callback shares your program's
state directly. The one caveat: a long, non-yielding C/XS call delays the callback
until it returns (it fires at Perl's safe points). To fire even during such work,
use scenario 8.

**Choosing the signal.** By default the fd is wired to `SIGIO`. If your program
already uses `SIGIO`/`O_ASYNC`, pass a different signal so they don't clash:

```perl
auto_dispatch_interrupts(1, 'USR1');  # deliver via SIGUSR1 instead (F_SETSIG)
```

**Opt in while arming.** Instead of a separate `auto_dispatch_interrupts(1)`
call, you can turn it on as part of `set_interrupt` — this enables the same
process-wide switch:

```perl
set_interrupt(0, INT_EDGE_RISING, sub { $count++ }, { auto_dispatch => 1 });
# or pick the signal:  { auto_dispatch => 'USR1' }
```

### 8. A background process (background_interrupt)

**Why/when:** True fire-while-busy with zero servicing, even during long blocking
work — because the handler runs in a *separate process*. Best for **independent**
handlers (drive a pin, log, notify) that don't need your main program's variables.

**Real-world:** An emergency-stop button that drops a motor relay immediately — it
must fire even while main is mid-way through a long upload or computation, and the
handler just drives a GPIO.

**Main & interrupt:** The callback runs in a **separate process**, truly
concurrently — it fires even while main blocks, but **cannot** see or change main's
variables (separate memory; share via IPC). Neither can corrupt the other.

`background_interrupt` hides the fork, the wait loop, and the cleanup: give it a
pin, an edge, and a callback, and it runs that callback in a background process on
each edge while your main program does whatever it likes. **The callback runs in
the background process** — ideal for independent handlers (drive a pin, log, send
a message); it can't touch your main program's variables.

```perl
use strict;
use warnings;
use WiringPi::API qw(setup pin_mode background_interrupt INPUT INT_EDGE_RISING);

setup();
pin_mode(0, INPUT);

my $h = background_interrupt(0, INT_EDGE_RISING, sub {
    my ($edge, $ts_us) = @_;
    # runs in the background on each rising edge — independent work only
});

# main carries on; the handler fires on its own

for (1 .. 10) {
    do_other_work();
    sleep 1;
}

$h->stop;                  # stops + reaps the background handler

sub do_other_work {
    # ...
}
```

No `pipe`, no `fork`, no `select`, no `waitpid` — the library owns all of it (and
an `END` hook reaps the child even if you forget `stop`). `$h->stop` is
**idempotent**: safe to call more than once, and safe after the child has already
exited (it won't croak on an already-reaped handler). Needs no threaded Perl.

**Reporting values back (the `results` channel).** For a handler that just needs
to report a value to the parent, you don't need the manual fork of scenario 9 —
pass `{ results => 1 }` and **return** a value from the handler; the parent drains
it:

```perl
my $h = background_interrupt(
    0,
    INT_EDGE_RISING,
    sub {
        my ($edge, $ts_us) = @_;
        return "$edge\@$ts_us"; # Returned to parent
    },
    { results => 1 }
);

while (defined(my $msg = $h->read)) {  # non-blocking drain
    print "handler reported: $msg\n";
}

# $h->fh is the read filehandle, for select / IO::Select
```

For anything more elaborate than reporting the handler's return value, scenario 9
shows the manual fork with your own results channel.

### 9. Under the hood: manual fork

**Why/when:** You rarely write this by hand — it's what scenario 8 does for you.
Use it directly only when you need each edge **delivered back to the parent** to
handle there, rather than handled in the child.

**Real-world:** A logger that timestamps every edge into the parent's open CSV/DB
handle — the child forwards edges over the pipe and the parent, which owns the
handle, writes them.

**Main & interrupt:** The child runs the wiringPi handler and only forwards events;
**main** runs your real logic when it drains the pipe (in main's interpreter, full
access to its state and handles). The child can't touch main's variables.

This is essentially what scenario 8 does for you, by hand — and the pattern to use
directly when you need each edge **delivered back to the parent** (main reacts),
rather than handled in the child. The child forwards edges over a pipe; the parent
drains and dispatches.

```perl
use strict;
use warnings;
use IO::Select;
use WiringPi::API qw(setup pin_mode set_interrupt wait_interrupts INPUT INT_EDGE_RISING);

setup();
pin_mode(0, INPUT);

# This $rx/$tx pipe is YOUR OWN results channel (child -> parent), separate from
# the library's internal self-pipe (a fixed 24-byte {pin, pin_bcm, edge, status, ts} record). You
# choose this channel's format; here, one newline-terminated text line per edge —
# self-delimiting, and portable (no 64-bit pack template, no fixed-width framing
# to get wrong).

pipe(my $rx, my $tx) or die "pipe: $!";

my $pid = fork // die "fork: $!";

if ($pid == 0) {
    # Child owns interrupt handling; arm HERE (post-fork). Only the child reads
    # the library's interrupt fd — the parent never calls dispatch on it.

    close $rx;

    set_interrupt(
        0,
        INT_EDGE_RISING,
        sub {
            my ($edge, $ts_us) = @_;
            syswrite $tx, "$edge $ts_us\n"; # One text line up to the parent
        }
    );

    wait_interrupts(1000) while 1;
    exit 0;
}

# Parent: free to work; drain results without blocking

close $tx;
my $sel = IO::Select->new($rx);
my $buf = '';

# Reap the child on normal exit/die even if you forget to stop it explicitly.
# (Not run on signal-kill — trap signals too if you need that.)

END { if ($pid) { kill 'TERM', $pid; waitpid $pid, 0; $pid = undef; } }

while (1) {
    do_other_work();

    while ($sel->can_read(0)) {
        my $n = sysread($rx, my $chunk, 4096);
        if (! defined $n) {
            last if $!{EINTR};                        # Signal: retry next pass ($buf intact)
            $sel->remove($rx); last;                  # Any other error: stop, don't spin
        }

        if ($n == 0) {
            # EOF: child exited — stop watching
            $sel->remove($rx);
            last
        }  
        $buf .= $chunk;
        
        while ($buf =~ s/^([^\n]*)\n//) {             # Consume only complete lines
            my ($edge, $ts_us) = split ' ', $1;
            print "edge $edge at ${ts_us}us\n";
        }
    }
}

sub do_other_work {
    # ... your work ...
}
```

**One reader of the interrupt fd.** After the fork, only the *child* reads the
library's interrupt fd (it owns dispatch). The parent reacts through the results
pipe `$rx`, **never** by calling `dispatch_interrupts()` on the shared fd — two
readers would race for the same records.

**Backpressure.** `$tx` is a blocking pipe. If the parent stalls in
`do_other_work()` and stops draining `$rx`, the child's callback blocks in
`syswrite`, stops servicing its own internal self-pipe, and edges start dropping
(visible to the child via `interrupt_dropped()`). Keep the parent draining — or
set `$tx` non-blocking and handle `EAGAIN` if you'd rather drop than block.

**Don't busy-spin.** As in scenario 1, this loop's pace is set by
`do_other_work()`. If that can return instantly, do real periodic work, add a
short `sleep`, or `select` on `$rx` with a timeout (`$sel->can_read($secs)`) so the
parent sleeps when idle instead of spinning on `can_read(0)`.

> **High-rate alternative.** For very high edge rates you can use fixed binary
> records (`pack`/`unpack`) instead of text — but only if your Perl has 64-bit-IV
> support (the `q`/`Q` template, *not* present on every 32-bit Pi build) and each
> record stays ≤ `PIPE_BUF` (so writes remain atomic and reads stay
> record-aligned). Text framing avoids both constraints and is the better default.

> An `ithread`-based equivalent (shared variables instead of a results pipe) is in
> `threads-examples.md` — see `worker()` with `{ mechanism => 'thread' }`.

### 10. Many pins in one background child (background_interrupts)

**Why/when:** You want background handling (scenario 8) for *several* pins, but a
separate child per pin is wasteful. `background_interrupts` forks **one** child
that services them all, and lets you arm/disarm individual pins at runtime.

**Real-world:** A control box with several buttons and sensors, all handled off
the main program in a single helper process.

**Main & interrupt:** Each callback runs in the one shared child (separate memory
from main, as in scenario 8). The callbacks are fixed when the child forks —
`fork` can't carry new code — so `arm`/`disarm` only toggle pins registered in the
initial call.

```perl
use strict;
use warnings;
use WiringPi::API qw(setup pin_mode background_interrupts
                     INPUT INT_EDGE_RISING INT_EDGE_BOTH);

setup();
pin_mode($_, INPUT) for (0, 2);

my $h = background_interrupts(
    [0, INT_EDGE_RISING, \&on_button],
    [2, INT_EDGE_BOTH,   \&on_sensor, 5 * 1000],   # Optional debounce
);

# ... main does its own thing; both pins are handled in the one child ...

$h->disarm(2);    # stop servicing pin 2 (the child keeps running for pin 0)
$h->arm(2);       # resume it
$h->stop;         # tear down and reap the single child

sub on_button { ... }
sub on_sensor { ... }
```

The handle has the same `stop`/`pid`/`running` as scenario 8, plus
`arm($pin)`/`disarm($pin)`. Arming a pin that wasn't in the initial list croaks.

---

## Non-threaded Perl

The interrupt API needs nothing special. Everything in this doc — including
background handling via `auto_dispatch_interrupts` (7) or `fork` (8) — works on a Perl built **without**
ithreads. "Background" does not imply `use threads`; only the ithread variants in
`threads-examples.md` do.

## Anti-patterns to avoid

- **Forgetting to service the fd in cooperative mode.** If you never call
  `dispatch_interrupts()`/`wait_interrupts()`, callbacks never fire — there is no
  background process doing it for you unless you set one up (scenarios 7-8).
- **Forking *after* arming interrupts.** wiringPi's ISR pthreads don't survive
  `fork`, and a mutex held at fork time is left locked in the child. Fork first,
  then arm in the child that dispatches.
- **Sharing one device fd across forked processes.** An i2c/spi/serial handle
  should be used by a single process; two processes transacting on it interleave.
- **Two processes reading the same interrupt fd.** After a `fork`, exactly one
  context should drain the library's interrupt fd (scenario 9: the child). A
  second reader steals records from the first.
- **Relying on `auto_dispatch_interrupts` during a long non-yielding C/XS call.** Its
  callbacks fire at Perl's safe points (op boundaries, interrupted sleeps); a long
  C call that never yields delays them. Use `background_interrupt` (separate
  process) if a handler must fire during such work.
- **Enabling `auto_dispatch_interrupts` when your program already uses `SIGIO`/`O_ASYNC`.**
  It claims that signal; pick one owner, or choose a different delivery signal
  (eg `auto_dispatch_interrupts(1, 'USR1')`).
- **Busy-spinning a `do_work + poll` loop.** A `while (1) { do_other_work();
  dispatch_interrupts() }` (scenario 1) or `can_read(0)` drain (scenario 9) burns
  100% CPU if the work returns instantly. Pace it, sleep, or select with a timeout.

## API reference for these examples

| Call | Purpose | Returns † |
|---|---|---|
| `setup()` / `setup_gpio()` | init (wiringPi / BCM numbering); once, in main | int status (`0` = ok) |
| `pin_mode($pin, $mode)` | `0`=INPUT, `1`=OUTPUT | — |
| `write_pin($pin, $val)` / `read_pin($pin)` | pin I/O | — / pin level (`0`/`1`) |
| `set_interrupt($pin, $edge, $cb [, $debounce_us] [, \%opts])` | arm; `$cb->($edge, $ts_us)`. `\%opts`: `{auto_dispatch=>1\|$sig}` | true on success |
| `background_interrupt($pin, $edge, $cb [, $debounce_us] [, \%opts])` | run the handler in a forked child. `\%opts`: `{results=>1}` | handle `$h` (`stop` / `pid` / `running` / `read` / `fh`) |
| `background_interrupts([$pin,$edge,$cb[,$deb]], ...)` | one shared child for many pins | handle `$h` (+ `arm($pin)` / `disarm($pin)`) |
| `auto_dispatch_interrupts($bool [, $signal])` | fire callbacks automatically in-process (default `SIGIO`; named signal via `F_SETSIG`); no loop | true |
| `wait_interrupts($timeout_ms)` | block until event/timeout, then dispatch | count dispatched (`0` on timeout) |
| `run_interrupt_loop($timeout_ms [, $max])` / `stop_interrupt_loop()` | built-in blocking dispatch loop; stop via the flag or `$max` | count dispatched |
| `dispatch_interrupts()` | non-blocking: dispatch pending events | count dispatched |
| `interrupt_fd()` | read fd for `select`/event loops | int fd |
| `interrupt_dropped()` | count of events dropped on a full pipe | int count |
| `interrupt_buffer([$bytes])` | get/set the event-queue (pipe) capacity | int size (bytes) |
| `last_interrupt()` | full status of the most recent dispatched event | hashref `{pin, pin_bcm, edge, status, ts_us}` or `undef` |
| `stop_interrupt($pin)` / `stop_interrupts()` | teardown | — |
| `INT_EDGE_FALLING` (1) / `INT_EDGE_RISING` (2) / `INT_EDGE_BOTH` (3) | edge constants | int |

> See L<WiringPi::API> POD for the authoritative per-function documentation. For
> background workers, shared state, and periodic events, see `worker()` in
> `threads-examples.md`.

## Code flow — Perl → API.pm → API.xs → wiringPi

Worked numbers use `setup()` (wiringPi numbering) where **wpi pin 0 = BCM 17**,
showing why `userdata` (the caller's pin) is the dispatch key, not
`wfiStatus.pinBCM`.

### Arming — `set_interrupt(0, 2, \&cb)`

```text
1 Perl (user)     set_interrupt(0, 2, \&cb);
2 Perl (API.pm)   $_interrupt_cb{0} = \&cb;  _arm_interrupt(0, 2, 0);     # callback stays in Perl
3 API.xs          _arm_interrupt(pin=0,edge=2,deb=0):
                    (lazily create the pipe, both ends O_NONBLOCK)
                    wiringPiISR2(0, 2, isr2_writer, 0, (void*)0);          # userdata = caller pin 0
4 wiringPi.c      wiringPiISR2 -> wiringPiISRInternal: ToBCMPin 0->17;
                    isrFunctionsV2[17]=isr2_writer; isrUserdata[17]=(void*)0;
                    pthread_create(&isrThreads[17], …, interruptHandlerV2);
```

### Firing — a rising edge on GPIO 17  (NO Perl on this path)

```text
4 wiringPi.c      interruptHandlerV2 (BCM-17 thread): wfiStatus={pinBCM=17,edge=2,ts};
                    isrFunctionsV2[17](wfiStatus, isrUserdata[17]);        # -> isr2_writer(.., (void*)0)
3 API.xs          isr2_writer(wfiStatus, ud):
                    rec = { .pin=(int)(intptr_t)ud /*=0, the caller pin*/, .pin_bcm=17, .edge=2,
                            .status=wfiStatus.statusOK, .ts_us=wfiStatus.timeStamp_us };
                    if (write(pipe_wr, &rec, sizeof rec) != sizeof rec) dropped++;   # 24-byte record
                    # returns immediately; interpreter never touched
```

### Dispatch — when Perl services the fd (main thread, or a fork child)

```text
2 Perl (API.pm)   wait_interrupts($ms): select(interrupt_fd) -> dispatch_interrupts():
                    while (sysread interrupt_fd, $buf, 24) {
                        ($pin,$pin_bcm,$edge,$status,$ts) = unpack "i I i i q", $buf;
                        $_last_interrupt = {...}; $_interrupt_cb{$pin}->($edge,$ts);   # $pin==0 -> matches
                    }
1 Perl (user)     &cb runs in the consuming interpreter, in normal context (G_EVAL-able).
```

Keying on `userdata` (0) — not `pinBCM` (17) — is what makes `$_interrupt_cb{0}`
match under `setup()`; under `setup_gpio()` they'd coincide. The wiringPi ISR
thread only ever does a `write()` of the fixed 24-byte record; it never enters
the Perl interpreter, which is why this works on any Perl without locking.
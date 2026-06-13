# WiringPi::API — integrated example: main-loop pin handling, background interrupts, and a worker messenger

> **Status — runs as written** against `WiringPi::API` 3.18+ on a Pi with
> wiringPi 3.18+. This example combines the three concurrency mechanisms the
> distribution provides — a polled pin handled in `main`, interrupt callbacks
> firing in the background, and a forked `worker()` streaming messages back to
> the user — in one coherent program: a single-head traffic-signal controller.
> The mechanisms are documented individually in `docs/interrupt-examples.md`
> and `docs/threads-examples.md`; this file shows them composed.

## What it demonstrates

| Requirement | Mechanism used |
|---|---|
| Read a pin and handle it in `main` | The pedestrian crossing button is polled with `read_pin` in the main loop; the walk phase is handled right there in `main` |
| Two interrupts driving the signal in the background | `set_interrupt` × 2 (a side-road vehicle detector + a night-flash switch) under `auto_dispatch_interrupts(1)` — the callbacks fire on their own, with no dispatch loop, and drive the single signal head |
| Send messages to the user via a worker | A fork-based `worker()` monitors a lamp-fault input on its own pin and streams a status line every 5 s over the `results` channel; `main` drains it and prints to the operator |

## The hardware

The signal head is three real LEDs — red, yellow, and green — wired one per
pin through a current-limiting resistor to ground. All pin numbers are BCM
(`setup_gpio()`).

| BCM | Dir | Role |
|---|---|---|
| 17 / 27 / 22 | out | Signal head: red / yellow / green LED |
| 23 | in, pull-down | Side-road vehicle detector — interrupt, rising edge, 5 ms debounce |
| 24 | in, pull-down | Night-flash switch — interrupt, both edges |
| 26 | in, pull-up | Pedestrian button (active-low) — polled in `main` |
| 16 | in, pull-up | Lamp-fault contact (active-low) — owned by the worker |

The head rests on **green** (the major road flows). A side-road vehicle
detector or the pedestrian button demands a stop: green → yellow → red, then
back to green. The night-flash switch overrides everything with a flashing
yellow caution.

## The program

```perl
#!/usr/bin/env perl

use warnings;
use strict;
use feature 'say';

use WiringPi::API qw(
    setup_gpio pin_mode pull_up_down read_pin write_pin
    set_interrupt auto_dispatch_interrupts stop_interrupts worker
    INPUT OUTPUT HIGH LOW PUD_UP PUD_DOWN
    INT_EDGE_RISING INT_EDGE_BOTH
);

use constant {
    PEDESTRIAN_BUTTON_PIN => 26,  # Pedestrian crossing button, polled in main
    VEHICLE_SENSOR_PIN    => 23,  # Side-road vehicle detector
    NIGHT_FLASH_PIN       => 24,  # Night-mode flash switch
    LAMP_FAULT_PIN        => 16,  # Lamp-fault input; owned by the worker

    YELLOW_PHASE_SECONDS => 3,
    RED_PHASE_SECONDS    => 5,
    WALK_PHASE_SECONDS   => 8,
};

# One signal head - three real LEDs
my %signal_head_pins = (red => 17, yellow => 27, green => 22);

# Which aspect the head shows in a given controller state
my %aspect_for_state = (
    GREEN  => 'green',
    YELLOW => 'yellow',
    RED    => 'red',
    WALK   => 'red',
    FLASH  => 'flash',   # the flasher owns the lamps in this state
);

my $controller_state   = 'GREEN';
my $state_expires_at   = 0;   # Epoch when a timed state ends (0 = steady)
my $walk_phase_pending = 0;
my $controller_running = 1;

$SIG{INT} = $SIG{TERM} = sub { $controller_running = 0 };

# All GPIO configuration happens here - once, in main, before any fork

setup_gpio();

pin_mode($signal_head_pins{$_}, OUTPUT) for ('red', 'yellow', 'green');

pin_mode($_, INPUT) for (
    PEDESTRIAN_BUTTON_PIN, VEHICLE_SENSOR_PIN, NIGHT_FLASH_PIN, LAMP_FAULT_PIN
);

pull_up_down(PEDESTRIAN_BUTTON_PIN, PUD_UP);  # Button shorts the pin to ground
pull_up_down(LAMP_FAULT_PIN, PUD_UP);         # Fault contact shorts to ground

pull_up_down($_, PUD_DOWN) for (VEHICLE_SENSOR_PIN, NIGHT_FLASH_PIN);

apply_state();

# The worker forks HERE, while no interrupt is armed yet. It owns
# LAMP_FAULT_PIN and nothing else; every status line it returns is shipped
# back to main on the results channel

my $lamp_monitor = worker(sub {
    my $lamp_status =
        read_pin(LAMP_FAULT_PIN) == LOW ? 'LAMP FAULT' : 'lamps ok';
    return sprintf "%s, cpu %s", $lamp_status, cpu_temp();
}, { interval => 5, results => 1 });

# Now arm the two traffic interrupts; with auto dispatch enabled they fire
# on their own from here on - no dispatch loop, and they share main's state

auto_dispatch_interrupts(1);

set_interrupt(
    VEHICLE_SENSOR_PIN, INT_EDGE_RISING, sub { request_red() }, 5000
);

set_interrupt(NIGHT_FLASH_PIN, INT_EDGE_BOTH, sub {
    my ($edge) = @_;

    # Switch closed: flashing-yellow caution, held until the switch opens
    $edge == INT_EDGE_RISING ? enter_night_flash() : enter('GREEN', 0);
});

# Main: poll the button, finish timed phases, relay the monitor's messages

say "controller up - state $controller_state";

my $previous_button_state = HIGH;

while ($controller_running) {
    my $button_state = read_pin(PEDESTRIAN_BUTTON_PIN);
    walk_request() if $button_state == LOW && $previous_button_state == HIGH;
    $previous_button_state = $button_state;

    tick();

    while (defined(my $status_message = $lamp_monitor->read)) {
        say "[monitor] $status_message";
    }

    # The interrupt callbacks fire during this sleep (and between ops)
    select(undef, undef, undef, 0.25);
}

# Teardown: silence the interrupts, reap the worker, fail safe to all-red

stop_interrupts();
$lamp_monitor->stop;

write_pin($signal_head_pins{red}, HIGH);
write_pin($signal_head_pins{$_}, LOW) for ('yellow', 'green');

say "controller down - head left red";

sub apply_state {
    return if $controller_state eq 'FLASH';   # the flasher owns the lamps here

    my $lit = $aspect_for_state{$controller_state};

    for my $color ('red', 'yellow', 'green') {
        write_pin($signal_head_pins{$color}, $lit eq $color ? HIGH : LOW);
    }
}
sub flash_tick {
    # Caution flash: blink the yellow lamp at 1 Hz, the others dark
    my $lamp_on = time() % 2 == 0;
    write_pin($signal_head_pins{red}, LOW);
    write_pin($signal_head_pins{green}, LOW);
    write_pin($signal_head_pins{yellow}, $lamp_on ? HIGH : LOW);
}
sub cpu_temp {
    open my $fh, '<', '/sys/class/thermal/thermal_zone0/temp' or return 'n/a';
    chomp(my $millidegrees = <$fh>);
    close $fh;
    return sprintf '%.1fC', $millidegrees / 1000;
}
sub enter {
    my ($new_state, $duration_seconds) = @_;

    $controller_state = $new_state;
    $state_expires_at = $duration_seconds ? time() + $duration_seconds : 0;
    apply_state();
    say "state -> $controller_state";
}
sub enter_night_flash {
    $walk_phase_pending = 0;
    enter('FLASH', 0);
}
sub request_red {
    # A side-road vehicle is waiting; bring the head to red. Ignore the demand
    # while flashing or if the head is not currently resting on green
    return if $controller_state ne 'GREEN';

    # tick() hands the head to red when this yellow expires
    enter('YELLOW', YELLOW_PHASE_SECONDS);
}
sub tick {
    if ($controller_state eq 'FLASH') {
        flash_tick();
        return;
    }
    return if ! $state_expires_at || time() < $state_expires_at;

    if ($controller_state eq 'YELLOW') {
        $walk_phase_pending
            ? enter('WALK', WALK_PHASE_SECONDS)
            : enter('RED',  RED_PHASE_SECONDS);
        $walk_phase_pending = 0;
        return;
    }

    # A red or walk phase has expired; release the head back to green
    enter('GREEN', 0);
}
sub walk_request {
    return if $controller_state eq 'FLASH'
        || $controller_state eq 'WALK'
        || $walk_phase_pending;

    say "walk requested";
    $walk_phase_pending = 1;

    if ($controller_state eq 'GREEN') {
        enter('YELLOW', YELLOW_PHASE_SECONDS);
    }

    # If a yellow is already running (a vehicle demand), the pending walk is
    # picked up by tick() when that yellow expires
}
```

## Why it is built this way

**The two interrupts run in-process, not in a forked child.** The handlers
must mutate the controller state (`$controller_state`,
`$walk_phase_pending`) that `main` also reads and writes — so
`background_interrupt`/ `background_interrupts` (separate process, separate
memory) would be the wrong tool. `auto_dispatch_interrupts(1)` gives the same
hands-off behaviour in-process: callbacks fire at Perl's safe points (between
ops, and during the main loop's `select` sleep) in *main's own interpreter*, so
they share its variables with **no locking** and no dispatch loop. The
trade-off — a long non-yielding C/XS call would defer them — doesn't apply
here; the main loop never blocks longer than 250 ms. See
`docs/interrupt-examples.md`, scenario 7.

**The worker forks before any interrupt is armed.** wiringPi's ISR pthreads do
not survive a `fork`, and an ISR mutex held at fork time stays locked in the
child (`docs/interrupt-examples.md`, anti-patterns). Ordering the program
*configure pins → fork worker → arm interrupts* keeps the worker's fork clean
without any special handling.

**Pin ownership follows the setup-once-in-main contract.** Every `pin_mode`/
`pull_up_down` happens once, in `main`, before the fork. Afterwards each
context does steady-state I/O on distinct pins only: the worker reads
`LAMP_FAULT_PIN` and nothing else; `main` (including the interrupt callbacks,
which run in main's interpreter) owns the three head LEDs and the button. See
`docs/threads-examples.md`, "The setup-once-in-main contract".

**Messages reach the user through the worker's `results` channel.** A fork
worker cannot touch main's variables, so it composes its message from what it
owns — the fault input and `/sys` — and *returns* it; `{ results => 1 }`
length-frames every return value back over a pipe. `main` drains with the
non-blocking `$lamp_monitor->read` every pass, so the channel never backs up,
and each status line is far below the `PIPE_BUF` (4096-byte) frame limit on
the drain channels.

**Timed phases complete in `main`, not in the callbacks.** A yellow must hold
for `YELLOW_PHASE_SECONDS`, but sleeping inside an interrupt callback would
stall the whole program (callbacks run inline in main's interpreter). So the
vehicle-detector callback only *decides* — sets the new state and its expiry —
and `tick()` in the main loop *completes* the transition when the deadline
passes. The flashing-yellow caution is driven the same way: the night-switch
callback only flips the controller into the `FLASH` state, and `tick()` blinks
the lamp each pass. Callbacks stay short; nothing blocks.

**The detector is debounced in the kernel.** The 4th argument to
`set_interrupt` (5000 µs) is applied as a GPIO-v2 line attribute, so contact
bounce is dropped before it ever reaches the event pipe — one event per
vehicle. The night switch is a maintained contact read on both edges, so it
needs no debounce window. See `docs/interrupt-examples.md`, scenario 5.

**The main loop is paced, not spinning.** `select(undef, undef, undef, 0.25)`
keeps button latency at ≤ 250 ms while idling near 0 % CPU — and the
auto-dispatched callbacks fire *during* that sleep, so light changes are not
delayed by the pacing.

## Run it

```sh
perl traffic.pl
# Trigger the detector / flip the night switch / press the button and watch
# the state lines; every 5 seconds the monitor worker reports lamp status and
# CPU temp. Ctrl-C exits: interrupts released, worker reaped, head left red.
```

## See also

- `docs/interrupt-examples.md` — every interrupt mechanism, individually
- `docs/threads-examples.md` — `worker()` and the concurrency contract
- `INT.md` in the `RPi::WiringPi` distribution — this same program written
  against the object-oriented layer
```

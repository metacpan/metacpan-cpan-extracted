## Name

Time::Nanos - Nanosecond time resolution via clock\_gettime().

## Synopsis

```perl
use Time::Nanos;

my $nanoseconds             = nanos();
my $microseconds            = micros();
my $milliseconds            = millis();

my ($seconds, $nanoseconds) = nanos(1);
```

## Functions

### nanos

```perl
my $ns = nanos();
my ($sec, $nsec) = nanos(1);
```

Returns nanoseconds. In scalar context returns total nanoseconds. With optional
second param returns a list of (seconds, nanoseconds) instead.

Accepts optional arguments: `nanos($list, $clock)` where `$list` selects list
context and `$clock` is `'monotonic'` (default) or `'realtime'`.

### micros

```perl
my $us = micros();
```

Returns microseconds as an integer. Accepts optional clock argument:
`micros(undef, 'realtime')`.

### millis

```perl
my $ms = millis();
```

Returns milliseconds as an integer. Accepts optional clock argument:
`millis(undef, 'realtime')`.

## Description

This module provides high-resolution time via `clock_gettime()`. The clock
reference epoch is unspecified, so a single reading is not in itself a useful
measurement of wall-clock time. These values are only meaningful when compared
against each other to measure elapsed time.

The default clock is `CLOCK_MONOTONIC`. An optional argument selects the
clock: `'monotonic'` or `'realtime'`. `'realtime'` measures the system's
uptime but is susceptible to clock skew from user clock changes, NTP updates,
etc. When using `'realtime'`, it is possible (but rare) to observe a negative
duration when comparing two successive calls.

## Usage

```
nanos()                       # CLOCK_MONOTONIC, nanoseconds
micros()                      # CLOCK_MONOTONIC, microseconds
millis()                      # CLOCK_MONOTONIC, milliseconds

nanos(1)                      # CLOCK_MONOTONIC, list (sec, nsec)
nanos(undef, 'realtime')      # CLOCK_REALTIME, nanoseconds
nanos(1, 'realtime')          # CLOCK_REALTIME, list (sec, nsec)

micros(undef, 'realtime')     # CLOCK_REALTIME, microseconds
millis(undef, 'realtime')     # CLOCK_REALTIME, milliseconds
```

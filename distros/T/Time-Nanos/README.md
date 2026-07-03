## Name

Time::Nanos - Nanosecond time resolution via clock\_gettime().

## Synopsis

```perl
use Time::Nanos;

my $nanoseconds  = nanos();
my $microseconds = micros();
my $milliseconds = millis();

my ($seconds, $nanoseconds) = nanos(1);
```

## Variables

### $CLOCK

```
$Time::Nanos::CLOCK = 'realtime';
```

Controls which clock source the functions use. Defaults to `'realtime'`.
Valid values: `'monotonic'` or `'realtime'`.

## Functions

### nanos()

```perl
my $ns = nanos();
my ($sec, $nsec) = nanos(1);
```

Returns nanoseconds. In scalar context returns total nanoseconds. With a true
argument returns a list of (seconds, nanoseconds) instead.

### micros()

```perl
my $us = micros();
my ($sec, $usec) = micros(1);
```

Returns microseconds as an integer. In scalar context returns total
microseconds. With a true argument returns a list of (seconds, microseconds)
instead.

### millis()

```perl
my $ms = millis();
my ($sec, $msec) = millis(1);
```

Returns milliseconds as an integer. In scalar context returns total
milliseconds. With a true argument returns a list of (seconds, milliseconds)
instead.

## Description

This module provides high-resolution time via `clock_gettime()`.
The default clock is `CLOCK_REALTIME`. `'realtime'` uses the system clock,
which measures time since the Unix epoch. This is susceptible to clock skew from
NTP updates, user clock changes, etc.  When using `'realtime'`, it is possible
(but rare) to observe a negative duration when comparing two successive calls.

When using `'monotonic'` the clock reference epoch is unspecified, so a single
reading is not in itself a useful measurement of time. These values are only
meaningful when compared against each other to measure elapsed time.

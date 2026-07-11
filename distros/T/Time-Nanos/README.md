## Name

Time::Nanos - Nanosecond time resolution via clock\_gettime().

## Synopsis

```perl
use Time::Nanos;

my $nanoseconds  = nanos();
my $microseconds = micros();
my $milliseconds = millis();

my ($seconds, $nanoseconds)  = nanos(1);
my ($seconds, $microseconds) = micros(1);
my ($seconds, $milliseconds) = millis(1);
```

## Functions

### nanos()

```perl
my $ns = nanos();
my ($sec, $nsec) = nanos(1);
```

Returns the current time as an integer number of nanoseconds. With a true
argument, returns a list of (seconds, nanoseconds) instead.

### micros()

```perl
my $us = micros();
my ($sec, $usec) = micros(1);
```

Returns the current time as an integer number of microseconds. With a true
argument, returns a list of (seconds, microseconds) instead.

### millis()

```perl
my $ms = millis();
my ($sec, $msec) = millis(1);
```

Returns the current time as an integer number of milliseconds. With a true
argument, returns a list of (seconds, milliseconds) instead.

### Time::Nanos::clock\_source()

```
Time::Nanos::clock_source('monotonic');
```

Selects which clock source the functions use. Defaults to `'realtime'`.
Valid values: `'realtime'` or `'monotonic'`.
`clock_source()` is not exported, so it must be called fully qualified.

## Description

This module provides high-resolution time via `clock_gettime()`.
The default clock is `CLOCK_REALTIME`. `'realtime'` uses the system clock,
which measures time since the Unix epoch. This is susceptible to clock skew from
NTP updates, user clock changes, etc.  When using `'realtime'`, it is possible
(but rare) to observe a negative duration when comparing two successive calls.

When using `'monotonic'` the clock reference epoch is unspecified, so a single
reading is not in itself a useful measurement of time. These values are only
meaningful when compared against each other to measure elapsed time.

On 32-bit Perl builds the nanosecond granularity is around 256 ns rather than
an exact value. The `(seconds, fraction)` array forms remain usable.

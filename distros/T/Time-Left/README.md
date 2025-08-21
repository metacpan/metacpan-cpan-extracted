# Time::Left

[![CPAN version](https://badge.fury.io/pl/Time-Left.svg)](https://metacpan.org/pod/Time::Left)
[![License](https://img.shields.io/cpan/l/Time-Left)](https://metacpan.org/pod/Time::Left)

Simple Perl module for tracking time limits or deadlines.

## Synopsis

```perl
use Time::Left qw(time_left);

# Progress indicator with time limit.
local $! = 1;
print "Working ...";
my $timer = time_left("10s");
until (done() or $timer->expired) {
    Time::HiRes::sleep(0.25);
    print ".";
}
die " timed out.\n"
    unless done();
print " done.\n";
```

## Key Features

- **Duration parsing** - Accepts strings like "5m", "2h", "30s"
- **Monotonic timing** - Uses CLOCK_MONOTONIC when available to avoid clock skew issues
- **Select-compatible** - Returns undef for indefinite timers, perfect for select() timeouts
- **Overloading** - Boolean and string contexts work intuitively
- **Simple API** - Just 6 methods covering all use cases

## Installation

```bash
cpanm Time::Left
```

## Basic Usage

### Creating Timers

```perl
use Time::Left qw(time_left to_seconds);

# From duration strings
my $timer = time_left("1m");   # 60 seconds
my $timer = time_left("2.5h"); # 2.5 hours

# From seconds
my $timer = Time::Left->new(60); # 60 seconds

# Indefinite (no timeout)
my $timer = time_left(undef);
```

### Checking Status

```perl
my $sec = $timer->remaining;   # Seconds left (or undef if indefinite)
my $active = $timer->active;   # True if time remains
my $expired = $timer->expired; # True if time is up

# Boolean context uses active/expired
while ($timer) {
    # Still time left
}

if (!$timer) {
    # Timer expired
}
```

### Common Patterns

**Time-limited socket read:**

```perl
if (IO::Select->new($socket)->can_read($timer->remaining)) {
    $socket->recv($buffer, 1024);
    # Process data...
}
```

**Conditional timeout setup:**

```perl
# Set up alarm if timer is limited
Time::HiRes::alarm($timer->remaining)
    if $timer->is_limited;
```

## API Quick Reference

### Functions

- `$s = to_seconds($duration)` - Convert duration string to seconds
- `$t = time_left($duration)` - Create a Time::Left object

### Methods

- `$t = $class->new($seconds)` - Constructor (seconds/undef only, no parsing)
- `$s = $t->remaining` - Get seconds remaining (undef if indefinite)
- `$bool = $t->active` - Check if timer has time left
- `$bool = $t->expired` - Check if timer has run out
- `$bool = $t->is_limited` - Check if timer has a limit (not indefinite)
- `$t->abort` - Expire the timer immediately

## Requirements

- Perl 5.10+
- Time::HiRes
- Scalar::Util

## License

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

## Author

Brett Watson

## See Also

- [Time::HiRes](https://metacpan.org/pod/Time::HiRes) - High resolution time functions
- [IO::Select](https://metacpan.org/pod/IO::Select) - OO interface to the "select" system call

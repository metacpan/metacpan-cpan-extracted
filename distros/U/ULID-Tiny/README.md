## Name

ULID::Tiny - A lightweight ULID (Universally Unique Lexicographically Sortable Identifier) generator

## Synopsis

```perl
use ULID::Tiny qw(ulid ulid_date);

# Generate a new ULID
my $id = ulid(); # e.g. "01ARZ3NDEKTSV4RRFFQ69G5FAV"

# Generate a ULID with a specific timestamp (milliseconds since epoch)
my $id = ulid(time => 1234567890000);

# Extract the timestamp from a ULID (returns milliseconds since epoch)
my $ms = ulid_date($id);

# Generate a ULID in raw 16-byte binary form
my $bytes = ulid(binary => 1);
```

## Description

ULID::Tiny is a minimal, pure Perl, dependency-light module for generating
ULIDs.

https://github.com/ulid/spec

A ULID is a 128-bit identifier consisting of:

- 48-bit millisecond timestamp (first 10 characters)
- 80-bit cryptographic randomness (last 16 characters)

Key properties:

- Lexicographically sortable
- Canonically encoded as a 26 character string
- Monotonically increasing within the same millisecond

## Methods

- **ulid(%opts)**

    Generate a new ULID string. Options:

    - `time` - Specify timestamp in milliseconds. Defaults to current time.
    - `binary` - Returns the raw 16-byte binary ULID instead of an alpha-numeric string.

- **ulid\_date($ulid\_string)**

    Extract the timestamp from a ULID string. Returns the number of milliseconds
    since the Unix epoch.

## Randomness

The module attempts to use the best available entropy source:

- `getrandom(2)` syscall on Linux
- `/dev/urandom`
- Perl's `rand()` as a last resort

## Version

1.0.0

## License

This module is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

# gmd5

A Pure Perl implementation of the MD5 hashing algorithm, compliant with RFC 1321.

## Synopsis

```perl
use gmd5 qw(md5 md5_hex);

# Direct hash
my $binary = md5("Hello World");
my $hex = md5_hex("Hello World");

# Streaming hash
my $md5 = gmd5->new;
$md5->add("Hello ");
$md5->add("World");
$hex = $md5->hexdigest;
```

## Description

`gmd5` provides a fast and lightweight `MD5` hashing library in Pure Perl, with no `XS` or `C` dependencies. It supports both one-shot hashing and streaming for large datasets, optimized with efficient buffering and bitwise operations.

## Installation

To install from CPAN:
```
cpan gmd5
```
Or manually:
```
perl Makefile.PL
make
make test
make install
```

## Dependencies

- Core Perl modules: `strict`, `warnings`, `Exporter`
- Optional: `Time::HiRes` (for profiling)
- Testing: `Test::More`

## Testing

Run the test suite:
```
prove -v ./
```

## Author

OnEhIppY, Domero Software <domerosoftware@gmail.com>

## License

This module is released under the Perl 5 license.

## See Also

[RFC 1321](https://www.ietf.org/rfc/rfc1321.txt) - The MD5 Message-Digest Algorithm
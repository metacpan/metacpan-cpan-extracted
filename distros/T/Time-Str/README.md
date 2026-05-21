# Time::Str

Parse and format date/time strings in multiple standard formats.

```perl
use Time::Str qw(str2time str2date time2str);

# Parse to Unix timestamp
my $time = str2time('2024-12-24T15:30:45Z');
# 1735052445

my $time = str2time('Mon, 24 Dec 2012 15:30:45 +0100', format => 'RFC2822');

# Parse to components
my %date = str2date('2024-12-24T15:30:45.500+01:00');
# (year => 2024, month => 12, day => 24, hour => 15,
#  minute => 30, second => 45, nanosecond => 500000000,
#  tz_offset => 60)

# Format Unix timestamp
my $str = time2str(1735052445);
# '2024-12-24T15:30:45Z'

my $str = time2str(1735052445, format => 'RFC2822', offset => 60);
# 'Tue, 24 Dec 2024 16:30:45 +0100'
```

## Supported Formats

### Profiles of ISO 8601

| Format                                                          | Example                      |
|-----------------------------------------------------------------|------------------------------|
| [ISO8601](https://metacpan.org/pod/Time::Str#ISO8601)           | `20241224T153045.500+0100`   |
| [RFC4287](https://metacpan.org/pod/Time::Str#RFC4287)           | `2024-12-24T15:30:45Z`       |
| [W3CDTF](https://metacpan.org/pod/Time::Str#W3CDTF)             | `2024-12-24T15:30:45+01:00`  |
| [RFC5545](https://metacpan.org/pod/Time::Str#RFC5545)           | `20241224T153045Z`           |

### Based on ISO 8601

| Format                                                          | Example                                   |
|-----------------------------------------------------------------|-------------------------------------------|
| [RFC3339](https://metacpan.org/pod/Time::Str#RFC3339)           | `2024-12-24 15:30:45+01:00`               |
| [RFC9557](https://metacpan.org/pod/Time::Str#RFC9557)           | `2024-12-24 15:30:45+01:00[Europe/Paris]` |
| [ISO9075](https://metacpan.org/pod/Time::Str#ISO9075)           | `2024-12-24 15:30:45 +01:00`              |
| [ASN1GT](https://metacpan.org/pod/Time::Str#ASN1GT)             | `20241224153045Z`                         |
| [ASN1UT](https://metacpan.org/pod/Time::Str#ASN1UT)             | `241224153045Z`                           |
| [RFC5280](https://metacpan.org/pod/Time::Str#RFC5280)           | `241224153045Z`                           |

### RFC / IMF / HTTP / IMAP

| Format                                                          | Example                              |
|-----------------------------------------------------------------|--------------------------------------|
| [RFC2822](https://metacpan.org/pod/Time::Str#RFC2822)           | `Tue, 24 Dec 2024 15:30:45 +0100`    |
| [RFC2616](https://metacpan.org/pod/Time::Str#RFC2616)           | `Tue, 24 Dec 2024 15:30:45 GMT`      |
| [RFC3501](https://metacpan.org/pod/Time::Str#RFC3501)           | `24-Dec-2024 15:30:45 +0100`         |

### Unix / C Library

| Format                                                          | Example                              |
|-----------------------------------------------------------------|--------------------------------------|
| [ANSIC](https://metacpan.org/pod/Time::Str#ANSIC)               | `Tue Dec 24 15:30:45 2024`           |
| [UnixDate](https://metacpan.org/pod/Time::Str#UnixDate)         | `Tue Dec 24 15:30:45 UTC 2024`       |
| [UnixStamp](https://metacpan.org/pod/Time::Str#UnixStamp)       | `Tue Dec 24 15:30:45.500 2024 UTC`   |
| [GitDate](https://metacpan.org/pod/Time::Str#GitDate)           | `Tue Dec 24 15:30:45 2024 +0100`     |
| [RubyDate](https://metacpan.org/pod/Time::Str#RubyDate)         | `Tue Dec 24 15:30:45 +0100 2024`     |

`UnixStamp` is a superset of `ANSIC`, `GitDate`, `RubyDate`, and `UnixDate`.

### Other

| Format                                                           | Example                              |
|------------------------------------------------------------------|--------------------------------------|
| [ECMAScript](https://metacpan.org/pod/Time::Str#ECMAScript)      | `Tue Dec 24 2024 15:30:45 GMT+0100`  |
| [CLF](https://metacpan.org/pod/Time::Str#CLF)                    | `24/Dec/2024:15:30:45 +0100`         |
| [DateTime](https://metacpan.org/pod/Time::Str#DateTime)          | *(permissive, multi-format parser)*  |

`DateTime` can parse `ISO8601` (extended format), `RFC3339`, `RFC9557`,
`RFC4287`, `W3CDTF`, `ISO9075`, `RFC2822`, `RFC2616`, `RFC3501`, and
`ECMAScript` formats.

Each format is implemented according to its specification. Optional fields
are optional. Constrained fields are validated. Day names, when present,
are verified against the actual date.

## The `DateTime` Format

The `DateTime` format is a permissive parser for real-world dates that does
not use heuristics. If it cannot parse the input unambiguously, it croaks.

```perl
str2date('Monday, 24th December 2024 at 3:30 PM UTC+01:00',
         format => 'DateTime');

str2date('2024-12-24T15:30:45+01:00[Europe/Stockholm]',
         format => 'DateTime');

str2date('24.XII.2024', format => 'DateTime');
```

Numeric dates must be in year-month-day order. Ordinal suffixes must match
the day number. Four-digit years are required.

See [DATETIME FORMAT PARSING](https://metacpan.org/pod/Time::Str#DATETIME-FORMAT-PARSING) in the documentation.

## Installation

```
cpanm Time::Str
```

Requires Perl 5.10.1 or later. Runtime dependencies are `Carp` and
`Exporter`, both core modules.

## Optional C/XS

The XS backend (C99) is loaded when a compiler is available; otherwise it
falls back to Pure Perl. The `TIME_STR_PP` environment variable forces the
Pure Perl path.

```perl
say Time::Str::IMPLEMENTATION;  # "XS" or "PP"
```

The XS backend includes native C parsers (generated by Ragel) for ASN.1 
GeneralizedTime, ECMAScript, ISO 8601, ISO 9075, RFC 2822, RFC 3339, 
RFC 4287, RFC 9557 and W3CDTF formats. When available, these are 
tried first; otherwise parsing falls back to the precompiled regexps from
`Time::Str::Regexp`. Both paths produce identical results.

## Related Modules

- [Time::Str::Regexp](https://metacpan.org/pod/Time::Str::Regexp) - Precompiled regexps with named captures for all formats
- [Time::Str::Token](https://metacpan.org/pod/Time::Str::Token) - Token parsers (month names, day names, timezone offsets)
- [Time::Str::Calendar](https://metacpan.org/pod/Time::Str::Calendar) - Gregorian calendar utilities (leap year, day-of-week, RDN conversion)

## Documentation

Full documentation is available on [MetaCPAN](https://metacpan.org/pod/Time::Str) or via `perldoc Time::Str` after installation.

## Standards

- [ISO 8601:2019](https://www.iso.org/obp/ui/#iso:std:iso:8601)
- [RFC 3339](https://datatracker.ietf.org/doc/html/rfc3339#section-5.6)
- [RFC 2822](https://datatracker.ietf.org/doc/html/rfc2822#section-3.3) / [RFC 5322](https://datatracker.ietf.org/doc/html/rfc5322#section-3.3)
- [RFC 2616](https://datatracker.ietf.org/doc/html/rfc2616#section-3.3) / [RFC 7231](https://datatracker.ietf.org/doc/html/rfc7231#section-7.1.1.1)
- [RFC 3501](https://datatracker.ietf.org/doc/html/rfc3501#section-2.3.3) / [RFC 9051](https://datatracker.ietf.org/doc/html/rfc9051#section-2.3.3)
- [RFC 4287](https://datatracker.ietf.org/doc/html/rfc4287#section-3.3)
- [RFC 5280](https://datatracker.ietf.org/doc/html/rfc5280#section-4.1.2.5)
- [RFC 5545](https://datatracker.ietf.org/doc/html/rfc5545#section-3.3.4)
- [RFC 9557](https://datatracker.ietf.org/doc/html/rfc9557)
- [ISO 9075](https://www.iso.org/standard/76583.html)
- [ITU-T X.680 / ISO/IEC 8824-1](https://www.itu.int/rec/T-REC-X.680-202102-I) (ASN.1)
- [W3C Date and Time Formats](https://www.w3.org/TR/NOTE-datetime)
- [ECMAScript Date.prototype.toString](https://tc39.es/ecma262/multipage/numbers-and-dates.html#sec-date.prototype.tostring)

## Author

Christian Hansen

## License

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

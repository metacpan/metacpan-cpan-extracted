[![Build Status](https://travis-ci.org/karupanerura/Time-Strptime.svg?branch=master)](https://travis-ci.org/karupanerura/Time-Strptime) [![Coverage Status](http://codecov.io/github/karupanerura/Time-Strptime/coverage.svg?branch=master)](https://codecov.io/github/karupanerura/Time-Strptime?branch=master) [![MetaCPAN Release](https://badge.fury.io/pl/Time-Strptime.svg)](https://metacpan.org/release/Time-Strptime)
# NAME

Time::Strptime - parse date and time string.

# SYNOPSIS

```perl
use Time::Strptime qw/strptime/;

# function
my ($epoch_f, $offset_f) = strptime('%Y-%m-%d %H:%M:%S', '2014-01-01 00:00:00');

# OO style
my $fmt = Time::Strptime::Format->new('%Y-%m-%d %H:%M:%S');
my ($epoch_o, $offset_o) = $fmt->parse('2014-01-01 00:00:00');
```

# DESCRIPTION

Time::Strptime is pure perl date and time string parser.
In other words, This is pure perl implementation a [strptime(3)](http://man.he.net/man3/strptime).

This module allows you to perform better by pre-compile the format by string.

benchmark:GMT(-0000) `tp=Time::Piece, ts=Time::Strptime, pt=POSIX::strptime(+Time::Local), tm=Time::Moment`

```
Benchmark: running pt, tm, tp, tp(cached), ts(cached) for at least 10 CPU seconds...
        pt: 11 wallclock secs (10.41 usr +  0.01 sys = 10.42 CPU) @ 297345.59/s (n=3098341)
        tm: 10 wallclock secs (10.17 usr +  0.01 sys = 10.18 CPU) @ 2481673.28/s (n=25263434)
        tp: 10 wallclock secs (10.52 usr +  0.01 sys = 10.53 CPU) @ 56390.98/s (n=593797)
tp(cached): 11 wallclock secs (10.53 usr +  0.01 sys = 10.54 CPU) @ 80838.24/s (n=852035)
ts(cached): 11 wallclock secs (10.60 usr +  0.01 sys = 10.61 CPU) @ 267686.15/s (n=2840150)
                Rate         tp tp(cached) ts(cached)         pt         tm
tp           56391/s         --       -30%       -79%       -81%       -98%
tp(cached)   80838/s        43%         --       -70%       -73%       -97%
ts(cached)  267686/s       375%       231%         --       -10%       -89%
pt          297346/s       427%       268%        11%         --       -88%
tm         2481673/s      4301%      2970%       827%       735%         --
```

benchmark:Asia/Tokyo(-0900) `tp=Time::Piece, ts=Time::Strptime, pt=POSIX::strptime(+Time::Local), tm=Time::Moment`

```
Benchmark: running pt, tm, tp, tp(cached), ts(cached) for at least 10 CPU seconds...
        pt: 10 wallclock secs (10.29 usr +  0.05 sys = 10.34 CPU) @ 147048.07/s (n=1520477)
        tm: 10 wallclock secs (10.00 usr +  0.03 sys = 10.03 CPU) @ 2344311.67/s (n=23513446)
        tp: 10 wallclock secs (10.15 usr +  0.02 sys = 10.17 CPU) @ 44565.39/s (n=453230)
tp(cached): 11 wallclock secs (10.41 usr +  0.06 sys = 10.47 CPU) @ 50136.29/s (n=524927)
ts(cached): 10 wallclock secs (10.73 usr +  0.07 sys = 10.80 CPU) @ 114871.48/s (n=1240612)
                Rate         tp tp(cached) ts(cached)         pt         tm
tp           44565/s         --       -11%       -61%       -70%       -98%
tp(cached)   50136/s        13%         --       -56%       -66%       -98%
ts(cached)  114871/s       158%       129%         --       -22%       -95%
pt          147048/s       230%       193%        28%         --       -94%
tm         2344312/s      5160%      4576%      1941%      1494%         --
```

# FAQ

## What's the difference between this module and other modules?

This module is fast and not require XS. but, support epoch `strptime` only.
[DateTime](https://metacpan.org/pod/DateTime) is very useful and stable! but, It is slow.
[Time::Piece](https://metacpan.org/pod/Time::Piece) is fast and useful! but, treatment of time zone is confusing. and, require XS.
[Time::Moment](https://metacpan.org/pod/Time::Moment) is very fast and useful! but, does not support `strptime`. and, require XS.

## How to specify a time zone?

Set time zone name or [DateTime::TimeZone](https://metacpan.org/pod/DateTime::TimeZone) object to `time_zone` option.

```perl
use Time::Strptime::Format;

my $format = Time::Strptime::Format->new('%Y-%m-%d %H:%M:%S', { time_zone => 'Asia/Tokyo' });
my ($epoch, $offset) = $format->parse('2014-01-01 00:00:00');
```

## How to specify a locale?

Set locale name object to `locale` option.

```perl
use Time::Strptime::Format;

my $format = Time::Strptime::Format->new('%Y-%m-%d %H:%M:%S', { locale => 'ja_JP' });
my ($epoch, $offset) = $format->parse('2014-01-01 00:00:00');
```

# LICENSE

Copyright (C) karupanerura.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

karupanerura <karupa@cpan.org>

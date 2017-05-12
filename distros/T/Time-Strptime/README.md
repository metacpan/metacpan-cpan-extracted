[![Build Status](https://travis-ci.org/karupanerura/Time-Strptime.svg?branch=master)](https://travis-ci.org/karupanerura/Time-Strptime) [![Coverage Status](http://codecov.io/github/karupanerura/Time-Strptime/coverage.svg?branch=master)](https://codecov.io/github/karupanerura/Time-Strptime?branch=master)
# NAME

Time::Strptime - parse date and time string.

# SYNOPSIS

    use Time::Strptime qw/strptime/;

    # function
    my ($epoch_f, $offset_f) = strptime('%Y-%m-%d %H:%M:%S', '2014-01-01 00:00:00');

    # OO style
    my $fmt = Time::Strptime::Format->new('%Y-%m-%d %H:%M:%S');
    my ($epoch_o, $offset_o) = $fmt->parse('2014-01-01 00:00:00');

# DESCRIPTION

Time::Strptime is pure perl date and time string parser.
In other words, This is pure perl implementation a [strptime(3)](http://man.he.net/man3/strptime).

This module allows you to perform better by pre-compile the format by string.

benchmark:GMT(-0000) `dt=DateTime, ts=Time::Strptime, tp=Time::Piece`

    Benchmark: running dt, dt(cached), pt, tm, tp, tp(cached), ts, ts(cached) for at least 10 CPU seconds...
            dt: 10 wallclock secs (10.62 usr +  0.03 sys = 10.65 CPU) @ 2189.58/s (n=23319)
    dt(cached): 11 wallclock secs (10.76 usr +  0.03 sys = 10.79 CPU) @ 7451.53/s (n=80402)
            tp: 11 wallclock secs (10.31 usr +  0.02 sys = 10.33 CPU) @ 120097.97/s (n=1240612)
    tp(cached): 10 wallclock secs (10.75 usr +  0.03 sys = 10.78 CPU) @ 271138.50/s (n=2922873)
            ts: 10 wallclock secs (10.30 usr +  0.02 sys = 10.32 CPU) @ 3626.74/s (n=37428)
    ts(cached): 11 wallclock secs (10.38 usr +  0.02 sys = 10.40 CPU) @ 168626.35/s (n=1753714)
                    Rate     dt     ts dt(cached)    tp ts(cached) tp(cached)
    dt            2190/s     --   -40%       -71%  -98%       -99%       -99%
    ts            3627/s    66%     --       -51%  -97%       -98%       -99%
    dt(cached)    7452/s   240%   105%         --  -94%       -96%       -97%
    tp          120098/s  5385%  3211%      1512%    --       -29%       -56%
    ts(cached)  168626/s  7601%  4550%      2163%   40%         --       -38%
    tp(cached)  271138/s 12283%  7376%      3539%  126%        61%         --

benchmark:Asia/Tokyo(-0900) `dt=DateTime, ts=Time::Strptime, tp=Time::Piece`

    Benchmark: running dt, dt(cached), pt, tm, tp, tp(cached), ts, ts(cached) for at least 10 CPU seconds...
            dt: 11 wallclock secs (10.87 usr +  0.02 sys = 10.89 CPU) @ 2075.76/s (n=22605)
    dt(cached): 11 wallclock secs (10.59 usr +  0.03 sys = 10.62 CPU) @ 6561.11/s (n=69679)
            tp: 12 wallclock secs (10.99 usr +  0.03 sys = 11.02 CPU) @ 120083.39/s (n=1323319)
    tp(cached): 10 wallclock secs (10.69 usr +  0.03 sys = 10.72 CPU) @ 270033.49/s (n=2894759)
            ts: 10 wallclock secs (10.73 usr +  0.03 sys = 10.76 CPU) @ 3179.37/s (n=34210)
    ts(cached): 12 wallclock secs (10.95 usr +  0.04 sys = 10.99 CPU) @ 79787.26/s (n=876862)
                    Rate     dt     ts dt(cached) ts(cached)    tp tp(cached)
    dt            2076/s     --   -35%       -68%       -97%  -98%       -99%
    ts            3179/s    53%     --       -52%       -96%  -97%       -99%
    dt(cached)    6561/s   216%   106%         --       -92%  -95%       -98%
    ts(cached)   79787/s  3744%  2410%      1116%         --  -34%       -70%
    tp          120083/s  5685%  3677%      1730%        51%    --       -56%
    tp(cached)  270033/s 12909%  8393%      4016%       238%  125%         --

# FAQ

## What's the difference between this module and other modules?

This module is fast and not require XS. but, support epoch `strptime` only.
[DateTime](https://metacpan.org/pod/DateTime) is very useful and stable! but, It is slow.
[Time::Piece](https://metacpan.org/pod/Time::Piece) is fast and useful! but, treatment of time zone is confusing. and, require XS.
[Time::Moment](https://metacpan.org/pod/Time::Moment) is very fast and useful! but, not support `strptime`. and, require XS.

## How to specify a time zone?

Set time zone name or [DateTime::TimeZone](https://metacpan.org/pod/DateTime::TimeZone) object to `time_zone` option.

    use Time::Strptime::Format;

    my $format = Time::Strptime::Format->new('%Y-%m-%d %H:%M:%S', { time_zone => 'Asia/Tokyo' });
    my ($epoch, $offset) = $format->parse('2014-01-01 00:00:00');

## How to specify a locale?

Set locale name object to `locale` option.

    use Time::Strptime::Format;

    my $format = Time::Strptime::Format->new('%Y-%m-%d %H:%M:%S', { locale => 'ja_JP' });
    my ($epoch, $offset) = $format->parse('2014-01-01 00:00:00');

# LICENSE

Copyright (C) karupanerura.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

karupanerura &lt;karupa@cpan.org>

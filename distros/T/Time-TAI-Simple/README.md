# Time::TAI::Simple

## NAME

Time::TAI::Simple - High resolution UNIX epoch time without leapseconds

## VERSION

1.11

## SYNOPSIS

```
        use Time::TAI::Simple;  # imports tai, tai10, and tai35

        # simple and fast procedural interfaces:

        $seconds_since_epoch = tai();
        $since_epoch_minus_ten = tai10();  # Probably what you want!
        $same_as_utc_time_for_now = tai35();

        ##############################################################
        # That's it!  YOU CAN LIKELY SKIP THE REST OF THIS SYNOPSIS! #
        ##############################################################

        # object-oriented interface:

        $tai = Time::TAI::Simple->new();

        $since_epoch_minus_ten = $tai->time();

        # download a more up-to-date leapsecond list, and recalculate time base:

        $tai->download_leapseconds() or die("cannot download leapseconds file");
        $tai->load_leapseconds();
        $tai->calculate_base();
        $since_epoch_minus_ten = $tai->time();

        # .. or simply download the leapsecond list as part of instantiation.
        # There is also an option for specifying where to put/find the list:

        $tai = Time::TAI::Simple->new(
            download_leapseconds => 1,
            leapseconds_pathname => '/etc/leap-seconds.list'
            );
        $since_epoch_minus_ten = $tai->time();

        # use mode parameter for TAI-00 time or TAI-35 time:
    
        $tai00 = Time::TAI::Simple->new(mode => 'tai');
        $seconds_since_epoch = $tai00->time();

        $tai35 = Time::TAI::Simple->new(mode => 'tai35');
        $same_as_utc_time_for_now = $tai35->time();

        # reduce processing overhead of instantiation, at the expense of 
        # some precision, by turning off fine-tuning step:

        $tai = Time::TAI::Simple->new(fine_tune => 0);
        $nowish = $tai->time();  # accurate to a few milliseconds, not microseconds.
```

## DESCRIPTION

The Time::TAI::Simple module provides a very simple way to obtain the
number of seconds elapsed since the beginning of the UNIX epoch (January
1st, 1970).

It differs from "Time::HiRes" in that it returns the actual number of
elapsed seconds, unmodified by the leap seconds introduced by the IETF
to make UTC time. These leap seconds can be problematic for automation
software, as they effectively make the system clock stand still for one
second every few years.

D. J. Bernstein describes other problems with leapseconds-adjusted time
in this short and sweet article: <http://cr.yp.to/proto/utctai.html>

Time::TAI::Simple provides a monotonically increasing count of
seconds, which means it will never stand still or leap forward or
backward due to system clock adjustments (such as from NTP), and avoids
leapseconds-related problems in general.

This module differs from "Time::TAI" and "Time::TAI::Now" in a few ways:
* it is much simpler to use,
* it uses the same epoch as perl's "time" builtin and "Time::HiRes", not the IETF's 1900-based epoch,
* it is a "best effort" implementation, accurate to a few microseconds,
* it depends on the local POSIX monotonic clock, not an external atomic clock.

## ABOUT TAI, TAI10, TAI35

This module provides three *modes* of TAI time:

tai is, very simply, the actual number of elapsed seconds since the epoch.

tai10 provides TAI-10 seconds, which is how TAI time has traditionally
been most commonly used, because when leapseconds were introduced in
1972, UTC was TAI minus 10 seconds.

It is the type of time provided by Arthur David Olson's popular time
library, and by the TAI patch currently proposed to the standard
zoneinfo implementation. When most people use TAI time, it is usually
TAI-10.

tai35 provides TAI-35 seconds, which makes it exactly equal to the
system clock time returned by "Time::HiRes::time()" at the time of this
writing. When the IETF next introduces a leapsecond, tai35 will be one
second ahead of the system clock time.

This mode is provided for use-cases where compatability with other TAI
time implementations is not required, and keeping the monotonically
increasing time relatively close to the system clock time is desirable.

It was decided to provide three types of TAI time instead of allowing an
arbitrary seconds offset parameter to make it easier for different
systems with different users and different initialization times to pick
compatible time modes.

## FULL DOCUMENTATION

The full documentation is available online at
<https://metacpan.org/search?q=Time::TAI::Simple>
or via local perldoc by running ```perldoc Time::TAI::Simple```

## AUTHOR

TTK Ciar, <ttk[at]ciar[dot]org>

## COPYRIGHT AND LICENSE

Copyright 2014-2017 by TTK Ciar

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.


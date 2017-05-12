# NAME

Time::TZOffset - Show timezone offset strings like +0900

# SYNOPSIS

    use Time::TZOffset qw/tzoffset/;

    my @localtime = localtime;
    say tzoffset(@localtime);

# DESCRIPTION

Time::TZOffset provides tzoffset function that determines timezone offset and shows strings
like `+0900`
This module implemented by XS, it's may be faster than other way to show timezone offset.
And also Time::TZOffset is more portable than using `POSIX::strftime` with `%z`.

# FUNCTION

- tzoffset(@localtime)

    Returns a timezone offset string like `+0900`

- tzoffset\_as\_seconds(@localtime)

    Returns a timezone offset seconds.

# BENCHMARK

I did this benchmark on linux.

    use Benchmark qw/:all/;
    use POSIX qw//;
    use Time::Local;
    use Time::TZOffset;
    
    cmpthese(timethese(-1, {
        'posix' => sub {
            POSIX::strftime('%z', @lt);
        },
        'time_local' => sub {
            my $sec = Time::Local::timegm(@lt) - Time::Local::timelocal(@lt);
            sprintf '%+03d%02u', $sec/60/60, $min/60%60;
        },
        'tzoffset' => sub {
            Time::TZOffset::tzoffset(@lt);
        },
    }));
    __END__
    Benchmark: running posix, time_local, tzoffset for at least 1 CPU seconds...
         posix:  1 wallclock secs ( 0.66 usr +  0.39 sys =  1.05 CPU) @ 179442.86/s (n=188415)
    time_local:  1 wallclock secs ( 1.12 usr +  0.16 sys =  1.28 CPU) @ 25846.09/s (n=33083)
      tzoffset:  1 wallclock secs ( 0.75 usr +  0.25 sys =  1.00 CPU) @ 286720.00/s (n=286720)
                   Rate time_local      posix   tzoffset
    time_local  25846/s         --       -86%       -91%
    posix      179443/s       594%         --       -37%
    tzoffset   286720/s      1009%        60%         --

# LICENSE

Copyright (C) Masahiro Nagano.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# POSIX::strftime::GNU LICENSE

This modules uses [POSIX::strftime::GNU](https://metacpan.org/pod/POSIX::strftime::GNU)'s code. [POSIX::strftime::GNU](https://metacpan.org/pod/POSIX::strftime::GNU)'s  license term is following:

Copyright (c) 2012-2014 Piotr Roszatycki <dexter@cpan.org>.

Format specification is based on strftime(3) manual page which is a part of
the Linux man-pages project.

This is free software; you can redistribute it and/or modify it under
the same terms as perl itself.

See [http://dev.perl.org/licenses/artistic.html](http://dev.perl.org/licenses/artistic.html)

# AUTHOR

Masahiro Nagano <kazeburo@gmail.com>

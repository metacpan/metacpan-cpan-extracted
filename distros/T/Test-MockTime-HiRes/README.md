[![Build Status](https://travis-ci.org/tarao/perl5-Test-MockTime-HiRes.svg?branch=master)](https://travis-ci.org/tarao/perl5-Test-MockTime-HiRes)
# NAME

Test::MockTime::HiRes - Replaces actual time with simulated high resolution time

# SYNOPSIS

    use Test::MockTime::HiRes qw(mock_time);

    my $now = time;
    mock_time {
        time;    # == $now;

        sleep 3; # returns immediately

        time;    # == $now + 3;

        usleep $microsecond;
    } $now;

# DESCRIPTION

`Test::MockTime::HiRes` is a [Time::HiRes](https://metacpan.org/pod/Time::HiRes) compatible version of
[Test::MockTime](https://metacpan.org/pod/Test::MockTime).  You can wait milliseconds in simulated time.

It also provides `mock_time` to restrict the effect of the simulation
in a code block.

# SEE ALSO

[Test::MockTime](https://metacpan.org/pod/Test::MockTime)

[Time::HiRes](https://metacpan.org/pod/Time::HiRes)

# LICENSE

Copyright (C) INA Lintaro

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

INA Lintaro <tarao.gnn@gmail.com>

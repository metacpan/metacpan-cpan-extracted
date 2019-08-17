# NAME

Test2::Plugin::MemUsage - Collect and display memory usage information.

# CAVEAT - UNIX ONLY

Currently this only works on unix systems that provide `/proc/PID/status`
access. For all other systems this plugin is essentially a no-op.

# DESCRIPTION

This plugin will collect memory usage info from `/proc/PID/status` and display
it for you when the test is done running.

# SYNOPSIS

    use Test2::Plugin::MemUsage;

This is also useful at the command line for 1-time use:

    $ perl -MTest2::Plugin::MemUsage path/to/test.t

Output:

    # rss:  36708kB
    # size: 49836kB
    # peak: 49836kB

# SOURCE

The source code repository for Test2-Plugin-MemUsage can be found at
`https://github.com/Test-More/Test2-Plugin-MemUsage/`.

# MAINTAINERS

- Chad Granum <exodist@cpan.org>

# AUTHORS

- Chad Granum <exodist@cpan.org>

# COPYRIGHT

Copyright 2019 Chad Granum <exodist@cpan.org>.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See `http://dev.perl.org/licenses/`

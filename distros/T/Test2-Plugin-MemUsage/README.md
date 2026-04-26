# NAME

Test2::Plugin::MemUsage - Collect and display memory usage information.

# PLATFORM SUPPORT

The plugin selects a memory collector based on `$^O`:

- Linux, Cygwin, GNU/kFreeBSD

    Reads `/proc/PID/status`. Reports rss, size (VmSize), and peak (VmPeak).

- macOS (darwin), \*BSD, Solaris, AIX, HP-UX

    Shells out to `ps -o rss=,vsz= -p $$`. Reports rss and size; peak is
    NA unless [BSD::Resource](https://metacpan.org/pod/BSD%3A%3AResource) is installed (see below).

- MSWin32

    Uses [Win32::Process::Memory](https://metacpan.org/pod/Win32%3A%3AProcess%3A%3AMemory) if installed to call
    `GetProcessMemoryInfo`. Reports rss (WorkingSetSize), peak
    (PeakWorkingSetSize), and size (PagefileUsage).

- Other / fallback

    If [BSD::Resource](https://metacpan.org/pod/BSD%3A%3AResource) is installed, `getrusage` is used to fill in a
    peak RSS value when the primary collector did not provide one (or
    when no native collector matched the platform at all).

If no collector and no fallback applies, the plugin is a silent no-op.

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

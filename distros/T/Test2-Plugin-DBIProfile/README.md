# NAME

Test2::Plugin::DBIProfile - Plugin to enable and display DBI profiling.

# DESCRIPTION

This will enable [DBI::Profile](https://metacpan.org/pod/DBI::Profile) globally so that DBI profiling data is
collected. Once testing is complete an event will be produced which contains
and displays the profiling data.

Normal output looks like this:

    # DBI::Profile: 0.000824s (24 calls) xxx.t @ 2019-08-16 14:24:01

If you use [Test2::Harness](https://metacpan.org/pod/Test2::Harness) aka [App::Yath](https://metacpan.org/pod/App::Yath) detailed profiling data is
available in the event log.

# SYNOPSIS

    use Test2::Plugin::DBIProfile;

This is also useful at the command line for 1-time use:

    $ perl -MTest2::Plugin::DBIProfile path/to/test.t

You can also specify a 'path' for DBI::Profile:

    use Test2::Plugin::DBIProfile "!MethodClass";

See ["ENABLING A PROFILE" in DBI::Profile](https://metacpan.org/pod/DBI::Profile#ENABLING-A-PROFILE) for path options.

The default is to use whatever is already in `$ENV{DBI_PROFILE}` if it is set,
and to fallback to `"!MethodClass"` otherwise.

# SOURCE

The source code repository for Test2-Suite can be found at
`https://github.com/Test-More/Test2-Suite/`.

# MAINTAINERS

- Chad Granum <exodist@cpan.org>

# AUTHORS

- Chad Granum <exodist@cpan.org>

# COPYRIGHT

Copyright 2019 Chad Granum <exodist@cpan.org>.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See `http://dev.perl.org/licenses/`

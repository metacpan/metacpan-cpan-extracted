# NAME

Test2::Plugin::IOEvents - Turn STDOUT and STDERR into Test2 events.

# DESCRIPTION

This plugin turns prints to STDOUT and STDERR (including warnings) into proper
Test2 events.

# SYNOPSIS

    use Test2::Plugin::IOEvents;

This is also useful at the command line for 1-time use:

    $ perl -MTest2::Plugin::IOEvents path/to/test.t

# CAVEATS

The magic of this module is achieved via tied variables.

# SOURCE

The source code repository for Test2-Plugin-IOEvents can be found at
`https://github.com/Test-More/Test2-Plugin-IOEvents/`.

# MAINTAINERS

- Chad Granum <exodist@cpan.org>

# AUTHORS

- Chad Granum <exodist@cpan.org>

# COPYRIGHT

Copyright 2020 Chad Granum <exodist@cpan.org>.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See `http://dev.perl.org/licenses/`

# NAME

*.pl - example scripts for [UI::Various](https://metacpan.org/pod/UI%3A%3AVarious)

# SYNOPSIS

    EXAMPLE.pl              # run with "best" UI
    DISPLAY= EXAMPLE.pl     # run with "best" TUI
    EXAMPLE.pl <N>          # run with UI number N, if available
    EXAMPLE.pl -?           # list UI numbers
    UI=<Name> EXAMPLE.pl    # run with UI with name "Name"

# ABSTRACT

These are the example scripts for [UI::Various](https://metacpan.org/pod/UI%3A%3AVarious),
e. g. several "Hello World!" variants.

# DESCRIPTION

If an example script is called without parameter if is run using the
best available user interface.  If the environment variable `DISPLAY`
is not set this would be the best available terminal user interface
(TUI).  If the first parameter is a number, the corresponding user
interface from the following list is chosen:

- 1 Tk (Perl Tk)

- 2 Curses (Curses::UI)

- 3 RichTerm (builtin rich terminal interface)

- 4 PoorTerm (builtin poor terminal interface, also fallback)

# SEE ALSO

[Tk](https://metacpan.org/pod/Tk), [Curses::UI](https://metacpan.org/pod/Curses%3A%3AUI)

# LICENSE

Copyright (C) Thomas Dorner.

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.  See LICENSE file for more details.

# AUTHOR

Thomas Dorner <dorner (at) cpan (dot) org>

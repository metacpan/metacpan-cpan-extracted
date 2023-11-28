[![MetaCPAN Release](https://badge.fury.io/pl/Text-VisualPrintf.svg)](https://metacpan.org/release/Text-VisualPrintf)
# NAME

Text::VisualPrintf - printf family functions to handle Non-ASCII characters

# SYNOPSIS

    use Text::VisualPrintf;
    Text::VisualPrintf::printf FORMAT, LIST
    Text::VisualPrintf::sprintf FORMAT, LIST

    use Text::VisualPrintf qw(vprintf vsprintf);
    vprintf FORMAT, LIST
    vsprintf FORMAT, LIST

# VERSION

Version 4.03

# DESCRIPTION

**Text::VisualPrintf** is a almost-printf-compatible library with a
capability of handling:

    - Multi-byte wide characters
    - Combining characters
    - Backspaces

When the given string is truncated by the maximum precision, space
character is padded if the wide character does not fit to the remained
space.

# FUNCTIONS

- printf FORMAT, LIST
- sprintf FORMAT, LIST
- vprintf FORMAT, LIST
- vsprintf FORMAT, LIST

    Use just like perl's _printf_ and _sprintf_ functions
    except that _printf_ does not take FILEHANDLE.

    Take a look at an experimental `Text::VisualPrintf::IO` if you want
    to work with FILEHANDLE and printf.

# VARIABLES

- $REORDER

    The original `printf` function has the ability to specify the
    arguments to be targeted by the position specifier, but by default
    this module assumes that the arguments will appear in the given order,
    so you will not get the expected result. If you wish to use it, set
    the package variable `$REORDER` to 1.

    By doing so, the order in which arguments appear can be changed and
    the same argument can be processed even if it appears more than once.

# IMPLEMENTATION NOTES

Strings in the LIST which contains wide-width character are replaced
before formatting, and recovered after the process.  Replacement is
implemented in the [Text::Conceal](https://metacpan.org/pod/Text%3A%3AConceal) module.

# SEE ALSO

[Text::VisualPrintf](https://metacpan.org/pod/Text%3A%3AVisualPrintf), [Text::VisualPrintf::IO](https://metacpan.org/pod/Text%3A%3AVisualPrintf%3A%3AIO),
[https://github.com/tecolicom/Text-VisualPrintf](https://github.com/tecolicom/Text-VisualPrintf)

[Text::Conceal](https://metacpan.org/pod/Text%3A%3AConceal), [https://github.com/tecolicom/Text-Conceal](https://github.com/tecolicom/Text-Conceal)

[Text::ANSI::Printf](https://metacpan.org/pod/Text%3A%3AANSI%3A%3APrintf), [https://github.com/tecolicom/Text-ANSI-Printf](https://github.com/tecolicom/Text-ANSI-Printf)

# AUTHOR

Kazumasa Utashiro

# LICENSE

Copyright 2011-2023 Kazumasa Utashiro.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

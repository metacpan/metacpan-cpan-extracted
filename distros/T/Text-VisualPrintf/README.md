[![Build Status](https://travis-ci.com/kaz-utashiro/Text-VisualPrintf.svg?branch=master)](https://travis-ci.com/kaz-utashiro/Text-VisualPrintf) [![MetaCPAN Release](https://badge.fury.io/pl/Text-VisualPrintf.svg)](https://metacpan.org/release/Text-VisualPrintf)
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

Version 4.01

# DESCRIPTION

Text::VisualPrintf is a almost-printf-compatible library with a
capability of handling multi-byte wide characters properly.

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

- $VISUAL\_WIDTH

    Hold a function reference to calculate visual width of given string.
    Default function is `Text::VisualWidth::PP::width`.

- $IS\_TARGET

    Hold a regexp object of funciton reference to test if the given string
    is subject of replacement.  Default is `qr/[\e\b\P{ASCII}]/`, and
    test if the string include `ESCAPE` or `BACKSPACE` or non-ASCII
    characters.

# IMPLEMENTATION NOTES

Strings in the LIST which contains wide-width character are replaced
before formatting, and recovered after the process.

Unique replacement string contains combinations of two ASCII
characters not found in the format string and all parameters.  If two
characters are not available, function behaves just like a standard
one.

# SEE ALSO

[Text::VisualPrintf](https://metacpan.org/pod/Text::VisualPrintf), [Text::VisualPrintf::IO](https://metacpan.org/pod/Text::VisualPrintf::IO),
[https://github.com/kaz-utashiro/Text-VisualPrintf](https://github.com/kaz-utashiro/Text-VisualPrintf)

[Text::Conceal](https://metacpan.org/pod/Text::Conceal), [https://github.com/kaz-utashiro/Text-Conceal](https://github.com/kaz-utashiro/Text-Conceal)

[Text::ANSI::Printf](https://metacpan.org/pod/Text::ANSI::Printf), [https://github.com/kaz-utashiro/Text-ANSI-Printf](https://github.com/kaz-utashiro/Text-ANSI-Printf)

# AUTHOR

Kazumasa Utashiro

# LICENSE

Copyright 2011-2020 Kazumasa Utashiro.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

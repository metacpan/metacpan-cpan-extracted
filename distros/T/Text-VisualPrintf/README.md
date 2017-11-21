# NAME

Text::VisualPrintf - printf family functions to handle Non-ASCII characters

# SYNOPSIS

    use Text::VisualPrintf;
    Text::VisualPrintf::printf(FORMAT, LIST)
    Text::VisualPrintf::sprintf(FORMAT, LIST)

    use Text::VisualPrintf qw(vprintf vsprintf);
    vprintf(FORMAT, LIST)
    vsprintf(FORMAT, LIST)

# DESCRIPTION

Text::VisualPrintf is a almost-printf-compatible library with a
capability of handling multi-byte wide characters properly.

# FUNCTIONS

- printf(FORMAT, LIST)
- sprintf(FORMAT, LIST)
- vprintf(FORMAT, LIST)
- vsprintf(FORMAT, LIST)

    Use just like perl's _printf_ and _sprintf_ functions
    except that _printf_ does not take FILEHANDLE as a first argument.

# IMPLEMENTATION NOTES

Strings in the LIST which contains wide-width character are replaced
before formatting, and recovered after the process.

Unique replacement string contains a combination of control characters
(Control-A to Control-E).  So, if the FORMAT contains a string in this
range, it has a chance to be a subject of replacement.

Single half-width multi-byte character is exception, and all
represented by single octal 006 (Control-F) character.  It may sounds
odd, but they are converted to proper string because the order is
preserved.  Same thing can be done for longer arguments, and when the
number or arguments exceeds 25, they are encoded by same code.

# SEE ALSO

[Text::VisualWidth::PP](https://metacpan.org/pod/Text::VisualWidth::PP)

# AUTHOR

Kaz Utashiro

# LICENSE

Copyright (C) 2011-2017 Kaz Utashiro.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

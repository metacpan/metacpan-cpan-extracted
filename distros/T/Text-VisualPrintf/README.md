[![Build Status](https://travis-ci.com/kaz-utashiro/Text-VisualPrintf.svg?branch=master)](https://travis-ci.com/kaz-utashiro/Text-VisualPrintf) [![MetaCPAN Release](https://badge.fury.io/pl/Text-VisualPrintf.svg)](https://metacpan.org/release/Text-VisualPrintf)
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

# BUGS

Text truncation is not supported.  Next program does not work.

    vsprintf("%.4s", "一二三");

# IMPLEMENTATION NOTES

Strings in the LIST which contains wide-width character are replaced
before formatting, and recovered after the process.

Unique replacement string contains a combination of control characters
(Control-A to Control-E).  If the FORMAT contains all of these two
bytes combinations, the function behaves just like a standard one.

Because this mechanism expects entire replacement string can be found
in formatted text, it does not work when the string is truncated by
maximum precision.

# SEE ALSO

[Text::VisualWidth::PP](https://metacpan.org/pod/Text::VisualWidth::PP)

[https://github.com/kaz-utashiro/Text-VisualPrintf](https://github.com/kaz-utashiro/Text-VisualPrintf)

# AUTHOR

Kazumasa Utashiro

# LICENSE

Copyright (C) 2011-2020 Kazumasa Utashiro.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

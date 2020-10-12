[![Build Status](https://travis-ci.com/kaz-utashiro/Text-ANSI-Printf.svg?branch=master)](https://travis-ci.com/kaz-utashiro/Text-ANSI-Printf)
# NAME

Text::ANSI::Printf - printf function for string with ANSI sequence

# VERSION

Version 1.01

# SYNOPSIS

    use Text::ANSI::Printf;
    Text::ANSI::Printf::printf FORMAT, LIST
    Text::ANSI::Printf::sprintf FORMAT, LIST

    use Text::ANSI::Printf qw(ansi_printf ansi_sprintf);
    ansi_printf FORMAT, LIST
    ansi_sprintf FORMAT, LIST

# DESCRIPTION

Text::ANSI::Printf is a almost-printf-compatible library with a
capability of handling string with ANSI color sequences, as well as
multi-byte wide characters.

# FUNCTIONS

- printf FORMAT, LIST
- sprintf FORMAT, LIST
- ansi\_printf FORMAT, LIST
- ansi\_sprintf FORMAT, LIST

    Use just like perl's _printf_ and _sprintf_ functions
    except that _printf_ does not take FILEHANDLE.

# IMPLEMENTATION NOTES

This module uses [Text::VisualPrintf](https://metacpan.org/pod/Text::VisualPrintf) and [Text::ANSI::Fold::Util](https://metacpan.org/pod/Text::ANSI::Fold::Util)
internally.

# SEE ALSO

[Text::VisualPrintf](https://metacpan.org/pod/Text::VisualPrintf),
[https://github.com/kaz-utashiro/Text-VisualPrintf](https://github.com/kaz-utashiro/Text-VisualPrintf)

[Text::ANSI::Fold::Util](https://metacpan.org/pod/Text::ANSI::Fold::Util),
[https://github.com/kaz-utashiro/Text-ANSI-Fold-Util](https://github.com/kaz-utashiro/Text-ANSI-Fold-Util)

[Text::ANSI::Printf](https://metacpan.org/pod/Text::ANSI::Printf),
[https://github.com/kaz-utashiro/Text-ANSI-Printf](https://github.com/kaz-utashiro/Text-ANSI-Printf)

[App::ansicolumn](https://metacpan.org/pod/App::ansicolumn),
[https://github.com/kaz-utashiro/App-ansicolumn](https://github.com/kaz-utashiro/App-ansicolumn)

[https://en.wikipedia.org/wiki/ANSI\_escape\_code](https://en.wikipedia.org/wiki/ANSI_escape_code)

# AUTHOR

Kazumasa Utashiro

# LICENSE

Copyright 2020 Kazumasa Utashiro.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

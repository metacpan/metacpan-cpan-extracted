[![Actions Status](https://github.com/tecolicom/Text-ANSI-Printf/workflows/test/badge.svg)](https://github.com/tecolicom/Text-ANSI-Printf/actions) [![MetaCPAN Release](https://badge.fury.io/pl/Text-ANSI-Printf.svg)](https://metacpan.org/release/Text-ANSI-Printf)
# NAME

Text::ANSI::Printf - printf function for string with ANSI sequence

# VERSION

Version 2.02

# SYNOPSIS

    use Text::ANSI::Printf;
    Text::ANSI::Printf::printf FORMAT, LIST
    Text::ANSI::Printf::sprintf FORMAT, LIST

    use Text::ANSI::Printf qw(ansi_printf ansi_sprintf);
    ansi_printf FORMAT, LIST
    ansi_sprintf FORMAT, LIST

# DESCRIPTION

**Text::ANSI::Printf** is a almost-printf-compatible library with a
capability of handling:

    - ANSI terminal sequences
    - Multi-byte wide characters
    - Backspaces

You can give any string including these data as an argument for
`printf` and `sprintf` funcitons.  Each field width is calculated
based on its visible appearance.

For example,

    printf "| %-5s | %-5s | %-5s |\n", "Red", "Green", "Blue";

this code produces the output like:

    | Red   | Green | Blue  |

However, if the arguments are colored by ANSI sequence,

    printf("| %-5s | %-5s | %-5s |\n",
           "\e[31mRed\e[m", "\e[32mGreen\e[m", "\e[34mBlue\e[m");

this code produces undsirable result:

    | Red | Green | Blue |

`ansi_printf` can be used to properly format colored text.

    use Text::ANSI::Printf 'ansi_printf';
    ansi_printf("| %-5s | %-5s | %-5s |\n",
           "\e[31mRed\e[m", "\e[32mGreen\e[m", "\e[34mBlue\e[m");

It does not matter if the result is shorter than the original text.
Next code produces `[R] [G] [B]` in proper color.

    ansi_printf("[%.1s] [%.1s] [%.1s]\n",
           "\e[31mRed\e[m", "\e[32mGreen\e[m", "\e[34mBlue\e[m");

# FUNCTIONS

- printf FORMAT, LIST
- sprintf FORMAT, LIST
- ansi\_printf FORMAT, LIST
- ansi\_sprintf FORMAT, LIST

    Use just like perl's _printf_ and _sprintf_ functions
    except that _printf_ does not take FILEHANDLE.

# IMPLEMENTATION NOTES

This module uses [Text::Conceal](https://metacpan.org/pod/Text%3A%3AConceal) and [Text::ANSI::Fold::Util](https://metacpan.org/pod/Text%3A%3AANSI%3A%3AFold%3A%3AUtil)
internally.

# SEE ALSO

[Term::ANSIColor::Concise](https://metacpan.org/pod/Term%3A%3AANSIColor%3A%3AConcise),
[https://github.com/tecolicom/Term-ANSIColor-Concise](https://github.com/tecolicom/Term-ANSIColor-Concise)

[Text::Conceal](https://metacpan.org/pod/Text%3A%3AConceal),
[https://github.com/kaz-utashiro/Text-Conceal](https://github.com/kaz-utashiro/Text-Conceal)

[Text::ANSI::Fold::Util](https://metacpan.org/pod/Text%3A%3AANSI%3A%3AFold%3A%3AUtil),
[https://github.com/tecolicom/Text-ANSI-Fold-Util](https://github.com/tecolicom/Text-ANSI-Fold-Util)

[Text::ANSI::Printf](https://metacpan.org/pod/Text%3A%3AANSI%3A%3APrintf),
[https://github.com/tecolicom/Text-ANSI-Printf](https://github.com/tecolicom/Text-ANSI-Printf)

[App::ansicolumn](https://metacpan.org/pod/App%3A%3Aansicolumn),
[https://github.com/tecolicom/App-ansicolumn](https://github.com/tecolicom/App-ansicolumn)

[App::ansiecho](https://metacpan.org/pod/App%3A%3Aansiecho),
[https://github.com/tecolicom/App-ansiecho](https://github.com/tecolicom/App-ansiecho)

[https://en.wikipedia.org/wiki/ANSI\_escape\_code](https://en.wikipedia.org/wiki/ANSI_escape_code)

# AUTHOR

Kazumasa Utashiro

# LICENSE

Copyright 2020-2023 Kazumasa Utashiro.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

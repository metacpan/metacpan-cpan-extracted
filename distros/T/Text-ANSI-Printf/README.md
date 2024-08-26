[![Actions Status](https://github.com/tecolicom/Text-ANSI-Printf/workflows/test/badge.svg)](https://github.com/tecolicom/Text-ANSI-Printf/actions) [![MetaCPAN Release](https://badge.fury.io/pl/Text-ANSI-Printf.svg)](https://metacpan.org/release/Text-ANSI-Printf)
# NAME

Text::ANSI::Printf - printf function to print string including ANSI sequence

# VERSION

Version 2.0602

# SYNOPSIS

    use Text::ANSI::Printf;
    Text::ANSI::Printf::printf FORMAT, LIST
    Text::ANSI::Printf::sprintf FORMAT, LIST

    use Text::ANSI::Printf qw(ansi_printf ansi_sprintf);
    ansi_printf FORMAT, LIST
    ansi_sprintf FORMAT, LIST

    $ ansiprintf format args ...

# DESCRIPTION

**Text::ANSI::Printf** is a almost-printf-compatible library with a
capability of handling:

    - ANSI terminal sequences
    - Multi-byte wide characters
    - Combining characters
    - Backspaces

You can give any string including these data as an argument for
`printf` and `sprintf` functions.  Each field width is calculated
based on its visible appearance.

For example,

    printf("| %-8s | %-8s | %-8s |\n", "Red", "Green", "Blue");

this code produces the output like:

<div>
    <p><img width="300" src="https://raw.githubusercontent.com/tecolicom/Text-ANSI-Printf/master/images/plain.png">
</div>

However, if the arguments are colored by ANSI sequence,

    printf("| %-8s | %-8s | %-8s |\n",
           "\e[31mRed\e[m", "\e[32;3mGreen\e[m", "\e[34;3;4mBlue\e[m");

this code produces undesirable result:

<div>
    <p><img width="300" src="https://raw.githubusercontent.com/tecolicom/Text-ANSI-Printf/master/images/bad.png">
</div>

This is still better because the output is readable, but if the result
is shorter than the original string, for example, "%3.3s", the result
will be disastrous.

`ansi_printf` can be used to properly format colored text.

    use Text::ANSI::Printf 'ansi_printf';
    ansi_printf("| %-8s | %-8s | %-8s |\n",
                "\e[31mRed\e[m", "\e[32;3mGreen\e[m", "\e[34;3;4mBlue\e[m");

<div>
    <p><img width="300" src="https://raw.githubusercontent.com/tecolicom/Text-ANSI-Printf/master/images/good.png">
</div>

It does not matter if the result is shorter than the original text.
Next code produces `[R] [G] [B]` in proper color.

    use Text::ANSI::Printf 'ansi_printf';
    ansi_printf("[%.1s] [%.1s] [%.1s]\n",
                "\e[31mRed\e[m", "\e[32;3mGreen\e[m", "\e[34;3;4mBlue\e[m");

<div>
    <p><img width="300" src="https://raw.githubusercontent.com/tecolicom/Text-ANSI-Printf/master/images/shorten.png">
</div>

# RELATED TOOLS

[Text::ANSI::Printf](https://metacpan.org/pod/Text%3A%3AANSI%3A%3APrintf) only prints strings including ANSI sequences, it
does not generate ANSI colored text.  To produce colored text, use
standard [Term::ANSIColor](https://metacpan.org/pod/Term%3A%3AANSIColor) or companion module
[Term::ANSIColor::Concise](https://metacpan.org/pod/Term%3A%3AANSIColor%3A%3AConcise).  Using `ansi_color` function of
[Term::ANSIColor::Concise](https://metacpan.org/pod/Term%3A%3AANSIColor%3A%3AConcise) module, above example can be written as
follows.

    use Text::ANSI::Printf 'ansi_printf';
    use Term::ANSIColor::Concise 'ansi_color';
    ansi_printf("| %-5s | %-5s | %-5s |\n",
                ansi_color("R", "Red", "GI", "Green", "BIU", "Blue"));

Using the command line interface, `ansiprintf`, and the companion
command, `ansiecho`, the shell command can be executed as follows.

    ansiprintf "| %-5s | %-5s | %-5s |\n" $(ansiecho -cR Red -cGI Green -cBIU Blue)

In fact, this can be done with the `ansiecho` command alone.

    ansiecho -f "| %-5s | %-5s | %-5s |" -cR Red -cGI Green -cBIU Blue

# ARGUMENT REORDERING

The original `printf` function has the ability to specify the
arguments to be targeted by the position specifier, but by default
this module assumes that the arguments will appear in the given order,
so you will not get the expected result. If you wish to use it, set
the package variable `$REORDER` to 1.

    $Text::ANSI::Printf::REORDER = 1;

By doing so, the order in which arguments appear can be changed and
the same argument can be processed even if it appears more than once.

If you want to enable this feature only in specific cases, create a
wrapper function and declare `$Text::ANSI::Printf::REORDER` as local
in it.

This behavior is experimental and may change in the future.

# FUNCTIONS

- printf FORMAT, LIST
- sprintf FORMAT, LIST
- ansi\_printf FORMAT, LIST
- ansi\_sprintf FORMAT, LIST

    Use just like Perl's _printf_ and _sprintf_ functions
    except that _printf_ does not take FILEHANDLE.

# IMPLEMENTATION NOTES

This module uses [Text::Conceal](https://metacpan.org/pod/Text%3A%3AConceal) and [Text::ANSI::Fold::Util](https://metacpan.org/pod/Text%3A%3AANSI%3A%3AFold%3A%3AUtil)
internally.

# CLI TOOLS

This package contains the [ansiprintf(1)](http://man.he.net/man1/ansiprintf) command as a wrapper for
this module. By using this command from the command line interface,
you can check the functionality of [Text::ANSI::Printf](https://metacpan.org/pod/Text%3A%3AANSI%3A%3APrintf).  See
[ansiprintf(1)](http://man.he.net/man1/ansiprintf) or \`perldoc ansiprintf\`.

# SEE ALSO

[App::ansiprintf](https://metacpan.org/pod/App%3A%3Aansiprintf)

[Term::ANSIColor::Concise](https://metacpan.org/pod/Term%3A%3AANSIColor%3A%3AConcise),
[https://github.com/tecolicom/Term-ANSIColor-Concise](https://github.com/tecolicom/Term-ANSIColor-Concise)

[Text::Conceal](https://metacpan.org/pod/Text%3A%3AConceal),
[https://github.com/tecolicom/Text-Conceal](https://github.com/tecolicom/Text-Conceal)

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

Copyright © 2020-2024 Kazumasa Utashiro.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

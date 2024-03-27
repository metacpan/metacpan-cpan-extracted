[![Actions Status](https://github.com/tecolicom/Text-ANSI-Tabs/workflows/test/badge.svg)](https://github.com/tecolicom/Text-ANSI-Tabs/actions) [![MetaCPAN Release](https://badge.fury.io/pl/Text-ANSI-Tabs.svg)](https://metacpan.org/release/Text-ANSI-Tabs)
# NAME

Text::ANSI::Tabs - Tab expand and unexpand with ANSI sequence

# SYNOPSIS

    use Text::ANSI::Tabs qw(:all);
    use Text::ANSI::Tabs qw(ansi_expand ansi_unexpand);
    ansi_expand($text);
    ansi_unexpand($text);

    use Text::ANSI::Tabs;
    Text::ANSI::Tabs::expand($text);
    Text::ANSI::Tabs::unexpand($text);

# VERSION

Version 1.0501

# DESCRIPTION

ANSI sequence and Unicode wide characters aware version of Text::Tabs.

# FUNCTION

There are exportable functions start with `ansi_` prefix, and
unexportable functions without them.

- **expand**(_text_, ...)
- **ansi\_expand**(_text_, ...)

    Expand tabs.  Interface is compatible with [Text::Tabs](https://metacpan.org/pod/Text%3A%3ATabs)::expand().

    Default tabstop is 8, and can be accessed through
    `$Text::ANSI::Tabs::tabstop` variable.

    Option for the underlying `Text::ANSI::Fold` object can be passed by
    first parameter as an array reference, as well as `Text::ANSI::Tabs->configure` call.

        my $opt = [ tabhead => 'T', tabspace => '_' ];
        ansi_expand($opt, @text);

        Text::ANSI::Tabs->configure(tabstyle => 'bar');
        ansi_expand(@text);

    See [Text::ANSI::Fold](https://metacpan.org/pod/Text%3A%3AANSI%3A%3AFold) for detail.

- **unexpand**(_text_, ...)
- **ansi\_unexpand**(_text_, ...)

    Unexpand tabs.  Interface is compatible with
    [Text::Tabs](https://metacpan.org/pod/Text%3A%3ATabs)::unexpand().  Default tabstop is same as `ansi_expand`.

    Please be aware that, current implementation may add and/or remove
    some redundant color designation code.

# METHODS

- **configure**

    Confiugre and return the underlying `Text::ANSI::Fold` object.
    Related parameters are those:

    - **tabstop** => _num_

        Set the value of variable `$Text::ANSI::Tabs::tabstop` to _num_.

    - **tabhead** => _char_
    - **tabspace** => _char_

        Tab character is converted to **tabhead** and following **tabspace**
        characters.  Both are white space by default.

    - **tabstyle** => _style_

        Set tab expansion style.  This parameter set both **tabhead** and
        **tabspace** at once according to the given style name.  Each style has
        two values for tabhead and tabspace.

        If two style names are combined, like `symbol,space`, use
        `symbols`'s tabhead and `space`'s tabspace.

    - **minimum** => _num_

        By default, **unexpand** converts two or more consecutive whitespace
        characters into tab characters.  This parameter specifies the minimum
        number of whitespace characters to be converted to tabs.  Specifying
        it to 1 will convert all possible whitespace characters.

    See [Text::ANSI::Fold](https://metacpan.org/pod/Text%3A%3AANSI%3A%3AFold) for detail.

# SEE ALSO

[App::ansiexpand](https://metacpan.org/pod/App%3A%3Aansiexpand),
[https://github.com/tecolicom/App-ansiexpand](https://github.com/tecolicom/App-ansiexpand)

[Text::ANSI::Tabs](https://metacpan.org/pod/Text%3A%3AANSI%3A%3ATabs),
[https://github.com/tecolicom/Text-ANSI-Tabs](https://github.com/tecolicom/Text-ANSI-Tabs)

[Text::ANSI::Fold::Util](https://metacpan.org/pod/Text%3A%3AANSI%3A%3AFold%3A%3AUtil),
[https://github.com/tecolicom/Text-ANSI-Fold-Util](https://github.com/tecolicom/Text-ANSI-Fold-Util)

[Text::ANSI::Fold](https://metacpan.org/pod/Text%3A%3AANSI%3A%3AFold),
[https://github.com/tecolicom/Text-ANSI-Fold](https://github.com/tecolicom/Text-ANSI-Fold)

[Text::Tabs](https://metacpan.org/pod/Text%3A%3ATabs)

# AUTHOR

Kazumasa Utashiro

# LICENSE

Copyright 2021-2024 Kazumasa Utashiro.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

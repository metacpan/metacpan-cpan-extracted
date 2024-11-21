[![Actions Status](https://github.com/tecolicom/Text-ANSI-Fold-Util/workflows/test/badge.svg)](https://github.com/tecolicom/Text-ANSI-Fold-Util/actions) [![MetaCPAN Release](https://badge.fury.io/pl/Text-ANSI-Fold-Util.svg)](https://metacpan.org/release/Text-ANSI-Fold-Util)
# NAME

Text::ANSI::Fold::Util - Text::ANSI::Fold utilities (width, substr)

# SYNOPSIS

    use Text::ANSI::Fold::Util qw(:all);
    use Text::ANSI::Fold::Util qw(ansi_width ansi_substr);
    ansi_width($text);
    ansi_substr($text, $offset, $width [, $replacement]);

    use Text::ANSI::Fold::Util;
    Text::ANSI::Fold::Util::width($text);
    Text::ANSI::Fold::Util::substr($text, ...);

# VERSION

Version 1.04

# DESCRIPTION

This is a collection of utilities using Text::ANSI::Fold module.  All
functions are aware of ANSI terminal sequence.

# FUNCTION

There are exportable functions start with **ansi\_** prefix, and
unexportable functions without them.

Unless otherwise noted, these functions are executed in the same
context as `ansi_fold` exported by `Text::ANSI::Fold` module. That
is, the parameters set by `Text::ANSI::Fold->configure` are
effective.

- **width**(_text_)
- **ansi\_width**(_text_)

    Returns visual width of given text.

- **substr**(_text_, _offset_, _width_ \[, _replacement_\])
- **ansi\_substr**(_text_, _offset_, _width_ \[, _replacement_\])

    Returns substring just like Perl's **substr** function, but string
    position is calculated by the visible width on the screen instead of
    number of characters.  If there is no corresponding substring, undef
    is returned always.

    If the `padding` option is specified, then if there is a
    corresponding substring, it is padded to the specified width and
    returned.

    It does not cut the text in the middle of multi-byte character.  If
    you want to split the text in the middle of a wide character, specify
    the `crackwide` option.

        Text::ANSI::Fold->configure(crackwide => 1);

    If an optional _replacement_ parameter is given, replace the
    substring by the replacement and return the entire string.  If 0 is
    specified for the width, there may be no error even if the
    corresponding substring does not exist.

# SEE ALSO

[Text::ANSI::Fold::Util](https://metacpan.org/pod/Text%3A%3AANSI%3A%3AFold%3A%3AUtil),
[https://github.com/tecolicom/Text-ANSI-Fold-Util](https://github.com/tecolicom/Text-ANSI-Fold-Util)

[Text::ANSI::Tabs](https://metacpan.org/pod/Text%3A%3AANSI%3A%3ATabs),
[https://github.com/tecolicom/Text-ANSI-Tabs](https://github.com/tecolicom/Text-ANSI-Tabs)

[Text::ANSI::Fold](https://metacpan.org/pod/Text%3A%3AANSI%3A%3AFold),
[https://github.com/tecolicom/Text-ANSI-Fold](https://github.com/tecolicom/Text-ANSI-Fold)

[Text::Tabs](https://metacpan.org/pod/Text%3A%3ATabs)

# AUTHOR

Kazumasa Utashiro

# LICENSE

Copyright 2020-2024 Kazumasa Utashiro.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

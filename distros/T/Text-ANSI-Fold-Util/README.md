# NAME

Text::ANSI::Fold::Util - Text::ANSI::Fold utilities (width, substr, expand)

# VERSION

Version 0.02

# SYNOPSIS

    use Text::ANSI::Fold::Util qw(:all);
    use Text::ANSI::Fold::Util qw(ansi_width ansi_substr ansi_expand);
    ansi_width($text);
    ansi_substr($text, $offset, $width [, $replacement]);
    ansi_expand($text);

    use Text::ANSI::Fold::Util;
    Text::ANSI::Fold::Util::width($text);
    Text::ANSI::Fold::Util::substr($text, ...);
    Text::ANSI::Fold::Util::expand($text);

# DESCRIPTION

This is a collection of utilities using Text::ANSI::Fold module.  All
functions are aware of ANSI terminal sequence.

# FUNCTION

There are exportable functions start with **ansi\_** prefix, and
unexportable functions without them.

- **width**(_text_)
- **ansi\_width**(_text_)

    Returns visual width of given text.

- **substr**(_text_, _offset_, _width_ \[, _replacement_\])
- **ansi\_substr**(_text_, _offset_, _width_ \[, _replacement_\])

    Returns substring just like Perl's **substr** function, but string
    position is calculated by the visible width on the screen instead of
    number of characters.

    If an optional _replacemnt_ parameter is given, replace the substring
    by the replacement and return the entire string.

    It does not cut the text in the middle of multi-byte character, of
    course.  Its behavior depends on the implementation of lower module.

- **expand**(_text_, ...)
- **ansi\_expand**(_text_, ...)

    Expand tabs.  Interface is compatible with [Text::Tabs](https://metacpan.org/pod/Text::Tabs)::expand().

    Dafault tabstop is 8, and can be accessed through
    `$Text::ANSI::Fold::Util::tabstop` variable.

# SEE ALSO

[Text::ANSI::Fold::Util](https://metacpan.org/pod/Text::ANSI::Fold::Util), [https://github.com/kaz-utashiro/Text-ANSI-Fold-Util](https://github.com/kaz-utashiro/Text-ANSI-Fold-Util)

[Text::ANSI::Fold](https://metacpan.org/pod/Text::ANSI::Fold), [https://github.com/kaz-utashiro/Text-ANSI-Fold](https://github.com/kaz-utashiro/Text-ANSI-Fold)

[Text::Tabs](https://metacpan.org/pod/Text::Tabs)

# LICENSE

Copyright 2020 Kazumasa Utashiro.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

Kazumasa Utashiro <kaz@utashiro.com>

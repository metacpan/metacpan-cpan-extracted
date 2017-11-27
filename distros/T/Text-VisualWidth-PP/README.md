# NAME

Text::VisualWidth::PP - trimming text by the number of the column s of terminals and mobile phones.

# SYNOPSIS

    use utf8;
    use Text::VisualWidth::PP;

    Text::VisualWidth::PP::width("あいうえおaiu"); # => 13
    Text::VisualWidth::PP::trim("あいうえおaiu", 7); # => "あいう"

    # with exporter
    use Text::VisualWidth::PP qw(vwidth vtrim);
    vwidth("あいうえおaiu"); # => 13
    vtrim("あいうえおaiu", 7); # => "あいう"

# DESCRIPTION

This module provides functions to treat half-width and full-width characters and display correct size of text in one line on terminals and mobile phones. You can know the visual width of any text and truncate text by the visual width. Now this module support flagged UTF-8 and tested only with Japanese.

This module is pure perl version of [Text::VisualWidth](https://metacpan.org/pod/Text::VisualWidth). This is bit slow, but it's not require compiler.

# Ambiguous Characters

This module treats ambiguous characters are half width by default.

And you can specify the behavior by the `$Text::VisualWidth::PP::EastAsian` flag expressly.

Note: If `$Unicode::EastAsianWidth::EastAsian` is true on compilation time, this module set `$Text::VisualWidth::PP::EastAsian` as true for backward compatibility.

If you want to detect the ambw parameter from users' environment, please look [Unicode::EastAsianWidth::Detect](https://metacpan.org/pod/Unicode::EastAsianWidth::Detect).

# AUTHOR

Tokuhiro Matsuno &lt;tokuhirom AAJKLFJEF GMAIL COM>

# SEE ALSO

[Text::VisualWidth](https://metacpan.org/pod/Text::VisualWidth)

# LICENSE

Copyright (C) Tokuhiro Matsuno

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

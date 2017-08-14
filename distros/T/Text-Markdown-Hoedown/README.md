[![Build Status](https://travis-ci.org/tokuhirom/Text-Markdown-Hoedown.svg?branch=master)](https://travis-ci.org/tokuhirom/Text-Markdown-Hoedown)
# NAME

Text::Markdown::Hoedown - hoedown for Perl5

# SYNOPSIS

    use Text::Markdown::Hoedown;

    print markdown(<<'...');
    # foo

    bar

      * hoge
      * fuga
    ...

# DESCRIPTION

Text::Markdown::Hoedown is binding library for hoedown.

hoedown is a forking project from sundown.

# FUNCTIONS

- ` my $out = markdown($src :Str, %options) :Str `

    Rendering markdown.

    Options are following:

    - toc\_nesting\_lvl

        Nesting levels for TOC generation.

        (Default: 99)

    - extensions

        This is bit flag.  You can use the flags by '|' operator.
        Values are following:

        - HOEDOWN\_EXT\_TABLES

            Parse PHP-Markdown style tables.

        - HOEDOWN\_EXT\_FENCED\_CODE

            Parse fenced code blocks.

        - HOEDOWN\_EXT\_FOOTNOTES

            Parse footnotes.

        - HOEDOWN\_EXT\_AUTOLINK

            Automatically turn safe URLs into links.

        - HOEDOWN\_EXT\_STRIKETHROUGH

            Parse ~~stikethrough~~ spans.

        - HOEDOWN\_EXT\_UNDERLINE

            Parse \_underline\_ instead of emphasis.

        - HOEDOWN\_EXT\_HIGHLIGHT

            Parse ==highlight== spans.

        - HOEDOWN\_EXT\_QUOTE

            Render "quotes" as &lt;q>quotes&lt;/q>.

        - HOEDOWN\_EXT\_SUPERSCRIPT

            Parse super^script.

        - HOEDOWN\_EXT\_MATH

            Parse TeX $$math$$ syntax, Kramdown style.

        - HOEDOWN\_EXT\_NO\_INTRA\_EMPHASIS

            Disable emphasis\_between\_words.

        - HOEDOWN\_EXT\_SPACE\_HEADERS

            Require a space after '#' in headers.

        - HOEDOWN\_EXT\_MATH\_EXPLICIT

            Instead of guessing by context, parse $inline math$ and $$always block math$$ (requires HOEDOWN\_EXT\_MATH).

        - HOEDOWN\_EXT\_DISABLE\_INDENTED\_CODE

            Don't parse indented code blocks.

    - html\_options

        This is bit flag.  You can use the flags by '|' operator.
        Values are following:

        - HOEDOWN\_HTML\_SKIP\_HTML

            Strip all HTML tags.

        - HOEDOWN\_HTML\_ESCAPE

            Escape all HTML.

        - HOEDOWN\_HTML\_HARD\_WRAP

            Render each linebreak as &lt;br>.

        - HOEDOWN\_HTML\_USE\_XHTML

            Render XHTML.

    - max\_nesting

        I don't know what this do.

- `markdown_toc($src:Str, %opts) :Str`

    Generate TOC HTML from `$str`.

    Options are following:

    - nesting\_level

        Maximum nesting level for TOC.

    - extensions

        Same as above.

    - max\_nesting

        Same as above.

    All `HOEDOWN_*` constants are exported by default.

# TODO

- Document about low level APIs

# HACKING

`hoedown/` directory is managed by git subtree.

You can pull the modifications from upstream by following command:

     git subtree pull --prefix=hoedown git@github.com:hoedown/hoedown.git master

# LICENSE

Copyright (C) tokuhirom.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

tokuhirom <tokuhirom@gmail.com>

# NAME

Text::Markdown::Discount - fast function for converting markdown to HTML (requires C compiler)

# SYNOPSIS

    use Text::Markdown::Discount;
    my $html = markdown($text)

# DESCRIPTION

Text::Markdown::Discount is a perl interface to the `Discount` library,
a C implementation of John Gruber's `markdown`.

It is the fastest of the
Perl modules available for converting markdown: see the list in ["SEE ALSO"](#see-also).
It passes Gruber's Markdown testsuite.

Given that the performance of Discount, Text::Markdown::Discount processes
markdown formatted text quickly and passes the Markdown test suite at
[http://daringfireball.net/projects/downloads/MarkdownTest\_1.0.zip](http://daringfireball.net/projects/downloads/MarkdownTest_1.0.zip)

The interface of the `markdown()` function in this module
is not compatible with the `markdown()` function in [Text::Markdown](https://metacpan.org/pod/Text%3A%3AMarkdown).

## EXPORT

_markdown_ is exported by default.

## FUNCTION

- `Text::Markdown::Discount::with_html5_tags()`

    This function enables html5 block-level elements support.
    `Text::Markdown::Discount::markdown()` will handle these html5 tags as
    block elements: aside, footer, header, hgroup, nav, section, article.

    **NOTE**: There is no way to disable/re-enable this feature in one process right now.

        use Text::Markdown::Discount;
        Text::Markdown::Discount::with_html5_tags();
        my $html = markdown('<article>content</article>');
        #
        # In $html, <article> tag won't be wrapped with <p> tag

# SEE ALSO

There are other modules on CPAN for converting Markdown:

- [Text::Markdown](https://metacpan.org/pod/Text%3A%3AMarkdown) is a pure-perl markdown converter.
- [Markdent](https://metacpan.org/pod/Markdent) is a toolkit for parsing markdown,
which can also be used to convert markdown to HTML.
- [Text::Markup](https://metacpan.org/pod/Text%3A%3AMarkup) is a converter than can handle a number of input formats, including markdown.
- [Text::MultiMarkdown](https://metacpan.org/pod/Text%3A%3AMultiMarkdown) converts MultiMarkdown (a superset of the original markdown format)
to HTML.

Additional markdown resources:

- [Discount](http://www.pell.portland.or.us/~orc/Code/markdown/) -
David Loren Parsons's library for converting markdown, written in C.
- [Markdown definition](http://daringfireball.net/projects/markdown/) -
John Gruber's original definition of the markdown format.
- [Markdown testsuite](http://daringfireball.net/projects/downloads/MarkdownTest_1.0.zip) -
John Gruber's testsuite for markdown.
- [Markdown modules](http://neilb.org/reviews/markdown.html) - a review
of all Perl modules for handling markdown, written by Neil Bowers.

# AUTHOR

Masayoshi Sekimura, <sekimura@cpan.org>

# COPYRIGHT AND LICENSE

Copyright (C) 2013 by Masayoshi Sekimura

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.

This product includes software developed by
David Loren Parsons &lt;http://www.pell.portland.or.us/~orc>

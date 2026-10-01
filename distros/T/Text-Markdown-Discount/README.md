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

- `markdown($text, [$flags_or_options])`

The legacy form accepts a scalar bitmap made by combining `MKD_*`
constants:

    my $html = markdown(
        $text,
        MKD_NOHEADER | MKD_NOPANTS | MKD_FENCEDCODE,
    );

The options form accepts a hash reference:

    my $html = markdown($text, {
        flags           => MKD_NOHEADER | MKD_NOPANTS,
        normal_listitem => 1,
        alt_as_title    => 1,
        extended_attr   => 1,
    });

The `flags` option is the same legacy bitmap accepted by the scalar form.
If it is omitted or undefined, the existing default bitmap is used.

`normal_listitem` disables GitHub-style checkbox list items.
`alt_as_title` uses image alt text as its title when no title is specified.
With the bundled Discount 3.0.2.0 release, images are not rendered as expected
when this option is enabled. The option is passed through unchanged so it will
follow upstream behavior when Discount is updated.
`extended_attr` enables extended attribute suffixes on links, images, and
reference links. These options do not consume bits in the legacy bitmap and
are therefore safe on 32-bit Perl builds.

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

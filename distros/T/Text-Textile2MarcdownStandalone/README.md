[![Actions Status](https://github.com/takihito/Text-Textile2MarcdownStandalone/actions/workflows/test.yml/badge.svg)](https://github.com/takihito/Text-Textile2MarcdownStandalone/actions)
# NAME

Text::Textile2MarcdownStandalone - Standalone converter from Textile markup to Markdown

# DEPRECATION

This module is \*\*DEPRECATED\*\* and was uploaded by mistake.
Please use \*\*Text-Textile2MarkdownStandalone\*\* instead.

# VERSION

version 0.04

# SYNOPSIS

    use Text::Textile2MarcdownStandalone;

    # Convert a Textile file to a Markdown file
    my $converter = Text::Textile2MarcdownStandalone->new(
      input_file  => 'input.textile',
      output_file => 'output.md',
    );
    $converter->convert;

    # Get the Markdown output as a string
    my $markdown = Text::Textile2MarcdownStandalone->new(
      input_file => 'input.textile'
    )->convert;

# DESCRIPTION

Text::Textile2MarcdownStandalone provides a simple, standalone tool to convert Textile-formatted text into Markdown. It supports:

- - Headings (h1-h6)
- Ordered and unordered lists with nesting
- Emphasis, strong emphasis, and strikethrough
- Code spans and code blocks
- Blockquotes
- Links and images
- Tables, including cells spanning multiple lines
- Horizontal rules and URL protection

# METHODS

- new(%options)

    Create a new converter object. Options:

        input_file  => path to the input Textile file
        output_file => path to write the output Markdown file
                        (if omitted, convert() returns the Markdown string)

- input\_file(\[$file\])

    Get or set the input file path.

- output\_file(\[$file\])

    Get or set the output file path.

- convert

    Execute the conversion. Reads the input file, converts its content to Markdown, and either writes it to the output file or returns it as a string.

# cli

> Use the helper script included with this distribution to run from the command line:
>
>     perl script/textile2markdown.pl --input input.textile --output output.md
>
> If only an input file is provided, the Markdown output will be printed to STDOUT.

# AUTHOR

Akihito Takeda <takeda.akihito@gmail.com>

# COPYRIGHT AND LICENSE

Copyright (C) 2025 Akihito Takeda

This software is free software; you may redistribute it and/or modify it under the same terms as Perl itself.

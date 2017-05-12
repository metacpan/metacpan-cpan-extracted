# NAME

Text::Markdown::Slidy - Markdown converter for HTML slide tools

# SYNOPSIS

    use Text::Markdown::Slidy;

    markdown(<<'MARKDOWN');
    Title1
    ======

    ## sub title
    abcde
    fg

    Title2
    ------
    hoge
    MARKDOWN
    # <div class="slide">
    # <h1>Title1</h1>
    # <h2>sub title<h2>
    #
    # <p>abcde
    # fg</p>
    # </div>
    #
    # <div class="slide">
    # <h2>Title2</h2>
    #
    # <p>hoge</p>
    # </div>

    # split markdown text to slide sections
    my @markdowns_per_section = split_markdown($markdown_text);

# DESCRIPTION

Text::Markdown::Slidy is to convert markdown syntax to HTML slide tools.

# METHODS

## `$md = Text::Markdown::Slidy->new(%opt)`

Constructor.

## `$html_text = $md->markdown($markdown_text)`

# FUNCTIONS

## `$html_text = markdown($markdown_text)`

## `@markdowns_per_section = split_markdown($markdown_text)`

# LICENSE

Copyright (C) Masayuki Matsuki.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

Masayuki Matsuki <y.songmu@gmail.com>

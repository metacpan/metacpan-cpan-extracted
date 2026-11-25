[![Actions Status](https://github.com/tecolicom/Text-ANSI-Image/actions/workflows/test.yml/badge.svg?branch=main)](https://github.com/tecolicom/Text-ANSI-Image/actions?workflow=test) [![MetaCPAN Release](https://badge.fury.io/pl/Text-ANSI-Image.svg)](https://metacpan.org/release/Text-ANSI-Image)
# NAME

Text::ANSI::Image - images as lines of text for the terminal

# SYNOPSIS

    use Text::ANSI::Image;

    my $img = Text::ANSI::Image->new or exit;   # no method for the terminal
    print "$_\n" for $img->rows('logo.png', width => 40);
    $img->flush;

# VERSION

Version 0.01

# DESCRIPTION

<div>
    <p><img width="602" src="https://raw.githubusercontent.com/tecolicom/Text-ANSI-Image/main/images/ansipic.png"></p>
</div>

This module draws an image in a terminal as lines of text.  The lines
can be laid out, folded around, paged and scrolled like any other
text: put in columns by [ansicolumn(1)](https://metacpan.org/pod/App%3A%3Aansicolumn), shown by
`less`, and they stay with the text around them.

How the lines are made is the _method_.  Each method is a module
`Text::ANSI::Image::`_NAME_.  The one of this distribution is:

- `kitty`

    The Unicode placeholders of the kitty graphics protocol.  Each cell
    of the image is the character U+10EEEE, with its row and column as
    combining characters and the id of the image as the foreground
    color.  The image itself is sent to the terminal once, by **flush**,
    and the terminal draws it in the cells, in its full resolution.
    kitty, Ghostty and iTerm2 3.7.3 or later support it.

PNG, JPEG and GIF files are shown.  The type is detected from the
content, not the name of the file.  The `kitty` method sends PNG; a
JPEG or a GIF is converted to PNG by `sips` (macOS) or ImageMagick,
and is not shown without them.  A PNG much larger than the room is
reduced by the same tools to send less data, or sent as it is without
them.

# METHODS

- **new**(_OPTIONS_)

    Returns an object of a method.  The options are:

    - **method** => _NAME_

        The method: `kitty`, or `auto` (the default), the first method in
        `@Text::ANSI::Image::METHODS` which the terminal supports.  With
        `auto`, **new** returns `undef` when the terminal supports none.  An
        unknown name dies.

    - **term** => _COLS_**x**_ROWS_\[**:**_W_**x**_H_\]

        The size of the terminal, in columns and rows, and the size of a cell
        in pixels.  By default it is read from `/dev/tty`.  A cell of 8x17
        pixels is taken when its size is not known.

    - **tty** => _FILE_

        Where the data of the images is sent by **flush** (default:
        `/dev/tty`).

    - **width** => _N_, **rows** => _N_

        The most columns and rows that an image may take (default: the
        terminal width, and its height but four lines).

    - **types** => \[ _TYPE_, ... \]

        The types of images shown: `png`, `jpeg` and `gif` (default: all).

- **rows**(_FILE_, _OPTIONS_)

    Returns the rows of the image of _FILE_, as lines without newlines,
    or an empty list when it is not shown: the file is not found, not an
    image, of a type not in **types**, or cannot be converted.  **width**,
    **rows** and **types** may be given for this call.  An image is as large
    as its pixels, and not larger than the room.

- **flush**

    Sends to the terminal what the rows given so far need: the images
    for `kitty`.  Call it before the rows are shown, or soon after.

- **method**

    The name of the method of the object.

- **supported**

    Whether the terminal supports the method, by the environment.  It is
    a class method: `Text::ANSI::Image::kitty->supported`.

- **terminal**

    Columns, rows and the size of a cell in pixels of the terminal.  As a
    class method, it takes _term_ as the argument:
    `Text::ANSI::Image->terminal` reads the size of `/dev/tty`.

- **info**(_FILE_)

    Width, height and type of an image file, or an empty list.  It is a
    class method too.

- **cells**(_W_, _H_, _OPTIONS_)

    The columns and rows that an image of _W_ x _H_ pixels takes.

# METHOD MODULES

A method is a module `Text::ANSI::Image::`_NAME_, a subclass of
Text::ANSI::Image, which has:

- **render**(_FILE_, _W_, _H_, _TYPE_, _COLS_, _ROWS_)

    The rows of the image in _COLS_ x _ROWS_ cells.  Required.

- **supported**

    Whether the terminal supports it (default: no).

- **max\_cells**

    The most columns and rows it can draw (default: 0, no limit).

- **flush**

    What is sent to the terminal (default: nothing).

**png** is there for a method which needs a PNG of the image.

# SEE ALSO

[Terminal graphics protocol, Unicode placeholders](https://sw.kovidgoyal.net/kitty/graphics-protocol/#unicode-placeholders)

[App::mdee](https://metacpan.org/pod/App%3A%3Amdee), which shows the images of Markdown files with it.

[App::ansicolumn](https://metacpan.org/pod/App%3A%3Aansicolumn), [Text::ANSI::Fold](https://metacpan.org/pod/Text%3A%3AANSI%3A%3AFold)

# AUTHOR

Kazumasa Utashiro

# LICENSE

Copyright © 2026 Kazumasa Utashiro.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

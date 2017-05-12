# NAME

Text::AAlib - Perl Binding for AAlib

# SYNOPSIS

    use Text::AAlib;
    use Imager;

    my $img = Imager->new( file => 'sample.jpg' );
    my ($width, $height) = ($img->getwidth, $img->getheight);

    my $aa = Text::AAlib->new(
        width  => $width,
        height => $height,
        mask   => AA_REVERSE_MASK,
    );

    $aa->put_image(image => $img);
    print $aa->render();

# DESCRIPTION

Text::AAlib is perl binding for AAlib. AAlib is a library for creating
ascii art(AA).

# INTERFACE

## Class Methods

### `Text::AAlib->new(%args)`

Creates and returns a new Text::AAlib instance.

`%args` is:

- width :Int

    Width of output file.

- height :Int

    Height of output file.

- mask :Int

    Masks for attribute. Supported masks are `AA_NORMAL_MASK`, `AA_DIM_MASK`,
    `AA_BOLD_MASK`, `AA_BOLDFONT_MASK`, `AA_REVERSE_MASK`.

## Instance Methods

### `$aalib->putpixel(%args)`

- x :Int

    x-coordinate of pixel. `x` parameter should be 0 <= `x` <= `width`.
    `width` is parameter of constructor.

- y :Int

    y-coordinate of pixel. `y` parameter should be 0 <= `y` <= `height`.
    `height` is parameter of constructor.

- color :Int

    Brightness of pixel. `color` parameter should be 0 <= `color` <= 255.

### `$aalib->puts(%args)`

- x :Int

    x-coordinate.

- y :Int

    y-coordinate

- string :Str

    String set

- attribute :Enum(enum aa\_attribute)

    Buffer attribute. This parameter should be AA\_NORMAL, AA\_BOLD, AA\_DIM,
    AA\_BOLDFONT, AA\_REVERSE.

### `$aalib->put_image(%args)`

- x :Int = 0

    x-coordinate.

- y :Int = 0

    y-coordinate

- image :Imager

    Image as Imager object

### `$aalib->render(%args) :Str`

Render buffer and return it as plain text.
You can specify render parameter following

- bright :Int
- contrast :Int
- gamma :Float
- dither :Enum
- inversion :Int

### `$aalib->as_string($with_attr) :Str`

Return AA as string.
If `$with_attr` is true, text attribute(BOLD, DIM, REVERSE) is enable.

### `$aalib->resize()`

Resize buffers at runtime.

### `$aalib->flush()`

Flush buffers.

### `$aalib->close()`

Close AAlib context.

# AUTHOR

Syohei YOSHIDA <syohex@gmail.com>

# COPYRIGHT

Copyright 2011- Syohei YOSHIDA

# LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# SEE ALSO

Some idea are taken from python-aalib. [http://aa-project.sourceforge.net/aalib/](http://aa-project.sourceforge.net/aalib/)

[http://jwilk.net/software/python-aalib](http://jwilk.net/software/python-aalib)

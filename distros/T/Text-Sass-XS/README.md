# NAME

Text::Sass::XS - Perl Binding for libsass

# SYNOPSIS

    # OO Interface
    use Text::Sass::XS;
    use Try::Tiny;

    my $sass = Text::Sass::XS->new;

    try {
        my $css = $sass->compile(".something { color: red; }");
    }
    catch {
        die $_;
    };

    # OO Interface with options
    my $sass = Text::Sass::XS->new(
        include_paths   => ['path/to/include'],
        image_path      => '/images',
        output_style    => SASS_STYLE_COMPRESSED,
        source_comments => SASS_SOURCE_COMMENTS_NONE,
    );
    try {
        my $css = $sass->compile(".something { color: red; }");
    }
    catch {
        die $_;
    };



    # Compile from file.
    my $sass = Text::Sass::XS->new;
    my $css = $sass->compile_file("/path/to/foo.scss");

    # with options.
    my $sass = Text::Sass::XS->new(
        include_paths   => ['path/to/include'],
        image_path      => '/images',
        output_style    => SASS_STYLE_COMPRESSED,
        source_comments => SASS_SOURCE_COMMENTS_NONE,
    );
    my $css = $sass->compile_file("/path/to/foo.scss");



    # Functional Interface
    # export sass_compile, sass_compile_file and some constants
    use Text::Sass::XS ':all';

    my $sass = "your sass string here...";
    my $options = {
        output_style    => SASS_STYLE_COMPRESSED,
        source_comments => SASS_SOURCE_COMMENTS_NONE,
        include_paths   => 'site/css:vendor/css',
        image_path      => '/images'
    };
    my ($css, $errstr) = sass_compile($sass, $options);
    die $errstr if $errstr;

    my $sass_filename = "/path/to/foo.scss";
    my $options = {
        output_style    => SASS_STYLE_COMPRESSED,
        source_comments => SASS_SOURCE_COMMENTS_NONE,
        include_paths   => 'site/css:vendor/css',
        image_path      => '/images'
    };

    # In scalar context, sass_compile(_file)? returns css only.
    my $css = sass_compile_file($sass_filename, $options);
    print $css;



    # Text::Sass compatible Interface
    my $sass = Text::Sass::XS->new(%options);
    my $css = $sass->scss2css($source);

    # sass2css and css2sass are implemented by Text::Sass
    my $css  = $sass->sass2css($source);
    my $scss = $sass->css2sass($css);

# DESCRIPTION

Text::Sass::XS is a Perl Binding for libsass.

[libsass Project page](https://github.com/hcatlin/libsass)

# OO INTERFACE

- `new`

        $sass = Text::Sass::XS->new(options)

    Creates a Sass object with the specified options. Example:

        $sass = Text::Sass::XS->new; # no options
        $sass = Text::Sass::XS->new(output_style => SASS_STYLE_NESTED);

- `compile(source_code)`

        $css = $sass->compile("source code");

    This compiles the Sass string that is passed in the first parameter. If
    there is an error it will `croak()`.

- `compile_file(input_path)`

        $css = $sass->compile_file("/path/to/foo.scss");

    This compiles the Sass file that is passed in the first parameter. If
    there is an error it will `croak()`.

- `options`

        $sass->options->{include_paths} = ['/path/to/assets'];

    Allows you to inspect or change the options after a call to `new`.

- `scss2css(source_code)`

        $css = $sass->scss2css("scss souce code");

    Same as `compile`.

- `sass2css(source_code)`

        $css = $sass->compile("sass source code");

    Wrapper method of `Text::Sass#sass2css`.

- `css2sass(source_code)`

        $css = $sass->css2sass("css source code");

    Wrapper method of `Text::Sass#css2sass`.

# FUNCTIONAL INTERFACE

# EXPORT

Nothing to export.

# EXPORT\_OK

## Funcitons

- `sass_compile($source_string :Str, $options :HashRef)`

    Returns css string if success. Otherwise throws exception.

    Default value of `$options` is below.

        my $options = {
            output_style    => SASS_STYLE_COMPRESSED,
            source_comments => SASS_SOURCE_COMMENTS_NONE, 
            include_paths   => undef,
            image_path      => undef,
        };

    `input_paths` is a coron-separated string for "@import". `image_path` is a string using for "image-url".

- `sass_compile_file($input_path :Str, $options :HashRef)`

    Returns css string if success. Otherwise throws exception. `$options` is same as `sass_compile`.

## Constants

For `$options->{output_style}`.

- `SASS_STYLE_NESTED`
- `SASS_STYLE_EXPANDED`
- `SASS_STYLE_COMPRESSED`

For `$options->{source_comments}`.

- `SASS_SOURCE_COMMENTS_NONE`
- `SASS_SOURCE_COMMENTS_DEFAULT`
- `SASS_SOURCE_COMMENTS_MAP`

# EXPORT\_TAGS

- :func

    Exports `sass_compile` and `sass_compile_file`.

- :const

    Exports all constants.

- :all

    Exports :func and :const.

# SEE ALSO

[Text::Sass](http://search.cpan.org/perldoc?Text::Sass) - Pure perl implementation.

[CSS::Sass](http://search.cpan.org/perldoc?CSS::Sass) - Yet another libsass binding.

# LICENSE

Text::Sass::XS

Copyright (C) 2013 Yoshihiro Sasaki.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

libsass

Copyright (C) 2012 by Hampton Catlin.

See libsass/LICENSE for more details.

# AUTHOR

Yoshihiro Sasaki <ysasaki@cpan.org>

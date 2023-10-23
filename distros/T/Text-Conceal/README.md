[![Actions Status](https://github.com/tecolicom/Text-Conceal/workflows/test/badge.svg)](https://github.com/tecolicom/Text-Conceal/actions) [![MetaCPAN Release](https://badge.fury.io/pl/Text-Conceal.svg)](https://metacpan.org/release/Text-Conceal)
# NAME

Text::Conceal - conceal and recover interface for text processing

# SYNOPSIS

    use Text::Conceal;
    my $conceal = Text::Conceal->new(
        length => \&sub,
        match  => qr/regex/,
        );
    $conceal->encode(@args);
    $_ = foo(@args);
    $conceal->decode($_);

# VERSION

Version 1.03

# DESCRIPTION

This is a general interface to transform text data into desirable
form, and recover the result after the process.

For example, [Text::Tabs](https://metacpan.org/pod/Text%3A%3ATabs) does not take care of Asian wide characters
to calculate string width.  So next program does not work as we wish.

    use Text::Tabs;
    print expand <>;

In this case, make conceal object with **length** function which can
correctly handle wide character width, and the pattern of string to be
concealed.

    use Text::Conceal;
    use Text::VisualWidth::PP;
    my $conceal = Text::Conceal->new(
        length => \&Text::VisualWidth::PP::width,
        match  => qr/\P{ASCII}+/,
    );

Then next program encode data, call **expand**() function, and recover
the result into original text.

    my @lines = <>;
    $conceal->encode(@lines);
    my @expanded = expand @lines;
    $conceal->decode(@expanded);
    print @expanded;

Be aware that **encode** and **decode** method alter the values of given
arguments.  Because they return results as a list too, this can be
done more simply.

    print $conceal->decode(expand($conceal->encode(<>)));

Next program implements ANSI terminal sequence aware expand command.

    use Text::ANSI::Fold::Util qw(ansi_width);

    my $conceal = Text::Conceal->new(
        length => \&ansi_width,
        match  => qr/[^\t\n]+/,
    );
    while (<>) {
        print $conceal->decode(expand($conceal->encode($_)));
    }

Calling **decode** method with many arguments is not a good idea, since
replacement cycle is performed against all entries.  So collect them
into single chunk if possible.

    print $conceal->decode(join '', @expanded);

# METHODS

- **new**

    Create conceal object.  Takes following parameters.

    - **length** => _function_

        Function to calculate text width.  Default is `length`.

    - **match** => _regex_

        Specify text area to be replaced.  Default is `qr/.+/s`.

    - **max** => _number_

        When the maximum number of replacement is known, give it by **max**
        parameter to avoid unnecessary work.

    - **test** => _regex_ or _sub_

        Specify regex or subroutine to test if the argument is to be processed
        or not.  Default is **undef**, and all arguments will be subject to
        replace.

    - **except** => _string_

        Text concealing is done by replacing text with different string which
        can not be found in any arguments.  This parameter gives additional
        string which also to be taken care of.

    - **visible** => _number_ (default 0)
        - `0`

            With default value 0, this module uses characters in the range:

                [0x01 => 0x07], [0x10 => 0x1f], [0x21 => 0x7e], [0x81 => 0xfe]

        - `1`

            Use printable characters first, then use non-printable characters.

                [0x21 => 0x7e], [0x01 => 0x07], [0x10 => 0x1f], [0x81 => 0xfe]

        - `2`

            Use only printable characters.

                [0x21 => 0x7e]
    - **ordered** => _bool_ (default 1)

        Ensures that the parameters given and the order in which they appear in 
        the output do not change. The default is set to 1; if set to 0, it will 
        be handled correctly even if they appear in a different order, a 
        behavior that may lead to instability.

    - **duplicate** => _bool_ (default 0)

        It is assumed that the string before conversion appears only once
        after the process. Therefore, if the same string appears a second
        time, the conversion fails. By setting this parameter to 1, it is
        possible to allow a string to appear multiple times. However, doing so
        will increase the probability of failure if a large number of strings
        are attempted to be converted.

- **encode**
- **decode**

    Encode/Decode arguments and return them.  Given arguments will be
    altered.

# LIMITATION

All arguments given to **encode** method have to appear in the same
order in the pre-decode string.  If you want to convert unordered
output, set the `ordered` parameter to 0.  However, if a large number
of short items are included, you may get unexpected results.

Each argument can be shorter than the original, or it can even
disappear.

If an argument is trimmed down to single byte in a result, and it have
to be recovered to wide character, it is replaced by single space.

Replacement string is made of characters those are not found in any
arguments.  So if they contains all characters in the given range,
**encode** stop to work.  It requires at least two.

Minimum two characters are enough to produce correct result if all
arguments will appear in the same order.  However, if even single item
is missing, it won't work correctly.  Using three characters, one
continuous missing is allowed.  Less characters, more confusion.

# SEE ALSO

- [Text::VisualPrintf](https://metacpan.org/pod/Text%3A%3AVisualPrintf), [https://github.com/tecolicom/Text-VisualPrintf](https://github.com/tecolicom/Text-VisualPrintf)

    This module is originally implemented as a part of
    [Text::VisualPrintf](https://metacpan.org/pod/Text%3A%3AVisualPrintf) module.

- [Text::ANSI::Printf](https://metacpan.org/pod/Text%3A%3AANSI%3A%3APrintf), [https://github.com/tecolicom/Text-ANSI-Printf](https://github.com/tecolicom/Text-ANSI-Printf)

# AUTHOR

Kazumasa Utashiro

# LICENSE

Copyright 2020-2023 Kazumasa Utashiro.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

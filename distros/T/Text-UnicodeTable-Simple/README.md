[![Build Status](https://travis-ci.org/syohex/p5-Text-UnicodeTable-Simple.svg?branch=master)](https://travis-ci.org/syohex/p5-Text-UnicodeTable-Simple)
# NAME

Text::UnicodeTable::Simple - Create a formatted table using characters.

# SYNOPSIS

    use Text::UnicodeTable::Simple;
    $t = Text::UnicodeTable::Simple->new();

    $t->set_header(qw/Subject Score/);
    $t->add_row('English',     '78');
    $t->add_row('Mathematics', '91');
    $t->add_row('Chemistry',   '64');
    $t->add_row('Physics',     '95');
    $t->add_row_line();
    $t->add_row('Total', '328');

    print "$t";

    # Result:
    .-------------+-------.
    | Subject     | Score |
    +-------------+-------+
    | English     |    78 |
    | Mathematics |    91 |
    | Chemistry   |    64 |
    | Physics     |    95 |
    +-------------+-------+
    | Total       |   328 |
    '-------------+-------'

# DESCRIPTION

Text::UnicodeTable::Simple creates character table.

There are some modules for creating a text table at CPAN, [Text::ASCIITable](https://metacpan.org/pod/Text::ASCIITable),
[Text::SimpleTable](https://metacpan.org/pod/Text::SimpleTable), [Text::Table](https://metacpan.org/pod/Text::Table) etc. But those module deal with only ASCII,
don't deal with full width characters. If you use them with full width
characters, a table created may be bad-looking.

Text::UnicodeTable::Simple resolves problem of full width characters.
So you can use Japansese Hiragana, Katakana, Korean Hangeul, Chinese Kanji
characters. See `eg/` directory for examples.

# INTERFACE

## Methods

### new(%args)

Creates and returns a new table instance with _%args_.

_%args_ might be

- header :ArrayRef

    Table header. If you set table header with constructor,
    you can omit `set_header` method.

- border :Bool = True

    Table has no border if `border` is False.

- ansi\_color :Bool = False

    Ignore ANSI color escape sequence

- alignment :Int = 'left' or 'right'

    Alignment for each columns. Every columns are aligned by this if you
    specify this parameter.

### set\_header() \[alias: setCols \]

Set the headers for the table. (compare with <th> in HTML).
You must call `set_header` firstly. If you call other methods
without calling `set_header`, then you fail.

Input strings should be **string**, not **octet stream**.

### add\_row(@list\_of\_columns | \\@list\_of\_columns) \[alias: addRow \]

Add one row to the table.

Input strings should be **string**, not **octet stream**.

### add\_rows(@list\_of\_columns)

Add rows to the table. You can add row at one time.
Each `@collists` element should be ArrayRef.

### add\_row\_line() \[alias: addRowLine \]

Add a line after the current row. If 'border' parameter is false,
add a new line.

### draw()

Return the table as string.

Text::UnicodeTable::Simple overload stringify operator,
so you can omit `->draw()` method.

# AUTHOR

Syohei YOSHIDA <syohex@gmail.com>

# COPYRIGHT

Copyright 2011- Syohei YOSHIDA

# SEE ALSO

[Text::ASCIITable](https://metacpan.org/pod/Text::ASCIITable)

[Text::SimpleTable](https://metacpan.org/pod/Text::SimpleTable)

[Text::Table](https://metacpan.org/pod/Text::Table)

# LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

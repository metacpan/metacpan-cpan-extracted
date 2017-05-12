# NAME

Text::Affixes - Prefixes and suffixes analysis of text

# SYNOPSIS

    use Text::Affixes;
    my $text = "Hello, world. Hello, big world.";
    my $prefixes = get_prefixes($text);

    # $prefixes now holds
    # {
    #     3 => {
    #             'Hel' => 2,
    #             'wor' => 2,
    #     }
    # }

    # or

    $prefixes = get_prefixes({min => 1, max => 2},$text);

    # $prefixes now holds
    # {
    #     1 => {
    #             'H' => 2,
    #             'w' => 2,
    #             'b' => 1,
    #     },
    #     2 => {
    #             'He' => 2,
    #             'wo' => 2,
    #             'bi' => 1,
    #     }
    # }

    # the use for get_suffixes is similar

# DESCRIPTION

Provides methods for prefix and suffix analysis of text.

# METHODS

## get\_prefixes

Extracts prefixes from text. You can specify the minimum and maximum
number of characters of prefixes you want.

Returns a reference to a hash, where the specified limits are mapped
in hashes; each of those hashes maps every prefix in the text into the
number of times it was found.

By default, both minimum and maximum limits are 3. If the minimum
limit is greater than the lower one, an empty hash is returned.

A prefix is considered to be a sequence of word characters (\\w) in
the beginning of a word (that is, after a word boundary) that does not
reach the end of the word ("regular expressionly", a prefix is the $1
of /\\b(\\w+)\\w/).

    # extracting prefixes of size 3
    $prefixes = get_prefixes( $text );

    # extracting prefixes of sizes 2 and 3
    $prefixes = get_prefixes( {min => 2}, $text );

    # extracting prefixes of sizes 3 and 4
    $prefixes = get_prefixes( {max => 4}, $text );

    # extracting prefixes of sizes 2, 3 and 4
    $prefixes = get_prefixes( {min => 2, max=> 4}, $text);

## get\_suffixes

The get\_suffixes function is similar to the get\_prefixes one. You
should read the documentation for that one and than come back to this
point.

A suffix is considered to be a sequence of word characters (\\w) in
the end of a word (that is, before a word boundary) that does not start
at the beginning of the word ("regular expressionly" speaking, a
suffix is the $1 of /\\w(\\w+)\\b/).

    # extracting suffixes of size 3
    $suffixes = get_suffixes( $text );

    # extracting suffixes of sizes 2 and 3
    $suffixes = get_suffixes( {min => 2}, $text );

    # extracting suffixes of sizes 3 and 4
    $suffixes = get_suffixes( {max => 4}, $text );

    # extracting suffixes of sizes 2, 3 and 4
    $suffixes = get_suffixes( {min => 2, max=> 4}, $text);

# OPTIONS

Apart from deciding on a minimum and maximum size for prefixes or suffixes, you
can also decide on some configuration options.

## exclude\_numbers

Set to 0 if you consider numbers as part of words. Default value is 1.

    # this
    get_suffixes( {min => 1, max => 1, exclude_numbers => 0}, "Hello, but w8" );

    # returns this:
      {
        1 => {
               'o' => 1,
               't' => 1,
               '8' => 1
             }
      }

## lowercase

Set to 1 to extract all prefixes in lowercase mode. Default value is 0.

ATTENTION: This does not mean that prefixes with uppercased characters won't be
extracted. It means they will be extracted after being lowercased.

    # this...
    get_prefixes( {min => 2, max => 2, lowercase => 1}, "Hello, hello");

    # returns this:
      {
        2 => {
               'he' => 2
             }
      }

# TO DO

- Make it more efficient (use C for that)

# AUTHOR

Jose Castro, `<cog@cpan.org>`

# COPYRIGHT & LICENSE

Copyright 2004 Jose Castro, All Rights Reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

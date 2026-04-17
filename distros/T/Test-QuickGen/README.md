# NAME

Test::QuickGen - Utilities for generating random test data

# SYNOPSIS

    use Test::QuickGen qw(:all);

    my $id = id();
    my $ascii = ascii_string(10);
    my $alphanum = alphanumeric_string(10);
    my $utf8 = utf8_string(20);
    my $clean = utf8_sanitized(15);

    my $rand = between(1, 100);
    my $opt = nullable("value");
    my $item = pick(qw(a b c));

    my $words = words(\&ascii_string, 5);

# DESCRIPTION

`Test::QuickGen` provides a set of utility functions for generating random
data, primarily intended for testing purposes. These generators are simple,
fast, and have minimal dependencies.

# COMMAND LINE TOOL

This module comes bundled with an optional test runner, see [quicktest](https://metacpan.org/pod/quicktest) for
more details.

# IMPORTING

Nothing is exported by default.

Import functions explicitly:

    use Test::QuickGen qw(id ascii_string);

Import groups of functions using tags:

    use Test::QuickGen qw(:all);
    use Test::QuickGen qw(:ascii);
    use Test::QuickGen qw(:utf8);
    use Test::QuickGen qw(:basic);

- `:all`

    All available functions.

- `:ascii`

    ASCII specific functions.

- `:utf8`

    UTF-8 specific functions.

- `:basic`

    Simple utils like `pick` or `id`.

See source for exact composition of the imports.

# FUNCTIONS

## id

    my $id1 = id();
    my $id2 = id();

    # $id1 != $id2

Returns a monotonically increasing integer starting from 0.

The counter is process-local and resets each time the program runs.

## string\_of($n, @chars)

    my $str = string_of(10, qw(a b c));

Generates a random string of length `$n` using the provided list of characters `@chars`.

- `$n` must be a non-negative integer.
- At least one character must be provided.

## ascii\_string($n)

    my $str = ascii_string(10);

Generates a random ASCII string length `$n`.

The character set includes all visible ASCII symbols and characters (in the
range 33 to 126).

## alphanumeric\_string($n)

    my $str = alphanumeric_string($n);

Generates a random ASCII string of only alphanumericeric characters of
length `$n`.

## utf8\_string($n)

    my $str = utf8_string(10);

Generates a random UTF-8 string of `$n` characters.

The generator:

- Includes visible Unicode characters up to code point `0x2FFF`.
- Excludes control characters and invalid Unicode ranges.
- Skips surrogate pairs and non-characters.

Note: Because characters may vary in byte length, this function targets
character count (not byte length).

## utf8\_sanitized($n)

    my $clean = utf8_sanitized(10);

Generates a UTF-8 string of length `$n` and removes all non-alphanumericeric
characters, retaining only:

- Unicode letters (`\p{L}`)
- Unicode numbers (`\p{N}`)
- Whitespace

If all characters are filtered out, the function retries until a non-empty
string is produced.

## words($gen, $n, $max\_len = 70)

    my $str = words(\&string_generator, 5);

Generates a string made up of `$n` space-separated "words".

Each word is produced by calling the generator function `$gen`.

- `$gen`

    A coderef that is called once per word.

    It accepts a single integer argument (the desired length), and returns a string.

    For example:

        sub string_generator {
          my ($len) = @_;
          # return a string of length $len
        }

- `$max_len`

    An optional parameter to set the maximum length (inclusive) of a word.
    Defaults to 70. Must be a positive number.

- Word generation

    For each of the `$n` words, a random length between 1 and `$max_len` is
    chosen. That length is passed to `$gen`, which returns the word.

- Output format

    The generated words are joined together with a single space.

Example:

    words(\&ascii_string, 3);
    # might return: "aZ3 kLm92 Q"

## between($min, $max)

    my $n = between(1, 10);

Returns a random integer between `$min` and `$max` (inclusive).

`$min` must be <= `$max`.

## nullable($val)

    my $value = nullable("data");

Returns either the given value or `undef`.

25% chance of returning `undef`, 75% chance of returning the original value.
Useful for testing optional fields.

## pick(@items)

    my $item = pick(qw(a b c));

Returns a random element from the provided list.

If provided an empty list, will return `undef`.

# NOTES

- These functions are not cryptographically secure.
- Randomness uses the builtin function [rand](https://metacpan.org/pod/perlfunc#rand), so all limitations
that apply to that also apply here. Randomness in this module's functions is
uniform in its distribution unless specified otherwise.
- They are intended for testing, fuzzing, and data generation only.

# AUTHOR

Antonis Kalou <kalouantonis@protonmail.com>

# CONTRIBUTORS

**bas080**: [https://github.com/bas080](https://github.com/bas080)

**Penfold**: Mike Whitaker <pendfold@cpan.org>

# LICENSE

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself. See `LICENSE` for details.

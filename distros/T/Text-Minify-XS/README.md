# NAME

Text::Minify::XS - remove indentation and trailing whitespace

# VERSION

version v0.6.3

# SYNOPSIS

```perl
use Text::Minify::XS qw/ minify /;

my $out = minify( $in );
```

# DESCRIPTION

This is a simple and fast text minifier that removes quickly extra
whitespace from multi-line text.

# EXPORTS

None by default.

## minify

```perl
my $out = minify( $in );
```

This is a quick-and-dirty text minifier that removes indentation and
trailing whitespace from a multi-line text document in a single pass.

It does the following:

- removes leading whitespace (indentation),
- removes trailing whitespace,
- collapses multiple newlines,
- and changes carriage returns to newlines.

It does not recognise any form of markup, comments or text quoting.
Nor does it remove extra whitespace in the middle of the line.

Because it does not recognise any markup, newlines are not removed
since they may be significant.

## minify\_utf8

This is an alias for ["minify"](#minify).  It was added in v0.5.3.

## minify\_ascii

This is a version of ["minify"](#minify) that works on ASCII text. It was added in v0.5.3.

If you are only processing 8-bit text, then it should be faster.
(Rudimentary benchmarks show it is twice as fast as ["minify"](#minify).)

Unlike the ["minify"](#minify), if the input string has the UTF-8 flag set, the
resulting string will not.  You should ensure the string is properly
encoded.

# KNOWN ISSUES

## Malformed UTF-8

Malformed UTF-8 characters may be be mangled or omitted from the
output.  In extreme cases it may throw an exception in order to avoid
memory overflows. You should ensure that the input string is properly
encoded as UTF-8.

# SEE ALSO

There are many string trimming and specialised whitespace/comment-removal modules on CPAN.
It is not practical to include such a list.

# SOURCE

The development version is on github at [https://github.com/robrwo/Text-Minify-XS](https://github.com/robrwo/Text-Minify-XS)
and may be cloned from [git://github.com/robrwo/Text-Minify-XS.git](git://github.com/robrwo/Text-Minify-XS.git)

# BUGS

Please report any bugs or feature requests on the bugtracker website
[https://github.com/robrwo/Text-Minify-XS/issues](https://github.com/robrwo/Text-Minify-XS/issues)

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

# AUTHOR

Robert Rothenberg <rrwo@cpan.org>

# COPYRIGHT AND LICENSE

This software is Copyright (c) 2020-2022 by Robert Rothenberg.

This is free software, licensed under:

```
The Artistic License 2.0 (GPL Compatible)
```

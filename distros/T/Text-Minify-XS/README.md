# NAME

Text::Minify::XS - Simple text minification

# VERSION

version v0.3.6

# SYNOPSIS

```perl
use Text::Minify::XS qw/ minify /;

my $out = minify( $in );
```

# EXPORTS

## minify

```perl
my $out = minify( $in );
```

This is a quick-and-dirty text minifier that removes whitespace in a
single pass.

It does the following:

- removes leading whitespace (indentation),
- removes trailing whitespace,
- removes multiple newlines,
- and changes carriage returns to newlines.

It does not recognise any form of markup, comments or text quoting.

# KNOWN ISSUES

## Support for older Perl versions

This module requires Perl v5.9.3 or newer.

Pull requests to support older versions of Perl are welcome. See
["SOURCE"](#source).

## Malformed UTF-8

Malformed UTF-8 characters may be be mangled or omitted from the
output. You should ensure that the input string is properly encoded as
UTF-8.

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

This software is Copyright (c) 2020-2021 by Robert Rothenberg.

This is free software, licensed under:

```
The Artistic License 2.0 (GPL Compatible)
```

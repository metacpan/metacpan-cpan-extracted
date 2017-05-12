# NAME 

re::engine::Hyperscan - High-performance regular expression matching library (Intel only)

# SYNOPSIS

    use re::engine::Hyperscan;

    if ("Hello, world" =~ /(Hello|Hi), (world)/) {
        print "Greetings, $1!";
    }

# DESCRIPTION

ALPHA - Does not work YET

Replaces perl's regex engine in a given lexical scope with Intel's 
Hyperscan regular expressions provided by `libhyperscan`.

This provides the fastest regular expression library on Intel-CPU's
only, but needs to fall back to the core perl regexp compiler with
backtracking, lookbehind, zero-width assertions and more advanced
patterns.  It is typically 50% faster then the core regex engine.

For the supported syntax see
[https://01org.github.io/hyperscan/dev-reference/compilation.html](https://01org.github.io/hyperscan/dev-reference/compilation.html).

With the following unsupported constructs in the pattern, the compiler
will fall back to the core re engine:

- Backreferences and capturing sub-expressions.
- Arbitrary zero-width assertions.
- Subroutine references and recursive patterns.
- Conditional patterns.
- Backtracking control verbs.
- The `\C` "single-byte" directive (which breaks UTF-8 sequences).
- The `\R` newline match.
- The `\K` start of match reset directive.
- Callouts and embedded code.
- Atomic grouping and possessive quantifiers.

# METHODS

- min\_width (RX)

    Returns the result from hs\_expression\_info(). NYI
    The minimum length in bytes of a match for the pattern.

- max\_width (RX)

    Returns the result from hs\_expression\_info(). NYI
    The maximum length in bytes of a match for the pattern. If the pattern
    has an unbounded maximum width, this will be set to the maximum value of
    an unsigned int (UINT\_MAX).

- unordered\_matches (RX)

    Returns the result from hs\_expression\_info(). NYI
    Whether this expression can produce matches that are not returned in
    order, such as those produced by assertions.

- matches\_at\_eod (RX)

    Returns the result from hs\_expression\_info(). NYI
    Whether this expression can produce matches at end of data (EOD).

- matches\_only\_at\_eod (RX)

    Returns the result from hs\_expression\_info(). NYI
    Whether this expression can \*only\* produce matches at end of data (EOD).

# FUNCTIONS

- ENGINE

    Returns a pointer to the internal Hyperscan engine, the database,
    suitable for the XS API `(regexp*)re->engine` field.

# AUTHORS

Reini Urban <rurban@cpan.org>

# COPYRIGHT

Copyright 2017 Reini Urban.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

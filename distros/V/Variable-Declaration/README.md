[![Build Status](https://travis-ci.org/kfly8/Variable-Declaration.svg?branch=master)](https://travis-ci.org/kfly8/Variable-Declaration)
# NAME

Variable::Declaration - declare with type constraint

# SYNOPSIS

    use Variable::Declaration;
    use Types::Standard '-all';

    # variable declaration
    let $foo;      # is equivalent to `my $foo`
    static $bar;   # is equivalent to `state $bar`
    const $baz;    # is equivalent to `my $baz;dlock($baz)`

    # with type constraint

    # init case
    let Str $foo = {}; # => Reference {} did not pass type constraint "Str"

    # store case
    let Str $foo = 'foo';
    $foo = {}; # => Reference {} did not pass type constraint "Str"

# DESCRIPTION

Variable::Declaration provides new variable declarations, i.e. \`let\`, \`static\`, and \`const\`.

\`let\` is equivalent to \`my\` with type constraint.
\`static\` is equivalent to \`state\` with type constraint.
\`const\` is equivalent to \`let\` with data lock.

# LICENSE

Copyright (C) Kenta, Kobayashi.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

Kenta, Kobayashi <kentafly88@gmail.com>

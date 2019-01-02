[![Build Status](https://travis-ci.org/kfly8/p5-Variable-Declaration.svg?branch=master)](https://travis-ci.org/kfly8/p5-Variable-Declaration) [![Coverage Status](https://img.shields.io/coveralls/kfly8/p5-Variable-Declaration/master.svg?style=flat)](https://coveralls.io/r/kfly8/p5-Variable-Declaration?branch=master) [![MetaCPAN Release](https://badge.fury.io/pl/Variable-Declaration.svg)](https://metacpan.org/release/Variable-Declaration)
# NAME

Variable::Declaration - declare with type constraint

# SYNOPSIS

```perl
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
```

# DESCRIPTION

Warning: This module is still new and experimental. The API may change in future versions. The code may be buggy.

Variable::Declaration provides new variable declarations, i.e. `let`, `static`, and `const`.

`let` is equivalent to `my` with type constraint.
`static` is equivalent to `state` with type constraint.
`const` is equivalent to `let` with data lock.

## LEVEL

You can specify the LEVEL in three stages of checking the specified type:

`LEVEL 0` does not check type,
`LEVEL 1` check type only at initializing variables,
`LEVEL 2` check type at initializing variables and reassignment.
`LEVEL 2` is default level.

```perl
# CASE: LEVEL 2 (DEFAULT)
use Variable::Declaration level => 2;

let Int $s = 'foo'; # => ERROR!
let Int $s = 123;
$s = 'bar'; # => ERROR!

# CASE: LEVEL 1
use Variable::Declaration level => 1;

let Int $s = 'foo'; # => ERROR!
let Int $s = 123;
$s = 'bar'; # => NO error!

# CASE: LEVEL 0
use Variable::Declaration level => 0;

let Int $s = 'foo'; # => NO error!
let Int $s = 123;
$s = 'bar'; # => NO error!
```

There are three ways of specifying LEVEL.
First, as shown in the example above, pass to the arguments of the module.
Next, set environment variable `$ENV{Variable::Declaration::LEVEL}`.
Finally, set `$Variable::Declaration::DEFAULT_LEVEL`.

# LICENSE

Copyright (C) kfly8.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

kfly8 <kfly@cpan.org>

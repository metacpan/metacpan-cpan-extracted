[![Actions Status](https://github.com/kfly8/p5-namespace-allclean/workflows/test/badge.svg)](https://github.com/kfly8/p5-namespace-allclean/actions) [![Coverage Status](https://img.shields.io/coveralls/kfly8/p5-namespace-allclean/master.svg?style=flat)](https://coveralls.io/r/kfly8/p5-namespace-allclean?branch=master) [![MetaCPAN Release](https://badge.fury.io/pl/namespace-allclean.svg)](https://metacpan.org/release/namespace-allclean)
# NAME

namespace::allclean - Avoid imports all subroutines into your namespace

# SYNOPSIS

```perl
package Foo;
use namespace::allclean;
sub bar { }

# later on:
Foo->bar; # will fail. `bar` got cleaned after compilation.
```

# DESCRIPTION

`namespace::allclean` will remove all subroutines at the end of
the current package's compile cycle. Functions called in the package
itself will still be bound by their name, but they won't show up
as methods on your class or instances.

This module is intended to be used when defining the interface.

# LICENSE

Copyright (C) kfly8.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

kfly8 <kfly8@cpan.org>

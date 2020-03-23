[![Actions Status](https://github.com/thibaultduponchelle/Test-Slow/workflows/linux/badge.svg)](https://github.com/thibaultduponchelle/Test-Slow/actions) [![Actions Status](https://github.com/thibaultduponchelle/Test-Slow/workflows/macos/badge.svg)](https://github.com/thibaultduponchelle/Test-Slow/actions) [![Actions Status](https://github.com/thibaultduponchelle/Test-Slow/workflows/windows/badge.svg)](https://github.com/thibaultduponchelle/Test-Slow/actions) [![Kritika Status](https://kritika.io/users/thibaultduponchelle/repos/thibaultduponchelle+Test-Slow/heads/master/status.svg)](https://kritika.io/users/thibaultduponchelle/repos/thibaultduponchelle+Test-Slow)
# NAME

Test::Slow - Skip test(s) that are too slow to run frequently

# SYNOPSIS

Some test are too slow to run frequently. This module makes it
easy to skip slow tests so that you can run the others more
frequently. To mark a test as slow simply `use` this module:

```perl
use Test::Slow;
use Test::More;
...
done_testing;
```

To run just the quick tests, set the `QUICK_TEST` environment
variable to a true value:

```
$ QUICK_TEST=1 prove --lib t/*t
```

The other approach is to disable slow tests by default and run 
them only when requested :

```perl
use Test::Slow "skip";
use Test::More;
...
done_testing;
```

To run even the slow tests, set the `SLOW_TESTS` environment 
variable to a true value :

```
$ SLOW_TEST=1 prove --lib t/*t
```

# COPYRIGHT & LICENSE

Copyright 2010-2020 Tomáš Znamenáček, zoul@fleuron.cz

Copyright 2020 Thibault Duponchelle, thibault.duponchelle@gmail.com

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

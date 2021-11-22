Tree::RB::XS
------------

### About

This module provides a similar API to Tree::RB, but is implemented in XS for
a speed boost.

### Installing

When distributed, all you should need to do is run

    perl Makefile.PL
    make install

or better,

    cpanm Tree-RB-XS.tar.gz

or from CPAN:

    cpanm Tree::RB::XS

### Developing

However if you're trying to build from a fresh Git checkout, you'll need
the Dist::Zilla tool (and many plugins) to create the Makefile.PL

    cpanm Dist::Zilla
    dzil listdeps | cpanm
    dzil build

While Dist::Zilla takes the busywork and mistakes out of module authorship,
it fails to address the need of XS authors to easily compile XS projects
and run single testcases, rather than the whole test suite.  For this, you
might find the following script handy:

    ./dzil-prove t/15-insert.t  # or any other testcase

which runs "dzil build" to get a clean dist, then enters the build directory
and runs "perl Makefile.PL" to compile the XS, then "prove -lvb t/15-insert.t".

### Copyright

This software is copyright (c) 2021 by Michael Conrad

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

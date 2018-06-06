X11::GLX
--------

### About

This module provides Perl5 access to the low-level C API of the X11 bindings
for OpenGL (known as "GLX")  It uses Perl XS on the back-end, and so requires
a working C compiler.

This module is heavily based on X11::Xlib, and uses some of its back-end XS
functions and structures, so you should try to make sure this module gets
compiled by the same compiler as X11::Xlib.

### Installing

When distributed, all you should need to do is run

    perl Makefile.PL
    make install

or better,

    cpanm X11-GLX.tar.gz

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

    ./dtest t/30-dwim.t  # or any other testcase

which runs "dzil build" to get a clean dist, then enters the build directory
and runs "perl Makefile.PL" to compile the XS, then "prove -lvb t/30-dwim.t".

### Copyright

This software is copyright (c) 2017 by Michael Conrad

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

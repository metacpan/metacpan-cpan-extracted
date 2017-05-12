Text/Diff/HTML version 0.07
===========================

This class subclasses
[Text::Diff::Unified](http://search.cpan.org/perldoc?Text::Diff::Unified), a
formatting class provided by the
[Text-Diff](http://search.cpan.org/dist/Text-Diff) distribution, to add XHTML
markup to the unified diff format.

In the XHTML formatted by this module, the contents of the diff are wrapped in
a `<div>` element, as is each hunk of the diff. Within each hunk, all content
is properly HTML encoded and the various sections of the diff are marked up
with the appropriate XHTML elements.

Installation
------------

To install this module, type the following:

    perl Build.PL
    ./Build
    ./Build test
    ./Build install

Or, if you don't have Module::Build installed, type the following:

    perl Makefile.PL
    make
    make test
    make install

Dependencies
------------

Text::WordDiff requires the following modules:

* Text::Diff 0.11
* HTML::Entities

Copyright and Licence
---------------------

Copyright (c) 2005-2011 David E. Wheeler. Some Rights Reserved.

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.


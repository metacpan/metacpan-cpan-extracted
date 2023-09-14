Text/Markup version 0.31
========================

[![CPAN version](https://badge.fury.io/pl/Text-Markup.svg)](https://badge.fury.io/pl/Text-Markup)
[![Build Status](https://github.com/theory/text-markup/workflows/CI/badge.svg)](https://github.com/theory/text-markup/actions/)

This library's module, Text::Markup, provides an single interface for parsing
a large number of text markup formats and converting them to HTML. It
currently supports the following markups:

*   [Asciidoc](https://asciidoc.org)
*   [BBcode](https://www.bbcode.org)
*   [Creole](https://www.wikicreole.org)
*   [HTML](https://whatwg.org/html)
*   [Markdown](https://daringfireball.net/projects/markdown/)
*   [MediaWiki](https://en.wikipedia.org/wiki/Help:Contents/Editing_Wikipedia)
*   [MultiMarkdown](https://fletcherpenney.net/multimarkdown/)
*   [Pod](https://metacpan.org/dist/perl/view/pod/perlpodspec.pod)
*   [reStructuredText](https://docutils.sourceforge.io/rst.html)
*   [Textile](https://textile-lang.com)
*   [Trac](https://trac.edgewall.org/wiki/WikiFormatting)

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

Text-Markup requires the following modules:

* File::BOM 0.15
* HTML::Entities
* perl 5.8.1
* Pod::Simple::XHTML 3.15
* Text::Markdown 1.000004
* Text::MediawikiFormat 1.0
* Text::Textile 2.10
* Text::Trac 0.10
* Parse::BBCode 0.15
* Text::WikiCreole 0.07

Copyright and Licence
---------------------

Copyright (c) 2011-2023 David E. Wheeler. Some Rights Reserved.

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

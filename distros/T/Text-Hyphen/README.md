# NAME

Text::Hyphen - determine positions for hyphens inside words

# SYNOPSIS

This module implements Knuth-Liang algorithm to find positions inside
words where it is possible to insert hyphens to break a line.

The original Knuth patterns for English language are built-in.
If you need to hyphenate other languages, please see Text::Hyphen::\*
modules on CPAN.

    use Text::Hyphen;

    my $hyphenator = new Text::Hyphen;

    print $hyp->hyphenate('representation', '-');
    # prints rep-re-sen-ta-tion

    print map "($_)", $hyp->hyphenate('multiple');
    # prints "(mul)(ti)(ple)"

# EXPORT

This version does not export anything and uses OOP interface.

# FUNCTIONS

## new(%options)

Creates the hyphenator object.

You can pass several options:

- min\_word

    Minimum length of word to be hyphenated. Shorter words are returned
    right away. Defaults to 5 for English.

- min\_prefix

    Minimal prefix to leave without any hyphens. Defaults to 2 for
    English.

- min\_suffix

    Minimal suffix to leave wothout any hyphens. Defaults to 2 for
    English.

## hyphenate($word, \[$delim\])

Hyphenates the `$word`.

If $delim is undefined then in list context this method will break the word
into pieces on hyphenation positions and return the list of the pieces.
In scalar context it will return the $word with "-" inserted into suggested
hyphenation positions.

If $delim is defined this methods returns the $word with $delim inserted
into hyphenation positions.

Basically, it tries to DWIM.

# AUTHOR

Alex Kapranoff, `<kappa at cpan.org>`

# BUGS AND SUPPORT

This code is hoste don Github, please see [https://github.com/kappa/Text-Hyphen](https://github.com/kappa/Text-Hyphen).

Please report any bugs or feature requests to GitHub issues.

You can also look for information at:

- AnnoCPAN: Annotated CPAN documentation

    [http://annocpan.org/dist/Text-Hyphen](http://annocpan.org/dist/Text-Hyphen)

- CPAN Ratings

    [http://cpanratings.perl.org/d/Text-Hyphen](http://cpanratings.perl.org/d/Text-Hyphen)

- Search CPAN

    [http://search.cpan.org/dist/Text-Hyphen](http://search.cpan.org/dist/Text-Hyphen)

# ACKNOWLEDGEMENTS

Donald Knuth and Frank Liang for the algorithm.

Alexander Lebedev for all his valuable work on russian ispell
dictionaries and russian hyphenation patterns. See his archive
at [ftp://scon155.phys.msu.ru/pub/russian/](ftp://scon155.phys.msu.ru/pub/russian/).

Mark-Jason Dominus and Jan Pazdziora for [Text::Hyphenate](https://metacpan.org/pod/Text::Hyphenate) and [TeX::Hyphenate](https://metacpan.org/pod/TeX::Hyphenate)
modules on CPAN.

Ned Batchelder for his public domain Python implementation of
Knuth-Liang algorithm available at [http://nedbatchelder.com/code/modules/hyphenate.html](http://nedbatchelder.com/code/modules/hyphenate.html).

# COPYRIGHT & LICENSE

Copyright 2008-2015 Alex Kapranoff.

This is free software; you can redistribute it and/or modify it under
the terms GNU General Public License version 3.

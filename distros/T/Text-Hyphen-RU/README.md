# NAME

Text::Hyphen::RU - determine positions for hyphens inside russian words

# SYNOPSIS

This module is an implementation of Knuth-Liang hyphenation algorithm
for russian text using Alexander Lebedev's russian patterns.

    use Text::Hyphen::RU;

    my $hyphenator = new Text::Hyphen::RU;

    print $hyphenator->hyphenate($russian_word_in_Unicode);
    # prints hyphenated with dashes

# EXPORT

See [Text::Hyphen](https://metacpan.org/pod/Text::Hyphen) for the interface documentation.

This module only provides russian patterns.

# AUTHOR

Alex Kapranoff, `<kappa at cpan.org>`

# BUGS

Please report any bugs or feature requests to `bug-text-hyphen at rt.cpan.org`, or through
the web interface at [http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Text-Hyphen](http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Text-Hyphen).  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

# SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Text::Hyphen::RU

You can also look for information at:

- RT: CPAN's request tracker

    [http://rt.cpan.org/NoAuth/Bugs.html?Dist=Text-Hyphen](http://rt.cpan.org/NoAuth/Bugs.html?Dist=Text-Hyphen)

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
at [ftp://scon155.phys.msu.ru/pub/russian/](ftp://scon155.phys.msu.ru/pub/russian/) or his hyphenation page
at [http://scon155.phys.msu.su/~swan/hyphenation.html](http://scon155.phys.msu.su/~swan/hyphenation.html).

These patterns are also a part of ruhyphen CTAN package which
is available at [https://www.ctan.org/tex-archive/language/hyphenation/ruhyphen](https://www.ctan.org/tex-archive/language/hyphenation/ruhyphen).

# COPYRIGHT & LICENSE

Copyright 2008-2015 Alex Kapranoff.

This is free software; you can redistribute it and/or modify it under
the terms GNU General Public License version 3.

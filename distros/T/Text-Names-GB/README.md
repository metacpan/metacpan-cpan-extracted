# NAME

Text::Names::GB - Perl extension for proper name parsing, normalization, recognition, and classification

# VERSION

Version 0.03

# SYNOPSIS

The documentation for Text::Names doesn't make this clear, that module is specific to the US.
This module fixes that for the UK.
Unfortunately because of the nature of Text::Names other countries will also have
to be implemented as subclasses.

# SUBROUTINES/METHODS

## guessGender

Overrides the US tests with UK tests,
that's probably true in most other countries as well.

# AUTHOR

Nigel Horne, `<njh at bandsman.co.uk>`

# BUGS

I need to work out how to make ISA and Exporter play nicely with each other.

# SEE ALSO

[Text::Names](https://metacpan.org/pod/Text::Names)

# SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Text::Names::GB

You can also look for information at:

- RT: CPAN's request tracker

    [http://rt.cpan.org/NoAuth/Bugs.html?Dist=Text-Names-GB](http://rt.cpan.org/NoAuth/Bugs.html?Dist=Text-Names-GB)

- AnnoCPAN: Annotated CPAN documentation

    [http://annocpan.org/dist/Text-Names-GB](http://annocpan.org/dist/Text-Names-GB)

- CPAN Ratings

    [http://cpanratings.perl.org/d/Text-Names-GB](http://cpanratings.perl.org/d/Text-Names-GB)

- Search CPAN

    [http://search.cpan.org/dist/Text-Names-GB/](http://search.cpan.org/dist/Text-Names-GB/)

# LICENSE AND COPYRIGHT

Copyright 2017-2019 Nigel Horne.

This program is released under the following licence: GPL2

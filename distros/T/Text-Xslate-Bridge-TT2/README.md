# NAME

Text::Xslate::Bridge::TT2 - Template-Toolkit virtual methods and filters for Xslate (deprecated)

# VERSION

This document describes Text::Xslate::Bridge::TT2 version 1.0002.

# SYNOPSIS

    use Text::Xslate;

    my $xslate = Text::Xslate->new(
        module => ['Text::Xslate::Bridge::TT2'],
    );

    print $xslate->render_string('<: "foo".length() :>'); # => 3

# DESCRIPTION

This is __a demo module to extend Text::Xslate::Brige__. Use [Text::Xslate::Bridge::TT2Like](http://search.cpan.org/perldoc?Text::Xslate::Bridge::TT2Like), which is a stand alone utilities compatible with TT2.

# CAVEAT

## Limitation of dynamic filters

All the dynamic filters require parens (i.e. to "call" them first),
even if you want to omit their arguments.

    [% FILTER repeat   # doesn't work! %]
    [% FILTER repeat() # works. %]

## Unsupported features

Filters that require Template-Toolkit context object are not supported,
which include `eval`, `evaltt`, `perl`, `evalperl` and `redirect`.

# DEPENDENCIES

Perl 5.8.1 or later.

# BUGS

All complex software has bugs lurking in it, and this module is no
exception. If you find a bug please either email me, or add the bug
to cpan-RT.

# SEE ALSO

[Text::Xslate](http://search.cpan.org/perldoc?Text::Xslate)

[Template](http://search.cpan.org/perldoc?Template)

[Template::Manual::VMethods](http://search.cpan.org/perldoc?Template::Manual::VMethods)

[Template::Manual::Filters](http://search.cpan.org/perldoc?Template::Manual::Filters)

# AUTHOR

Fuji, Goro (gfx) <gfuji@cpan.org>

# LICENSE AND COPYRIGHT

Copyright (c) 2010-2013, Fuji, Goro (gfx). All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. See [perlartistic](http://search.cpan.org/perldoc?perlartistic) for details.

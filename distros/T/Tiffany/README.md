# NAME

Tiffany - Generic interface for Perl5 template engines.

# SYNOPSIS

    use Tiffany;

    my $tmpl = Tiffany->load('Text::Xslate', {syntax => 'TTerse'});
    $tmpl->render(\'Hello, [% name %]', {name => 'John'});
    # => "Hello, John"

# DESCRIPTION

Tiffany is a generic interface for Perl5 template engines.

# FACTORY METHOD

Tiffany.pm acts as a factory for Tiffany::\* classes, which in turn are the actual adaptor classes for each template engine.

- `my $tiffany = Tiffany->load($klass, $args)`

    Load Tiffany::\* class if necessary, and create new instance of using the given arguments.

        my $xslate = Tiffany->load("Text::Xslate", +{syntax => 'TTerse'});

        my $xslate = Tiffany->load("+My::Template::Engine", +{option => 'here'});

# The Tiffany Protocol

The Tiffany protocol is based on duck typing. A template adaptor does not need to inherit from a particular class, but its API needs to adhere to the spec provided here.

In the documentation that follows, `Tiffany::Thing` represents an adaptor class.

- `my $tiffanny = Tiffany::Thing->new([$args:HashRef|ArrayRef]);`

    The module SHOULD have a __new__ method.

    This method creates a new instance of Tiffany module.

    $args should be passed to the constructor of the template engine.

- `my $result = $tmpl->render($stuff:Scalar|ScalarRef [, @args]);`

    The module SHOULD have a __render__ method.

    This method should invoke the appropriate rendering method for the underlying template engine, using @args.

    If the template engine found any errors, this method MUST throw an exception.

    If the template engine throws any exceptions, Tiffany module SHOULD pass through the exception unaltered.

    __$stuff__ SHOULD expect a Scalar that represents the template filename. The module MAY allow a ScalarRef that holds the actual template code.

    This method MUST return plain string. Do not return a blessed reference.

# HOW TO USE IT IN MY WEB APPLICATION FRAMEWORK?

Example code is here: eg/sinatraish/ in distribution tar ball or [http://github.com/tokuhirom/p5-tiffany/tree/master/eg/sinatraish/](http://github.com/tokuhirom/p5-tiffany/tree/master/eg/sinatraish/).

# FAQ

- Is Tiffany supports JSON?

    Tiffany should not support JSON. Tiffany protocol can support JSON serialize.
    But real web application needs more things like Content-Type.
    It is not supported area for Tiffany.

# AUTHOR

Tokuhiro Matsuno <tokuhirom AAJKLFJEF@ GMAIL COM>

# SEE ALSO

[Any::Template](http://search.cpan.org/perldoc?Any::Template), [http://github.com/rtomayko/tilt](http://github.com/rtomayko/tilt)

# THANKS TO

kazuhooku

gfx

miyagawa

lestrrat

# LICENSE

Copyright (C) Tokuhiro Matsuno

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

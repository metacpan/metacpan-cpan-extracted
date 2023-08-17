[![Actions Status](https://github.com/nyarla/p5-Text-HyperScript/actions/workflows/test.yml/badge.svg)](https://github.com/nyarla/p5-Text-HyperScript/actions)
# NAME

Text::HyperScript - Let's write html/xml templates as perl code!

# SYNOPSIS

    use feature qw(say);
    use Text::HyperScript qw(h true);

    # tag only
    say h('hr');          # => '<hr />'
    say h(script => q{}); # => '<script></script>'

    # tag with content
    say h('p', 'hi,');    # => '<p>hi,</p>'
    say h('p', ['hi,']);  # => '<p>hi,</p>'

    say h('p', 'hi', h('b', ['anonymous']));  # => '<p>hi,<b>anonymous</b></p>'
    say h('p', 'foo', ['bar'], 'baz');        # => '<p>foobarbarz</p>'

    # tag with attributes
    say h('hr', { id => 'foo' });                     # => '<hr id="foo" />'
    say h('hr', { id => 'foo', class => 'bar'});      # => '<hr class="bar" id="foo">'
    say h('hr', { class => ['foo', 'bar', 'baz'] });  # => '<hr class="bar baz foo">' 

    # tag with prefixed attributes
    say h('hr', { data => { foo => 'bar' } });              # => '<hr data-foo="bar">'
    say h('hr', { data => { foo => [qw(foo bar baz)] } });  # => '<hr data-foo="bar baz foo">'

    # tag with value-less attribute
    say h('script', { crossorigin => true }, ""); # <script crossorigin></script>

# DESCRIPTION

This module is a html/xml tags generator like as hyperscript-ish style.

# FEATURES

- All html/xml tags write as perl code!

    We're able to write html/xml templates witout raw markup.

- Generates automatic escaped html/xml tags

    This module generates automatic escaped html/xml tags by default.

    Like this:

        use feature qw(say);
        
        say h('p', 'hello, <script>alert("XSS!")</script>')
        # => <p>hello, &lt;scrip&gt;alert("XSS!")&lt;/script&gt;</p>

- Includes shorthand for multiple class name and prefixed attributes

    This module has shorthand multiple class name, and data or aria and others prefixed attributes.

    For examples:

        use feature qw(say);
        
        say h('h1', { class => [qw/ C B A /] }, 'msg');
        # => <h1 class="A B C">msg</h1>
        
        say h('button', { data => { click => '1' } }, 'label');
        # => <button data-click="1">label</button>
        
        say h('a', { href => '#', aria => {label => 'label' } }, 'link');
        # => <a aria-label="label" href="#">link</a>

- Enable to generate empty and empty content tags

    This module supports empty element and empty content tags.

    Like that:

        use feature qw(say);
        
        say h('hr'); # empty tag
        # => <hr />
        
        say h('script', '') # empty content tag
        # => <script></script>

# TAGSETS

This modules includes shorthand modules for writes tag name as subroutine.

Currently Supported:

HTML5: [Text::HyperScript::HTML5](https://metacpan.org/pod/Text%3A%3AHyperScript%3A%3AHTML5)

# MODULE FUNCTIONS

## text

This function generates html/xml escaped text.

## raw

This function generates raw text **without html/xml escape**.

This function **should be used for display trusted text content**.

## true / false (constants)

This constants use for value-less attributes.

For examples, if we'd like to use `crossorigin` attriute on `script` tag,
we're able to use these contants like this:

    use feature qw(say);

    say h('scirpt', { crossorigin => true }, '')
    # => <scritp crossorigin></script>

`false` constants exists for override value-less attributes.
If set `false` to value-less attribute, that attribute ignored.

## h

This function makes html/xml text from perl code.

The first argument is tag name, and after argument could be passed these values as repeatable.

NOTICE:

The all element attributes sorted by ascendant.

This behaviour is intentional for same result of reproducible output.

- $text : Str

    The text string uses as a element content.

    For example:

        use feature qw(say);

        say h('p', 'hi,') # <- 'hi,' is a plain text string
        # => <p>hi,</p>

- \\%attributes : HashRef\[Str | ArrayRef\[Str\] | HashRef\[Str\] \]

    The element attributes could be defined by these styles:

    - \\%attributes contains Str

        In this case, Str value uses for single value of attribute.

            use feature qw(say);
            
            say h('p', { id => 'msg' }, 'hi,')
            # => <p id="msg">hi,</p>

    - \\%attributes contains ArrayRef\[Str\]

        If attribute is ArrayRef\[Str\], these Str values joined by whitespace and sorted ascendant.

            use feature qw(say);
            
            say h('p', { class => [qw/ foo bar baz /] }, 'hi,')
            # => <p class="bar baz foo">hi,</p>

    - HashRef\[Str\]

        If attribute is HashRef\[Str\], this code means shorthand for prefixed attribute.

            use feature qw(say);

            say h('p', { data => { label => 'foo' } }, 'hi,')
            # => <p data-label="foo"></p>

- \\@nested : ArrayRef

    The all ArrayRef passed to `h` function is flatten by internally.

    This ArrayRef supported all content type of `h` function.

# LICENSE

Copyright (C) OKAMURA Naoki a.k.a nyarla.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

OKAMURA Naoki a.k.a nyarla: <nyarla@kalaclista.com>

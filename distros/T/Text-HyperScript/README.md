[![Actions Status](https://github.com/nyarla/p5-Text-HyperScript/actions/workflows/test.yml/badge.svg)](https://github.com/nyarla/p5-Text-HyperScript/actions)
# NAME

Text::HyperScript - The HyperScript like library for Perl.

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

This module is a html/xml string generator like as hyperscirpt.

The name of this module contains **HyperScript**,
but this module features isn't same of another language or original implementation.

This module has submodule for some tagset:

HTML5: [Text::HyperScript::HTML5](https://metacpan.org/pod/Text%3A%3AHyperScript%3A%3AHTML5)

# FUNCTIONS

## h

This function makes html/xml text by perl code. 

This function is complex. but it's powerful.

**Arguments**:

    h($tag, [ \%attrs, $content, ...])

- `$tag`

    Tag name of element.

    This value should be `Str` value.

- `\%attrs` 

    Attributes of element.

    Result of attributes sorted by alphabetical according.

    You could pass to theses types as attribute values:

    - `Str`

        If you passed to this type, attribute value became a `Str` value.

        For example:

            h('hr', { id => 'id' }); # => '<hr id="id" />'

    - `Text::HyperScript::Boolean`

        If you passed to this type, attribute value became a value-less attribute.

        For example:

            # `true()` returns Text::HyperScript::Boolean value as !!1 (true)
            h('script', { crossorigin => true }); # => '<script crossorigin></script>'

    - `ArrayRef[Str]`

        If you passed to this type, attribute value became a **sorted** (alphabetical according),
        delimited by whitespace `Str` value,

        For example:

            h('hr', { class => [qw( foo bar baz )] });
            # => '<hr class="bar baz foo">'

    - `HashRef[ Str | ArrayRef[Str] | Text::HyperScript::Boolean ]`

        This type is a shorthand of prefixed attributes.

        For example:

            h('hr', { data => { id => 'foo', flags => [qw(bar baz)], enabled => true } });
            # => '<hr data-enabled data-flags="bar baz" data-id="foo" />'

- `$contnet`

    Contents of element.

    You could pass to these types:

    - `Str`

        Plain text as content.

        This value always applied html/xml escape by [HTML::Escape#escape\_html](https://metacpan.org/pod/HTML%3A%3AEscape%23escape_html).

    - `Text::HyperScript::Element`

        Raw html/xml string as content.

        **This value does not applied html/xml escape**,
        **you should not use this type for untrusted text**.

    - `ArrayRef[ Str | Text::HyperScript::Element ]`

        The ArrayRef of `$content`.

        This type value is flatten of other `$content` value.

## text

This function returns a html/xml escaped text.

If you use untrusted stirng for display,
you should use this function for wrapping untrusted content.

## raw

This function makes a instance of `Text::HyperScript::Element`.

Instance of `Text::HyperScript::Element` has `markup` method,
that return text with html/xml markup.

The value of `Text::HyperScript::Element` is not escaped by [HTML::Escape::escape\_html](https://metacpan.org/pod/HTML%3A%3AEscape%3A%3Aescape_html),
you should not use this function for display untrusted content. 
Please use `text` instead of this function.

## true / false

This functions makes instance of `Text::HyperScript::Boolean` value.

Instance of `Text::HyperScript::Boolean` has two method like as `is_true` and `is_false`,
these method returns that value pointed `true` or `false` values.

Usage of these functions for make html5 value-less attribute.

For example:

    h('script', { crossorigin => true }, ''); # => '<script crossorigin></script>'

# QUESTION AND ANSWERS

## How do I get element of empty content like as \`script\`?

This case you chould gets element string by pass to empty string.

For example:

    h('script', ''); # <script></script>

## Why all attributes and attribute values sorted by alphabetical according?

This reason that gets same result on randomized orderd hash keys. 

# LICENSE

Copyright (C) OKAMURA Naoki a.k.a nyarla.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

OKAMURA Naoki a.k.a nyarla: <nyarla@kalaclista.com>

# SEE ALSO

[Text::HyperScript::HTML5](https://metacpan.org/pod/Text%3A%3AHyperScript%3A%3AHTML5)

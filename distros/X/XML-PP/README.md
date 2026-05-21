# NAME

XML::PP - A simple XML parser

# VERSION

Version 0.08

# SYNOPSIS

    use XML::PP;

    my $parser = XML::PP->new();
    my $xml = '<note id="1"><to priority="high">Tove</to><from>Jani</from><heading>Reminder</heading><body importance="high">Don\'t forget me this weekend!</body></note>';
    my $tree = $parser->parse($xml);

    print $tree->{name};  # 'note'
    print $tree->{children}[0]->{name};   # 'to'

# DESCRIPTION

You almost certainly do not need this module.
For most tasks,
use [XML::Simple](https://metacpan.org/pod/XML%3A%3ASimple) or [XML::LibXML](https://metacpan.org/pod/XML%3A%3ALibXML).
`XML::PP` exists only for the most lightweight scenarios where you can't get one of the above modules to install,
for example,
CI/CD machines running Windows that get stuck with [https://stackoverflow.com/questions/11468141/cant-load-c-strawberry-perl-site-lib-auto-xml-libxml-libxml-dll-for-module-x](https://stackoverflow.com/questions/11468141/cant-load-c-strawberry-perl-site-lib-auto-xml-libxml-libxml-dll-for-module-x).

`XML::PP` is a simple, lightweight XML parser written in pure Perl.
It does not rely on external libraries like `XML::LibXML` and is suitable for small XML parsing tasks.
This module supports basic XML document parsing, including namespace handling, attributes, and text nodes.

# METHODS

## new

    my $parser = XML::PP->new();
    my $parser = XML::PP->new(strict => 1);
    my $parser = XML::PP->new(warn_on_error => 1);

Creates a new `XML::PP` object.
It can take several optional arguments:

- `strict` - If set to true, the parser dies when it encounters unknown entities or unescaped ampersands.
- `warn_on_error` - If true, the parser emits warnings for unknown or malformed XML entities. This is enabled automatically if `strict` is enabled.
- `logger`

    Used for warnings and traces.
    It can be an object that understands warn() and trace() messages,
    such as a [Log::Log4perl](https://metacpan.org/pod/Log%3A%3ALog4perl) or [Log::Any](https://metacpan.org/pod/Log%3A%3AAny) object,
    a reference to code,
    a reference to an array,
    or a filename.

## parse

    my $tree = $parser->parse($xml_string);

Parses the XML string and returns a tree structure representing the XML content.
The returned structure is a hash reference with the following fields:

- `name` - The tag name of the node.
- `ns` - The namespace prefix (if any).
- `ns_uri` - The namespace URI (if any).
- `attributes` - A hash reference of attributes.
- `children` - An array reference of child nodes (either text nodes or further elements).

## collapse\_structure

Collapses a parsed XML tree into a simplified nested hash,
similar in spirit to [XML::Simple](https://metacpan.org/pod/XML%3A%3ASimple).
It is designed to be called on the output of `parse()`,
and the two methods compose cleanly as a pipeline.

### Purpose

Transforms the verbose node-and-children structure produced by `parse()`
into a compact hash that is easier to address with ordinary Perl hash
syntax.
Each element's tag name becomes a hash key and its text content becomes
the corresponding value.
Nested elements are recursed into rather than flattened.

### Arguments

- `$node` (required)

    A hash reference representing a parsed XML node,
    as returned by `parse()`.
    Must contain a defined `name` key and a `children` array reference.
    Returns an empty hash reference immediately if any of the following are
    true: `$node` is not a hash reference; `$node` has no defined `name`
    key; `$node` has no `children` key.

### Returns

A hash reference whose single top-level key is the element's tag name.
Its value is a hash of collapsed children where each child's tag name maps
to its text content or to a recursively collapsed sub-hash.

If two or more children share the same tag name their values are collected
into an array reference in document order rather than overwriting each other.

Children whose text content is undefined or the empty string are silently
omitted.
Children with no tag name (bare text nodes) are silently skipped.
Attributes of child elements are not included in the collapsed output; use
the raw tree from `parse()` if attribute values are needed.

### Example

    use XML::PP;

    my $parser = XML::PP->new();
    my $xml    = '<note id="1">'
               .   '<to>Tove</to>'
               .   '<from>Jani</from>'
               .   '<heading>Reminder</heading>'
               .   '<body>Don\'t forget me this weekend!</body>'
               . '</note>';

    my $tree   = $parser->parse($xml);
    my $result = $parser->collapse_structure($tree);

    # $result = {
    #     note => {
    #         to      => 'Tove',
    #         from    => 'Jani',
    #         heading => 'Reminder',
    #         body    => "Don't forget me this weekend!",
    #     }
    # }

    print $result->{note}{to};       # Tove
    print $result->{note}{heading};  # Reminder

    # Repeated child elements become an array reference:
    my $list   = $parser->parse('<list><item>a</item><item>b</item></list>');
    my $flat   = $parser->collapse_structure($list);
    print $flat->{list}{item}[0];    # a
    print $flat->{list}{item}[1];    # b

### API specification

#### Input

    {
        node => {
            type      => HASHREF,
            required  => 1,
            callbacks => {
                'has defined name key' => sub {
                    ref $_[0] eq 'HASH' && defined $_[0]->{name}
                },
                'has children key' => sub {
                    ref $_[0] eq 'HASH' && exists $_[0]->{children}
                },
            },
        },
    }

#### Output

    {
        type => HASHREF,
        min  => 1,
    }

The returned hash reference always has exactly one top-level key (the root
element's tag name) whose value is a plain hash reference of collapsed
children.
An empty hash reference `{}` is returned when the input fails the guard
conditions.

# AUTHOR

Nigel Horne, `<njh at nigelhorne.com>`

# SEE ALSO

- [XML::LibXML](https://metacpan.org/pod/XML%3A%3ALibXML)
- [XML::Simple](https://metacpan.org/pod/XML%3A%3ASimple)

# SUPPORT

This module is provided as-is without any warranty.

# LICENCE AND COPYRIGHT

Copyright 2025-2026 Nigel Horne.

Usage is subject to GPL2 licence terms.
If you use it,
please let me know.

# NAME

XML::PP - A simple XML parser

# VERSION

Version 0.06

# SYNOPSIS

    use XML::PP;

    my $parser = XML::PP->new();
    my $xml = '<note id="1"><to priority="high">Tove</to><from>Jani</from><heading>Reminder</heading><body importance="high">Don\'t forget me this weekend!</body></note>';
    my $tree = $parser->parse($xml);

    print $tree->{name};  # 'note'
    print $tree->{children}[0]->{name};   # 'to'

# DESCRIPTION

You almost certainly do not need this module,
for most tasks use [XML::Simple](https://metacpan.org/pod/XML%3A%3ASimple) or [XML::LibXML](https://metacpan.org/pod/XML%3A%3ALibXML).
`XML::PP` exists only for the most lightweight of scenarios where you can't get one of the above modules to install,
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

Collapse an XML-like structure into a simplified hash (like [XML::Simple](https://metacpan.org/pod/XML%3A%3ASimple)).

    use XML::PP;

    my $input = {
        name => 'note',
        children => [
            { name => 'to', children => [ { text => 'Tove' } ] },
            { name => 'from', children => [ { text => 'Jani' } ] },
            { name => 'heading', children => [ { text => 'Reminder' } ] },
            { name => 'body', children => [ { text => 'Don\'t forget me this weekend!' } ] },
        ],
        attributes => { id => 'n1' },
    };

    my $result = collapse_structure($input);

    # Output:
    # {
    #     note => {
    #         to      => 'Tove',
    #         from    => 'Jani',
    #         heading => 'Reminder',
    #         body    => 'Don\'t forget me this weekend!',
    #     }
    # }

The `collapse_structure` subroutine takes a nested hash structure (representing an XML-like data structure) and collapses it into a simplified hash where each child element is mapped to its name as the key, and the text content is mapped as the corresponding value. The final result is wrapped in a `note` key, which contains a hash of all child elements.

This subroutine is particularly useful for flattening XML-like data into a more manageable hash format, suitable for further processing or display.

`collapse_structure` accepts a single argument:

- `$node` (Required)

    A hash reference representing a node with the following structure:

        {
            name      => 'element_name',  # Name of the element (e.g., 'note', 'to', etc.)
            children  => [                # List of child elements
                { name => 'child_name', children => [{ text => 'value' }] },
                ...
            ],
            attributes => { ... },        # Optional attributes for the element
            ns_uri => ... ,               # Optional namespace URI
            ns => ... ,                   # Optional namespace
        }

    The `children` key holds an array of child elements. Each child element may have its own `name` and `text`, and the function will collapse all text values into key-value pairs.

The subroutine returns a hash reference that represents the collapsed structure, where the top-level key is `note` and its value is another hash containing the child elements' names as keys and their corresponding text values as values.

For example:

    {
        note => {
            to      => 'Tove',
            from    => 'Jani',
            heading => 'Reminder',
            body    => 'Don\'t forget me this weekend!',
        }
    }

- Basic Example:

    Given the following input structure:

        my $input = {
            name => 'note',
            children => [
                { name => 'to', children => [ { text => 'Tove' } ] },
                { name => 'from', children => [ { text => 'Jani' } ] },
                { name => 'heading', children => [ { text => 'Reminder' } ] },
                { name => 'body', children => [ { text => 'Don\'t forget me this weekend!' } ] },
            ],
        };

    Calling `collapse_structure` will return:

        {
            note => {
                to      => 'Tove',
                from    => 'Jani',
                heading => 'Reminder',
                body    => 'Don\'t forget me this weekend!',
            }
        }

## \_parse\_node

    my $node = $self->_parse_node($xml_ref, $nsmap);

Recursively parses an individual XML node.
This method is used internally by the `parse` method.
It handles the parsing of tags, attributes, text nodes, and child elements.
It also manages namespaces and handles self-closing tags.

# AUTHOR

Nigel Horne, `<njh at nigelhorne.com>`

# SEE ALSO

- [XML::LibXML](https://metacpan.org/pod/XML%3A%3ALibXML)
- [XML::Simple](https://metacpan.org/pod/XML%3A%3ASimple)

# SUPPORT

This module is provided as-is without any warranty.

# LICENSE AND COPYRIGHT

Copyright 2025 Nigel Horne.

Usage is subject to licence terms.

The licence terms of this software are as follows:

- Personal single user, single computer use: GPL2
- All other users (including Commercial, Charity, Educational, Government)
  must apply in writing for a licence for use from Nigel Horne at the
  above e-mail.

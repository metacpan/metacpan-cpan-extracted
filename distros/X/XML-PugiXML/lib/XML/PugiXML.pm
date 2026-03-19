package XML::PugiXML;
use strict;
use warnings;

our $VERSION = '0.03';

require XSLoader;
XSLoader::load('XML::PugiXML', $VERSION);

1;

__END__

=head1 NAME

XML::PugiXML - Perl binding for pugixml C++ XML parser

=head1 SYNOPSIS

    use XML::PugiXML;

    my $doc = XML::PugiXML->new;
    $doc->load_string('<root><item id="1">Hello</item></root>');

    my $root = $doc->root;
    my $item = $root->child('item');
    print $item->text, "\n";           # Hello
    print $item->attr('id')->value, "\n";  # 1

    # XPath
    my $node = $doc->select_node('//item[@id="1"]');
    print $node->text, "\n";

    # Compiled XPath (faster for repeated queries)
    my $xpath = $doc->compile_xpath('//item');
    my @items = $xpath->evaluate_nodes($root);

    # Modification
    my $new = $root->append_child('item');
    $new->set_text('World');
    $new->set_attr('id', '2');  # Convenience method
    $doc->save_file('output.xml');

    # Formatting options
    print $doc->to_string("  ", XML::PugiXML::FORMAT_INDENT());

    # Node cloning
    my $copy = $root->append_copy($item);

=head1 DESCRIPTION

XML::PugiXML provides a Perl interface to the pugixml C++ XML parsing library.
It offers fast parsing, XPath support, and a clean API. All string inputs
are automatically upgraded to UTF-8, and all outputs are UTF-8 flagged.

=head1 METHODS

=head2 XML::PugiXML (Document)

=over 4

=item new()

Create a new empty XML document.

=item load_file($path, $parse_options?)

Load and parse XML from a file. Returns true on success.
Optional $parse_options (default PARSE_DEFAULT).

=item load_string($xml, $parse_options?)

Parse XML from a string. Returns true on success.
Optional $parse_options (default PARSE_DEFAULT).

=item save_file($path, $indent?, $flags?)

Save the document to a file. Returns true on success.
Optional $indent (default "\t") and $flags (default FORMAT_DEFAULT).

=item to_string($indent?, $flags?)

Serialize the document to an XML string.
Optional $indent (default "\t") and $flags (default FORMAT_DEFAULT).

=item reset()

Clear the document, removing all nodes. Existing Node and Attr
handles become stale -- accessing them will croak with
"Stale node/attribute handle". Use C<valid()> to check without croaking.
The same applies after C<load_file()> or C<load_string()> replaces content.

=item root()

Return the document element (root node).

=item child($name)

Get a direct child by name.

=item select_node($xpath)

Execute XPath query, return single result. Returns an
C<XML::PugiXML::Node> or C<XML::PugiXML::Attr> depending on the query.

=item select_nodes($xpath)

Execute XPath query, return list of results. Returns a mix of
C<XML::PugiXML::Node> and C<XML::PugiXML::Attr> objects as appropriate.

=item compile_xpath($xpath)

Compile an XPath expression for repeated use. Returns an XML::PugiXML::XPath object.

=back

=head3 Format Constants

=over 4

=item FORMAT_DEFAULT()

Default formatting (indent with tabs).

=item FORMAT_INDENT()

Indent output.

=item FORMAT_NO_DECLARATION()

Omit XML declaration.

=item FORMAT_RAW()

No formatting (compact output).

=item FORMAT_WRITE_BOM()

Write BOM (byte order mark).

=back

=head3 Parse Constants

=over 4

=item PARSE_DEFAULT()

Default parsing options.

=item PARSE_MINIMAL()

Minimal parsing (fastest, no comments/PI/DOCTYPE).

=item PARSE_PI()

Parse processing instructions.

=item PARSE_COMMENTS()

Parse comments.

=item PARSE_CDATA()

Parse CDATA sections.

=item PARSE_WS_PCDATA()

Preserve whitespace-only PCDATA nodes.

=item PARSE_ESCAPES()

Parse character/entity references.

=item PARSE_EOL()

Normalize end-of-line characters.

=item PARSE_DECLARATION()

Parse XML declaration.

=item PARSE_DOCTYPE()

Parse DOCTYPE.

=item PARSE_FULL()

Full parsing (all features enabled).

=back

=head2 XML::PugiXML::Node

=over 4

=item name(), value(), text()

Get node name, value, or text content.

=item type()

Return the node type as an integer. Values:
0=null, 1=document, 2=element, 3=pcdata, 4=cdata, 5=comment, 6=pi, 7=declaration.

=item path($delimiter?)

Return the absolute XPath path to this node. Default delimiter is '/'.

=item hash()

Return a hash value for this node. Useful for comparison.

=item offset_debug()

Return the source offset of this node (for debugging).

=item valid()

Return true if this is a valid node handle.

=item root()

Return the document element from any node (consistent with C<< $doc->root >>).

=back

=head3 Navigation

=over 4

=item parent()

Get parent node.

=item first_child(), last_child()

Get first or last child node.

=item next_sibling($name?), previous_sibling($name?)

Get next or previous sibling. Optionally filter by name.

=item child($name)

Get a named child node.

=item children($name?)

Return list of child nodes, optionally filtered by name.

=item find_child_by_attribute($tag, $attr_name, $attr_value)

Find first child with given tag name and attribute value.

=back

=head3 Attributes

=over 4

=item attr($name)

Get attribute by name.

=item attrs()

Return list of all attributes.

=item set_attr($name, $value)

Set attribute value (creates if doesn't exist). Returns the attribute.

=item append_attr($name), prepend_attr($name)

Add attribute at end or beginning.

=item remove_attr($name)

Remove an attribute by name. Returns true on success.

=back

=head3 Modification

=over 4

=item append_child($name), prepend_child($name)

Add child element at end or beginning.

=item insert_child_before($name, $ref_node), insert_child_after($name, $ref_node)

Insert child element before or after a reference node.

=item append_copy($source), prepend_copy($source)

Clone and append/prepend a node (deep copy).

=item insert_copy_before($source, $ref), insert_copy_after($source, $ref)

Clone and insert node before/after reference.

=item append_cdata($content)

Add a CDATA section with the given content.

=item append_comment($content)

Add a comment node with the given content.

=item append_pi($target, $data?)

Add a processing instruction. E.g., C<< <?target data?> >>

=item remove_child($node)

Remove a child node. Returns true on success.

=item set_name($name), set_value($value), set_text($text)

Modify node properties.

=back

=head3 XPath

=over 4

=item select_node($xpath)

Execute XPath relative to this node, return single result (Node or Attr).

=item select_nodes($xpath)

Execute XPath relative to this node, return list of results (Node and/or Attr).

=back

=head2 XML::PugiXML::Attr

=over 4

=item name(), value()

Get attribute name and value.

=item as_int(), as_uint()

Get value as 32-bit signed/unsigned integer.

=item as_llong(), as_ullong()

Get value as 64-bit signed/unsigned integer.
On 32-bit Perl (IVSIZE < 8), returns a string to avoid truncation.

=item as_double()

Get value as floating-point number.

=item as_bool()

Get value as boolean (recognizes "true", "1", "yes", "on").

=item element()

Return the parent element node that owns this attribute.

=item set_value($value)

Set attribute value.

=item valid()

Return true if this is a valid attribute handle.

=back

=head2 XML::PugiXML::XPath (Compiled Queries)

=over 4

=item evaluate_node($context_node)

Evaluate XPath and return single result (Node or Attr).

=item evaluate_nodes($context_node)

Evaluate XPath and return list of results (Node and/or Attr).

=item evaluate_string($context_node)

Evaluate XPath and return string result.

=item evaluate_number($context_node)

Evaluate XPath and return numeric result.

=item evaluate_boolean($context_node)

Evaluate XPath and return boolean result.

=back

=head1 ERROR HANDLING

Parse and save operations return false on failure and set C<$@> with
an error message. XPath syntax errors throw exceptions via C<croak()>.

    # Parse errors - check return value
    my $ok = $doc->load_string('<bad>');
    if (!$ok) {
        warn "Parse failed: $@";
    }

    # XPath errors - use eval
    eval { $doc->select_node('[invalid'); };
    if ($@) {
        warn "XPath error: $@";
    }

=head1 MEMORY MODEL

Node and attribute handles keep the parent document alive through
reference counting. You can safely use a node after the document
variable goes out of scope:

    my $node;
    {
        my $doc = XML::PugiXML->new;
        $doc->load_string('<root><item/></root>');
        $node = $doc->root->child('item');
    }
    # $node is still valid here

=head1 PERFORMANCE

Benchmarked against XML::LibXML (100-5000 element documents):

    Parsing:          8-12x faster
    XPath queries:    2-13x faster
    Tree traversal:   15-17x faster
    DOM modification: 2-11x faster
    Serialization:    2-4x faster

See F<bench/benchmark.pl> for details.

=head1 SECURITY

This module uses pugixml which does NOT process external entities (XXE)
by default, making it safe against XXE attacks.

=head1 THREAD SAFETY

Different document instances can be used in different threads safely.
Concurrent access to the same document from multiple threads is not safe.

=head1 AUTHOR

vividsnow

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

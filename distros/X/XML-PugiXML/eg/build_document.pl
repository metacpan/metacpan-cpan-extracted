#!/usr/bin/env perl
# Build an XML document from scratch
use strict;
use warnings;
use XML::PugiXML;

my $doc = XML::PugiXML->new;

# An empty document has no root element, and the document class has no
# append_child; create the root element by parsing a minimal skeleton.
$doc->load_string('<catalog/>') or die $@;
my $root = $doc->root;

# Add products
for my $item (
    { sku => 'A001', name => 'Widget',  price => '9.99'  },
    { sku => 'A002', name => 'Gadget',  price => '24.50' },
    { sku => 'A003', name => 'Gizmo',   price => '14.75' },
) {
    my $product = $root->append_child('product');
    $product->set_attr('sku', $item->{sku});
    $product->set_text($item->{name});

    my $price = $root->append_child('price');
    $price->set_attr('for', $item->{sku});
    $price->set_text($item->{price});
}

# Add metadata
$root->prepend_child('updated')->set_text('2026-03-04');
$root->append_comment(' end of catalog ');

# Output with 2-space indent, no XML declaration
print $doc->to_string("  ", XML::PugiXML::FORMAT_INDENT()
                           | XML::PugiXML::FORMAT_NO_DECLARATION());

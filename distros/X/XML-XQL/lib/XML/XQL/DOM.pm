############################################################################
# Copyright (c) 1998 Enno Derksen
# All rights reserved.
# This program is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
############################################################################
#
# Functions added to the XML::DOM implementation for XQL support
#
# NOTE: This code is a bad example of how to use XML::DOM.
# I'm accessing internal (private) data members for a little gain in performance.
# When the internal DOM implementation changes, this code will no longer work.
# But since I maintain XML::DOM, it's easy for me to keep them in sync.
# Regular users are adviced to use the XML::DOM API as described in the 
# documentation.
#

use strict;
package XML::XQL::DOM;

BEGIN
{
    require XML::DOM;

    # import constant field definitions, e.g. _Doc
    import XML::DOM::Node qw{ :Fields };
}

package XML::DOM::Node;

sub xql
{
    my $self = shift;

    # Odd number of args, assume first is XQL expression without 'Expr' key
    unshift @_, 'Expr' if (@_ % 2 == 1);
    my $query = new XML::XQL::Query (@_);
    my @result = $query->solve ($self);
    $query->dispose;

    @result;
}

sub xql_sortKey
{
    my $key = $_[0]->[_SortKey];
    return $key if defined $key;

    $key = XML::XQL::createSortKey ($_[0]->[_Parent]->xql_sortKey, 
				    $_[0]->xql_childIndex, 1);
#print "xql_sortKey $_[0] ind=" . $_[0]->xql_childIndex . " key=$key str=" . XML::XQL::keyStr($key) . "\n";
    $_[0]->[_SortKey] = $key;
}

# Find previous sibling that is not a text node with ignorable whitespace
sub xql_prevNonWS
{
    my $self = shift;
    my $parent = $self->[_Parent];
    return unless $parent;

    for (my $i = $parent->getChildIndex ($self) - 1; $i >= 0; $i--)
    {
	my $node = $parent->getChildAtIndex ($i);
	return $node unless $node->xql_isIgnorableWS;	# skip whitespace
    }
    undef;
}

# True if it's a Text node with just whitespace and xml::space != "preserve"
sub xql_isIgnorableWS
{
    0;
}

# Whether the node should preserve whitespace
# It should if it has attribute xml:space="preserve"
sub xql_preserveSpace
{
    $_[0]->[_Parent]->xql_preserveSpace;
}

sub xql_element
{
#?? I wonder which implemention is used for e.g. DOM::Text, since XML::XQL::Node also has an implementation
    [];
}

sub xql_document
{
    $_[0]->[_Doc];
}

sub xql_node
{
    my $kids = $_[0]->[_C];
    if (defined $kids)
    {
	# Must copy the list or else we return a blessed reference
	# (which causes trouble later on)
	my @list = @$kids;
	return \@list;
    }

    [];
}

#?? implement something to support NamedNodeMaps in DocumentType
sub xql_childIndex
{
    $_[0]->[_Parent]->getChildIndex ($_[0]);
}

#?? implement something to support NamedNodeMaps in DocumentType
sub xql_childCount
{
    my $ch = $_[0]->[_C];
    defined $ch ? scalar(@$ch) : 0;
}

sub xql_parent
{
    $_[0]->[_Parent];
}

sub xql_DOM_nodeType
{
    $_[0]->getNodeType;
}

sub xql_nodeType
{
    $_[0]->getNodeType;
}

# As it appears in the XML document
sub xql_xmlString
{
    $_[0]->toString;
}

package XML::DOM::Element;

sub xql_attribute
{
    my ($node, $attrName) = @_;

    if (defined $attrName)
    {
	my $attr = $node->getAttributeNode ($attrName);
	defined ($attr) ? [ $attr ] : [];
    }
    else
    {
	defined $node->[_A] ? $node->[_A]->getValues : [];
    }
}

# Used by XML::XQL::Union::genSortKey to generate sort keys
# Returns the maximum of the number of children and the number of Attr nodes.
sub xql_childCount
{
    my $n = scalar @{$_[0]->[_C]};
    my $m = defined $_[0]->[_A] ? $_[0]->[_A]->getLength : 0;
    return $n > $m ? $n : $m;
}

sub xql_element
{
    my ($node, $elem) = @_;

    my @list;
    if (defined $elem)
    {
	for my $kid (@{$node->[_C]})
	{
	    push @list, $kid if $kid->isElementNode && $kid->[_TagName] eq $elem;
	}
    }
    else
    {
	for my $kid (@{$node->[_C]})
	{
	    push @list, $kid if $kid->isElementNode;
	}
    }
    \@list;
}

sub xql_nodeName
{
    $_[0]->[_TagName];
}

sub xql_baseName
{
    my $name = $_[0]->[_TagName];
    $name =~ s/^\w*://;
    $name;
}

sub xql_prefix
{
    my $name = $_[0]->[_TagName];
    $name =~ /([^:]+):/;
    $1;
}

sub xql_rawText
{
    my ($self, $recurse) = @_;
    $recurse = 1 unless defined $recurse;

    my $text = "";

    for my $kid (@{$self->xql_node})
    {
	my $type = $kid->xql_nodeType;

	# type=1: element
	# type=3: text (Text, CDATASection, EntityReference)
	if (($type == 1 && $recurse) || $type == 3)
	{
	    $text .= $kid->xql_rawText ($recurse);
	}
    }
    $text;
}

sub xql_text
{
    my ($self, $recurse) = @_;
    $recurse = 1 unless defined $recurse;

    my $j = -1;
    my @text;
    my $last_was_text = 0;

    # Collect text blocks. Consecutive blocks of Text, CDataSection and 
    # EntityReference nodes should be merged without stripping and without
    # putting spaces in between.
    for my $kid (@{$self->xql_node})
    {
	my $type = $kid->xql_nodeType;

	if ($type == 1)	    # 1: element
	{
	    if ($recurse)
	    {
		$text[++$j] = $kid->xql_text ($recurse);
	    }
	    $last_was_text = 0;
	}
	elsif ($type == 3)  # 3: text (Text, CDATASection, EntityReference)
	{
	    ++$j unless $last_was_text;		# next text block
	    $text[$j] .= $kid->getData;
	    $last_was_text = 1;
	}
	else	# e.g. Comment
	{
	    $last_was_text = 0;
	}
    }

    # trim whitespace and remove empty blocks
    my $i = 0;
    my $n = @text;
    while ($i < $n)
    {
	# similar to XML::XQL::trimSpace
	$text[$i] =~ s/^\s+//;
	$text[$i] =~ s/\s+$//;

	if ($text[$i] eq "")
	{
	    splice (@text, $i, 1);	# remove empty block
	    $n--;
	}
	else
	{
	    $i++;
	}
    }
    join (" ", @text);
}

#
# Returns a list of text blocks for this Element.
# A text block is a concatenation of consecutive text-containing nodes (i.e.
# Text, CDATASection or EntityReference nodes.)
# For each text block a reference to an array is returned with the following
# 3 items:
#  [0] index of first node of the text block
#  [1] index of last node of the text block
#  [2] concatenation of the raw text (of the nodes in this text block)
#
# The text blocks are returned in reverse order for the convenience of
# the routines that want to modify the text blocks.
#
sub xql_rawTextBlocks
{
    my ($self) = @_;

    my @result;
    my $curr;
    my $prevWasText = 0;
    my $kids = $self->[_C];
    my $n = @$kids;
    for (my $i = 0; $i < $n; $i++)
    {
	my $node = $kids->[$i];
	# 3: text (Text, CDATASection, EntityReference)
	if ($node->xql_nodeType == 3)
	{
	    if ($prevWasText)
	    {
		$curr->[1] = $i;
		$curr->[2] .= $node->getData;
	    }
	    else
	    {
		$curr = [$i, $i, $node->getData];
		unshift @result, $curr;
		$prevWasText = 1;
	    }
	}
	else
	{
	    $prevWasText = 0;
	}
    }
    @result;
}

sub xql_replaceBlockWithText
{
    my ($self, $start, $end, $text) = @_;
    for (my $i = $end; $i > $start; $i--)
    {
	# dispose of the old nodes
	$self->removeChild ($self->[_C]->[$i])->dispose;
    }
    my $node = $self->[_C]->[$start];
    my $newNode = $self->[_Doc]->createTextNode ($text);
    $self->replaceChild ($newNode, $node)->dispose;
}

sub xql_setValue
{
    my ($self, $str) = @_;
    # Remove all children
    for my $kid (@{$self->[_C]})
    {
	$self->removeChild ($kid);
    }
    # Add a (single) text node
    $self->appendChild ($self->[_Doc]->createTextNode ($str));
}

sub xql_value
{
    XML::XQL::elementValue ($_[0]);
}

sub xql_preserveSpace
{
    # attribute value should be "preserve" (1), "default" (0) or "" (ask parent)
    my $space = $_[0]->getAttribute ("xml:space");
    $space eq "" ? $_[0]->[_Parent]->xql_preserveSpace : ($space eq "preserve");
}

package XML::DOM::Attr;

sub xql_sortKey
{
    my $key = $_[0]->[_SortKey];
    return $key if defined $key;

    $_[0]->[_SortKey] = XML::XQL::createSortKey ($_[0]->xql_parent->xql_sortKey, 
						$_[0]->xql_childIndex, 0);
}

sub xql_nodeName
{
    $_[0]->getNodeName;
}

sub xql_text
{
    XML::XQL::trimSpace ($_[0]->getValue);
}

sub xql_rawText
{
    $_[0]->getValue;
}

sub xql_value
{
    XML::XQL::attrValue ($_[0]);
}

sub xql_setValue
{
    $_[0]->setValue ($_[1]);
}

sub xql_baseName
{
    my $name = $_[0]->getNodeName;
    $name =~ s/^\w*://;
    $name;
}

sub xql_prefix
{
    my $name = $_[0]->getNodeName;
    $name =~ s/:\w*$//;
    $name;
}

sub xql_parent
{
    $_[0]->[_UsedIn]->{''}->{Parent};
}

sub xql_childIndex
{
    my $map = $_[0]->[_UsedIn];
    $map ? $map->getChildIndex ($_[0]) : 0;
}

package XML::DOM::Text;

sub xql_rawText
{
    $_[0]->[_Data];
}

sub xql_text
{
    XML::XQL::trimSpace ($_[0]->[_Data]);
}

sub xql_setValue
{
    $_[0]->setData ($_[1]);
}

sub xql_isIgnorableWS
{
    $_[0]->[_Data] =~ /^\s*$/ &&
    !$_[0]->xql_preserveSpace;
}

package XML::DOM::CDATASection;

sub xql_rawText
{
    $_[0]->[_Data];
}

sub xql_text
{
    XML::XQL::trimSpace ($_[0]->[_Data]);
}

sub xql_setValue
{
    $_[0]->setData ($_[1]);
}

sub xql_nodeType
{
    3;	# it contains text, so XQL spec states it's a text node
}

package XML::DOM::EntityReference;

BEGIN
{
    # import constant field definitions, e.g. _Data
    import XML::DOM::CharacterData qw{ :Fields };
}

sub xql_text
{
    $_[0]->getData;
}

sub xql_rawText
{
    XML::XQL::trimSpace ($_[0]->[_Data]);
}

sub xql_setValue
{
    $_[0]->setData ($_[1]);
}

sub xql_nodeType
{
    3;	# it contains text, so XQL spec states it's a text node
}

package XML::DOM::Document;

BEGIN
{
    # import constant field definitions, e.g. _TagName
    import XML::DOM::Element qw{ :Fields };
}

sub xql_sortKey
{
    "";
}

sub xql_element
{
    my ($node, $elem) = @_;

    my @list;
    if (defined $elem)
    {
	for my $kid (@{$node->[_C]})
	{
	    push @list, $kid if $kid->isElementNode && $kid->[_TagName] eq $elem;
	}
    }
    else
    {
	for my $kid (@{$node->[_C]})
	{
	    push @list, $kid if $kid->isElementNode;
	}
    }
    \@list;
}

sub xql_parent
{
    undef;
}

# By default the elements in a document don't preserve whitespace
sub xql_preserveSpace
{
    0;
}

package XML::DOM::DocumentFragment;

BEGIN
{
    # import constant field definitions, e.g. _TagName
    import XML::DOM::Element qw{ :Fields };
}

sub xql_element
{
    my ($node, $elemName) = @_;

    my @list;
    if (defined $elemName)
    {
	for my $kid (@{$node->[_C]})
	{
	    push @list, $kid if $kid->isElementNode && $kid->[_TagName] eq $elemName;
	}
    }
    else
    {
	for my $kid (@{$node->[_C]})
	{
	    push @list, $kid if $kid->isElementNode;
	}
    }
    \@list;
}

sub xql_parent
{
    undef;
}

1; # module loaded successfuly

__END__

=head1 NAME

XML::XQL::DOM - Adds XQL support to XML::DOM nodes

=head1 SYNOPSIS

 use XML::XQL;
 use XML::XQL::DOM;

 $parser = new XML::DOM::Parser;
 $doc = $parser->parsefile ("file.xml");

 # Return all elements with tagName='title' under the root element 'book'
 $query = new XML::XQL::Query (Expr => "book/title");
 @result = $query->solve ($doc);

 # Or (to save some typing)
 @result = XML::XQL::solve ("book/title", $doc);

 # Or (see XML::DOM::Node)
 @result = $doc->xql ("book/title");

=head1 DESCRIPTION

XML::XQL::DOM adds methods to L<XML::DOM> nodes to support XQL queries
on XML::DOM document structures.

See L<XML::XQL> and L<XML::XQL::Query> for more details.
L<XML::DOM::Node> describes the B<xql()> method.



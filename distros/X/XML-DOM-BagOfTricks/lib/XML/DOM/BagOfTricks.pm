package XML::DOM::BagOfTricks;
use strict;

=head1 NAME

XML::DOM::BagOfTricks - Convenient XML DOM

=head1 SYNOPSIS

  use XML::DOM::BagOfTricks;

  # get the XML document and root element
  my ($doc,$root) = createDocument('Foo');

  # or

  # get the XML document with xmlns and version attributes specified
  my $doc = createDocument({name=>'Foo', xmlns=>'http://www.other.org/namespace', version=>1.3});

  # get a text element like <Foo>Bar</Bar>
  my $node = createTextElement($doc,'Foo','Bar');

  # get an element like <Foo isBar="0" isFoo="1"/>
  my $node = createElement($doc,'Foo','isBar'=>0, 'isFoo'=>1);

  # get a nice element with attributes that contains a text node <Foo isFoo="1" isBar="0">Bar</Foo>
  my $foo_elem = createElementwithText($DOMDocument,'Foo','Bar',isFoo=>1,isBar=>0);

  # add attributes to a node
  addAttributes($node,foo=>'true',bar=>32);

  # add text to a node
  addText($node,'This is some text');

  # add more elements to a node
  addElements($node,$another_node,$yet_another_node);

  # adds two text nodes to a node
  addTextElements($node,Foo=>'some text',Bar=>'some more text');

  # creates new XML:DOM::Elements and adds them to $node
  addElements($node,{ name=>'Foo', xlink=> 'cid:..' },{ .. });

  # extracts the text content of a node (and its subnodes)
  my $content = getTextContents($node);

=head1 DESCRIPTION

XML::DOM::BagOfTricks provides a bundle, or bag, of functions that make
dealing with and creating DOM objects easier.

The goal of this BagOfTricks is to deal with DOM and XML in a more perl
friendly manner, using native idioms to fit in with the rest of a perl
program.

As of version 0.02 the API has changed to be clearer and more in line with
the DOM API in general, now using createFoo instead of getFoo to create
new elements, documents, etc.

=cut


use XML::DOM;

require Exporter;
use AutoLoader qw(AUTOLOAD);

our $VERSION = '0.05';
our @ISA = qw(Exporter);
our %EXPORT_TAGS = ( 'all' => [ qw(
				   &getTextContents
                                   &createDocument &createTextElement &createElement &createElementwithText
                                   &addAttributes &addText &addElements &addTextElements
				   ) ] );
our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

=head2 createTextElement($doc,$name,$value)

    This function returns a nice XML::DOM::Node representing an element
    with an appended Text subnode, based on the arguments provided.

    In the example below $node would represent '<Foo>Bar</Foo>'

    my $node = getTextElement($doc,'Foo','Bar');

    More useful than a pocketful of bent drawing pins!

    When called with no text value defined, will just return a normal 
    element without a textnode attached so the example below would 
    return a node representing '<Foo/>'

    my $node = getTextElement($doc,'Foo');

=cut

sub createTextElement {
    my ($doc, $name, $value) = @_;
    die "createTextElement requires a name  : ", caller() unless $name;
    my $field = $doc->createElement($name);
    if (defined $value) {
	my $fieldvalue = $doc->createTextNode($value);
	$field->appendChild($fieldvalue);
    }
    return $field;
}

=head2 createElement($doc,$name,%attributes)

    This function returns a nice XML::DOM::Node representing an element
    with an appended Text subnode, based on the arguments provided.

    In the example below $node would represent '<Foo isBar='0' isFoo='1'/>'

    my $node = createElement($doc,'Foo','isBar'=>0, 'isFoo'=>1);

    Undefined attributes will be ignored, if you want to set an attribute value
    as an empty value pass it an empty string like ''.

=cut


sub createElement {
    my ($doc, $name, @attributes) = @_;
    my $node = $doc->createElement($name);
    while (@attributes) {
	my ($name,$value) = (shift @attributes, shift @attributes);
	$node->setAttribute($name,$value) if ($name);
    }

    return $node;
}


=head2 createElementwithText($DOMDocument,$node_name,$text,$attr_name=>$attr_value);

  # get a nice element with attributes that contains a text node ( i.e. <Foo isFoo='1' isBar='0'>Bar</Foo> )
  my $foo_elem = getElementwithText($DOMDocument,'Foo','Bar',isFoo=>1,isBar=>0);

  The order of attributes is preserved with this method, other methods may not do so.

=cut

sub createElementwithText {
    my ($doc, $nodename, $textvalue, @attributes) = @_;
    die "getElementwithText requires a DOMDocument ", caller()  unless (ref $doc);
    die "getElementwithText requires a name : ", caller() unless $nodename;
    my $node = $doc->createElement($nodename);
    if ($textvalue) {
	my $text = $doc->createTextNode($textvalue);
	$node->appendChild($text);
    }
    while (@attributes) {
	my ($name,$value) = (shift @attributes, shift @attributes);
	$node->setAttribute($name,$value) if ($name);
    }

    return $node;
}


=head2 addAttributes

  Adds attributes to a provided XML::DOM::Node. Based on set_atts from XML::DOM::Twig by Michel Rodriguez.

  addAttributes($node,foo=>'true',bar=>32);

  Returns the modified node

  The order of attributes is preserved with this method, other methods may not do so.

=cut

# based on set_atts from XML::DOM::Twig by Michel Rodriguez
sub addAttributes {
    my $node = shift;
    while (@_) {
	$node->setAttribute(shift,shift) if ($_[0]);
    }
    return $node;
}

=head2 addElements

  Adds elements to a provided XML::DOM::Element. Based on set_content from XML::DOM::Twig by Michel Rodriguez.

  # adds $another_node and $yet_another_node to $node where all are XML:DOM::Elements
  addElements($node,$another_node,$yet_another_node);

  or

  # creates new XML:DOM::Elements and adds them to $node
  addElements($node,{ name=>'Foo', xlink=> 'cid:..' },{ .. });

  Returns the modified node

  Note: The order of attributes is NOT preserved with this method.

=cut

# based on set_content from XML::DOM::Twig by Michel Rodriguez
sub addElements {
    my $node = shift;
    my $doc;
    foreach my $elem (@_) { 
	if ( ref $elem eq 'XML::DOM::Element') {
	    $node->appendChild( $elem);
	} else {
	    $doc ||= $node->getOwnerDocument;
	    my $element = $doc->createElement($elem->{name});
	    foreach (keys %$elem) {
		next if /name/;
		$node->setAttribute($_,$elem->{$_}) if ($_);
	    }
	    $node->appendChild( $element);
	}
    }
    return $node;
}

=head2 addTextElements

  Adds Text Elements to a provided XML::DOM::Element.

  # adds two text nodes to $node
  addTextElements($node,Foo=>'some text',Bar=>'some more text');

  Returns the amended node.

  Preserves the order of the text nodes added.

  If adding elements with no defined text, these will be added
  as nodes representing '<element_name/>'

=cut

sub addTextElements {
    my $node = shift;
    my $doc = $node->getOwnerDocument;

    while (@_) {
	my $text_elem = $doc->createElement(shift);
	my $value = shift;
	$text_elem->appendChild($doc->createTextNode($value)) if (defined $value);
	$node->appendChild($text_elem);
    }

    return $node;
}

=head2 addText

    Adds text content to a provided element.

    addText($node,'This is some text');

    returns the modified node

=cut

sub addText {
    my ($node,$text) = @_;
    my $doc = $node->getOwnerDocument;
    $node->appendChild($doc->createTextNode($text));
    return $node;
}

=head2 createDocument($root_tag)

This function will return a nice XML:DOM::Document object,
if called in array context it will return a list of the Document and the root.

It requires a root tag, and a list of tags to be added to the document

the tags can be scalars :

my ($doc,$root) = createDocument('Foo', 'Bar', 'Baz');

or a hashref of attributes, and the tags name :

my $doc = createDocument({name=>'Foo', xmlns=>'http://www.other.org/namespace', version=>1.3}, 'Bar', 'Baz');

NOTE: attributes of tags will not maintain their order

=cut

sub createDocument {
    my ($root_tag,@tags) = @_;
    my $docroot = (ref $root_tag) ? $root_tag->{name} : $root_tag;
    my $doc = XML::DOM::Document->new();
    my $root = $doc->createElement($docroot);
    if (ref $root_tag) {
	foreach (keys %$root_tag) {
	    next if /name/;
	    $root->setAttribute($_,$root_tag->{$_});
	}
    }
    $doc->appendChild($root);

    foreach my $tag ( @tags ) {
	last unless ($tag);
	my $element_tag = (ref $tag) ? $tag->{name} : $tag;
	my $element = $doc->createElement ($element_tag);
	if (ref $tag) {
	    foreach (keys %$tag) {
		next if /name/;
		$element->setAttribute($_,$tag->{$_});
	    }
	}
	$root->appendChild($element);
    }
    return (wantarray) ? ($doc,$root): $doc;
}

# Based on example in 'Effective XML processing with DOM and XPath in Perl'
# by Parand Tony Darugar, IBM Developerworks Oct 1st 2001
# Copyright (c) 2001 Parand Tony Darugar

=head2 getTextContents($node)

returns the text content of a node (and its subnodes)

my $content = getTextContents($node);

Function by P T Darugar, published in IBM Developerworks Oct 1st 2001

=cut

sub getTextContents {
    my ($node, $strip)= @_;
    my $contents;

    if (! $node ) {
	return;
    }
    for my $child ($node->getChildNodes()) {
	if ( $child->getNodeType() == 3 or $child->getNodeType() == 4 ) {
	    $contents .= $child->getData();
	}
    }

    if ($strip) {
	$contents =~ s/^\s+//;
	$contents =~ s/\s+$//;
    }

    return $contents;
}


#####################################################


1;
__END__

=head2 EXPORT

:all

&getTextContents

&createDocument &createTextElement &createElement &createElementwithText

&addAttributes &addText &addElements &addTextElements

=head1 SEE ALSO

XML:DOM

XML::Xerces

XML::Xerces::BagOfTricks

=head1 AUTHOR

Aaron Trevena, E<lt>teejay@droogs.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2004 by Aaron Trevena
Copyright (c) 2001 Michel Rodriguez, where applicable
Copyright (c) 2001 Parand Tony Darugar, where applicable

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.1 or,
at your option, any later version of Perl 5 you may have available.


=cut

package XML::Xerces::BagOfTricks;

=head1 NAME

XML::Xerces::BagOfTricks - A library to make XML:Xerces easier and more perl-ish

=head1 SYNOPSIS

  use XML::Xerces::BagOfTricks qw(:all);

  # get a nice (empty) DOM Document
  my $DOMDocument = getDocument($namespace,$root_tag);

  # get a DOM Document from an XML file
  my $DOMDocument = getDocumentFromXML (file=>$file);

  # get a DOM Document from an XML file
  my $DOMDocument = getDocumentFromXML(xml=>$xml);

  # get a nice Element containing a text node (i.e. <foo>bar</foo>)
  my $foo_elem = getTextElement($DOMDocument,'Foo','Bar');

  # get a nice element with attributes (i.e '<Foo isBar='0' isFoo='1'/>')
  my $foo_elem = getElement($DOMDocument,'Foo','isBar'=>0, 'isFoo'=>1);

  # get a nice element with attributes that contains a text node
  my $foo_elem = getElementwithText($DOMDocument,'Foo','Bar',isFoo=>1,isBar=>0);
  # (i.e. <Foo isFoo='1' isBar='0'>Bar</Foo>)

  # if node is not of type Element then append its data to $contents
  # based on examples in article by P T Darugar.
  if ( $NodeType[$node->getNodeType()] ne 'Element' ) {
	    $contents .= $node->getData();
  }
  # or the easier..
  my $content = getTextContents($node);

  # get the nice DOM Document as XML
  my $xml = getXML($DOMDocument);

=head1 DESCRIPTION

This module is designed to provide a bag of tricks for users of
XML::Xerces DOM API. It provides some useful variables for
looking up xerces-c enum values.

It also provides functions that make dealing with, creating and
printing DOM objects much easier.

getTextContents() from 'Effective XML processing with DOM and XPath in Perl'
by Parand Tony Darugar, IBM Developerworks Oct 1st 2001

=head2 EXPORT

':all' tag exports the following :

%NodeType @NodeType $schemaparser $dtdparser $plainparser

&getTextContents &getDocument &getDocumentFromXML &getXML

&getTextElement &getElement &getElementwithText


=head1 FUNCTIONS

=cut

use strict;

use XML::Xerces;

require Exporter;
use AutoLoader qw(AUTOLOAD);

our $VERSION = '0.03';
our @ISA = qw(Exporter);
our %EXPORT_TAGS = ( 'all' => [ qw(
				   %NodeType @NodeType $schemaparser $dtdparser $plainparser
				   &getTextContents &getDocument &getDocumentFromXML &getXML &getTextElement
				   &getElement &getElementwithText
				   ) ] );
our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

# Xerces implementation and writer
my $impl = XML::Xerces::DOMImplementationRegistry::getDOMImplementation('LS');
my $writer = $impl->createDOMWriter();
if ($writer->canSetFeature('format-pretty-print',1)) {
    $writer->setFeature('format-pretty-print',1);
}

# Xerces parsers (one for Schema, DTD and neither)
my $validate = $XML::Xerces::AbstractDOMParser::Val_Auto;
my $schemaparser = XML::Xerces::XercesDOMParser->new();
my $dtdparser = XML::Xerces::XercesDOMParser->new();
my $plainparser = XML::Xerces::XercesDOMParser->new();
my $error_handler = XML::Xerces::PerlErrorHandler->new();
my $c = 0;
foreach ( $schemaparser, $dtdparser, $plainparser) {
  $_->setValidationScheme ($validate);
  $_->setDoNamespaces (1);
  $_->setCreateEntityReferenceNodes(1);
  $_->setErrorHandler($error_handler);
}
$schemaparser->setDoSchema (1);

my $parser = $plainparser;

our %NodeType;
our @NodeType = qw(ERROR ELEMENT_NODE ATTRIBUTE_NODE TEXT_NODE CDATA_SECTION_NODE ENTITY_REFERENCE_NODE ENTITY_NODE PROCESSING_INSTRUCTION_NODE COMMENT_NODE DOCUMENT_NODE DOCUMENT_TYPE_NODE DOCUMENT_FRAGMENT_NODE NOTATION_NODE );
@NodeType{@NodeType} = ( 0 .. 13 );

# Preloaded methods go here.

# Based on example in 'Effective XML processing with DOM and XPath in Perl'
# by Parand Tony Darugar, IBM Developerworks Oct 1st 2001

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
	if ( $NodeType[$child->getNodeType()] =~ /(?:TEXT|CDATA_SECTION)_NODE/ ) {
	    $contents .= $child->getData();
	}
    }

    if ($strip) {
	$contents =~ s/^\s+//;
	$contents =~ s/\s+$//;
    }

    return $contents;
}

=head2 getTextElement($doc,$name,$value)

    This function returns a nice XML::Xerces::DOMNode representing an element
    with an appended Text subnode, based on the arguments provided.

    In the example below $node would represent '<Foo>Bar</Foo>'

    my $node = getTextElement($doc,'Foo','Bar');

    More useful than a pocketful of bent drawing pins! If only the Chilli Peppers
    made music like they used to 'Zephyr' is no equal of 'Fight Like A Brave' or
    'Give it away'

=cut

sub getTextElement {
    my ($doc, $name, $value) = @_;
    warn "D'oh! it would be a good idea to provide a value to getTextElement : ", caller() unless $value;
    my $field = $doc->createElement($name);
    my $fieldvalue = $doc->createTextNode($value);
    $field->appendChild($fieldvalue);
    return $field;
}

=head2 getElement($doc,$name,%attributes)

    This function returns a nice XML::Xerces::DOMNode representing an element
    with an appended Text subnode, based on the arguments provided.

    In the example below $node would represent '<Foo isBar='0' isFoo='1'/>'

    my $node = getElement($doc,'Foo','isBar'=>0, 'isFoo'=>1);

=cut


sub getElement {
    my ($doc, $name, %attributes) = @_;
    my $node = $doc->createElement($name);
    foreach my $attr_name (keys %attributes) {
	if (defined $attributes{$attr_name}) {
	    $node->setAttribute($attr_name,$attributes{$attr_name});
	}
    }
    return $node;
}


=head2 getElementwithText($DOMDocument,$node_name,$text,$attr_name=>$attr_value);

  # get a nice element with attributes that contains a text node ( i.e. <Foo isFoo='1' isBar='0'>Bar</Foo> )
  my $foo_elem = getElementwithText($DOMDocument,'Foo','Bar',isFoo=>1,isBar=>0);

=cut

sub getElementwithText {
    my ($doc, $nodename, $textvalue, %attributes) = @_;
    my $node = $doc->createElement($nodename);
    if ($textvalue) {
	my $text = $doc->createTextNode($textvalue);
	$node->appendChild($text);
    }
    foreach my $attr_name (keys %attributes) {
	$node->setAttribute($attr_name,$attributes{$attr_name}) if (defined $attributes{$attr_name});
    }
    return $node;
}


=head2 getDocument($namespace,$root_tag)

This function will return a nice XML:Xerces::DOMDocument object.

It requires a namespace, a root tag, and a list of tags to be added to the document

the tags can be scalars :

my $doc = getDocument('http://www.some.org/schema/year foo.xsd', 'Foo', 'Bar', 'Baz');

or a hashref of attributes, and the tags name :

my $doc = getDocument($ns,{name=>'Foo', xmlns=>'http://www.other.org/namespace', version=>1.3}, 'Bar', 'Baz');

=cut

# maybe we should memoize this later

sub getDocument {
    my ($ns,$root_tag,@tags) = @_;
    my $docroot = (ref $root_tag) ? $root_tag->{name} : $root_tag;
    my $doc = eval{$impl->createDocument($ns, $docroot, undef)};
    XML::Xerces::error($@) if $@;
    my $root = $doc->getDocumentElement();
    if (ref $root_tag) {
	foreach (keys %$root_tag) {
	    next if /name/;
	    $root->setAttribute($_,$root_tag->{$_});
	}
    }
    foreach my $tag ( @tags ) {
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
    return $doc;

}

=head2 getDocumentFromXML

Returns an XML::Xerces::DOMDocument object based on the provided input

my $DOMDocument = getDocumentFromXML(xml=>$xml);

uses the XML::Xerces DOM parser to build a DOM Tree of the given xml

my $DOMDocument = getDocumentFromXML (file=>$file);

uses the XML::Xerces DOM parser to build a DOM Tree of the given xml

=cut

sub getDocumentFromXML {
    my $key = shift;
    my $value = shift;
    my $mode;

    if ( lc($key) eq 'xml') {
	$mode = 'xml';
    } elsif (lc $key eq 'file') {
	$mode = 'file';
    } else {
	$mode = ($key =~ /^</) ? 'xml' : 'file' ;
	$value = $key;
    }

    my $parser = $plainparser;

    my $input;
    if ($mode eq 'xml') {
	eval { $input =  XML::Xerces::MemBufInputSource->new($value); };
	XML::Xerces::error($@) if ($@);
#	warn "got buffer : $input \n";
    } else {
	$input = $value;
    }

    eval { $parser->parse ($input);  };
    XML::Xerces::error($@) if ($@);

    my $doc;
    if ($@) {
	if ($@->isa("XML::Xerces::XMLException")) {
	    warn("XML Exception: type = ".$@->getType.", "
		 ."code = ".$@->getCode.", message = "
		 .$@->getMessage.", src=".$@->getSrcFile." line "
		 .$@->getSrcLine);
	} else {
	    warn "XML Problem - Got a ".ref($@)." back! we were expecting an XML::Xerces:DOMDocument";
	    XML::Xerces::error($@);
	}
    } else {
	$doc =  $parser->getDocument;
#	warn "XML validated successfully\n";
    }
    return $doc;
}

=head2 getXML($DOMDocument)

getXML is exported in the ':all' tag and will return XML in a string
generated from the DOM Document passed to it

my $xml = getXML($doc);

=cut

sub getXML {
    my $doc = shift;
    my $target = XML::Xerces::MemBufFormatTarget->new();
    $writer->writeNode($target,$doc);
    my $xml = $target->getRawBuffer;
    return $xml;
}


################################################################

1;

__END__

=head1 SEE ALSO

XML::Xerces

=head1 AUTHOR

Aaron Trevena, E<lt>teejay@droogs.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2003 by Aaron Trevena, Surrey Technologies, Ltd.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.1 or,
at your option, any later version of Perl 5 you may have available.


=cut

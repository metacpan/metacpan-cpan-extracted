package XML::GDOME;

# generated automatically from generate script

use strict;
use vars qw($VERSION @ISA @EXPORT);

use XML::LibXML::Common qw(:encoding :w3c);

$VERSION = '0.86';

require DynaLoader;
require Exporter;
@ISA = qw(DynaLoader Exporter);

bootstrap XML::GDOME $VERSION;

my $di = XML::GDOME::DOMImplementation::mkref();

sub CLONE {
	XML::GDOME::DOMImplementation::ref($di);
}

@EXPORT = qw( GDOME_NOEXCEPTION_ERR INDEX_SIZE_ERR DOMSTRING_SIZE_ERR HIERARCHY_REQUEST_ERR WRONG_DOCUMENT_ERR INVALID_CHARACTER_ERR NO_DATA_ALLOWED_ERR NO_MODIFICATION_ALLOWED_ERR NOT_FOUND_ERR NOT_SUPPORTED_ERR INUSE_ATTRIBUTE_ERR INVALID_STATE_ERR SYNTAX_ERR INVALID_MODIFICATION_ERR NAMESPACE_ERR INVALID_ACCESS_ERR GDOME_NULL_POINTER_ERR GDOME_CORE_EXCEPTION GDOME_EVENT_EXCEPTION GDOME_XPATH_EXCEPTION GDOME_EXCEPTION_TYPE_MASK GDOME_EXCEPTION_CODE_MASK GDOME_READONLY_NODE GDOME_READWRITE_NODE GDOME_LOAD_PARSING GDOME_LOAD_VALIDATING GDOME_LOAD_RECOVERING GDOME_LOAD_SUBSTITUTE_ENTITIES GDOME_LOAD_COMPLETE_ATTRS GDOME_SAVE_STANDARD GDOME_SAVE_LIBXML_INDENT ELEMENT_NODE ATTRIBUTE_NODE TEXT_NODE CDATA_SECTION_NODE ENTITY_REFERENCE_NODE ENTITY_NODE PROCESSING_INSTRUCTION_NODE COMMENT_NODE DOCUMENT_NODE DOCUMENT_TYPE_NODE DOCUMENT_FRAGMENT_NODE NOTATION_NODE XPATH_NAMESPACE_NODE INVALID_EXPRESSION_ERR TYPE_ERR ANY_TYPE NUMBER_TYPE STRING_TYPE BOOLEAN_TYPE UNORDERED_NODE_ITERATOR_TYPE ORDERED_NODE_ITERATOR_TYPE UNORDERED_NODE_SNAPSHOT_TYPE ORDERED_NODE_SNAPSHOT_TYPE ANY_UNORDERED_NODE_TYPE FIRST_ORDERED_NODE_TYPE
encodeToUTF8
decodeFromUTF8
);

sub GDOME_NOEXCEPTION_ERR(){0;}
sub INDEX_SIZE_ERR(){1;}
sub DOMSTRING_SIZE_ERR(){2;}
sub HIERARCHY_REQUEST_ERR(){3;}
sub WRONG_DOCUMENT_ERR(){4;}
sub INVALID_CHARACTER_ERR(){5;}
sub NO_DATA_ALLOWED_ERR(){6;}
sub NO_MODIFICATION_ALLOWED_ERR(){7;}
sub NOT_FOUND_ERR(){8;}
sub NOT_SUPPORTED_ERR(){9;}
sub INUSE_ATTRIBUTE_ERR(){10;}
sub INVALID_STATE_ERR(){11;}
sub SYNTAX_ERR(){12;}
sub INVALID_MODIFICATION_ERR(){13;}
sub NAMESPACE_ERR(){14;}
sub INVALID_ACCESS_ERR(){15;}
sub GDOME_NULL_POINTER_ERR(){100;}
sub GDOME_CORE_EXCEPTION(){0;}
sub GDOME_EVENT_EXCEPTION(){1;}
sub GDOME_XPATH_EXCEPTION(){2;}
sub GDOME_EXCEPTION_TYPE_MASK(){0;}
sub GDOME_EXCEPTION_CODE_MASK(){0;}
sub GDOME_LOAD_PARSING(){0;}
sub GDOME_LOAD_VALIDATING(){1;}
sub GDOME_LOAD_RECOVERING(){2;}
sub GDOME_LOAD_SUBSTITUTE_ENTITIES(){4;}
sub GDOME_LOAD_COMPLETE_ATTRS(){8;}
sub GDOME_SAVE_STANDARD(){0;}
sub GDOME_SAVE_LIBXML_INDENT(){1;}
sub XPATH_NAMESPACE_NODE(){13;}
sub INVALID_EXPRESSION_ERR(){101;}
sub TYPE_ERR(){102;}
sub ANY_TYPE(){0;}
sub NUMBER_TYPE(){1;}
sub STRING_TYPE(){2;}
sub BOOLEAN_TYPE(){3;}
sub UNORDERED_NODE_ITERATOR_TYPE(){4;}
sub ORDERED_NODE_ITERATOR_TYPE(){5;}
sub UNORDERED_NODE_SNAPSHOT_TYPE(){6;}
sub ORDERED_NODE_SNAPSHOT_TYPE(){7;}
sub ANY_UNORDERED_NODE_TYPE(){8;}
sub FIRST_ORDERED_NODE_TYPE(){9;}

@XML::GDOME::DocumentFragment::ISA      = 'XML::GDOME::Node';
@XML::GDOME::Document::ISA              = 'XML::GDOME::Node';
@XML::GDOME::CharacterData::ISA         = 'XML::GDOME::Node';
@XML::GDOME::Text::ISA                  = 'XML::GDOME::CharacterData';
@XML::GDOME::CDATASection::ISA          = 'XML::GDOME::Text';
@XML::GDOME::Comment::ISA               = 'XML::GDOME::CharacterData';
@XML::GDOME::Attr::ISA                  = 'XML::GDOME::Node';
@XML::GDOME::Element::ISA               = 'XML::GDOME::Node';
@XML::GDOME::DocumentType::ISA          = 'XML::GDOME::Node';
@XML::GDOME::Notation::ISA              = 'XML::GDOME::Node';
@XML::GDOME::Entity::ISA                = 'XML::GDOME::Node';
@XML::GDOME::EntityReference::ISA       = 'XML::GDOME::Node';
@XML::GDOME::ProcessingInstruction::ISA = 'XML::GDOME::Node';
@XML::GDOME::XPath::Namespace::ISA      = 'XML::GDOME::Node';

sub createDocFromString {
  my $class = shift;
  my $str = shift;
  my $mode = shift || 0;
  return $di->createDocFromMemory($str, $mode);
}

sub createDocFromURI {
  my $class = shift;
  my $uri = shift; 
  my $mode = shift || 0;
  return $di->createDocFromURI($uri, $mode);
}

sub createDocument {
  my $class = shift;
  return $di->createDocument(@_);
}

sub createDocumentType {
  my $class = shift;
  return $di->createDocumentType(@_);
}

sub hasFeature {
  my $class = shift;
  return $di->hasFeature(@_);
}

sub new {
  my $class = shift;
  my %options = @_;
  my $self = bless \%options, $class;

  return $self;
}

sub parse_fh {
  my ($self, $fh) = @_;
  local $/ = undef;
  my $str = <$fh>;
  $self->init_parser();
  my $doc = __PACKAGE__->createDocFromString($str);
  if ( $self->{XML_GDOME_EXPAND_XINCLUDE} ) {
    $doc->process_xinclude();
  }
  return $doc;
}

sub parse_string {
  my ($self, $str) = @_;
  $self->init_parser();
  my $doc =__PACKAGE__->createDocFromString($str);
  if ( $self->{XML_GDOME_EXPAND_XINCLUDE} ) {
    $doc->process_xinclude();
  }
  return $doc;
}

sub parse_file {
  my ($self, $uri) = @_;
  $self->init_parser();
  my $doc = __PACKAGE__->createDocFromURI($uri);
  if ( $self->{XML_GDOME_EXPAND_XINCLUDE} ) {
    $doc->process_xinclude();
  }
  return $doc;
}

sub match_callback {
    my $self = shift;
    return $self->{XML_GDOME_MATCH_CB} = shift;
}

sub read_callback {
    my $self = shift;
    return $self->{XML_GDOME_READ_CB} = shift;
}

sub close_callback {
    my $self = shift;
    return $self->{XML_GDOME_CLOSE_CB} = shift;
}

sub open_callback {
    my $self = shift;
    return $self->{XML_GDOME_OPEN_CB} = shift;
}

sub callbacks {
    my $self = shift;
    if (@_) {
        my ($match, $open, $read, $close) = @_;
        @{$self}{qw(XML_GDOME_MATCH_CB XML_GDOME_OPEN_CB XML_GDOME_READ_CB XML_GDOME_CLOSE_CB)} = ($match, $open, $read, $close);
    }
    else {
        return @{$self}{qw(XML_GDOME_MATCH_CB XML_GDOME_OPEN_CB XML_GDOME_READ_CB XML_GDOME_CLOSE_CB)};
    }
}

sub expand_xinclude  {
    my $self = shift;
    $self->{XML_GDOME_EXPAND_XINCLUDE} = shift if scalar @_;
    return $self->{XML_GDOME_EXPAND_XINCLUDE};
}

sub init_parser {
    my $self = shift;
    $self->_match_callback( $self->{XML_GDOME_MATCH_CB} )
      if $self->{XML_GDOME_MATCH_CB};
    $self->_read_callback( $self->{XML_GDOME_READ_CB} )
      if $self->{XML_GDOME_READ_CB};
    $self->_open_callback( $self->{XML_GDOME_OPEN_CB} )
      if $self->{XML_GDOME_OPEN_CB};
    $self->_close_callback( $self->{XML_GDOME_CLOSE_CB} )
      if $self->{XML_GDOME_CLOSE_CB};
}

package XML::GDOME::Document;

sub toString {
  my $doc = shift;
  my $mode = shift || 0;
  return $di->saveDocToString($doc,$mode);
}

sub toStringEnc {
  my $doc = shift;
  my $encoding = shift;
  my $mode = shift || 0;
  return $di->saveDocToStringEnc($doc,$encoding,$mode);
}

package XML::GDOME::Node;

sub attributes {
  getAttributes(@_);
}

sub getAttributes {
  my ($elem) = @_;
  my $nnm = $elem->_attributes;
  if (wantarray) {
    return () if !$nnm;
    my @attrs;
    for my $i (0 .. $nnm->getLength - 1) {
      push @attrs, $nnm->item("$i");
    }
    return @attrs;
  } else {
    return $nnm;
  }
}

sub xpath_evaluate {
  my ($contextNode, $expression, $resolver, $type) = @_;
  $XML::GDOME::XPath::xpeval ||= XML::GDOME::XPath::Evaluator::mkref();
  no warnings;
  return $XML::GDOME::XPath::xpeval->evaluate($expression, $contextNode, $resolver, $type, undef);
}

sub findnodes {
  my $res = xpath_evaluate(@_);

  my @nodes;
  while (my $node = $res->iterateNext) {
    push @nodes, $node;
  }
  return @nodes;
}

sub xpath_createNSResolver {
  my ($node) = @_;
  $XML::GDOME::XPath::xpeval ||= XML::GDOME::XPath::Evaluator::mkref();
  return $XML::GDOME::XPath::xpeval->createNSResolver($node);
}

sub childNodes {
  getChildNodes(@_);
}

sub getChildNodes {
  my ($elem) = @_;
  my $nl = $elem->_childNodes;
  if (wantarray) {
    return () if !$nl;
    my @nodes;
    for my $i (0 .. $nl->getLength - 1) {
      push @nodes, $nl->item("$i");
    }
    return @nodes;
  } else {
    return $nl;
  }
}

sub iterator {
  my $self = shift;
  my $funcref = shift;
  my $child = undef;

  my $rv = $funcref->( $self );
  foreach $child ( $self->getChildNodes() ){
    $rv = $child->iterator( $funcref );
  }
  return $rv;
}

sub getAttributesNS {
  my ($self, $nsuri) = @_;
  my @attr;
  for my $attr ($self->getAttributes()) {
    push @attr, $attr if $attr->getNamespaceURI() eq $nsuri;
  }
  return @attr;
}

sub findvalue {
  my $res = xpath_evaluate(@_);

  my $val = '';
  while (my $node = $res->iterateNext) {
    $val .= $node->to_literal;
  }
  return $val;
}

sub find {
  my $res = xpath_evaluate(@_);

  my $type = $res->resultType;
  if ($type == XML::GDOME::UNORDERED_NODE_ITERATOR_TYPE ||
      $type == XML::GDOME::ORDERED_NODE_ITERATOR_TYPE) {
    my @nodes;
    while (my $node = $res->iterateNext) {
      push @nodes, $node;
    }
    return @nodes;
  }
  elsif ($type == XML::GDOME::NUMBER_TYPE()) {
    return $res->numberValue;
  }
  elsif ($type == XML::GDOME::STRING_TYPE()) {
    return $res->stringValue;
  }
  elsif ($type == XML::GDOME::BOOLEAN_TYPE()) {
    return $res->booleanValue;
  }
  else {
    croak("Unknown result type");
  }
}

sub insertAfter {
  my ($parent, $newChild, $refChild) = @_;

  if (!$refChild) {
    return $parent->appendChild($newChild);
  }
  my $nextChild = $refChild->getNextSibling();
  if ($nextChild) {
    $parent->insertBefore($newChild, $nextChild);
  } else {
    $parent->appendChild($newChild);
  }
}

sub getChildrenByTagName {
  my ($self, $tagname) = @_;
  my @nodes;
  for my $node ($self->getChildNodes()) {
    if ($node->getNodeName() eq $tagname) {
      push @nodes, $node;
    }
  }
  return @nodes;
}

sub getChildrenByTagNameNS {
  my ($self, $nsURI, $tagname) = @_;
  my @nodes;
  for my $node ($self->getChildNodes()) {
    if ($node->getLocalName() eq $tagname &&
      $node->getNamespaceURI eq $nsURI) {
      push @nodes, $node;
    }
  }
  return @nodes;
}

sub getElementsByLocalName {
  my ($self, $localname) = @_;
  # FIXME must fetch all descendants of node with local name
  my @elem;
  for my $elem ($self->getChildNodes()) {
    push @elem, $elem if $elem->getLocalName() eq $localname;
  }
  return @elem;
}

sub getName {
  getNodeName(@_);
}

sub getData {
  getNodeValue(@_);
}

sub getType {
  getNodeType(@_);
}

sub getOwner {
  getOwnerDocument(@_);
}

sub getChildnodes {
  getChildNodes(@_);
}

sub localname {
  getLocalName(@_);
}

package XML::GDOME::Element;

sub appendTextNode {
  appendText(@_);
}

sub appendText {
  my ($node, $xmlString) = @_;
  if ($xmlString != '') {
    my $text = $node->getOwnerDocument->createTextNode($xmlString);
    $node->appendChild($text);
  }
  return;
}

sub getElementsByTagName {
  my $elem = shift;
  my $nl = $elem->_getElementsByTagName(@_);
  if (wantarray) {
    return () if !$nl;
    my @nodes;
    for my $i (0 .. $nl->getLength - 1) {
      push @nodes, $nl->item("$i");
    }
    return @nodes;
  } else {
    return $nl;
  }
}

sub getElementsByTagNameNS {
  my $elem = shift;
  my $nl = $elem->_getElementsByTagNameNS(@_);
  if (wantarray) {
    return () if !$nl;
    my @nodes;
    for my $i (0 .. $nl->getLength - 1) {
      push @nodes, $nl->item("$i");
    }
    return @nodes;
  } else {
    return $nl;
  }
}

sub appendTextChild {
  my ($node, $tagName, $xmlString) = @_;
  my $dom = $node->getOwnerDocument();
  my $child = $node->appendChild($dom->createElement($tagName));
  return $child->appendChild($dom->createTextNode($xmlString));
  return $child;
}

sub appendWellBalancedChunk {
  my ($self, $chunk) = @_;
  my $dom0 = $self->getOwnerDocument();
  my $dom1 = XML::GDOME->createDocFromString("<gdome>".$chunk."</gdome>");
  for my $child ($dom1->getDocumentElement()->getChildNodes()) {
    my $copy = $dom0->importNode($child, 1);
    $self->appendChild($copy);
  }
}

package XML::GDOME::Document;

sub getElementsByTagName {
  my $elem = shift;
  my $nl = $elem->_getElementsByTagName(@_);
  if (wantarray) {
    return () if !$nl;
    my @nodes;
    for my $i (0 .. $nl->getLength - 1) {
      push @nodes, $nl->item("$i");
    }
    return @nodes;
  } else {
    return $nl;
  }
}

sub getElementsByTagNameNS {
  my $elem = shift;
  my $nl = $elem->_getElementsByTagNameNS(@_);
  if (wantarray) {
    return () if !$nl;
    my @nodes;
    for my $i (0 .. $nl->getLength - 1) {
      push @nodes, $nl->item("$i");
    }
    return @nodes;
  } else {
    return $nl;
  }
}

sub createAttribute {
  my ($elem, $name, $value) = @_;
  my $attr = $elem->_createAttribute($name);
  if ($value) {
    $attr->setValue($value);
  }
  return $attr;
}

sub createPI {
  createProcessingInstruction(@_);
}

1;

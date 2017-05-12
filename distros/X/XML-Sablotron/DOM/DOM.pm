# 
# The contents of this file are subject to the Mozilla Public
# License Version 1.1 (the "License"); you may not use this file
# except in compliance with the License. You may obtain a copy of
# the License at http://www.mozilla.org/MPL/
# 
# Software distributed under the License is distributed on an "AS
# IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or
# implied. See the License for the specific language governing
# rights and limitations under the License.
# 
# The Original Code is the XML::Sablotron::DOM module.
# 
# The Initial Developer of the Original Code is Ginger Alliance Ltd.
# Portions created by Ginger Alliance are 
# Copyright (C) 1999-2000 Ginger Alliance Ltd.
# All Rights Reserved.
# 
# Contributor(s): Albert.N.Micheev
# 
# Alternatively, the contents of this file may be used under the
# terms of the GNU General Public License Version 2 or later (the
# "GPL"), in which case the provisions of the GPL are applicable 
# instead of those above.  If you wish to allow use of your 
# version of this file only under the terms of the GPL and not to
# allow others to use your version of this file under the MPL,
# indicate your decision by deleting the provisions above and
# replace them with the notice and other provisions required by
# the GPL.  If you do not delete the provisions above, a recipient
# may use your version of this file under either the MPL or the
# GPL.
# 

package XML::Sablotron::DOM;

#require 5.005_62;
use strict;
use Carp;

use XML::Sablotron;

require Exporter;
require DynaLoader;

my @_constants = qw ( ELEMENT_NODE ATTRIBUTE_NODE TEXT_NODE 
		      CDATA_SECTION_NODE ENTITY_REFERENCE_NODE
		      ENTITY_NODE PROCESSING_INSTRUCTION_NODE
		      COMMENT_NODE DOCUMENT_NODE DOCUMENT_TYPE_NODE
		      DOCUMENT_FRAGMENT_NODE NOTATION_NODE 
		      
                      SDOM_OK INDEX_SIZE_ERR DOMSTRING_SIZE_ERR
                      HIERARCHY_ERR WRONG_DOCUMENT_ERR INVALID_CHARACTER_ERR
                      NO_DATA_ALLOWED_ERR NO_MODIFICATION_ALLOWED_ERR
                      NOT_FOUND_ERR NOT_SUPPORTED_ERR INUSE_ATTRIBUTE_ERR
                      INVALID_STATE_ERR SYNTAX_ERR INVALID_MODIFICATION_ERR
                      NAMESPACE_ERR INVALID_ACCESS_ERR INVALID_NODE_TYPE_ERR
                      QUERY_PARSE_ERR QUERY_EXECUTION_ERR NOT_OK_ERR
                      );

use vars qw(@ISA %EXPORT_TAGS @EXPORT_OK @EXPORT $useUniqueWrappers
	   );
@ISA = qw(Exporter DynaLoader);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use XML::Sablotron::DOM ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.

my @_functions = qw ( parse 
		      parseBuffer 
		      parseStylesheet 
		      parseStylesheetBuffer);

%EXPORT_TAGS = ( 'all' => [ @_constants, @_functions ],
		     'constants' => \@_constants,
		     'functions' => \@_functions,
		   );

@EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} }, q($useUniqueWrappers) );

@EXPORT = qw(createNode);

# global flag 
$useUniqueWrappers=0;

#constants for node types
use constant ELEMENT_NODE => 1;
use constant ATTRIBUTE_NODE => 2;
use constant TEXT_NODE => 3;
use constant CDATA_SECTION_NODE => 4;
use constant ENTITY_REFERENCE_NODE => 5;
use constant ENTITY_NODE => 6;
use constant PROCESSING_INSTRUCTION_NODE => 7;
use constant COMMENT_NODE => 8;
use constant DOCUMENT_NODE => 9;
use constant DOCUMENT_TYPE_NODE => 10;
use constant DOCUMENT_FRAGMENT_NODE => 11;
use constant NOTATION_NODE => 12;
use constant OTHER_NODE => 13; #not in spec

#constants for error codes
use constant SDOM_OK => 0;
use constant INDEX_SIZE_ERR => 1;
use constant DOMSTRING_SIZE_ERR => 2;
use constant HIERARCHY_ERR => 3;
use constant WRONG_DOCUMENT_ERR => 4;
use constant INVALID_CHARACTER_ERR => 5;
use constant NO_DATA_ALLOWED_ERR => 6;
use constant NO_MODIFICATION_ALLOWED_ERR => 7;
use constant NOT_FOUND_ERR => 8;
use constant NOT_SUPPORTED_ERR => 9;
use constant INUSE_ATTRIBUTE_ERR => 10;
use constant INVALID_STATE_ERR => 11;
use constant SYNTAX_ERR => 12;
use constant INVALID_MODIFICATION_ERR => 13;
use constant NAMESPACE_ERR => 14;
use constant INVALID_ACCESS_ERR => 15;

use constant INVALID_NODE_TYPE_ERR => 16;
use constant QUERY_PARSE_ERR => 17;
use constant QUERY_EXECUTION_ERR => 18;
use constant NOT_OK => 19;

1;

########################## Node #######################
package XML::Sablotron::DOM::Node;

sub _getOrSet {
    #situation can be placed in $_[3] or $_[4]:
    my ($self, $getter, $setter) = @_;
    if ( @_ == 3 ) {
        return &{$getter}($self);
    };
    #cannot be called like as self->getter(undef)
    #to avoid ambiguity with  self->setter(undef):
    if ( @_ == 4 ) {
        if ( ref($_[3]) ) {
	    # $_[3] is situation:
	    return &{$getter}($self, $_[3]);
	}
	else {
	    # $_[3] is not sit, but arg for setter:
	    return &{$setter}($self, $_[3]);
	};
    };
    # $_[3] is not situation here, but $_[4] is:
    return &{$setter}($self, $_[3], $_[4]);
}

sub nodeName {
    my $self = shift;
    return $self->_getOrSet(\&getNodeName, 
			    \&setNodeName, 
			    @_);
}

sub nodeValue {
    my $self = shift;
    return $self->_getOrSet(\&getNodeValue, 
			    \&setNodeValue, 
			    @_);
}

sub childNodes {
    return XML::Sablotron::DOM::NodeList::_new([@_],
					       \&_childIndex,
					       \&_childCount);
}

sub equals {
    my ($self, $other) = @_;
    return $self->{_handle} == $other->{_handle};
}

sub insertBefore {
    my $self = shift;
    my $child = shift;
    $self->_insertBefore($child, @_);
    return $child;
}

sub appendChild {
    my $self = shift;
    my $child = shift;
    $self->_appendChild($child, @_);
    return $child;
}

sub removeChild {
    my ($self, $child, $sit) = @_;
    $self->_removeChild($child, $sit);
    return $child;
}

sub replaceChild {
    my ($self, $new, $old, $sit) = @_;
    $self->_replaceChild($new, $old, $sit);
    return $old;
}

sub normalize {
}

sub isSupported {
    return 0;
}

sub attributes {
    return undef; #implemented in XML::Sablotron::DOM::Element
}

sub hasAttributes {
    return 0;
}

sub prefix {
    my $self = shift;
    return $self->_getOrSet(\&getPrefix, 
			    \&setPrefix, 
			    @_);
}

sub DESTROY {
    my $self = shift;
    $self->_clearInstanceData();
}


#################### Document ####################
package XML::Sablotron::DOM::Document;
use vars qw( @ISA );
@ISA = qw( XML::Sablotron::DOM::Node );

#constructors
#sub new {
#    my ($class, %params) = @_;
#    $class = ref $class || $class;
#    my $self = {};
#    bless $self, $class;
#    $self->{_handle} = $self->_getNewDocumentHandle($params{SITUATION});
#    return $self;
#}

sub new {
    my ($class, %params) = @_;
    my $self =  _new($class, $params{SITUATION});
    $self->{_autodispose} = $params{AUTODISPOSE};
    return $self;
}

sub freeDocument {
    my ($self) = @_;
    $self->_freeDocument() if $self->{_handle};
}

#to avoid namespace conflict with JavaScript built-in
sub _toString {
    my ($self,@args) = @_;
    return $self->toString(@args);
}

sub autodispose {
    my ($self, $val) = @_;
    $self->{_autodispose} = $val if defined $val;
    $self->{_autodispose};
}

sub DESTROY {
    my $self = shift;
    $self->freeDocument() if $self->{_autodispose};
    my $foo = $self->_clearInstanceData();
}

#################### Element ####################
package XML::Sablotron::DOM::Element;
use vars qw( @ISA );
@ISA = qw( XML::Sablotron::DOM::Node );

sub tagName {
    my ($self, $sit) = @_;
    return $self->getNodeName($sit);
}

sub setAttributes {
    my ($self, $hash, $sit) = @_;
    while (my ($a, $b) = each %$hash) {
	$self->setAttribute($a, $b, $sit);
    }
}

sub getAttributes {
    my ($self, $sit) = @_;
    my $arr = $self->_getAttributes($sit);
    my $rval = {};
    foreach my $att (@$arr) {
	$$rval{$att->getNodeName($sit)} = $att->getNodeValue($sit);
    }
    return $rval;
}

sub attributes {
    return XML::Sablotron::DOM::NamedNodeMap::_new([@_],
						   \&_attrIndex,
						   \&_attrCount,
						   1);# 1 == readonly
}

#################### Attribute ####################
package XML::Sablotron::DOM::Attribute;
use vars qw( @ISA );
@ISA = qw( XML::Sablotron::DOM::Node );

sub name {
    my ($self, $sit) = @_;
    return $self->getNodeName($sit);
}

sub specified {
    return 1;
}

sub value { #need _fix_ for entity references
    my $self = shift;
    return $self->_getOrSet(\&getNodeValue, 
			    \&setNodeValue, 
			    @_);
}

#################### CharacterData ####################
package XML::Sablotron::DOM::CharacterData;
use vars qw( @ISA );
@ISA = qw( XML::Sablotron::DOM::Node );

sub data {
    my $self = shift;
    return $self->_getOrSet(\&getNodeValue, 
			    \&setNodeValue, 
			    @_);
}

sub length {
    my $self = shift;
    return CORE::length($self->getNodeValue(@_));
}

sub substringData {
    my ($self, $offset, $count) = shift;
    my $data = $self->getNodeValue(@_);
    ( $offset < 0 
      || $count < 0
      || $offset > CORE::length($data) )
    && die(XML::Sablotron::DOM::INDEX_SIZE_ERR);  
    return substr($data, $offset, $count);
}

sub appendData {
    my ($self, $arg) = shift;
    my $data = $self->getNodeValue(@_) . $arg;
    $self->setNodeValue($data, @_);
}

sub insertData {
    my ($self, $offset, $arg) = shift;
    my $data = $self->getNodeValue(@_);
    ( $offset < 0 
      || $offset > CORE::length($data) )
    && die(XML::Sablotron::DOM::INDEX_SIZE_ERR);  
    $self->setNodeValue( substr($data, 0, $offset)
			 . $arg
			 . substr($data, $offset),
			 @_);
}

sub deleteData {
    my ($self, $offset, $count) = shift;
    my $data = $self->getNodeValue(@_);
    ( $offset < 0 
      || $count < 0
      || $offset > CORE::length($data) )
    && die(XML::Sablotron::DOM::INDEX_SIZE_ERR);  
    $self->setNodeValue( substr($data, 0, $offset)
			 . substr($data, $offset + $count),
			 @_);
}

sub replaceData {
    my ($self, $offset, $count, $arg) = shift;
    my $data = $self->getNodeValue(@_);
    ( $offset < 0 
      || $count < 0
      || $offset > CORE::length($data) )
    && die(XML::Sablotron::DOM::INDEX_SIZE_ERR);  
    $self->setNodeValue( substr($data, 0, $offset)
			 . $arg
			 . substr($data, $offset + $count),
			 @_);
}

#################### Text ####################
package XML::Sablotron::DOM::Text;
use vars qw( @ISA );
@ISA = qw( XML::Sablotron::DOM::CharacterData );

sub splitText {
    my ($self, $offset) = shift;
    my $data = $self->getNodeValue(@_);
    ( $offset < 0 
      || $offset > CORE::length($data) )
    && die(XML::Sablotron::DOM::INDEX_SIZE_ERR);  
    my $newData = substr($data, $offset + 1);
    my ($newNode, $nextSibling);
    $self->setNodeValue(substr($data, 0, $offset), @_);
    if ($self->nodeType(@_) == XML::Sablotron::DOM::TEXT_NODE) {
        $newNode = $self->ownerDocument(@_)->createTextNode($newData, @_);
    } 
    else {
        #($self->nodeType(@_) == XML::Sablotron::DOM::CDATA_SECTION_NODE)
        $newNode = $self->ownerDocument(@_)->createCDATASection($newData, @_);
    };
    if ($self->parentNode(@_)) {
	$self->parentNode(@_)->insertBefore($newNode, $self->nextSibling(@_), @_);
    };
    return $newNode;
}

#################### CDATASection ####################
package XML::Sablotron::DOM::CDATASection;
use vars qw( @ISA );
@ISA = qw( XML::Sablotron::DOM::Text );

#################### EntityReference ####################
package XML::Sablotron::DOM::EntityReference;
use vars qw( @ISA );
@ISA = qw( XML::Sablotron::DOM::Node );

#################### Entity ####################
package XML::Sablotron::DOM::Entity;
use vars qw( @ISA );
@ISA = qw( XML::Sablotron::DOM::Node );

#################### ProcessingInstruction ####################
package XML::Sablotron::DOM::ProcessingInstruction;
use vars qw( @ISA );
@ISA = qw( XML::Sablotron::DOM::Node );

sub _getData {
    my $self = shift;
    return $self->getNodeValue(@_);
}

sub _setData {
    my ($self, $data) = shift;
    $self->setNodeValue($data, @_);
}

sub data {
    my $self = shift;
    return $self->_getOrSet(\&_getData, 
			    \&_setData, 
			    @_);
}

sub target {
    my $self = shift;
    return $self->getNodeName(@_);
}

#################### Comment ####################
package XML::Sablotron::DOM::Comment;
use vars qw( @ISA );
@ISA = qw( XML::Sablotron::DOM::Node );

#################### DocumentType ####################
package XML::Sablotron::DOM::DocumentType;
use vars qw( @ISA );
@ISA = qw( XML::Sablotron::DOM::Node );

#################### DocumentFragment ####################
package XML::Sablotron::DOM::DocumentFragment;
use vars qw( @ISA );
@ISA = qw( XML::Sablotron::DOM::Node );

#################### Notation ####################
package XML::Sablotron::DOM::Notation;
use vars qw( @ISA );
@ISA = qw( XML::Sablotron::DOM::Node );

#################### DOMImplementation ####################
package XML::Sablotron::DOM::DOMImplementation;

#################### NodeList ####################
package XML::Sablotron::DOM::NodeList;
sub _new {
    # ([$parent, $sit or nothing], $ritem, $rlength) == @_;
    return bless(\@_,'XML::Sablotron::DOM::NodeList');
}

sub item {
    my ($self, $index) = @_;
    return &{$self->[1]}($index, @{$self->[0]});
}

sub length {
    my ($self) = @_;
    return &{$self->[2]}(@{$self->[0]});
}

#################### NamedNodeMap ####################
package XML::Sablotron::DOM::NamedNodeMap;
use vars qw( @ISA );
@ISA = qw( XML::Sablotron::DOM::NodeList );

sub _new {
    # ([$parent, $sit or nothing], $ritem, $rlength, $readonly) == @_;
    return bless(\@_,'XML::Sablotron::DOM::NamedNodeMap');
}

sub getNamedItem {
    my ($self, $name) = @_;
    my $imax = $self->length();
    for (my $i = 0; $i < $imax; $i++) {
        if ($self->item($i)->getNodeName($self->[0]->[1]) eq $name) {
	    return $self->item($i);
	}
    }
    return undef;
}

sub setNamedItem {
    my ($self, $node) = @_;
    $self->[3] && die(XML::Sablotron::DOM::NO_MODIFICATION_ALLOWED_ERR);
    my $parent = $self->[0]->[0];
    my $sit = $self->[0]->[1];
    my $old = $self->getNamedItem($node->getNodeName($sit));
    $parent->_insertBefore($parent, $node, $old, $sit);
    $old && $parent->_removeChild($parent, $old, $sit);
    return $old;
}

sub removeNamedItem {
    my ($self, $name) = @_;
    $self->[3] && die(XML::Sablotron::DOM::NO_MODIFICATION_ALLOWED_ERR);
    my $node = $self->getNamedItem($name);
    $node || die(XML::Sablotron::DOM::NOT_FOUND_ERR);
    my $parent = $self->[0]->[0];
    $parent->_removeChild($node, $self->[0]->[1]);
    return $node;
}

sub getNamedItemNS {
    my ($self, $nsUri, $locName) = @_;
    my $imax = $self->length();
    my $sit = $self->[0]->[1];
    for (my $i = 0; $i < $imax; $i++) {
        if ($self->item($i)->namespaceURI($sit) eq $nsUri
	    && $self->item($i)->localName($sit) eq $locName) {
	    return $self->item($i);
	}
    }
    return undef;
}

sub setNamedItemNS {
    my ($self, $node) = @_;
    $self->[3] && die(XML::Sablotron::DOM::NO_MODIFICATION_ALLOWED_ERR);
    my $old = undef;
    my $parent = $self->[0]->[0];
    my $sit = $self->[0]->[1];
    $old = $self->getNamedItemNS($node->namespaceURI($sit), $node->localName($sit));
    $parent->_insertBefore($parent, $node, $old, $sit);
    $old && $parent->_removeChild($parent, $old, $sit);
    return $old;
}

sub removeNamedItemNS {
    my ($self, $nsUri, $locName) = @_;
    $self->[3] && die(XML::Sablotron::DOM::NO_MODIFICATION_ALLOWED_ERR);
    my $old = $self->getNamedItemNS($nsUri, $locName);
    $old || die(XML::Sablotron::DOM::NOT_FOUND_ERR);
    my $parent = $self->[0]->[0];
    $parent->_removeChild($parent, $old, $self->[0]->[1]);
    return $old;
}

__END__



# Below is stub documentation for your module. You better edit it!

=head1 NAME

XML::Sablotron::DOM - The DOM interface to Sablotron's internal structures

=head1 SYNOPSIS

  use XML::Sablotron::DOM;

  my $situa = new XML::Sablotron::Situation();
  my $doc = new XML::Sablotron::DOM::Document(SITUATION => $sit);

  my $e = $doc->createElement($situa, "foo");
  my $t = $doc->createTextNode($situa, "this is my text");

  print $doc->toString();

=head1 DESCRIPTION

Sablotron uses internally the DOM-like data structures to represent
parsed XML trees. In the C<sdom.h> header file is defined a subset of
functions allowing the DOM access to these structures.

=head2 What is it good for

You may find this module useful if you need to

=over 4

=item * access parsed trees

=item * build trees on the fly

=item * pass parsed/built trees into XSLT processor

=back

=head2 Situation

There is one significant extension to the DOM specification. Since
Sablotron is designed to support multithreading processing (and well
reentrant code too), you need create and use special context for error
processing. This context is called the I<situation>.

An instance of this object MUST be passed as the first parameter to
almost all calls in the C<XML::Sablotron::DOM> code.

Some easy-to-use default behavior may be introduced in later releases.

See C<perldoc XML::Sablotron> for more details.

=head1 MEMORY ISSUES

Perl objects representing nodes of the DOM tree live independently on
internal structures of Sablotron. If you create and populate the
document, its structure is not related to the lifecycle of your Perl
variables. It is good for you, but there are two exceptions to this:

=over 4

=item * freeing the document

=item * accessing the node after the document is destroyed

=back

As results from above, you have to force XML::Sablotron::DOM to free
document, if you want. Use

  $doc->freeDocument($sit);

to to it. Another way is to use the autodispode feature (see the
documentation for the method autodispose and document constructor).

If you will try to access the node, which was previously disposed by
Sablotron (perhaps with the all tree), your Perl code will die with
exception -1. Use C<eval {};> to avoid program termination.

=head1 PACKAGES

The C<XML::Sablotron::DOM> defines several packages. Just will be
created manually in your code; they are mostly returned as a return
values from many functions.

=head1 XML::Sablotron::DOM

The C<XML::Sablotron::DOM> package is almost empty, and serves as a
parent module for the other packages.

By default this module exports no symbols into the callers package. If
want to use some predefined constants or functions, you may use

  use XML::Sablotron::DOM qw( :constants :functions );

=head2 constants

Constants are defined for:

=over 4

=item * node types

C<ELEMENT_NODE, ATTRIBUTE_NODE, TEXT_NODE, CDATA_SECTION_NODE,
ENTITY_REFERENCE_NODE, ENTITY_NODE, PROCESSING_INSTRUCTION_NODE,
COMMENT_NODE, DOCUMENT_NODE, DOCUMENT_TYPE_NODE,
DOCUMENT_FRAGMENT_NODE, NOTATION_NODE, OTHER_NODE>

=item * exception codes

C<SDOM_OK, INDEX_SIZE_ERR, DOMSTRING_SIZE_ERR, HIERARCHY_ERR,
WRONG_DOCUMENT_ERR, INVALID_CHARACTER_ERR, NO_DATA_ALLOWED_ERR,
NO_MODIFICATION_ALLOWED_ERR, NOT_FOUND_ERR, NOT_SUPPORTED_ERR,
INUSE_ATTRIBUTE_ERR, INVALID_STATE_ERR, SYNTAX_ERR,
INVALID_MODIFICATION_ERR, NAMESPACE_ERR, INVALID_ACCESS_ERR, 
INVALID_NODE_TYPE_ERR, QUERY_PARSE_ERR QUERY_EXECUTION_ERR,
NOT_OK>

=back

=head2 parse

This function parses the document specified by the URI. There is
currently no support for scheme handler for this operation (see
L<XML::Sablotron>) but it will be added soon.

Function returns the XML::Sablotron::DOM::Document object instance.

  XML::Sablotron::DOM::parse($sit, $uri);

=over 4

=item $sit

The situation to be used.

=item $uri

The URI of the document to be parsed.

=back

=head2 parseBuffer

This function parses the literal data specified.

  XML::Sablotron::DOM::parseBuffer($sit, $data);

=over 4

=item $sit

The situation to be used.

=item $data

The string containing the XML data to be parsed.

=back

=head2 parseStylesheet

This function parses the stylesheet specified by the URI. There is
currently no support for scheme handler for this operation (see
L<XML::Sablotron>) but it will be added soon.

Function returns the XML::Sablotron::DOM::Document object instance.

  XML::Sablotron::DOM::parseStylesheet($sit, $uri);

=over 4

=item $sit

The situation to be used.

=item $uri

The URI of the stylesheet to be parsed.

=back

=head2 parseStylesheetBuffer

This function parses the stylesheet given by the literal data.

  XML::Sablotron::DOM::parseStylesheetBuffer($sit, $data);

=over 4

=item $sit

The situation to be used.

=item $data

The string containing the stylesheet to be parsed.

=back

=head1 XML::Sablotron::DOM::Node

This package is used to represent the Sablotron internal
representation of the node. It is the common ancestor of all other
types. 

=head2 equals

Check if the to perl representations of the node represent the same
node in the DOM document. Not in DOM spec.

B<Synopsis:>

  $node1->equals($node2);

=over 4

=item $node2

The node to be compared to.

=back

=head2 getNodeName

For ELEMENT_NODE and ATTRIBUTE_NODE returns the name of the node. For
other node types return as follows:

TEXT_NODE => "#text", CDATA_SECTION_NODE => "#cdata-section",
COMMENT_NODE => "#comment", DOCUMENT_NODE => "#document",
PROCESSING_INSTRUCTION_NODE => target of this node

Not in DOM spec.

B<Synopsis:>

  $node->getNodeName([$situa]);

=over 4

=item $situa

The situation to be used (optional).

=back

=head2 setNodeName

Sets the name of the node. Not in DOM spec.

B<Exceptions:> 

=over 4

=item NO_MODIFICATION_ALLOWED_ERR 

for TEXT_NODE, CDATA_SECTION_NODE, COMMENT_NODE and DOCUMENT_NODE
for ATTRIBUTE_NODE:if attempt to set name of attribute, which defines
namespace used by coresponding element or by another attribute of
coresponding element
 
=item NAMESPACE_ERR 

for ELEMENT_NODE:if unknown prefix is used to set name
for ATTRIBUTE_NODE:if attempt to change non-namespace attribute to
namespace attribute a vice versa

=back

B<Synopsis:>

  $node->setNodeName($name [, $situa]);

=over 4

=item $name

The new node name.

=item $situa

The situation to be used (optional).

=back

=head2 nodeName

Gets or sets the name of the node.

B<Exceptions:> 

=over 4

=item see getNodeName, setNodeName 

=back

B<Synopsis:>

  $node->nodeName([$situa]);  
  $node->nodeName($name [, $situa]);

=over 4

=item $name

The new node name.

=item $situa

The situation to be used (optional). If used, cannot be undef.

=back

=head2 getNodeValue

Returns the value of ATTRIBUTE_NODE,
the content of TEXT_NODE, CDATA_SECTION_NODE and COMMENT_NODE,
the body of PROCESSING_INSTRUCTION_NODE and otherwise returns undef.
Not in DOM spec.

B<Synopsis:>

  $node->getNodeValue([$situa]);

=over 4

=item $situa

The situation to be used (optional).

=back

=head2 setNodeValue

Sets the content of the node for TEXT_NODE, CDATA_SECTION_NODE and
COMMENT_NODE, the value of ATTRIBUTE_NODE, the body of 
PROCESSING_INSTRUCTION_NODE. 
Not in DOM spec.

B<Exceptions:>

=over 4

=item NO_MODIFICATION_ALLOWED_ERR 

for ELEMENT_NODE, DOCUMENT_NODE

=item NAMESPACE_ERR 

for ATTRIBUTE_NODE, if attempt to change value of namespace-attribute,
which prefix is used by owning element or it's attribute 

=back

B<Synopsis:>

  $node->setNodeValue($value [, $situa]);

=over 4

=item $value

The new node value.

=item $situa

The situation to be used (optional).

=back

=head2 nodeValue

Gets or sets the content of the node for ATTRIBUTE_NODE, TEXT_NODE, CDATA_SECTION_NODE,
PROCESSING_INSTRUCTION_NODE and COMMENT_NODE. 

B<Exceptions:>

=over 4

=item see getNodeValue, setNodeValue 

=back

B<Synopsis:>
  $node->nodeValue([$situa]);
  $node->nodeValue($value [, $situa]);

=over 4

=item $value

The new node value.

=item $situa

The situation to be used (optional). If used, cannot be undef.

=back

=head2 getNodeType

Returns the node type. See L<"XML::Sablotron::DOM"> for more details.
Not in DOM spec.

B<Synopsis:>

  $node->getNodeType([$situa]);

=over 4

=item $situa

The situation to be used (optional).

=back

=head2 nodeType

Returns the node type. See L<"XML::Sablotron::DOM"> for more details.

B<Synopsis:>

  $node->nodeType([$situa]);

=over 4

=item $situa

The situation to be used (optional).

=back

=head2 getParentNode

Returns the parent node, if there is any. Otherwise returns
undef. Undefined value is always returned for the DOCUMENT_NODE.
Not in DOM spec.

B<Synopsis:>

  $node->getParentNode([$situa]);

=over 4

=item $situa

The situation to be used (optional).

=back

=head2 parentNode

Returns the parent node, if there is any. Otherwise returns
undef. Undefined value is always returned for the DOCUMENT_NODE.

B<Synopsis:>

  $node->parentNode([$situa]);

=over 4

=item $situa

The situation to be used (optional).

=back

=head2 getChildNodes

Returns the reference to the array of all child nodes of given node.
This array is NOT alive, i.e. the content of once created array does not
reflect the changes of DOM tree. 
Not in DOM spec.

B<Synopsis:>

  $node->getChildNodes([$situa]);

=over 4

=item $situa

The situation to be used (optional).

=back

=head2 childNodesArr

Returns the reference to the array of all child nodes of given node.
This array is NOT alive, i.e. the content of once created array does not
reflect the changes of DOM tree. 
Not in DOM spec.

B<Synopsis:>

  $node->childNodesArr([$situa]);

=over 4

=item $situa

The situation to be used (optional).

=back

=head2 childNodes

Returns the reference to the instance of 
XML::Sablotron::DOM::NodeList.
This array is alive, i.e. the content of once created array does 
reflect the changes of DOM tree. 

B<Synopsis:>

  see XML::Sablotron::DOM::NodeList

=head2 getFirstChild

Get the first child of the node or undef.
Not in DOM spec.

B<Synopsis:>

  $node->getFirstChild([$situa]);

=over 4

=item $situa

The situation to be used (optional).

=back

=head2 firstChild

Get the first child of the node or undef.

B<Synopsis:>

  $node->firstChild([$situa]);

=over 4

=item $situa

The situation to be used (optional).

=back

=head2 getLastChild

Get the last child of the node or undef.
Not in DOM spec.

B<Synopsis:>

  $node->getLastChild([$situa]);

=over 4

=item $situa

The situation to be used (optional).

=back

=head2 lastChild

Get the last child of the node or undef.

B<Synopsis:>

  $node->lastChild([$situa]);

=over 4

=item $situa

The situation to be used (optional).

=back

=head2 getPreviousSibling

Returns the node immediately preceding the node. Returns undef, if
there is no such node.
Not in DOM spec.

B<Synopsis:>

  $node->getPreviousSibling([$situa]);

=over 4

=item $situa

The situation to be used (optional).

=back

=head2 previousSibling

Returns the node immediately preceding the node. Returns undef, if
there is no such node.

B<Synopsis:>

  $node->previousSibling([$situa]);

=over 4

=item $situa

The situation to be used (optional).

=back

=head2 getNextSibling

Returns the node immediately following the node. Returns undef, if
there is no such node.
Not in DOM spec.

B<Synopsis:>

  $node->getNextSibling([$situa]);

=over 4

=item $situa

The situation to be used (optional).

=back

=head2 nextSibling

Returns the node immediately following the node. Returns undef, if
there is no such node.

B<Synopsis:>

  $node->nextSibling([$situa]);

=over 4

=item $situa

The situation to be used (optional).

=back

=head2 attributes

Returns undef. Implemented in XML::Sablotron::DOM::Element.

=head2 getOwnerDocument

Returns the document owning the node. It is always the document, which
created this node. For document itself the return value is undef.
Not in DOM spec.

B<Synopsis:>

  $node->getOwnerDocument([$situa]);

=over 4

=item $situa

The situation to be used (optional).

=back

=head2 ownerDocument

Returns the document owning the node. It is always the document, which
created this node. For document itself the return value is undef.

B<Synopsis:>

  $node->ownerDocument([$situa]);

=over 4

=item $situa

The situation to be used (optional).

=back

=head2 insertBefore

Makes a new node the child of thexpression to be replacede node. It is put right before the
reference node. If the reference node is not defined, the new node is
appended to the child list.

B<Exceptions:>

=over 4

=item HIERARCHY_REQUEST_ERR

Raised if the node doesn't allow children of given type.

=item WRONG_DOCUMENT_ERR

Raised if the new node is not owned by the same document as the node.

=back

B<Synopsis:>

  $node->insertBefore($new_node, $ref_node [, $situa]);

=over 4

=item $new_node

The inserted node.

=item $ref_node

The reference node. The new node is to be inserted right before this
node. May be undef; in this case the new node is appended.

=item $situa

The situation to be used (optional).

=back

=head2 replaceChild

Replace the child node with the new one.
Returns replaced (old) child.

B<Exceptions:>

=over 4

=item HIERARCHY_REQUEST_ERR

Raised if the node doesn't allow children of given type.

=item WRONG_DOCUMENT_ERR

Raised if the new node is not owned by the same document as the node.

=item NOT_FOUND_ERR

Raised if the replaced node is not the child of the node.

=back

B<Synopsis:>

  $node->replaceChild($child, $old_child [, $situa]);

=over 4

=item $child

The new child to be inserted (in the place of the $old_child).
The new child is removed from it's parent at first, if needed. 

=item $old_child

The node to be replaced.

=item $situa

The situation to be used (optional).

=back

=head2 removeChild

Remove the child node from the list of children of the node.

B<Exceptions:>

=over 4

=item NOT_FOUND_ERR

Raised if the removed node is not the child of the node.

=back

B<Synopsis:>

  $node->removeChild($child, [, $situa]);

=over 4

=item $child

The node to be removed.

=item $situa

The situation to be used (optional).

=back

=head2 appendChild

Appends the new node to the list of children of the node.

B<Exceptions:>

=over 4

=item HIERARCHY_REQUEST_ERR

Raised if the node doesn't allow children of given type.

=item WRONG_DOCUMENT_ERR

Raised if the new node is not owned by the same document as the node.

=back

B<Synopsis:>

  $node->appendChild($child, [$situa]);

=over 4

=item $child

The node to be appended.

=item $situa

The situation to be used (optional).

=back

=head2 hasChildNodes

Returns the count of child nodes.

B<Synopsis:>

  $node->hasChildNodes([$situa]);

=over 4

=item $situa

The situation to be used (optional).

=back

=head2 cloneNode

Returns the copy of node.

B<Exceptions:>

=over 4

=item INVALID_NODE_TYPE_ERR

Raised if the node is document.

=back

B<Synopsis:>

  $node->cloneNode($deep [, $situa]);

=over 4

=item $deep

Boolean flag causing deep copying of node.

=item $situa

The situation to be used (optional).

=back

=head2 normalize

Does and returns nothing.

=head2 isSupported

Returns false (exactly 0).

=head2 namespaceURI

Returns uri of the namespace, in which node is.

B<Synopsis:>

  $node->namespaceURI([$situa]);

=over 4

=item $situa

The situation to be used (optional).

=back

=head2 prefix

Gets or sets prefix of the node.

B<Synopsis:>

  $node->prefix([$situa]);
  $node->prefix($prefix [, $situa]);

=over 4

=item $prefix

The new value of node prefix.

=item $situa

The situation to be used (optional). If used, cannot be undef.

=back

=head2 localName

Returns local name of the node.

B<Synopsis:>

  $node->localName([$situa]);

=over 4

=item $situa

The situation to be used (optional).

=back

=head2 hasAttributes

Returns false (exactly 0).


=head2 xql

Executes the XPath expression and returns the ARRAYREF of resulting
nodes.
Not in DOM spec.

B<Synopsis:>

  $node->xql($expr [, $situa]);

=over 4

=item $expr

The expression to be replaced.

=item $situa

The situation to be used (optional).

=back

=head2 xql_ns

Executes the XPath expression and returns the ARRAYREF of resulting
nodes.
Not in DOM spec.

B<Synopsis:>

  $node->xql($expr, $nsmap [, $situa]);

=over 4

=item $expr

The expression to be replaced.

=item $nsmap

Hashref to namespace mappings like { prefix => uri, ...}

=item $situa

The situation to be used (optional).

=back

=head1 XML::Sablotron::DOM::Document

Represents the whole DOM document (the "/" root element).

=head2 new

Create the new empty document.
Not in DOM spec.

B<Synopsis:>

  $doc = XML::Sablotron::DOM::Document->new([AUTODISPOSE => $ad]);

=over 4

=item $ad

Specifies if the document is to be deleted after the last Perl
reference is dropped,

=back

=head2 autodispose

Reads or set the autodispose flag, This flag causes, that the document
is destroyed after the last Perl reference is undefined.
Not in DOM spec.

B<Synopsis:>

  $doc->autodispose([$ad]);

=over 4

=item $ad

Specifies if the document is to be deleted after the last Perl
reference is dropped,

=back

=head2 freeDocument

Disposes all memory allocated by Sablotron for the DOM document. This
is the only way how to do it. See L<"MEMORY ISSUES"> for more details.
Not in DOM spec.

B<Synopsis:>

  $doc->freeDocument([$situa]);

=over 4

=item $situa

The situation to be used (optional).

=back

=head2 toString

Serializes the document tree into the string representation.
Not in DOM spec.

B<Synopsis:>

  $doc->toString([$situa])

=over 4

=item $situa

The situation to be used (optional).

=back

=head2 documentElement

Returns the root element of the document.

B<Synopsis:>

  $doc->documentElement([$situa])

=over 4

=item $situa

The situation to be used (optional).

=back

=head2 createElement

Creates the new ELEMENT_NODE. The parent of the node is not set; the
owner document is set to the document. 

B<Synopsis:>

  $doc->createElement($name [, $situa]);

=over 4

=item $name

The new element name.

=item $situa

The situation to be used (optional).

=back

=head2 createTextNode

Creates the new TEXT_NODE. The parent of the node is not set; the
owner document is set to the document. 

B<Synopsis:>

  $doc->createTextNode($data [, $situa]);

=over 4

=item $data

The initial value of the node.

=item $situa

The situation to be used (optional).

=back

=head2 createComment

Creates the new COMMENT_NODE. The parent of the node is not set; the
owner document is set to the document. 

B<Synopsis:>

  $doc->createComment($data [, $situa]);

=over 4

=item $data

The initial value of the node.

=item $situa

The situation to be used (optional).

=back

=head2 createCDATASection

Creates the new CDATA_SECTION_NODE. The parent of the node is not set; the
owner document is set to the document. 

B<Synopsis:>

  $doc->createCDATASection($data [, $situa]);

=over 4

=item $data

The initial value of the node.

=item $situa

The situation to be used (optional).

=back

=head2 createProcessingInstruction

Creates the new PROCESSING_INSTRUCTION_NODE. The parent of the node is
not set; the owner document is set to the document.

B<Synopsis:>

  $doc->createProcessingInstruction($target, $data [, $situa]);

=over 4

=item $target

The target for the PI.

=item $data

The data for the PI.

=item $situa

The situation to be used (optional).

=back

=head2 createAttribute

Creates the new attribute. The owner document is set to the document.

B<Synopsis:>

  $doc->createAttribute($name [, $situa]);

=over 4

=item $name

The name of the attribute.

=item $situa

The situation to be used (optional).

=back

=head2 cloneNode

Clone the node. The children of the node may be cloned too. The cloned
node may be from another document; cloned nodes are always owned by the
calling document. Parent of the cloned node is not set.
Not in DOM spec.

B<Synopsis:>

  $doc->cloneNode($node, $deep [, $situa]);

=over 4

=item $node

The node to be cloned.

=item $deep

If true, all children of the node are cloned too.

=item $situa

The situation to be used (optional).

=back

=head2 importNode

Clone the node. The children of the node may be cloned too. The cloned
node may be from another document; cloned nodes are always owned by the
calling document. Parent of the cloned node is not set.

B<Synopsis:>

  $doc->importNode($node, $deep [, $situa]);

=over 4

=item $node

The node to be cloned.

=item $deep

If true, all children of the node are cloned too.

=item $situa

The situation to be used (optional).

=back

=head2 createElementNS

Creates the new element. The parent of the node is not set; the
owner document is set to the document. 

B<Exceptions:>

=over 4

=item INVALID_CHARACTER_ERR

Raised if the specified qualified name contains an illegal character.

=item NAMESPACE_ERR

Raised if the qname is malformed,
if the qname has a prefix and the namespaceUri is undefined, 
or if the qname has a prefix that is "xml" and the namespaceUri
is different from "http://www.w3.org/XML/1998/namespace".

=back

B<Synopsis:>

  $doc->createElementNS($namespaceUri, $qname [, $situa]);

=over 4

=item $namespaceUri

The uri of namespace, where the created element exist in.

=item $qname

The qualified name of created element.

=item $situa

The situation to be used (optional).

=back

=head2 createAttributeNS

Creates the new attribute. The owner document is set to the document. 

B<Exceptions:>

=over 4

=item INVALID_CHARACTER_ERR

Raised if the specified qualified name contains an illegal character.

=item NAMESPACE_ERR

Raised if the qname is malformed,
if the qname has a prefix and the namespaceUri is undefined, 
or if the qname has a prefix that is "xml" and the namespaceUri
is different from "http://www.w3.org/XML/1998/namespace", or if 
the qualifiedName is "xmlns" and the namespaceURI is different 
from "http://www.w3.org/2000/xmlns/".

=back

B<Synopsis:>

  $doc->createAttributeNS($namespaceUri, $qname [, $situa]);

=over 4

=item $namespaceUri

The uri of namespace, where the created attribute exist in.

=item $qname

The qualified name of created attribute.

=item $situa

The situation to be used (optional).

=back

=head1 XML::Sablotron::DOM::Element

Represents the element of the tree.

=head2 tagName

Returns the element name.

B<Synopsis:>

  $e->tagName([$situa]);

=over 4

=item $situa

The situation to be used (optional).

=back

=head2 getAttribute

Retrieves an attribute value by name.

B<Synopsis:>

  $value = $e->getAttribute($name [, $situa]);

=over 4

=item $name

The name of queried attribute.

=item $situa

The situation to be used (optional).

=back

=head2 setAttribute

If attribute with specified name already exists, sets its value, 
otherwise inserts new attribute and sets its value.

B<Synopsis:>

  $e->setAttribute($name, $value [, $situa]);

=over 4

=item $name

The name of attribute to be set.

=item $value

The value of the new attribute.

=item $situa

The situation to be used (optional).

=back

=head2 getAttributes

Returns the reference to the hash of all attributes of the element.
This hash is NOT alive, i.e. the content of once created hash does not
reflect the changes of DOM tree. 
Not in DOM spec.

B<Synopsis:>

  $hashref = $e->getAttributes([$situa]);

=over 4

=item $situa

The situation to be used (optional).

=back

=head2 setAttributes

Calls $e->setAttribute for each name/value pair of referenced hash.
Not in DOM spec.

B<Synopsis:>

  $e->setAttributes($hashref [, $situa]);

=over 4

=item $hashref

The HASHREF value. Referenced hash contains name/value pair to be used.

=item $situa

The situation to be used (optional).

=back

=head2 attributes

Named node map of element attributes. This object IS alive.
See XML::Sablotron::DOM::NamedNodeMap.

B<Synopsis:>

  $e->attributes->method_of_NamedNodeMap;

=head2 removeAttribute

Removes an attribute by name.

B<Synopsis:>

  $e->removeAttribute($name [, $situa]);

=over 4

=item $name

The name of attribute to be removed.

=item $situa

The situation to be used (optional).

=back

=head2 getAttributeNode

Retrieves an attribute node by name.

B<Synopsis:>

  $node = $e->getAttributeNode($name [, $situa]);

=over 4

=item $name

The name of queried attribute.

=item $situa

The situation to be used (optional).

=back

=head2 setAttributeNode

Adds a new attribute node. If an attribute with that name 
is already present in the element, it is replaced by the new one.

B<Exceptions:>

=over 4

=item WRONG_DOCUMENT_ERR
  
Raised if the $att is from different document as $e. 

=item INUSE_ATTRIBUTE_ERR

Raised if $att is attribute from another element.

=back

B<Synopsis:>

  $replaced = $e->setAttributeNode($att [, $situa]);

=over 4

=item $att

The new attribute node.

=item $situa

The situation to be used (optional).

=back

=head2 removeAttributeNode

Removes specified attribute and returns it.

B<Exceptions:>

=over 4

=item NO_MODIFICATION_ALLOWED_ERR

Raised if this node is read-only.

=item NOT_FOUND_ERR

Raised if attNode is not an attribute of the element.

=back

B<Synopsis:>

  $removed = $e->removeAttributeNode($attNode [, $situa]);

=over 4

=item $attNode

The attribute node to be removed.

=item $situa

The situation to be used (optional).

=back

=head2 getAttributeNS

Retrieves an attribute value by local name and namespace URI.

B<Synopsis:>

  $value = $e->getAttributeNS($nsURI, $localName [, $situa]);

=over 4

=item $nsURI

The namespace URI of queried attribute.

=item $localName

The local name of queried attribute.

=item $situa

The situation to be used (optional).

=back

=head2 setAttributeNS

If attribute with specified namespace URI and local name already
exists, sets its value and prefix;
otherwise inserts new attribute and sets its value.

B<Synopsis:>

  $removed = $e->setAttributeNS($nsURI, $qName, $value [, $situa]);

=over 4

=item $nsURI

The namespace URI of attribute to be set.

=item $qName

The qualified name of attribute to be set.

=item $value

The value of the new attribute.

=item $situa

The situation to be used (optional).

=back

=head2 removeAttributeNS

Removes an attribute by local name and namespace URI.

B<Exceptions:>

=over 4

=item NO_MODIFICATION_ALLOWED_ERR

Raised if this node is read-only.

=back

B<Synopsis:>

  $e->removeAttributeNS($namespaceURI, $localName [, $situa]);

=over 4

=item $namespaceURI

The URI of attribute to be removed.

=item $localName

The local name of attribute to be removed.

=item $situa

The situation to be used (optional).

=back

=head2 getAttributeNodeNS

Retrieves an attribute by local name and namespace URI.

B<Synopsis:>

  $node = $e->getAttributeNodeNS($nsURI, $localName [, $situa]);

=over 4

=item $nsURI

The namespace URI of queried attribute.

=item $localName

The local name of queried attribute.

=item $situa

The situation to be used (optional).

=back

=head2 setAttributeNodeNS

If attribute with the same namespace URI and local name already
exists, replaces it;
otherwise inserts specified attribute.

B<Synopsis:>

  $replaced = $e->setAttributeNS($att [, $situa]);

=over 4

=item $att

The attribute to be set.

=item $situa

The situation to be used (optional).

=back

=head2 hasAttribute

Returns true if attribute with the specified name already exists,
(exactly returns 1); otherwise returns false (exactly 0).

B<Synopsis:>

  $e->hasAttribute($name [, $situa]);

=over 4

=item $name

The name of queried attribute.

=item $situa

The situation to be used (optional).

=back

=head2 hasAttributeNS

Returns true if attribute with the specified namespace URI and local name
already exists, (exactly returns 1); otherwise returns false (exactly 0).

B<Synopsis:>

  $e->hasAttribute($nsURI, $localName [, $situa]);

=over 4

=item $nsURI

The namespace URI of queried attribute.

=item $localName

The local name of queried attribute.

=item $situa

The situation to be used (optional).

=back

=head2 toString

Serializes the element and its subtree into the string representation.

B<Synopsis:>

  $e->toString([$situa])

=over 4

=item $situa

The situation to be used (optional).

=back

=head1 XML::Sablotron::DOM::Attribute

Represents the attribute.

=head2 name

Returns the attribute name.

B<Synopsis:>

  $a->name([$situa])

=over 4

=item $situa

The situation to be used (optional).

=back

=head2 specified

Returns true (exactly 1).

B<Synopsis:>

  $a->specified([$situa])

=over 4

=item $situa

The situation to be used (optional).

=back

=head2 value

Gets or sets value of the attribute.
See XML::Sablotron::DOM::Node::nodeValue.

B<Synopsis:>

  $a->value([$situa])
  $a->value($value [, $situa])

=over 4

=item $value

The value to be set.

=item $situa

The situation to be used (optional).

=back

=head2 ownerElement

Returns element owning the attribute, if any.

B<Synopsis:>

  $e = $a->ownerElement([$situa])

=over 4

=item $situa

The situation to be used (optional).

=back

=head1 XML::Sablotron::DOM::CharacterData

Represents class, which serves as parent for another DOM objects.

=head2 data

Gets or sets character data of the node.
See XML::Sablotron::DOM::nodeValue

B<Synopsis:>

  $node->data([$situa])
  $node->data($data [, $situa])

=over 4

=item $data

The character data to be set.

=item $situa

The situation to be used (optional).

=back

=head2 length

Returns length of character data of the node.

B<Synopsis:>

  $node->length([$situa])

=over 4

=item $situa

The situation to be used (optional).

=back

=head2 substringData

Returns substring of character data of the node.

B<Exceptions:>

=over 4

=item INDEX_SIZE_ERR

Raised if $offset < 0 or $count < 0 or $offset > length of data.

=back

B<Synopsis:>

  $node->substringData($offset, $count [, $situa])

=over 4

=item $offset

Specifies, where (in the character data) the returned substring starts.

=item $count

Specifies the maximal count of returned characters.

=item $situa

The situation to be used (optional).

=back

=head2 appendData

Appends specified substring to character data of the node.

B<Synopsis:>

  $node->appendData($data [, $situa])

=over 4

=item $data

Characters to be appended.

=item $situa

The situation to be used (optional).

=back

=head2 insertData

Inserts specified substring to character data of the node.

B<Exceptions:>

=over 4

=item INDEX_SIZE_ERR

Raised if $offset < 0 or $offset > length of character data.

=back

B<Synopsis:>

  $node->insertData($offset, $data [, $situa])

=over 4

=item $offset

Starting point in character data of newly inserted substring.

=item $data

Characters to be inserted.

=item $situa

The situation to be used (optional).

=back

=head2 deleteData

Cuts specified substring from character data of the node.

B<Exceptions:>

=over 4

=item INDEX_SIZE_ERR

Raised if $offset < 0 or $count < 0 or $offset > length of data.

=back

B<Synopsis:>

  $node->deleteData($offset, $count [, $situa])

=over 4

=item $offset

Specifies, where (in the character data) the cut substring starts.

=item $count

Specifies the maximal count of cut characters.

=item $situa

The situation to be used (optional).

=back

=head2 replaceData

Replaces specified substring from character data of the node.

B<Exceptions:>

=over 4

=item INDEX_SIZE_ERR

Raised if $offset < 0 or $count < 0 or $offset > length of data.

=back

B<Synopsis:>

  $node->replaceData($offset, $count, $data [, $situa])

=over 4

=item $offset

Specifies, where (in the character data) the replaced substring starts.

=item $count

Specifies the maximal count of replaced characters.

=item $data

Character data replacing specified substring.

=item $situa

The situation to be used (optional).

=back

=head1 XML::Sablotron::DOM::Text

Represents a text node of DOM tree.

=head2 splitText

If length of data is greather than specified offset, inserts new text node 
behind original node and splits original node data to two chunks, the first 
chunk with offset length set to original node, the second chunk set to newly 
created node.

B<Exceptions:>

=over 4

=item INDEX_SIZE_ERR

Raised if $offset < 0 or $offset > length of data.

=back

B<Synopsis:>

  $node->splitText($offset [, $situa])

=over 4

=item $offset

Specifies length of character data of original node.

=item $situa

The situation to be used (optional).

=back

=head1 XML::Sablotron::DOM::ProcessingInstruction

Represents a processing instruction of DOM tree.

=head2 target

Gets the first token of node value.

B<Synopsis:>

  $pi->target([$situa])

=over 4

=item $situa

The situation to be used (optional).

=back

=head2 data

Gets or sets the content of the processing instruction (text starting with the first non-whitespace character after target).

B<Synopsis:>

  $pi->data([$situa])
  $pi->data($content [, $situa])

=over 4

=item $content

Specifies the new content of the processing instruction.

=item $situa

The situation to be used (optional).

=back

=head1 XML::Sablotron::DOM::NodeList

Represents a list of some items.

=head2 item

Returns the item on specified position in the list.

B<Synopsis:>

  $list->item($index)

=over 4

=item $index

The position of item.

=back

=head2 length

Returns count of the list items.

B<Synopsis:>

  $list->length()

=head1 XML::Sablotron::DOM::NamedNodeMap

Represents a collection of nodes that can be accessed by name.

=head2 getNamedItem

Returns the node specified by name.

B<Synopsis:>

  $node = $nnm->getNamedItem($name)

=over 4

=item $name

The name of queried node.

=back

=head2 setNamedItem

Inserts or replaces node to map by its name.

B<Synopsis:>

  $replaced = $nnm->setNamedItem($node)

=over 4

=item $node

The node to be inserted.

=head2 removeNamedItem

Removes node from map by its name.

B<Exceptions:>

=over 4

=item NOT_FOUND_ERR

Raised if there is not node with specified name.

=back

B<Synopsis:>

  $removed = $nnm->removeNamedItem($name)

=over 4

=item $name

The name of node to be removed.

=back

=head2 getNamedItemNS

Returns the node specified by local name and namespace URI.

B<Synopsis:>

  $node = $nnm->getNamedItemNS($nsURI, $localName)

=over 4

=item $nsURI

The namespace URI of queried node.

=item $localName

The local name of queried node.

=back

=head2 setNamedItemNS

Inserts or replaces node to map by its local name and namespace URI.

B<Synopsis:>

  $replaced = $nnm->setNamedItemNS($node)

=over 4

=item $node

The node to be inserted.

=head2 removeNamedItemNS

Removes node from map by its local name and namespace URI.

B<Exceptions:>

=over 4

=item NOT_FOUND_ERR

Raised if there is not node with specified name.

=back

B<Synopsis:>

  $removed = $nnm->removeNamedItemNS($nsURI, $localName)

=over 4

=item $nsURI

The namespace URI of removed node.

=item $localName

The local name of removed node.

=back

=head1 AUTHOR

Pavel Hlavnicka, pavel@gingerall.cz; Ginger Alliance LLC;
Jan Poslusny, pajout@gingerall.cz; Ginger Alliance LLC;

=head1 SEE ALSO

perl(1).

=cut


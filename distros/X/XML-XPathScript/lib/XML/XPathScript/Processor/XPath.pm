use strict;
use warnings;

package XML::XPathScript::Processor::XPath;

use base qw/ XML::XPathScript::Processor /;

our $VERSION = '1.54';

sub get_namespace { 
        my $prefix = $_[1]->getPrefix or return;
        return $_[1]->getNamespace( $prefix )->getExpanded();
}

sub get_attributes   { $_[1]->getAttributeNodes }
sub get_text_content { $_[1]->getData }
sub get_child_nodes  { $_[1]->getChildNodes }
sub get_node_name    { $_[1]->getName && $_[1]->getLocalName }
sub is_element_node  { $_[1]->isa( 'XML::XPath::Node::Element' ); }
sub is_text_node     { $_[1]->isa( 'XML::XPath::Node::Text' ); }
sub is_comment_node  { $_[1]->isa( 'XML::XPath::Node::Comment' ); }
sub is_pi_node       { $_[1]->isa( "XML::XPath::Node::PI" ); }
sub is_nodelist      { $_[1]->isa( 'XML::XPath::NodeSet' ); }
sub get_attribute    { $_[1]->toString }

1;

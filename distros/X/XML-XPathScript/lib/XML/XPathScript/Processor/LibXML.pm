package XML::XPathScript::Processor::LibXML;

use strict;
use warnings;

use base qw/ XML::XPathScript::Processor /;

our $VERSION = '1.54';

sub get_namespace {
        my $ns = $_[1]->getNamespaces();
        return $ns ? $ns->getData() : () ;
}

sub is_text_node {
    # little catch: XML::LibXML::Comment is a
    # XML::LibXML::Text
    return     $_[1]->isa('XML::LibXML::Text')
           && !$_[1]->isa('XML::LibXML::Comment');
}

sub get_attributes   { return $_[1]->attributes }
sub get_text_content { return $_[1]->textContent }
sub get_child_nodes  { return $_[1]->childNodes }
sub get_node_name    { return $_[1]->localname }
sub is_element_node  { return $_[1]->isa( 'XML::LibXML::Element' ); }
sub is_comment_node  { return $_[1]->isa( 'XML::LibXML::Comment' ); }
sub is_pi_node       { return $_[1]->isa( 'XML::LibXML::PI' ); }
sub is_nodelist      { return $_[1]->isa( 'XML::LibXML::NodeList' ); }

sub get_attribute {
    return $_[1]->isa( 'XML::LibXML::Namespace' )
         ?  ' xmlns:' . $_[1]->getName() . q{="} . $_[1]->value() . q{" }
         : $_[1]->toString( 0, 1 )
         ;
}

sub translate_node {
    my ( $self, $node, $params ) = @_;
    $node = $node->documentElement if $node->isa( 'XML::LibXML::Document' );
    return $self->SUPER::translate_node( $node, $params );
}

1;

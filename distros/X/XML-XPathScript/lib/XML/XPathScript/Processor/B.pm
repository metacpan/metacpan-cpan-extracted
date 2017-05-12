use strict;
use warnings;

package XML::XPathScript::Processor::B;

use base qw/ XML::XPathScript::Processor /;

our $VERSION = '1.54';

# No namespaces here
sub get_namespace { }

sub get_child_nodes { $_[1]->get_children }

sub findnodes { 
    my ( $self, $xpath, $context ) = @_;
    $context ||= $self->{dom};

    return $context->match( $xpath );
}

sub to_string {
    my ( $self, $node ) = @_;

    my $string = $self->start_tag( $node );
    $string .= $self->to_string( $_ ) for $node->get_children;
    $string .= $self->end_tag( $node );
   
    return $string;
}

sub get_node_name { $_[1]->get_name }

sub get_attributes {
    if ( $_[1]->can( 'get_attr_names' ) ) {
        return map { ( [ $_ => $_[1]->get_attr_value( $_ ) ] )
                       x !! defined $_[1]->get_attr_value( $_ )  } 
                   $_[1]->get_attr_names ;
    }

    return;
}

sub get_attribute { " $_[1][0]='$_[1][1]' " }

# it's all element nodes
sub is_element_node  { 1 }
sub is_nodelist      { 0 }
sub is_text_node     { 0 }
sub is_comment_node  { 0 }
sub is_pi_node       { 0 }

1;


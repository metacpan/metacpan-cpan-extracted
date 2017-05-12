# $Id: DOMHandler.pm,v 1.1 2002/08/20 18:06:48 eray Exp eray $

package XML::DOMHandler;
use strict;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);
require Exporter;
@ISA = qw( Exporter );
@EXPORT = qw( Version );
$VERSION = '1.0';
sub Version { $VERSION; }

#
# table of node types and internal handler methods
#
my %dispatch_table = (
		      &XML_ELEMENT_NODE        => '_handle_element',
		      &XML_ATTRIBUTE_NODE      => '_handle_attribute',
		      &XML_TEXT_NODE           => '_handle_text',
		      &XML_CDATA_SECTION_NODE  => '_handle_cdata',
		      &XML_ENTITY_REF_NODE     => '_handle_entity_ref',
		      &XML_ENTITY_NODE         => '',
		      &XML_PI_NODE             => '_handle_pi',
		      &XML_COMMENT_NODE        => '_handle_comment',
		      &XML_DOCUMENT_NODE       => '_handle_doc_node',
		      &XML_DOCUMENT_TYPE_NODE  => '_handle_doctype',
		      &XML_DOCUMENT_FRAG_NODE  => '',
		      &XML_NOTATION_NODE       => '',
		      &XML_HTML_DOCUMENT_NODE  => '',
		      &XML_DTD_NODE            => '',
		      &XML_ELEMENT_DECL_NODE   => '',
		      &XML_ATTRIBUTE_DECL_NODE => '',
		      &XML_ENTITY_DECL_NODE    => '',
		      &XML_NAMESPACE_DECL_NODE => '_handle_ns_decl',
		      &XML_XINCLUDE_START      => '',
		      &XML_XINCLUDE_END        => '',
		      );

my $level;          # depth in the tree
my $position;       # position in parent's content list
my @pstack;         # position stack
my $root;
my $rootset = 0;


sub new {
#
# initialize object with options
#
    my $class = shift;
    my $self = {@_};
    reset();
    return bless( $self, $class );
}


sub reset {
#
# set globals back to zero
#
    $level = 0;
    $position = 0;
    @pstack = (0);
}


sub traverse {
#
# dispatch node to handler, recurse
#
    my( $self, $node ) = @_;

    my $handled_flag = 0;
    my $fun = $dispatch_table{ $node->nodeType };

    $root = $node unless( $rootset );
    $rootset = 1;

    if( $fun ) {
	$handled_flag = $self->$fun( $node );
	return 1;

	# apply generic Node handler
	$handled_flag = 
	    $self->_apply_user_handler( $node, 'generic_node' )
		|| $handled_flag;
    
	# apply generic "else" node handler if no handlers applied
	$handled_flag ||=
	    $self->_apply_user_handler( $node, 'else_generic_node' );
    }

    return $handled_flag;
}


sub _handle_element {
#
# process an element, recurse if necessary
#
    my( $self, $node ) = @_;
    my $handled_flag = 0;

    # apply specific element handler
    my $name = $node->nodeName;
    $handled_flag = $self->_apply_user_handler( $node, $name );

    # apply generic element handler
    $handled_flag = $self->_apply_user_handler( $node, 'generic_element' )
	|| $handled_flag;
    
    # apply generic "else" handler if no element handlers applied
    $handled_flag ||= 
	$self->_apply_user_handler( $node, 'generic_element_else' );

    return $self->_handle_descendants( $node ) || $handled_flag;
}


#
# default handlers for node types
#
sub _handle_attribute {
    my( $self, $node ) = @_;
    return $self->_apply_user_handler( $node, 'generic_attribute' );
}

sub _handle_text {
    my( $self, $node ) = @_;
    return $self->_apply_user_handler( $node, 'generic_text' );
}

sub _handle_cdata {
    my( $self, $node ) = @_;
    return $self->_apply_user_handler( $node, 'generic_CDATA' );
}

sub _handle_entity_ref {
    my( $self, $node ) = @_;
    return $self->_apply_user_handler( $node, 'generic_entity_ref' );
}

sub _handle_pi {
    my( $self, $node ) = @_;
    return $self->_apply_user_handler( $node, 'generic_PI' );
}

sub _handle_comment {
    my( $self, $node ) = @_;
    return $self->_apply_user_handler( $node, 'generic_comment' );
}

sub _handle_doc_type {
    my( $self, $node ) = @_;
    return $self->_apply_user_handler( $node, 'generic_doctype' );
}


sub _handle_doc_node {
#
# process the document node, recurse if necessary
#
    my( $self, $node ) = @_;
    $self->_apply_user_handler( $node, 'generic_document' );
    $level++;
    $pstack[1] = 1;
    $position = 1;
    my $handled_flag = $self->traverse( $node->getDocumentElement );
    $level--;
    return $handled_flag;
}


sub _handle_descendants {
#
# recurse through descendants
#
# NOTES: 
# 1. Removing a node that follows the current node is dangerous!
# 2. Nodes inserted before or after the current node won't be processed.
#
    my( $self, $node ) = @_;
    my $handled_flag = 0;
    $level++;
    $pstack[ $level ] = 0;
    foreach my $child ( $node->getChildnodes ) {
	$pstack[ $level ] ++;
	$position = $pstack[ $level ];
	$handled_flag += $self->traverse( $child );
    }
    $level--;
    return $handled_flag;
}


sub _apply_user_handler {
#
# send reference to self and node to a handler method
#
    my( $self, $node, $handler ) = @_;
    my $handled_flag = 0;

    if( exists( $self->{ handler_package }) and
      UNIVERSAL::can( $self->{ handler_package }, $handler )) {
	$self->{ handler_package }->$handler( $self, $node );
	$handled_flag = 1;
    }

    return $handled_flag;
}


#
# Entity node types
#
sub XML_ELEMENT_NODE()            {1;}
sub XML_ATTRIBUTE_NODE()          {2;}
sub XML_TEXT_NODE()               {3;}
sub XML_CDATA_SECTION_NODE()      {4;}
sub XML_ENTITY_REF_NODE()         {5;}
sub XML_ENTITY_NODE()             {6;}
sub XML_PI_NODE()                 {7;}
sub XML_COMMENT_NODE()            {8;}
sub XML_DOCUMENT_NODE()           {9;}
sub XML_DOCUMENT_TYPE_NODE()     {10;}
sub XML_DOCUMENT_FRAG_NODE()     {11;}
sub XML_NOTATION_NODE()          {12;}
sub XML_HTML_DOCUMENT_NODE()     {13;}
sub XML_DTD_NODE()               {14;}
sub XML_ELEMENT_DECL_NODE()      {15;}
sub XML_ATTRIBUTE_DECL_NODE()    {16;}
sub XML_ENTITY_DECL_NODE()       {17;}
sub XML_NAMESPACE_DECL_NODE()    {18;}
sub XML_XINCLUDE_START()         {19;}
sub XML_XINCLUDE_END()           {20;}


1;
__END__
########################################################################
=pod

=head1 NAME

DOMHandler - Implements a call-back interface to DOM.

=head1 SYNOPSIS

  use DOMHandler;
  use XML::LibXML;
  $p = new XML::LibXML;
  $doc = $p->parse_file( 'data.xml' );
  $dh = new DOMHandler( handler_package => new testhandler );
  $dh->traverse( $doc );

  package testhandler;
  sub new {
      return bless {};
  }
  sub A {
      my( $self, $agent, $node ) = @_;
      my $par = $node->parentNode->nodeName;
      print "I'm in an A element and my parent is $par.\n";
  }
  sub generic_element {
      my( $self, $agent, $node ) = @_;
      my $name = $node->nodeName;
      print "I'm in an element named '$name'.\n";
  }
  sub generic_text {
      print "Here's some text.\n";
  }
  sub generic_PI {
      print "Here's a processing instruction.\n";
  }
  sub generic_CDATA {
      print "Here's a CDATA Section.\n";
  }

=head1 DESCRIPTION

This module creates a layer on top of DOM that allows you to program
in a "push" style rather than "pull". Once the document has been
parsed and you have a DOM object, you can call on the DOMHandler's
traverse() method to apply a set of call-back routines to all the
nodes in a tree. You supply the routines in a handler package when
initializing the DOMHandler.

In your handler package, the names of routines determine which will be
called for a given node. There are routines for node types, named
"generic_" plus the node type. For elements, you can name routines
after the element name and these will only be called for that type of
element. A list of supported handlers follows:

=over 4

=item else_generic_node()

Applied only to nodes that have not been handled by another routine.

=item generic_CDATA()

Applied to CDATA sections.

=item generic_comment()

Applied to XML comments.

=item generic_doctype()

Applied to DOCTYPE declarations.

=item generic_element()

Applied to all elements.

=item generic_node()

Applied to all nodes.

=item generic_PI()

Processing instruction

=item generic_text()

Applied to text nodes.

=back 4

A handler routine takes three arguments: the $self reference, a
reference to the DOMHandler object, and a reference to a node in the
document being traversed. You can use DOM routines on that node to do
any processing you want. At the moment, this module only supports
XML::LibXML documents.

IMPORTANT NOTE: Some DOM operations may cause unwanted results. For
example, if you delete the current node's parent, the program will
likely crash.

=head1 METHODS

=head2 traverse( $doc )

Visits each node in a document, in order, applying the appropriate
handler routines. 

=head1 AUTHOR

Erik Ray (eray@oreilly.com), Production Tools Dept.,
O'Reilly and Associates Inc.

=head1 COPYRIGHT

Copyright (c) 2002 Erik Ray and O'Reilly & Associates.

=cut

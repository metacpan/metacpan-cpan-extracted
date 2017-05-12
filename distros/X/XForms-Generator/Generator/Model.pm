package XML::XForms::Generator::Model;
######################################################################
##                                                                  ##
##  Package:  Model.pm                                              ##
##  Author:   D. Hageman <dhageman@dracken.com>                     ##
##                                                                  ##
##  Description:                                                    ##
##                                                                  ##
##  Perl object to assist in the generation of XML compliant with   ##
##  the W3's XForms specification.                                  ##
##                                                                  ##
######################################################################

##==================================================================##
##  Libraries and Variables                                         ##
##==================================================================##

require 5.006;
require Exporter;

use strict;
use warnings;

use Carp;
use XML::LibXML;
use XML::XForms::Generator::Common;

our @ISA = qw( Exporter XML::LibXML::Element );

our @EXPORT = qw( xforms_model );

our $VERSION = "0.70";

##==================================================================##
##  Constructor(s)/Deconstructor(s)                                 ##
##==================================================================##

##----------------------------------------------##
##  new                                         ##
##----------------------------------------------##
##  XForms::Model default contstructor.         ##
##----------------------------------------------##
sub new
{
	## Pull in what type of an object we will be.
	my $type = shift;
	## Pull in any arguments provided to the constructor.
	my $attributes = shift;
	my @children = @_;
	## The object we are generating is going to be a child class of
	## XML::LibXML's DOM objects.
	my $self = XML::LibXML::Element->new( 'model' );
	## Determine what exact class we will be blessing this instance into.
	my $class = ref( $type ) || $type;
	## Bless the class for it is good [tm].
	bless( $self, $class );
	## We need to set our namespace on our model element and activate it.
	$self->setNamespace( $XFORMS_NAMESPACE{xforms}, "xforms", 1 );
	## Determine if we have an 'id' attribute and set it if we do.
	__xforms_attribute( $self, $attributes );
	__xforms_children( $self, @children );
	## Send it back to the caller all happy like.
	return( $self );
}

##----------------------------------------------##
##  DESTROY                                     ##
##----------------------------------------------##
##  XForms::Model default deconstructor.        ##
##----------------------------------------------##
sub DESTROY
{
	## This is mainly a placeholder to keep things like mod_perl happy.
	return;
}

##==================================================================##
##  Method(s)                                                       ##
##==================================================================##

## Loop through all of the extension elements building convience methods
## as we go along.
no strict 'refs';

foreach my $element ( @XFORMS_MODEL_ELEMENT )
{
	## We need to temporarily remove the namespace prefix for our work.
	$element =~ s/^xforms://g;

##----------------------------------------------##
##  appendCHILDENAME                            ##
##----------------------------------------------##
##  Method generation for the common child      ##
##  elements of the model element.              ##
##----------------------------------------------##
	*{ "append" . ucfirst( $element ) } = 
	sub {

		my( $self, $attributes, @children ) = @_;

		my $node = XML::LibXML::Element->new( $element );

		$self->appendChild( $node );

		$node->setNamespace( $XFORMS_NAMESPACE{xforms}, "xforms", 1 );

		__xforms_attribute( $node, $attributes );
		__xforms_children( $node, @children );

		return( $node );
	};

##----------------------------------------------##
##  getCHILDENAME                               ##
##----------------------------------------------##
##  Method generation for the retrieval of      ##
##  common model elements.                      ##
##----------------------------------------------##
	*{ "get" . ucfirst( $element ) } = 
	sub {

		my $self = shift;
	
		my @nodes = 
			$self->getChildrenByTagName( "xforms:$element" );
		
		return( @nodes );
	};
}

use strict 'refs';

##----------------------------------------------##
##  bindControl                                 ##
##----------------------------------------------##
##  Method used to associate a control with a   ##
##  model's instance data.                      ##
##----------------------------------------------##
sub bindControl ($$$$)
{
	my( $self, $control, $bind, $value ) = @_;

	my( $instance ) = $self->getInstance();

	if( !defined( $instance ) )
	{
		croak( qq|Error: Model element requires an instance child |,
			   qq|element before controls can be bound to it.| );
	}

	## We really want the child element of the instance node.
	$instance = $instance->firstChild;

	if( ( defined( $bind ) ) && 
		( ref( $bind ) ) && 
		( $bind->isa( "XML::LibXML::Node" ) ) )
	{
		## The first case exists when we are giving a prebuilt
		## binding node.
		my @attributes = $bind->attributes;
		my @children = $bind->childNodes;

		my $attributes = {};

		foreach( @attributes )
		{
			$attributes->{$_->nodeName} = $_->getValue();
		}
		
		## We need to ensure we grab a copy of the nodeset and id attributes
		## here because appendBind is destructive.
		$bind = $attributes->{nodeset};
		my $id = $attributes->{id};
		
		## We don't attach the node that was passed in, but rather
		## we create another using it.  This allows us to do some
		## error/consistancy checking.
		$self->appendBind( $attributes, @children );
		
		## The second case is when we are just given a XPath to
		## to the instance data.
		$bind =~ s/^\/+//g;
		$bind =~ s/\/+/\//g;
		
		## We need to set the 'bind' attribute on the node.
		$control->setAttribute( 'bind', $id);
		$control->removeAttribute( 'ref' );
		
	}
	elsif( defined( $bind ) )
	{
		## The second case is when we are just given a XPath to
		## to the instance data.
		$bind =~ s/^\/+//g;
		$bind =~ s/\/+/\//g;

		## We need to set the 'ref' attribute on the node.
		$control->setAttribute( 'ref', $bind );
		$control->removeAttribute( 'bind' );
	}
	else
	{
		## The last case is the hope that the control element
		## already contains an 'ref' element.
		$bind = $control->getAttribute( "ref" );

		if( !defined( $bind ) )
		{
			croak( qq|Error: A binding expression must already exist on |,
				   qq|the control element or one must be supplied | );
		}

		## Clean the binding expression ...
		$bind =~ s/^\/+//g;
		$bind =~ s/\/+/\//g;
		
		## We will reset it to ensure that the clean version is used.
		$control->setAttribute( 'ref', $bind );
		$control->removeAttribute( 'bind' );
	}			

	## Break up the XPath statement into chunks.
	my @path = split( /\//, $bind );

	## Loop through each of the @path statements to ensure and build
	## the XPath to the instance data.
	for( my $search = 0; $search < scalar( @path ); $search++ )
	{
		my( $node ) = $instance->getChildrenByTagName( $path[ $search ] );

		## Check to see if the node is already defined.
		if( !defined( $node ) )
		{
			my $element = XML::LibXML::Element->new( $path[ $search ] );
			$instance = $instance->appendChild( $element );
		}
		else
		{
			$instance = $node;
		}
	}
	
	## Look to see if any nodes exist under the current node.
	if( $instance->hasChildNodes() )
	{
		$instance->removeChildNodes();
	}

	## Check to see if the value is text or a node.
	if( ( ref( $value ) ) && ( $value->isa( "XML::LibXML::Node" ) ) )
	{
		$instance->appendChild( $value );
	}
	else
	{
		my $text = XML::LibXML::Text->new( $value );
		$instance->appendChild( $text );
		## The below causes a segfault.  Need to figure that one out.
		##$instance->appendText( $value );
	}
	
	## I want to make sure that we properly associate this control
	## with the proper model.
	$control->setAttribute( 'model', $self->getAttribute( "id" ) );

	return( $instance );
}

##----------------------------------------------##
##  setInstanceData                             ##
##----------------------------------------------##
##  Convience method for setting instance data  ##
##  in the model element.                       ##
##----------------------------------------------##
sub setInstanceData ($$$)
{
	my( $self, $bind, $value ) = @_;

	## We make sure that $value is defined purely for the removal of
	## perl warning messages.
	if( !defined( $value ) )
	{
		$value = "";
	}	

	my( $instance ) = $self->getInstance();

	if( !defined( $instance ) )
	{
		croak( qq|Error: Model element requires an instance child |,
			   qq|element before controls can be bound to it.| );
	}

	## We really want the child element of the instance node.
	$instance = $instance->firstChild;

	## Clean up our binding expression a bit ...
	$bind =~ s/^\/+//g;
	$bind =~ s/\/+/\//g;

	## Break up the XPath statement into chunks.
	my @path = split( /\//, $bind );

	## Loop through each of the @path statements to ensure and build
	## the XPath to the instance data.
	for( my $search = 0; $search < scalar( @path ); $search++ )
	{
		my( $node ) = $instance->getChildrenByTagName( $path[ $search ] );

		## Check to see if the node is already defined.
		if( !defined( $node ) )
		{
			my $element = XML::LibXML::Element->new( $path[ $search ] );
			$instance = $instance->appendChild( $element );
		}
		else
		{
			$instance = $node;
		}
	}
	
	## Look to see if any nodes exist under the current node.
	if( $instance->hasChildNodes() )
	{
		$instance->removeChildNodes();
	}

	## Check to see if the value is text or a node.
	if( ( ref( $value ) ) && 
		( ref( $value ) ne "ARRAY" ) &&
		( ref( $value ) ne "HASH" ) &&
		( ref( $value ) ne "SCALAR" ) &&
		( ref( $value ) ne "CODE" ) &&
		( ref( $value ) ne "REF" ) &&
		( ref( $value ) ne "LVALUE" ) &&
		( ref( $value ) ne "GLOB" ) &&
		( $value->isa( "XML::LibXML::Node" ) ) )
	{
		$instance->appendChild( $value );
	}
	else
	{
		my $text = XML::LibXML::Text->new( $value );
		$instance->appendChild( $text );
		## The below causes a segfault.  Need to figure that one out.
		##$instance->appendText( $value );
	}

	return( $instance );
}

##==================================================================##
##  Function(s)                                                     ##
##==================================================================##

##----------------------------------------------##
##  xforms_model                                ##
##----------------------------------------------##
##  Alias for the default constructor.          ##
##----------------------------------------------##
sub xforms_model
{
	return( XML::XForms::Generator::Model->new( @_ ) );
}

##==================================================================##
##  Internal Function(s)                                            ##
##==================================================================##

##
## None.
##

##==================================================================##
##  End of Code                                                     ##
##==================================================================##
1;

##==================================================================##
##  Plain Old Documentation (POD)                                   ##
##==================================================================##

__END__

=head1 NAME

XML::XForms::Generator::Model

=head1 SYNOPSIS

 use XML::XForms::Generator;

 my $model = xforms_model( { id => 'MyFirstXForms' } );

=head1 DESCRIPTION

The XML::XForms::Generator::Model package is an implementation of the 
XForms model element.  This package has a single convience function 
(xforms_model) that takes a parameter 'id' to uniquely identify that model 
element in the document.  The result of calling this function is a
object that has all the methods available to a XML::LibXML::Element object
plus the methods listed below:

=head1 METHODS

=over 4 

=item appendBind ( { ATTRIBUTES }, @DATA )

Sets the binding information of a model.
This method takes a hash refernce of name => value pairs for the attributes
of the model's child.  The attributes are attached on the basis of their
legitamacy when compared to the XForms schema.  If it isn't a recognized
attribute then it won't get attached.  This method also takes an array
of XML::LibXML capable nodes and/or text data.

=item appendInstance ( { ATTRIBUTES }, @DATA )

Sets the instance data append of a model.
This method takes a hash refernce of name => value pairs for the attributes
of the model's child.  The attributes are attached on the basis of their
legitamacy when compared to the XForms schema.  If it isn't a recognized
attribute then it won't get attached.  This method also takes an array
of XML::LibXML capable nodes and/or text data.

=item appendExtension ( { ATTRIBUTES }, @DATA )

Sets the extensions of a model.
This method takes a hash refernce of name => value pairs for the attributes
of the model's child.  The attributes are attached on the basis of their
legitamacy when compared to the XForms schema.  If it isn't a recognized
attribute then it won't get attached.  This method also takes an array
of XML::LibXML capable nodes and/or text data.

=item appendSubmission ( { ATTRIBUTES }, @DATA )

Sets the submission data of a model.
This method takes a hash refernce of name => value pairs for the attributes
of the model's child.  The attributes are attached on the basis of their
legitamacy when compared to the XForms schema.  If it isn't a recognized
attribute then it won't get attached.  This method also takes an array
of XML::LibXML capable nodes and/or text data.

=item bindControl ( CONTROL, BIND, VALUE )

Method that allows you to bind a control to a model's instance data.  
This method is not necessarily needed if you use the setInstanceData
method.

=item getBind ()

Returns the binding children of a model.

=item getInstance ()

Returns the instance data section associated with a model.

=item getExtension ()

Returns any extension children of a model.

=item getSubmission ()

Returns the submitInfo data.

=item setInstanceData ( REF, DATA )

Method to set the instance data.

=back

=head1 AUTHOR

D. Hageman E<lt>dhageman@dracken.comE<gt>

=head1 SEE ALSO

 XML::XForms::Generator
 XML::XForms::Generator::Action
 XML::XForms::Generator::Control
 XML::XForms::Generator::UserInterface
 XML::LibXML
 XML::LibXML::DOM

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2002-2004 D. Hageman (Dracken Technologies).

All rights reserved.

This program is free software; you can redistribute it and/or modify 
it under the same terms as Perl itself. 

=cut

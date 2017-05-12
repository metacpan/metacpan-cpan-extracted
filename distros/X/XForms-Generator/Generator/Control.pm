package XML::XForms::Generator::Control;
######################################################################
##                                                                  ##
##  Package:  Control.pm                                            ##
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

our @EXPORT = qw();

our $VERSION = "0.70";

no strict 'refs';

foreach my $control ( @XFORMS_CONTROL )
{
	## We need to temporarily remove the namespace prefix.
	$control =~ s/^xforms://g;

	## I really hate the fact that I have to use the push function
	## instead of the Exporter.  Oh well.
	#Exporter::export_tags( "xforms_$control" );
	push( @EXPORT, "xforms_$control" );
	
	*{ "xforms_$control" } = sub {

		my( $attributes, @children ) = @_;

		my $node = XML::XForms::Generator::Control->new( $control );

		__xforms_attribute( $node, $attributes );
		__xforms_children( $node, @children );

		return( $node );
	};
}

use strict 'refs';

##==================================================================##
##  Constructor(s)/Deconstructor(s)                                 ##
##==================================================================##

##----------------------------------------------##
##  new                                         ##
##----------------------------------------------##
##  XForms::Control default contstructor.       ##
##----------------------------------------------##
sub new
{
	## Pull in what type of an object we will be.
	my $type = shift;
	## Grab the name of the control.
	my $control = shift;
	## The object we are generating is going to be a child class of
	## XML::LibXML's DOM objects.
	my $self = XML::LibXML::Element->new( $control );
	## Determine what exact class we will be blessing this instance into.
	my $class = ref( $type ) || $type;
	## Bless the class for it is good [tm].
	bless( $self, $class );
    ## We need to set our namespace on our model element and activate it.
    $self->setNamespace( $XFORMS_NAMESPACE{xforms}, "xforms", 1 );
	## Send it back to the caller all happy like.
	return( $self );
}

##----------------------------------------------##
##  DESTROY                                     ##
##----------------------------------------------##
##  XForms::Control default deconstructor.      ##
##----------------------------------------------##
sub DESTROY
{
	## This is mainly a placeholder to keep things like mod_perl happy.
	return;
}

##==================================================================##
##  Method(s)                                                       ##
##==================================================================##

no strict 'refs';

foreach my $element ( @XFORMS_CONTROL_ELEMENT )
{
	## We need to temporarily remove the namespace prefix for our work.
	$element =~ s/^xforms://g;

##----------------------------------------------##
##  appendCHILDENAME                            ##
##----------------------------------------------##
##  Method generation for the common child      ##
##  elements of controls.                       ##
##----------------------------------------------##
	*{ "append" . ucfirst( $element ) } = sub {

		my( $self, $attributes, @children ) = @_;

		## We need to determine what type of control we are working with.
		my $type = $self->nodeName;

		## We set a status bit to false indicating that at the momment we
		## don't know if this particular control has the potential of
		## having the child element in question attached to it.
		my $status = 0;

		## Loop through all the potential child elements looking for it.
		foreach( @{ $XFORMS_SCHEMA{ $type }->[3] },
				 @{ $XFORMS_SCHEMA{ $type }->[4] } )
		{
			## When we find it, make sure we change our status bit.
			if( ( $_ eq "$element" ) || ( $_ eq "xforms:$element" ) )
			{
				$status = 1;
			}
		}

		if( $status )
		{
			## If status is true, then proceed to build and append the 
			## child element.
			my $node = XML::LibXML::Element->new( $element );

			bless( $node, __PACKAGE__ );

			$self->appendChild( $node );

			$node->setNamespace( $XFORMS_NAMESPACE{xforms}, "xforms", 1 );

			__xforms_attribute( $node, $attributes );
			__xforms_children( $node, @children );
	
			return( $node );
		}
		else
		{
			croak( qq|Error: $type control does not have the ability to have |,
				   qq|a $element child element| );
		}
	};

##----------------------------------------------##
##  getCHILDENAME                               ##
##----------------------------------------------##
##  Method for retrieval of the control child   ##
##  elements.                                   ##
##----------------------------------------------##
	*{ "get" . ucfirst( $element ) } = sub {

		my $self = shift;

		my @nodes = 
			$self->getElementsByTagNameNS( $XFORMS_NAMESPACE{ 'xforms' },
										   $element );

		return( @nodes );
	};

##----------------------------------------------##
##  prependCHILDENAME                           ##
##----------------------------------------------##
##  Method generation for the common child      ##
##  elements of controls.                       ##
##----------------------------------------------##
	*{ "prepend" . ucfirst( $element ) } = sub {

		my( $self, $attributes, @children ) = @_;

		## We need to determine what type of control we are working with.
		my $type = $self->nodeName;

		## We set a status bit to false indicating that at the momment we
		## don't know if this particular control has the potential of
		## having the child element in question attached to it.
		my $status = 0;

		## Loop through all the potential child elements looking for it.
		foreach( @{ $XFORMS_SCHEMA{ $type }->[3] },
				 @{ $XFORMS_SCHEMA{ $type }->[4] } )
		{
			## When we find it, make sure we change our status bit.
			if( ( $_ eq "$element" ) || ( $_ eq "xforms:$element" ) )
			{
				$status = 1;
			}
		}

		if( $status )
		{
			## If status is true, then proceed to build and append the 
			## child element.
			my $node = XML::LibXML::Element->new( $element );

			bless( $node, __PACKAGE__ );

			my $first_node = $self->firstChild;

			$self->insertBefore( $node, $first_node );

			$node->setNamespace( $XFORMS_NAMESPACE{xforms}, "xforms", 1 );

			__xforms_attribute( $node, $attributes );
			__xforms_children( $node, @children );
	
			return( $node );
		}
		else
		{
			croak( qq|Error: $type control does not have the ability to have |,
				   qq|a $element child element| );
		}
	};
}

use strict 'refs';

##==================================================================##
##  Internal Function(s)                                            ##
##==================================================================##

##==================================================================##
##  End of Code                                                     ##
##==================================================================##
1;

##==================================================================##
##  Plain Old Documentation (POD)                                   ##
##==================================================================##

__END__

=head1 NAME

XML::XForms::Generator::Control

=head1 SYNOPSIS

 use XML::XForms::Generator;

 ## Example 1
 my $control = xforms_input( { ref => 'example' },
                             [ qq|label|,
                               {},
                               qq|Example Input:| ] );

  ## Example 2
  my $label = XML::LibXML::Element->new( "label" );

  my $control2 = xforms_input( { ref => 'example2' },
                               $label );

=head1 DESCRIPTION

The XML::LibXML DOM wrapper provided by XML::XForms::Generator module 
is based on convience functions for quick creation of XForms controls.  
These functions are named after the XForms control they create prefixed by 
'xforms_'.  The result of 'xforms_' convience functions is an object
with all of the methods available to a standard XML::LibXML::Element
along with all of the convience methods listed further down in this 
documentation under the METHODS section.

Each XForms control function takes a hash reference to set of name => value
pairs that describe the control's attributes and set of name => value
pairs that are associated with a controls child elements.

Each XForms control also takes an array of child elements to attach to 
control.  They can be specified in one of two ways in during object
creation.  The first method is to build an anonymous array as an
argument with the name of the child as the first element, anonymous hash
of attributes as the second element, and child elements as the the
rest of the anonymous array.  This is demonstrated in first example above.
The second method is to send an object that has XML::LibXML::Node 
in its ISA tree as an argument.  Some XForms controls require certain
child elements to exist to comply with the specification (most notably
the label element).  If you don't specify those elements on creation, the
creation will fail with an error.

=head1 XFORMS CONTROLS

 trigger     - Generates a trigger element (button?, etc.)
 input      - Simple text entry box
 output     - Display instance data
 range      - Selection of a set of contiguous data
 secret     - "Password" entry box
 select     - Multi-selection box
 select1    - Selection box
 submit     - Submit button
 textarea   - Large text entry box
 upload     - Control for file uploads

=head1 METHODS

=over 4 

See code for additional methods as I haven't found a momment to document
them.

=back

=head1 AUTHOR

D. Hageman E<lt>dhageman@dracken.comE<gt>

=head1 SEE ALSO

 XML::XForms::Generator
 XML::XForms::Generator::Action
 XML::XForms::Generator::Model
 XML::LibXML
 XML::LibXML::DOM

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2002-2004 D. Hageman (Dracken Technologies).

All rights reserved.

This program is free software; you can redistribute it and/or modify 
it under the same terms as Perl itself. 

=cut

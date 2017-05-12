package XML::XForms::Generator::UserInterface;
######################################################################
##                                                                  ##
##  Package:  UserInterface.pm                                      ##
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

foreach my $userinterface ( @XFORMS_USERINTERFACE )
{
	## We need to temporarily pop of the namespace prefix for our
	## work here.
	$userinterface =~ s/^xforms://g;

	## Can't use the below function - due to screwy logic it will
	## throw warnings.  Bah!
	#Exporter::export_tags( "xforms_$userinterface" );
	push( @EXPORT, "xforms_$userinterface" );
	
	*{ "xforms_$userinterface" } = sub {

		my( $attributes, @children ) = @_;

		my $node = XML::XForms::Generator::UserInterface->new( $userinterface );

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
##  UserInterface default contstructor.         ##
##----------------------------------------------##
sub new
{
	## Pull in what type of an object we will be.
	my $type = shift;
	## Pull in the parameters ...
	my $userinterface = shift;
	## The object we are generating is going to be a child class of
	## XML::LibXML's DOM objects.
	my $self = XML::LibXML::Element->new( $userinterface );
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
##  UserInterface default deconstructor.        ##
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

foreach my $element ( @XFORMS_USERINTERFACE_ELEMENT )
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
			if(  ( $_ eq "$element" ) || ( $_ eq "xforms:$element" ) )
			{
				$status = 1;
			}
		}

		if( $status )
		{
			## If status is true, then proceed to build and append the 
			## child element.
			my $node = XML::LibXML::Element->new( $element );

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
}

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

XML::XForms::Generator::UserInterface

=head1 SYNOPSIS

 use XML::XForms::Generator;

 my $ui = xforms_group( {},
 					    [ qq|label|,
						  {},
						  qq|Sample Group| ],
                        @controls );

=head1 DESCRIPTION

The XML::LibXML DOM wrapper provided by XML::XForms::Generator module
is based on convience functions for quick creation of XForms user 
interface elements.  These functions are named after the user interface
element they create prefixed by 'xforms_'.  The result of 'xforms_'
convience functions is an object with all of the methods available to
a standard XML::LibXML::Element along with all of the convience methods
listed further down in this document under the METHODS section.

=head1 METHODS

See the code.  Not documented yet.

=head1 AUTHOR

D. Hageman E<lt>dhageman@dracken.comE<gt>

=head1 SEE ALSO

 XML::XForms::Generator
 XML::XForms::Generator::Action
 XML::XForms::Generator::Control
 XML::XForms::Generator::Model
 XML::LibXML
 XML::LibXML::DOM

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2002-2004 D. Hageman (Dracken Technologies).

All rights reserved.

This program is free software; you can redistribute it and/or modify 
it under the same terms as Perl itself. 

=cut

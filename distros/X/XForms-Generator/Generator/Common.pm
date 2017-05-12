package XML::XForms::Generator::Common;
######################################################################
##                                                                  ##
##  Package:  Common.pm                                             ##
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

our @ISA = qw( Exporter XML::LibXML::Element );

our $VERSION = "0.70";

our @EXPORT = qw(	__xforms_attribute
					__xforms_children
					@XFORMS_ACTION
					@XFORMS_ATTRIBUTE_UICOMMON
					@XFORMS_ATTRIBUTE_LINKING
					@XFORMS_ATTRIBUTE_NODESET
					@XFORMS_ATTRIBUTE_SINGLENODE
					@XFORMS_CONTROL
					@XFORMS_CONTROL_ELEMENT
					@XFORMS_MODEL_ELEMENT
					@XFORMS_USERINTERFACE
					@XFORMS_USERINTERFACE_ELEMENT
					%XFORMS_SCHEMA
					%XFORMS_NAMESPACE );

## Potential namespaces used exclusively by the XForms generator.
our %XFORMS_NAMESPACE = (
	"xforms"	=>	"http://www.w3.org/2002/xforms/cr",
	"xlink"		=>	"http://www.w3.org/1999/xlink",
	"xsd"		=>	"http://www.w3.org/2001/XMLSchema",
	"xsi"		=>	"http://www.w3.org/2000/10/XMLSchema-instance",
	"ev"		=>	"http://www.w3.org/2001/xml-events" );

our @XFORMS_ATTRIBUTE_EVENT = qw( ev:event ev:observer ev:target ev:handler
								  ev:phase ev:propagate ev:defaultAction );

## XForms Common Attributes
our @XFORMS_ATTRIBUTE_UICOMMON = qw( accesskey navindex appearance );

## XForms Linking Attributes
our @XFORMS_ATTRIBUTE_LINKING = qw( src );

### XForms Nodeset Binding Attributes
our @XFORMS_ATTRIBUTE_NODESET = qw( nodeset model bind );

### XForms Single Node Binding Attributes
our @XFORMS_ATTRIBUTE_SINGLENODE = qw( ref model bind );

our @XFORMS_MODEL_ELEMENT = qw( xforms:bind xforms:extension 
								xforms:instance xforms:submission );

## XForms Control Elements
our @XFORMS_CONTROL = qw( xforms:input xforms:secret xforms:textarea 
						  xforms:output xforms:upload xforms:range
						  xforms:trigger xforms:submit xforms:select 
						  xforms:select1 xforms:item );

## XForms Control Child Elements
our @XFORMS_CONTROL_ELEMENT = qw( xforms:alert xforms:choices xforms:filename 
								  xforms:help xforms:hint xforms:item 
								  xforms:itemset xforms:label xforms:mediatype 
								  xforms:extension xforms:value);

## XForms User Interface Elements
our @XFORMS_USERINTERFACE = qw( xforms:group xforms:switch xforms:repeat );

## XForms User Interface Child Elements
our @XFORMS_USERINTERFACE_ELEMENT = qw( xforms:label xforms:case xforms:toggle );

our @XFORMS_ACTION = qw( xforms:action xforms:dispatch xforms:rebuild 
						 xforms:recalculate xforms:revalidate xforms:refresh
						 xforms:setfocus xforms:load xforms:setvalue 
						 xforms:send xforms:reset xforms:message );

## XForms Model Element
our %XFORMS_SCHEMA = (
	"xforms:alert"			=>	[ [],
								  [ @XFORMS_ATTRIBUTE_SINGLENODE,
									@XFORMS_ATTRIBUTE_LINKING ],
								  1,
								  [],
								  [ "xforms:output", "##OTHER##"] ],
	"xforms:bind"			=>	[ [ "id" ],
								  [ @XFORMS_ATTRIBUTE_NODESET, 
									"calculate", "constraint", "maxOccurs", 
									"minOccurs", "p3ptype",  "relevant", 
									"required", "type", ],
								  1,
								  [],
								  [ "xforms:bind" ], ],
	"xforms:choices"		=>	[ [], 
								  [], 
								  0, 
								  [], 
								  [ "xforms:label", "xforms:choices", 
								    "xforms:item", "xforms:itemset"] ],
	"xforms:filename"		=>	[ [],
								  [ @XFORMS_ATTRIBUTE_SINGLENODE ],
								  0,
								  [],
								  [] ],
	"xforms:extension"		=>	[ [], 
								  [], 
								  1, 
								  [], 
								  [ "##OTHER##" ] ],
	"xforms:model"			=>	[ [ "id" ], 
								  [ "functions", "schema" ], 
								  0, 
								  [], 
								  [ "xforms:bind", "xforms:extension", 
									"xforms:instance", "xforms:submission",
									@XFORMS_ACTION ] ],
	"xforms:instance"		=>	[ [],
								  [ @XFORMS_ATTRIBUTE_LINKING ],
								  0,
								  [ "##ANYDOM##" ],
								  [], ],
	"xforms:submission"		=>	[ [ "action", "method", "id" ], 
								  [ "cdata-section-elements", "encoding", 
							  		"indent", "omit-xml-declaration", 
									"ref", "replace", "seperator", 
									"standalone", "version" ],
								  1,
								  [],
								  [ @XFORMS_ACTION ], ],
	"xforms:input"			=>	[ [], 
								  [ @XFORMS_ATTRIBUTE_UICOMMON, 
									@XFORMS_ATTRIBUTE_SINGLENODE,
									"inputmode", "incremental" ],
								  0,
								  [ "xforms:label" ],
								  [ "help", "hint", "alert", 
									@XFORMS_ACTION, "extension" ], ],
	"xforms:secret"			=>	[ [],
								  [ @XFORMS_ATTRIBUTE_UICOMMON, 
									@XFORMS_ATTRIBUTE_SINGLENODE,
									"inputmode", "incremental" ],
								  0,
								  [ "xforms:label" ],
								  [ "help", "hint", "alert", 
									@XFORMS_ACTION, "extension" ], ],
	"xforms:textarea"		=>	[ [],
								  [ @XFORMS_ATTRIBUTE_UICOMMON, 
									@XFORMS_ATTRIBUTE_SINGLENODE,
									"inputmode", "incremental" ],
								  0,
								  [ "xforms:label" ],
								  [ "help", "hint", "alert", 
									@XFORMS_ACTION, "extension" ], ],
	"xforms:output"			=>	[ [],
								  [ @XFORMS_ATTRIBUTE_SINGLENODE, 
									"appearance",
									"value" ],
								  0,
								  [],
								  [ "xforms:label" ] ],
	"xforms:upload"			=>	[ [],
								  [ @XFORMS_ATTRIBUTE_UICOMMON, 
									@XFORMS_ATTRIBUTE_SINGLENODE,
									"incremental", "mediatype" ],
								  0,
								  [ "xforms:label" ],
								  [ "filename", "mediatype", "help", "hint", 
									"alert", @XFORMS_ACTION, "extension" ], ],
	"xforms:range"			=>	[ [],
								  [ @XFORMS_ATTRIBUTE_UICOMMON, 
									@XFORMS_ATTRIBUTE_SINGLENODE,
									"end", "incremental", "start", "step" ],
								  0,
								  [ "xforms:label" ],
								  [ "help", "hint", "alert", 
									@XFORMS_ACTION, "extension" ], ],
	"xforms:trigger"		=>	[ [],
								  [ @XFORMS_ATTRIBUTE_UICOMMON, 
									@XFORMS_ATTRIBUTE_SINGLENODE ],
								  0,
								  [ "xforms:label" ],
								  [ "help", "hint", "alert", 
									@XFORMS_ACTION, "extension" ], ],
	"xforms:submit"			=>	[ [ "submission" ],
								  [ @XFORMS_ATTRIBUTE_UICOMMON, 
									@XFORMS_ATTRIBUTE_SINGLENODE ],
								  0,
								  [ "xforms:label" ],
								  [ "help", "hint", "alert", 
									@XFORMS_ACTION, "extension" ], ],
	"xforms:select"			=>	[ [],
								  [ @XFORMS_ATTRIBUTE_UICOMMON, 
									@XFORMS_ATTRIBUTE_SINGLENODE,
									"incremental" ],
								  0,
								  [ "xforms:label" ],
								  [ "choices", "item", "itemset",
									"help", "hint", "alert", 
									@XFORMS_ACTION, "extension" ], ],
	"xforms:select1"		=>	[ [],
								  [ @XFORMS_ATTRIBUTE_UICOMMON, 
									@XFORMS_ATTRIBUTE_SINGLENODE,
									"incremental", "selection" ],
								  0,
								  [ "xforms:label" ],
								  [ "choices", "item", "itemset",
									"help", "hint", "alert", 
									@XFORMS_ACTION, "extension" ], ],
	"xforms:help"			=>	[ [],
								  [ @XFORMS_ATTRIBUTE_SINGLENODE,
									@XFORMS_ATTRIBUTE_LINKING ],
								  1,
								  [],
								  [ "xforms:output", "##OTHER##" ] ],
	"xforms:hint"			=>	[ [],
								  [ @XFORMS_ATTRIBUTE_SINGLENODE,
									@XFORMS_ATTRIBUTE_LINKING ],
								  1,
								  [],
								  [ "xforms:output", "##OTHER##" ] ],
	"xforms:item"			=>	[ [], 
								  [], 
								  0, 
								  [ "xforms:label", "xforms:value" ], 
								  [ "help", "hint", "alert", 
									@XFORMS_ACTION, "extension" ], ],
	"xforms:itemset"		=>	[ [], 
								  [ @XFORMS_ATTRIBUTE_NODESET], 
								  0, 
								  [ "xforms:label" ], 
								  [ "xforms:item", "xforms:copy", 
									"help", "hint", "alert", 
									@XFORMS_ACTION, "extension" ], ],
	"xforms:label"			=>	[ [],
								  [ @XFORMS_ATTRIBUTE_SINGLENODE,
									@XFORMS_ATTRIBUTE_LINKING ],
								  1,
								  [],
								  [ "xforms:output", "##OTHER##"] ],
	"xforms:mediatype"		=>	[ [],
								  [ @XFORMS_ATTRIBUTE_SINGLENODE ],
								  0,
								  [],
								  [] ],
	"xforms:value"			=>	[ [],
								  [ @XFORMS_ATTRIBUTE_SINGLENODE ],
								  1,
								  [],
								  [ "##ANY##" ] ],
	"xforms:group"			=>	[ [],
								  [ @XFORMS_ATTRIBUTE_SINGLENODE ],
								  0,
								  [],
								  [ "xforms:label", "xforms:group",
									"xforms:switch", "xforms:repeat",
									@XFORMS_CONTROL, "##OTHER##" ] ],
	"xforms:switch"			=>	[ [],
								  [],
								  0,
								  [ "xforms:case"],
								  [] ],
	"xforms:repeat"			=>	[ [],
								  [ "startindex", "number" ],
								  0,
						 		  [],
								  [ "xforms:group", "xforms:repeat",
									@XFORMS_CONTROL, "##OTHER##" ] ],
	"xforms:case"			=>	[ [ "id" ], 
								  [ "selected" ], 
								  0, 
								  [], 
								  [ @XFORMS_CONTROL,
								    @XFORMS_USERINTERFACE,
									"##OTHER##" ] ],
	"xforms:toggle"			=>	[ [], 
								  [ @XFORMS_ATTRIBUTE_EVENT,
									"case" ], 
								  0, 
								  [], 
								  [] ],
	"xforms:action"			=>	[ [],
								  [ @XFORMS_ATTRIBUTE_EVENT ], 
								  0, 
								  [], 
								  [ @XFORMS_ACTION ] ],
	"xforms:dispatch"		=>	[ [ "name", "target" ],
								  [ @XFORMS_ATTRIBUTE_EVENT,
									"bubbles", "cancelable" ],
								  0, 
								  [], 
								  [] ],
	"xforms:rebuild"		=>	[ [], 
								  [ @XFORMS_ATTRIBUTE_EVENT,
									"model" ], 
								  0, 
								  [], 
								  [] ],
	"xforms:recalculate"	=>	[ [], 
								  [ @XFORMS_ATTRIBUTE_EVENT,
									"model" ], 
								  0, 
								  [], 
								  [] ],
	"xforms:revalidate"		=>	[ [], 
								  [ @XFORMS_ATTRIBUTE_EVENT,
									"model" ], 
								  0, 
								  [], 
								  [] ],
	"xforms:refresh"		=>	[ [], 
								  [ @XFORMS_ATTRIBUTE_EVENT,
									"model" ], 
								  0, 
								  [], 
								  [] ],
	"xforms:setfocus"		=>	[ [ "control" ], 
								  [ @XFORMS_ATTRIBUTE_EVENT ],
								  0, 
								  [], 
								  [] ],
	"xforms:load"			=>	[ [ "src" ], 
								  [ @XFORMS_ATTRIBUTE_EVENT,
									@XFORMS_ATTRIBUTE_SINGLENODE,
									@XFORMS_ATTRIBUTE_LINKING,
									"show", "src" ], 
								  0, 
								  [], 
								  [] ],
	"xforms:setvalue"		=>	[ [], 
								  [ @XFORMS_ATTRIBUTE_EVENT,
									@XFORMS_ATTRIBUTE_SINGLENODE,
									"value" ], 
								  1, 
								  [], 
								  [] ],
	"xforms:send"			=>	[ [],
								  [ @XFORMS_ATTRIBUTE_EVENT,
									"submission" ], 
								  0, 
								  [], 
								  [] ],
	"xforms:reset"			=>	[ [],
								  [ @XFORMS_ATTRIBUTE_EVENT,
									"model" ], 
								  0, 
								  [], 
								  [] ],
	"xforms:message"		=>	[ [ "level" ],
								  [ @XFORMS_ATTRIBUTE_EVENT,
									@XFORMS_ATTRIBUTE_SINGLENODE,
									@XFORMS_ATTRIBUTE_LINKING ],
								  1, 
								  [], 
								  [] ],
);



##==================================================================##
##  Constructor(s)/Deconstructor(s)                                 ##
##==================================================================##

##
##  None.
##

##==================================================================##
##  Method(s)                                                       ##
##==================================================================##

##
##  None.
##

##==================================================================##
##  Function(s)                                                     ##
##==================================================================##

##
##  None.
##

##==================================================================##
##  Internal Function(s)                                            ##
##==================================================================##

##----------------------------------------------##
##  __xforms_attribute                          ##
##----------------------------------------------##
##  Convience function to set attributes on a   ##
##  XForms element.                             ##
##----------------------------------------------##
sub __xforms_attribute ($$)
{
	my( $element, $attributes ) = @_;

	my $type = $element->nodeName;

	## Look to make sure that we set all of the required elements.
	foreach( @{ $XFORMS_SCHEMA{$type}->[0] } )
	{
		if( defined( $attributes->{$_} ) )
		{
			$element->setAttribute( $_, $attributes->{$_} );
			delete( $attributes->{$_} );
		}
		else
		{
			croak( qq|Error: $type element is missing the required attribute | .
				   qq|'$_'| );
		}
	}

	## Make sure we set any optional elements defined as part of the
	## specification.
	foreach( @{ $XFORMS_SCHEMA{$type}->[1] }, "id", "nodeset", "type",
			 "readonly", "calculate", "required", "relevant",
			 "constraint", "maxOccurs" )
	{
		if( defined( $attributes->{$_} ) )
		{
			$element->setAttribute( $_, $attributes->{$_} );
			delete( $attributes->{$_} );
		}
	}

	## Finally - all XForms elements are allowed to have attributes existing
	## outside the specification, but they must be in another namespace.
	foreach( keys( %{ $attributes } ) )
	{
		## We need to ensure we grabbed a prefix from the attribute name.
		if( $_  !~ /:/ )
		{
			croak( qq|Error: This element can only accept attributes not |,
				   qq|defined by the XForms specification when they exist |,
				   qq|in another namespace. The attribute $_ is not |,
				   qq|recognized to be part of the XForms specification| );
		}

		## Pull the prefix of the name space from the attribute name.
		$_ =~ /^([a-z]+):/;

		## Check to ensure the name space is recognized.
		if( !defined( $XFORMS_NAMESPACE{ $1 } ) )
		{
			croak( qq|Error: The namespace $1 on the foriegn attribute $_ |,
				   qq|is not recognized.  Attempt to add its definition via |,
				   qq|xforms_add_namespace call and retry| );
		}

		## Add the attribute with the namespace attached.
		$element->setAttributeNS( $XFORMS_NAMESPACE{ $1 }, 
								  $_, 
								  $attributes->{$_} );
	}

	return;
}

##----------------------------------------------##
##  __xforms_children                           ##
##----------------------------------------------##
##  Convience function to append children       ##
##  correctly to a XForms element.              ##
##----------------------------------------------##
sub __xforms_children ($@)
{
	my( $element, @children ) = @_;

	my $type = $element->nodeName;
	
	## We first do a check to see if we have all of the required children
	## of an element.
	foreach( @{ $XFORMS_SCHEMA{$type}->[3] } )
	{
		my $status = 1;
		
		foreach my $child ( @children )
		{
			if( ( ref( $child ) ) && ( ref( $child ) eq "ARRAY" ) )
			{
				my $name = $child->[0];

				if( ( $_ eq $name ) || ( $_ eq "xforms:$name" ) )
				{
					$status = 0;
				}
			}
			elsif( ( ref( $child ) ) && ( $child->isa( "XML::LibXML::Node" ) ) )
			{
				my $name = $child->nodeName;
				
				if( ( $_ eq $name ) || ( $_ eq "xforms:$name" ) )
				{
					$status = 0;
				}
			}
		}

		if( $_ eq "##ANYDOM##" )
		{
			if( ( scalar( @children ) == 1 ) &&
				( ref( $children[0] ) ) && 
				( $children[0]->isa( "XML::LibXML::Node" ) ) )
			{
				## We need to ensure that the next test is passed because
				## this node is golden.
				$status = 0;
			}
			else
			{
				croak( qq|Error: $type element requires that a single |,
					   qq|DOM tree be its child element.| );
			}
		}

		if( $status )
		{
			croak( qq|Error: $type element is missing required child |,
				  qq|element '$_'| );
		}
	}

	## Loop through each of the children and determine what we need to do 
	## with them.
	foreach my $child ( @children )
	{
		if( ( defined( $child ) ) && ( $child ne "" ) )
		{
			if( ( ref( $child ) ) && ( ref( $child ) eq "ARRAY" ) )
			{
				my $name = "append" . ucfirst( lc( shift( @{ $child } ) ) );
				#my $name = ucfirst( lc( shift( @{ $child } ) ) );
				my $attr = shift( @{ $child } );
				my @chld = @{ $child };
				## I need to benchmark the two methods and figure out which
				## is faster.   I think the eval will be slower though.
				no strict 'refs';
				$element->$name( $attr, @chld );
				use strict 'refs';
				#eval "\$element->append$name( \$attr, \@chld );";
				#print "$@\n" if( $@ );
			}
			elsif( ( ref( $child ) ) && ( $child->isa( "XML::LibXML::Node" ) ) )
			{
				my $name = $child->nodeName;

				foreach( @{ $XFORMS_SCHEMA{$type}->[3] },
						 @{ $XFORMS_SCHEMA{$type}->[4] } )
				{
					if( ( $_ eq "##ANY##" ) || 
					    ( $_ eq $name ) || 
						( $_ eq "xforms:$name" ) ||
						( $_ eq "##ANYDOM##" ) )
					{
						$element->appendChild( $child );
					}
					elsif( ( $_ eq "##OTHER##" ) && ( $name !~ /xforms:/ ) )
					{
						$element->appendChild( $child );
					}
				}
			}
			else
			{
				if( $XFORMS_SCHEMA{$type}->[2] == 1 )
				{
					$element->appendText( $child );
				}
			}
		}
	}

	return;
}

##==================================================================##
##  End of Code                                                     ##
##==================================================================##
1;

##==================================================================##
##  Plain Old Documentation (POD)                                   ##
##==================================================================##

__END__

=head1 NAME

XML::XForms::Generator::Common

=head1 SYNOPSIS

 use XML::XForms::Generator::Common;

=head1 DESCRIPTION

Module is intended for internal XML::XForms::Generator use only.

=head1 METHODS

None.

=head1 AUTHOR

D. Hageman E<lt>dhageman@dracken.comE<gt>

=head1 SEE ALSO

 XML::XForms::Generator
 XML::XForms::Generator::Action
 XML::XForms::Generator::Control
 XML::XForms::Generator::Model
 XML::XForms::Generator::UserInterface
 XML::LibXML
 XML::LibXML::DOM

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2002-2004 D. Hageman (Dracken Technologies).

All rights reserved.

This program is free software; you can redistribute it and/or modify 
it under the same terms as Perl itself. 

=cut

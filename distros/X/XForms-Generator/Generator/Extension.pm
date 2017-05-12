package XML::XForms::Generator::Extension;
######################################################################
##                                                                  ##
##  Package:  Extension.pm                                          ##
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

our @ISA = qw( Exporter );

our $VERSION = "0.70";

our @EXPORT = qw( xforms_extension_html );

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
##  xforms_extension_html                       ##
##----------------------------------------------##
##  Generates a tag to be appended to the       ##
##  <extension> tag for backwards compatibility ##
##  with HTML.                                  ##
##----------------------------------------------##
sub xforms_extension_html
{
	my $attributes = shift;

	my $html = XML::LibXML::Element->new( "html" );

	foreach( keys( %{ $attributes } ) )
	{
		$html->setAttribute( $_, $attributes->{$_} );
	}

	return( $html );
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

XML::XForms::Generator::Extension

=head1 SYNOPSIS

 use XML::XForms::Generator::Extension;

=head1 DESCRIPTION

This module provides convience methods to the most common extension 
tagsets to the XForms standard.

=head1 FUNCTIONS

=over 4

=item xforms_extension_html

This function will create an E<lt>htmlE<gt> tag that can be embeded into
the E<lt>xforms:extensionE<gt> element to specify attributes of HTML
form tags that are missing from the XForms specification.  This is mainly
used to keep backward compatiblity with older systems.

=back

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

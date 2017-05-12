package XML::XForms::Generator;
######################################################################
##                                                                  ##
##  Package:  Generator.pm                                          ##
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
require Exporter::Cluster;

use strict;
use warnings;

@XML::XForms::Generator::ISA = qw( Exporter::Cluster );

%XML::XForms::Generator::EXPORT_CLUSTER = ( 
	'XML::XForms::Generator::Action'			=>	[],
	'XML::XForms::Generator::Control'			=>	[],
	'XML::XForms::Generator::Extension'			=>	[], 
	'XML::XForms::Generator::Model'				=>	[], 
	'XML::XForms::Generator::UserInterface'		=>	[], 
);

our $VERSION = "0.70";

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
##  End of Code                                                     ##
##==================================================================##
1;

##==================================================================##
##  Plain Old Documentation (POD)                                   ##
##==================================================================##

__END__

=head1 NAME

XML::XForms::Generator

=head1 SYNOPSIS

 use XML::XForms::Generator;

=head1 DESCRIPTION

XForms is a XML::LibXML DOM wrapper to ease the creation of XML that is 
complaint with the schema of the W3's XForms candidate recommendation.

The XForms webpage is located at: http://www.w3.org/MarkUp/Forms/

=head1 AUTHOR

D. Hageman E<lt>dhageman@dracken.comE<gt>

=head1 SEE ALSO

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

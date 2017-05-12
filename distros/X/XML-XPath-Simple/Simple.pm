package XML::XPath::Simple;
#############################################################
#  XML::XPath::Simple
#  Whyte.Wolf Simple XPath Module
#  Version 0.05
#
#  Copyright (c) 2002 by S.D. Campbell <whytwolf@spots.ab.ca>
#
#  Created 26 March 2002; Revised 30 March 2002 by SDC
#
#  Description:
#	A perl module which can be used for simple parsing of
#   XPath expressions.
#
#############################################################
#
#  This program is free software; you can redistribute it and/or
#  modify it under the terms of the GNU General Public License
#  as published by the Free Software Foundation; either version 2
#  of the License, or (at your option) any later version.
#
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
#  GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with this program; if not, write to the Free Software
#  Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
#############################################################

use Exporter;
use Carp;
use XML::Simple;

@ISA = qw(Exporter);
@EXPORT = qw();
@EXPORT_OK = qw();

use strict;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK $errmsg);

$VERSION = '0.05';
$errmsg = "";


#############################################################
# new
#
#  The constructor for the class.  Requires a string containing
#  XML.  Returns a reference to the new object or undef
#  on error.  Error can be retrieved from $XML::XPath::Simple::errmsg

sub new {
    my $class = shift;
    my %params = @_;
	my %xmlopts = ( keeproot => '1',
			 keyattr => [],
			 forcecontent => '1',
			 forcearray => '1',
			 contentkey => 'text',
			 );

    my $self = {};
	
	if($params{xml}){
		$$self{xml} = $params{xml};
		if($params{context}){
			$$self{context} = $params{context};
		} else {
			$$self{context} = '/';
		}
		$$self{ref} = XMLin($$self{xml}, %xmlopts);
		
        bless $self, $class;
    	return $self;
	}else{
		$errmsg = "XML::XPath::Simple -- No XML to parse: This module requires an XML string.";
		return undef;
	}
}

#############################################################
# context
#
#    Allows the user to get/set the context.  Returns
#    current default context, or undef if passed a new
#    context to set.

sub context {
	my $self = shift;
	if(scalar(@_) == 0) {
		return $$self{context};
	} else {	
		my $path = shift;
		$$self{context} = $path;	
	} 
	return undef;
}

#############################################################
# find
#
#    Returns true if the node specified by the path exists
#    false otherwise.

sub find {
	my $self = shift;
	my $path = shift;
	my $ref = $$self{ref};
	$path = $self->_convert($path);
	
	if (eval($path)) {
		return 'true';
	} else {
		return 'false';
	}	
}

#############################################################
# valueof
#
#    Returns the value of the node at the path specified

sub valueof {
	my $self = shift;
	my $path = shift;
	my $ref = $$self{ref};
	$path = $self->_convert($path);
	if (ref(eval($path))){
		$path .= '->{text}';
	}
	
	return eval($path);
}

#############################################################
# _convert
#
#    An internal subroutine that converts XPaths into
#    XML::Simple hash references.

sub _convert {

	my $self = shift;
	my $path = shift;
	if(substr($path, 0, 1) ne '/'){
		if(substr($path, 0, 2) eq '..'){
			my $context = $$self{context};
			$context =~ s/\/(\w*|@\w*|\w*\[\w*\])$//igs;
			$path =~ s/^..//is;
			$path = $context . $path;
		} elsif($path eq '.'){
			$path = $$self{context};
		} elsif(substr($path, 0, 1) eq '@'){
			$path = $$self{context} . $path;
		} else {
			$path = $$self{context} . '/' . $path;
		}
	}
	
	$path =~ s/\/(\w*)\[(\d*)\]/->{$1}[($2 - 1)]/igs;
	$path =~ s/\/(\w*)/->{$1}[0]/igs;
	$path =~ s/@(\w*)/->{$1}/igs;
	$path = '$ref' . $path;
	
	return $path;       	

}

1;
__END__
# Below is the stub of documentation for your module. You better edit it!

=head1 NAME

XML::XPath::Simple - Very simple interface for XPaths

=head1 SYNOPSIS

  use XML::XPath::Simple;
  
  $xp = new XML::XPath::Simple(
  								xml => $xml,
								context => '/'
								);
  $content = $xp->valueof('/doc/c[2]/d[1]@id');

=head1 DESCRIPTION

XML::XPath::Simple is designed to allow for the use of simple Abbreviated
XPath syntax to access values from a small XML document.  This module
is not meant as a drop-in replacement for XML::XPath, and doesn't support
the entire W3C XPath Recommendation.  This module is meant as an easy
and simple way to access XML data from small, non-complex structures.

XML::XPath::Simple doesn't support documents that have elements containing 
mixed content (text and tags), nor does it allow for the walking of the 
tree structure, or the counting of elements.  While this module allows 
access to specific nodes using the position() function, internally
the module doesn't necessarially parse the XML structure in any specific
order, so position() calls may not return the value expected.

=head1 METHODS

=head2 Creation

  $xp = new XML::XPath::Simple(
  								xml => $xml,
								context => '/'
								);

B<new> Creates a new XML::XPath::Simple object.  The constructor
requires an XML document be passed to it as text using the B<xml>
option.  An optional default context may be set using B<context>
but if no context is specified it is set to '/'(root).

=head2 context()

  $xp->context('/doc/a');
  $mycont = $xp->context();

B<context> allows for the retrieval of the currently set context as
an XPath expression, or for setting a new default context.

=head2 find()

  $xp->find('/doc/a');

B<find> looks for the node specified by the XPath expression provided.
This method returns true if the node exists, and false otherwise.

=head2 valueof()

  $myval = $xp->valueof('/doc/a');

B<valueof> returns the value stored in the node specified by the XPath
expression provided.

=head1 DIAGNOSTICS

=over 4

=item XML::XPath::Simple -- No XML to parse: This module requires an XML string.

(F) The module was not provided an XML document to parse.  

=back

=head1 AUTHOR

S.D. Campbell, whytwolf@spots.ab.ca

=head1 SEE ALSO

perl(1), XML::XPath, XML::Simple.

=head1 LICENSE

This program is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License
as published by the Free Software Foundation; either version 2
of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.

=cut


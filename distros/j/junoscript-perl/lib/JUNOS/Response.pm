#
# $Id: Response.pm,v 1.11 2003/03/02 11:12:09 dsw Exp $
#
# COPYRIGHT AND LICENSE
# Copyright (c) 2001-2003, Juniper Networks, Inc.  
# All rights reserved.  
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are
# met:
# 	1.	Redistributions of source code must retain the above
# copyright notice, this list of conditions and the following
# disclaimer. 
# 	2.	Redistributions in binary form must reproduce the above
# copyright notice, this list of conditions and the following disclaimer
# in the documentation and/or other materials provided with the
# distribution. 
# 	3.	The name of the copyright owner may not be used to 
# endorse or promote products derived from this software without specific 
# prior written permission. 
# THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS OR
# IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT,
# INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
# (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
# SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
# HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
# STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING
# IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
# POSSIBILITY OF SUCH DAMAGE.
#


package JUNOS::Response;

use strict;
use vars qw(@ISA $error_tag);

@ISA = qw(XML::DOM::Element);
$error_tag = "xnm:error";

use XML::DOM;
use JUNOS::Trace;

sub new
{
    my($class, $self) = @_;
    $self = [] unless ref $self;

    bless $self, $class;
}

sub getFirstError
{
    my($self) = @_;

    return undef if $#$self < 0;

    my $err;

    if ($self->getTagName() eq $error_tag) {
	$err = $self;
    } else {
	my $errors = $self->getElementsByTagName($error_tag);
	return undef unless defined $errors;
	return undef unless $errors->getLength;
	# We only really can return the first error.
	$err = shift @$errors;
    }

    my $rc = {};
    
    for my $kid ($err->getChildNodes) {
	next unless $kid->isElementNode;

	my $name = $kid->getNodeName;

	my $val;
	for my $baby ($kid->getChildNodes) {
	    $val .= $baby->getData if $baby->getNodeType == TEXT_NODE;
	}

	$name =~ s/^[\s\n]+//;
	$name =~ s/[\s\n]+$//;
	$name =~ s/-/_/g;
	$val =~ s/^[\s\n]+//;
	$val =~ s/[\s\n]+$//;
	trace("Noise", "JUNOS::Response: $name -> $val");
	$rc->{ $name } .= " $val";
    }

  # append any extraneous 'output' tag
  $rc->{message} .= $rc->{output};

    $rc;
}

sub toString
{
    my $self = shift;

    return undef if $#$self < 0;
    $self->SUPER::toString(@_);
}

#
# private: get_first_element_with_attribute
# 
# This subroutine is called to return the first element containing a specific
# attribute, so the caller of this subroutine can get, set or delete
# this attribute.
#
sub get_first_element_with_attribute
{
    my ($node, $attrname) = @_;

    my $attributes = $node->getAttributes();
    return $node if ($attributes && $node->getAttribute($attrname));

    my $nodes = $node->getChildNodes();
    my $len  = $nodes->getLength;

    for (my $i = 0; $i < $len; $i++) {
        my $nsnode = get_first_element_with_attribute($nodes->item($i), $attrname);
	return $nsnode if $nsnode;
    }
    return;
}

#
# private: remove_prefix_from_element
# 
# This subroutine is called to remove the namespace prefix from the
# XSL file to deal with the JUNOScript responses from old versions
# of JUNOS that do not contain default namespace.
#
sub remove_prefix_from_element
{
    my ($self, $node, $prefix) = @_;

    my $nodes = $node->getChildNodes();
    return unless $nodes;
	
    my $len  = $nodes->getLength;
    return unless $len;
    
    for (my $i = 0; $i < $len; $i++) {
	my $item = $nodes->item($i);
        my $attributes = $item->getAttributes();
	if ($attributes) {
            my $attrcount = $attributes->getLength();

            for (my $i = 0; $i < $attrcount; $i++) {
	        my $attr = $attributes->item($i);
	        my $value = $attr->getNodeValue();
	        $value =~ s/$prefix://g;
	        $attr->setNodeValue($value);
            }
	}

  	$self->remove_prefix_from_element($item, $prefix);
    }

    return;
}

use constant XML_NS_ATTRIBUTE => 'xmlns';

#
# translateXSLtoRelease
#
# XSLT 1.0 does not deal with default namespace as well as we had hoped.
# It requires the xsl file to declare a namspace given the default namespace
# from the XML data.  It must also prefix all the element names with the 
# local name.
#
# Because the default namespace in all JUNOScript responses contains
# the JUNOS version, the xsl file cannot point to the same default
# namespace for all routers.  Also there are backward compatibility
# problems in dealing with some JUNOScript responses form older versions
# of JUNOS that do not have default namespace (e.g. 
# <get-bgp-neighbor-information> response from pre-5.1 releases)
#
# Before transforming the response, the xsl file should be parsed and
# its namespace attribute for the JUNOScript response should be replaced with
# the default namespace in the response.  If the default namespace is not
# defined in the xml doc, the prefix will be removed from the XSL file
# to deal with the abovementioned backward compatibility problem.
#
# Hopefully, this subroutine will be made obsolete when XLST 2.0 implementation
# is made available.
#
use constant HASH_REFERENCE => 'HASH';
sub translateXSLtoRelease
{
    my ($self, $namespace, $input, $output) = @_;

    my $xsltparser = new XML::DOM::Parser;
    unless ($xsltparser) {
        print STDERR "ERROR: cannot create an XML::DOM::Parser object\n";
        return;
    }
    my $xsltdoc = $xsltparser->parsefile($input);
    unless ($xsltdoc) {
        print STDERR "ERROR: cannot parse the XSL input file $input\n";
        return;
    }
    if (ref($namespace) eq HASH_REFERENCE) {
	my %nstable = %$namespace;
	foreach my $k (keys(%nstable)) {
            setXSLtoRelease($self, $k, $nstable{$k}, $xsltdoc);
	}
    } else {
        setXSLtoRelease($self, $namespace, XML_NS_ATTRIBUTE, $xsltdoc);
    }
    $xsltdoc->printToFile($output);
    return $output;
}

sub setXSLtoRelease
{
    my ($self, $xslns, $xmlns, $xsltdoc) = @_;

    my $nselem = get_first_element_with_attribute($self, $xmlns);
    my $dfns = $nselem->getAttribute($xmlns) if $nselem;

    if ($dfns) {
        $nselem = get_first_element_with_attribute($xsltdoc, $xslns);
        return unless $nselem;
        $nselem->setAttribute($xslns, $dfns);
	return;
    }

    # if there is no instance of the specified namespace in the xml doc, 
    # make sure the prefix is removed from the xsl file.  This is for backward
    # compatiblitiy.  Some of the JUNOScript Responses from older
    # releases do not have the default namespace.  The XSL file would
    # not work with it unless we make this change.
  
    my ($declare, $prefix) = split(/:/, $xslns);
    $self->remove_prefix_from_element($xsltdoc, $prefix);
}

1;

__END__

=head1 NAME

JUNOS::Response - Response object from a remote Juniper box

=head1 SYNOPSIS

This example retrieves 'show chassis hardware' information and transforms
the input with XSLT.  A JUNOS::Response object is returned by the
$jnx->get_chassis_inventory() call.

    use JUNOS::Device;

    # connect TO the JUNOScript server
    $jnx = new JUNOS::Device(hostname => "router11",
                             login => "johndoe",
                             password => "secret",
                             access => "telnet");
    unless ( ref $jnx ) {
        die "ERROR: $deviceinfo{hostname}: can't connect.\n";
    }

    # send the command and receive a XML::DOM object
    my $res = $jnx->get_chassis_inventory(detail => 1);
    unless ( ref $res ) { 
        die "ERROR: $deviceinfo{hostname}: can't execute command $query.\n";   
    }

    # Check and see if there were any errors in executing the command.
    # If all is well, output the response using XSLT.
    my $err = $res->getFirstError();
    if ($err) {
        print STDERR "ERROR: $deviceinfo{'hostname'} - ", $err->{message}, "\n";
    } else {
        # 
        # Now do the transformation using XSLT.
        #
        my $xmlfile = "$deviceinfo{hostname}.xml";
	$res->printToFile($xmlfile);
        my $nm = $res->translateXSLtoRelease('xmlns:lc', $xslfile, "$xslfile.tmp");
        if ($nm) {
            my $command = "xsltproc $nm $deviceinfo{hostname}.xml";
            system($command);
        } else {
            print STDERR "ERROR: Invalid XSL File $xslfile\n";
        }
    }
    
    # always close the connection
    $jnx->request_end_session();
    $jnx->disconnect();

=head1 DESCRIPTION

This object encapsulates a response from a remote JUNOScript server.
It is returned from a JUNOS::Device::request, JUNOS::Device::command,
and all XML RPC methods within JUNOS::Device.  It is a subclass of
XML::DOM::Element.

=head1 CONSTRUCTOR

new($DOC)

The XML::DOM object ($DOC) returned from the JUNOScript server.

=head1 METHODS

getFirstError()

Returns a hash reference containing all of the errors
caused by the call this object was generated in response to.
Returns undef if no errors were encountered.

toString()

Returns a string-ified representation of this object.

translateXSLtoRelease($NAMESPACE, $XSLFILE, $TMPFILE)

Returns the name of the xsl file to transform the response data.

XSLT 1.0 requires that the xsl file must declare the a prefix
with the default namespace from the XML data it transforms.  
Because the default namespace in all JUNOScript responses 
contains version information, the xsl file will have to 
adapt to the default namespace from routers running different 
versions of JUNOS.  

This subroutine takes three input parameters: the prefix name ($NAMESPACE), 
xsl input file name ($XSLFILE) and xsl temp file name ($TMPFILE).  It replaces 
the value of the prefix attribute in the input xsl file with 
the default namespace from the JUNOScript response and puts 
the result in the output xsl file.  In some cases, it may
have to remove the prefix for default namespace from the
xsl input file because some JUNOScript responses from old versions
of JUNOS may not contain default namespace (e.g. response for
<get-bgp-neighbor-information> from pre-5.1 JUNOS).

If all is well, the name of the xsl file for transformation 
is returned.  Otherwise, undef is returned.
Please note that the returned xsl file can be the xsl input file or the 
temp file depending whether any changes are made on the
xsl input file for transformation.

=head1 SEE ALSO

    XML::DOM
    JUNOS::Device

=head1 AUTHOR

Juniper Junoscript Perl Team, send bug reports, hints, tips, and suggestions 
to support@juniper.net.

=head1 COPYRIGHT

Copyright (c) 2001 Juniper Networks, Inc.
All rights reserved.

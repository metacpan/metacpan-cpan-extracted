# ====================================================================
# Copyright (c) 2004 IBM Corporation 
# All rights reserved.   This program and the accompanying materials
# are made available under the terms of the Common Public License v1.0
# which accompanies this distribution, and is available at
# http://www.opensource.org/licenses/cpl.php
# 
# =====================================================================
package LS::Authority::WSDL::Constants;

use strict;
use warnings;

use vars qw( $SCHEMA_TYPES );


$SCHEMA_TYPES = 'http://www.ibm.com/LSID/Standard/WSDL/SchemaTypes';


package LS::Authority::WSDL::Constants::Protocols;

use strict;
use warnings;

use vars qw( 
		$HTTP $HTTP_GET $HTTP_POST
		$SOAP
		$FTP
		$FILESYSTEM
		$MIME
		
		%URI
		
		$LIST
		
		$DEBUG
	);


use Carp qw(:DEFAULT);




#
# BEGIN( ) - Base initialization of this module
#
sub BEGIN {

	# Create a list of protocols available that can be iterated
	# over by client code
	$LIST  = [ 
		keys(%URI),
	];


	#
	# $DEBUG - Controls whether there is debugging output
	#	   Default is 1, debugging output
	#
	$DEBUG = 1;
	
	
	#
	# The following variables are used 
	# to describe the protocol scheme used
	# in all of the WSDL endpoints
	#
	$HTTP = 'http';
	$HTTP_GET = 'GET';
	$HTTP_POST = 'POST';
	
	$SOAP = 'soap';
	
	$FTP = 'ftp';
	
	$FILESYSTEM = 'file';
	
	$MIME = 'mime';
	
	
	#
	# %URI - A mapping from protocol to its URI
	#
	%URI = (
		$HTTP=> 'http://schemas.xmlsoap.org/wsdl/http/',
		$SOAP=> 'http://schemas.xmlsoap.org/wsdl/soap/',
		$FTP=> 'http://www.ibm.com/wsdl/ftp/',
		
		$FILESYSTEM=> 'http://www.ibm.com/wsdl/filesystem/',
		
		$MIME=> 'http://schemas.xmlsoap.org/wsdl/mime/',
	);
}


#
# protocolToURI( $protocol ) - Helper function to map a protocol on to its URI
#
# 	Parameters:
#
#		$protocol - A string containing the protocol scheme 
#
#	Returns:
#
#		undef if there is an error or the protocol does not have a URI
#		or, the URI of the protocol
#
sub protocolToURI {

	my $protocol = shift;
	
	unless($protocol) {
	
		print STDERR Carp::longmess('Missing protocol parameter') 
			if($DEBUG);
		
		return undef;
	}
	
	return $URI{ $protocol };
}


#
# uriToProtocol( $lookupURI ) - Looks up the protocol scheme name for a given URI.
#
# 	Parameters:
#		$lookupURI - The URI used to locate the protocol scheme
#
#	Returns:
#		undef if there is an error or the protocol scheme is not found otherwise,
#		the protocol scheme is returned
#
sub uriToProtocol {
	
	my $lookupURI = shift;
	
	unless($lookupURI) {
	
		print STDERR Carp::longmess('Missing URI parameter') 
			if($DEBUG);
		
		return undef;
	}

	foreach my $key (keys(%URI)) {
		
		return $key if($URI{ $key } eq $lookupURI);
	}
	
	return undef;
}



1;

__END__

=head1 NAME

LS::Authority::WSDL::Constants - Perl module containing constants used in the LSID WSDL module.

=head1 SYNOPSIS

 use LS::Authority::WSDL::Constants;
 
 print "HTTP Protocol: " . $LS::Authority::WSDL::Protocols::HTTP . "\n";

=head1 DESCRIPTION

=head1 METHODS

C<LS::Authority::WSDL::Protocols>

=over

=item protocolToURI( $protocol )

	Helper function to map a protocol on to its URI.

 	Parameters:

		$protocol - A string containing the protocol scheme 

	Returns:

		undef if there is an error or the protocol does not have a URI
		or, the URI of the protocol

=item uriToProtocol( $lookupURI )

	Looks up the protocol scheme name for a given URI.

 	Parameters:
		$lookupURI - The URI used to locate the protocol scheme

	Returns:
		undef if there is an error or the protocol scheme is not found otherwise,
		the protocol scheme is returned

=back

=head1 COPYRIGHT

Copyright (c) 2004 IBM Corporation.
All rights reserved.   This program and the accompanying materials
are made available under the terms of the Common Public License v1.0
which accompanies this distribution, and is available at
L<http://www.opensource.org/licenses/cpl.php>

=cut

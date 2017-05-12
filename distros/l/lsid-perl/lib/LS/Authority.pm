# =====================================================================
# Copyright (c) 2002,2003 IBM Corporation 
# All rights reserved.  This program and the accompanying materials
# are made available under the terms of the Common Public License v1.0
# which accompanies this distribution, and is available at
# http://www.opensource.org/licenses/cpl.php
# 
# =====================================================================
package LS::Authority;

use strict;
use warnings;

use vars qw($METHOD_PREFIX);


use SOAP::Lite;


use LS::ID;
use LS::Authority::WSDL::Constants;

use LS::Client;
use LS::Client::HTTP;
use LS::Client::SOAP;

use LS::Cache::Manager;

use base 'LS::Client';

#
# $METHOD_PREFIX -
#
$METHOD_PREFIX = '';





#
# new( $id ) - 	Creates a new interface to an LSID's authority based on the LSID
#		in parameter $id.
#
#		If the authority can not be located or some other error occurs in the 
#		resolution process, the package level error variable will contain any
#		details available.
#
#		The error message can be retrieved using the errorString method inherited
#		from LS::Client.
#
sub new {

	my $class = shift;
	my ($lsid) = @_;

	# Make sure LS::Locator is loaded
	require LS::Locator;

	# LS::Locator objects resolve LSIDs using all available methods (file, network, etc.)
	my $locator = LS::Locator->new();
	unless( UNIVERSAL::isa($locator, 'LS::Locator') ) {

		LS::Base->recordError( 'Unable to create LS::Locator object' );
		LS::Base->appendError( (LS::Locator->errorString() || 'No error message from LS::Locator') );

		LS::Base->addStackTrace( LS::Locator->getStackTrace() );

		return undef;
	}
	
	# Use the Locator to resolve the LSID in to an LS::Authority interface
	my $authority = $locator->resolveAuthority($lsid);
	unless (UNIVERSAL::isa($authority, 'LS::Authority')) {

		LS::Base->recordError( 'Unable to locate authority ' );
		LS::Base->appendError( ($locator->errorString || 'No error message from LS::Locator') );

		LS::Base->addStackTrace( $locator->getStackTrace() );

		return undef;
	}
	
	return $authority;
}


#
# new_by_hostname( $host, $port, $path, $username, $password ) 
#
#		- Creates a new interface to an LSID authority from the specified host information.
#
#		  The authority's credentials will be set to the specified username and password for 
#		  subsequent calls to the authority. 
#		
sub new_by_hostname {

	my $class = shift;
	my ($host, $port, $service_path, $username, $password) = @_;

	$class = bless {
		_host => $host,
		_port => $port,
		_path => ($service_path || '/authority/'),
		_cache=> LS::Cache::Manager->new(),
	}, $class;

	if($username || $password) {

		$class->credentials( LS::Client::Credentials->new(username=> $username,
								  password=> $password));
	}

	return $class;
}


#
# host - Returns the DNS hostname of the authority
#
sub host {
	
	return $_[0]->{'_host'};
}


#
# port - Returns the network port of the authority
#
sub port {
	
	return $_[0]->{'_port'};
}


#
# path - Returns the path to the authority.
#
#	 This method takes care to collapse multiple leading
#	 '/' characters in to a single '/'
#
sub path {
	
	my $path = $_[0]->{'_path'};
	$path =~ s|^/+||;
	
	return '/' . $path;
}


#
# authenticate - Deprecated. The credentials method, inherited from LS::Client
#		 should be used instead.
#
sub authenticate {
	
	die(__PACKAGE__ . ': This method is deprecated. Use the method LS::Client::Credentials instead.');

	my $self = shift;
	my %options = @_;
	
	$self->{'_credentials'} = LS::Client::Credentials->new();

	$self->{'_credentials'}->username($options{'username'});
	$self->{'_credentials'}->password($options{'password'});
}


#
# clean_clean( ) -
#
sub clean_cache {
	
	my $self = shift;
	
	$self->{'_cache'}->maintain_cache($self->{'_cache'}->get_time()) 
		if($self->{'_cache'});
}


#
# getResource( $lsid ) - This method resolves the specified LSID and invokes getAvailableServices
#			 to retreive the WSDL document containing the metadata and data service 
#			 endpoints. An LS::Resource object is returned to the caller which is then
#			 used to make the subsequent getMetadata / getData requests.
#
#			 If an error occurs, check the LS::Client::errorString method for more detail.
#
sub getResource {

	my ($self, $lsid) = @_;

	$lsid = LS::ID->new($lsid) 
		unless(UNIVERSAL::isa($lsid, 'LS::ID'));

	unless (UNIVERSAL::isa($lsid, 'LS::ID')) {

		$self->recordError( 'Invalid LSID' );
		$self->addStackTrace();
		die($self->errorDetails());
	}

	my $response = $self->getAvailableServices($lsid, @_);	

	return undef 
		unless($response);

	local $/ = undef;
	my $wsdl = $response->response();
	$wsdl = <$wsdl>;

	# Moved here to make it load only if the user requests it
	require LS::Resource;

	return LS::Resource->new($lsid, $self, $wsdl);
}


#
# get_resource( $lsid ) - Synonym for getResource.
#
sub get_resource {

	my $self = shift;
	return $self->getResource(@_);
}


#
# _soap_call - An internal method usedt to make SOAP calls.
#
#		Parameters are in the form of a hash:
#
#		method - The method of the SOAP service to invoke. This 
#			 is removed from the hash before passing the rest
#			 of it to the actual method of invocation.
#
#
#		The rest of the option hash is passed to the SOAP method
#		over the transport protocol. These are specified in the 
#		caller of _soap_call.
#
#		If an error occurs, the internal class error variable will be
#		set with the details. As always, it can be accessed via the
#		LS::Client::errorString method
#
sub _soap_call {

	my $self = shift;
	my (%options) = @_;

	my $method;
	unless( ($method = $options{'method'}) ) {

		$self->recordError( 'SOAP Method not specified' );
		$self->addStackTrace();
		die($self->errorDetails());
	}

	# Remove method from the options hash
	delete $options{'method'};

	my $host = $self->host();
	my $port = $self->port();
	my $path = $self->path();

	my $endpoint = $self->make_endpoint_url();

	# Get the SOAP interface or create it if we haven't already
	my $SOAPclient = $self->{'_soap'};

	$SOAPclient = $self->{'_soap'} = LS::Client::SOAP->new(url=> "http://$host:$port$path")
		unless($SOAPclient);

	unless(UNIVERSAL::isa($SOAPclient, 'LS::Client::SOAP')) {

		$self->recordError( 'Failed to create a LS::Client::SOAP' );
		$self->appendError( (LS::Client::SOAP->errorString() || 'No details available from SOAP client') );

		$self->addStackTrace( LS::Client::SOAP->getStackTrace() );

		die($self->errorDetails());
	}

	$SOAPclient->credentials($self->{'_credentials'}) 
		if($self->{'_credentials'});

	# Invoke $method with %options as its parameters
	my $response = $SOAPclient->$method(%options);

	unless($response) {

		$self->recordError( "LS::Client::SOAP::$method failed" );
		$self->appendError( ($SOAPclient->errorString() || ' No details available from SOAP client') );

		$self->addStackTrace( $SOAPclient->getStackTrace() );

		die($self->errorDetails());
	}

	return $response;
}


#
# LSID Resolution Service method
#

#
# getAvailableServices - Queries the authority service for the available operations for the given LSID. 
#			 The LSID may either be a string or an object of class LS::ID. The return value 
#			 is a string, which is a WSDL document describing the operations, or undef
#			 if an error occurs. Error messages can be checked by calling the errorString
#			 method.
#
#			 Note that this method returns raw WSDL. You probably want to
#			 call getResource instead, unless you really intend to parse
#			 the WSDL yourself.
#
sub getAvailableServices {

	my ($self, $lsid, %options) = @_;

	$lsid = LS::ID->new($lsid) 
		unless(UNIVERSAL::isa($lsid, 'LS::ID'));

	unless (UNIVERSAL::isa($lsid, 'LS::ID'))  {

		$self->recordError( 'Invalid LSID' );
		$self->addStackTrace();
		die($self->errorDetails());
	}
	
	my $wsdl;

	my $wsdl_resp = $self->{'_cache'}->lookupWSDL(lsid=> $lsid);
	
	# Return the cached WSDL if found
	return $wsdl_resp
		if($wsdl_resp);
	
	my $protocol = ${LS::Authority::WSDL::Constants::Protocols::HTTP};

	if(exists($options{'protocol'}) && defined($options{'protocol'})) {
	
		$protocol = $options{'protocol'};
		
		unless($protocol eq ${LS::Authority::WSDL::Constants::Protocols::HTTP} ||
			$protocol eq ${LS::Authority::WSDL::Constants::Protocols::SOAP}) {
		
			$self->recordError('Invalid protocol specified: ' . $options{'protocol'});
			$self->addStackTrace();
			die($self->errorDetails());	
		}
	}
	
	$protocol = uc($protocol);
	
	my $client_class = "LS::Client::$protocol";
	eval("use $client_class");
	
	die($@)
		if($@);
	
	my $url = $self->make_endpoint_url();
	
	my $client = $client_class->new(url=> $url);
	
	# The WSDL is not cached so go get it
	my $svc_rsp = $client->getAvailableServices(lsid=> $lsid, url=> $url);	
	
	return undef
		unless(UNIVERSAL::isa($svc_rsp, 'LS::Service::Response'));

	# This is important, the cache manager returns an LS::Service::Response
	# with the LS::Service::Response::response set to an IO::File handle
	# linked to a file from the cache
	$svc_rsp = $self->{'_cache'}->cacheWSDL(lsid=> $lsid, 
					        response=> $svc_rsp);

	return $svc_rsp;	
}


sub make_endpoint_url {

	my $self = shift;

	my $host = $self->host();
	my $port = $self->port();
	my $path = $self->path();

	my $endpoint;

	#
	# FIXME: This will probably go away
	#
	if($self->credentials()) {

		my $username = $self->credentials()->username();
		my $password = $self->credentials()->password();

		# Setting username/password inside an http URI scheme is not standards
		# compliant.
		$endpoint = "http://$username:$password\@$host:$port$path";
	}
	else {

		$endpoint = "http://$host:$port$path";
	}
	
	return $endpoint;
}

package LS::Authority::FAN;

use strict;
use warnings;

use base 'LS::Authority';

#
# Foreign Authority Publication Service methods
# NOTE: This is subject to change
#



#
# notifyForeignAuthority( $lsid, $authorityName ) -
#
sub notifyForeignAuthority {

	my ($self, $lsid, $authorityName) = @_;

	$lsid = LS::ID->new($lsid) 
		unless(UNIVERSAL::isa($lsid, 'LS::ID'));

	unless (UNIVERSAL::isa($lsid, 'LS::ID')) {

		$self->recordError( 'Invalid LSID' );
		$self->addStackTrace();
		die($self->errorDetails());
	}

	unless($authorityName) {

		$self->recordError( 'Missing authority name' );
		$self->addStackTrace();
		die($self->errorDetails());
	}

	my $svc_rsp = $self->_soap_call(method=> 'notifyForeignAuthority',
					lsid=> $lsid,
					authorityName=> $authorityName);

	return $svc_rsp->response() 
		if(UNIVERSAL::isa($svc_rsp, 'LS::Service::Response'));

	return undef;
}


#
# revokeNotificationForeignAuthority( $lsid, $authorityName ) -
#
sub revokeNotificationForeignAuthority {

	my ($self, $lsid, $authorityName) = @_;

	$lsid = LS::ID->new($lsid) 
		unless(UNIVERSAL::isa($lsid, 'LS::ID'));

	unless (UNIVERSAL::isa($lsid, 'LS::ID')) {

		$self->recordError( 'Invalid LSID' );
		$self->addStackTrace();
		die($self->errorDetails());
	}

	unless($authorityName) {

		$self->recordError( 'Missing authority name' );
		$self->addStackTrace();
		die($self->errorDetails());
	}

	my $svc_rsp = $self->_soap_call(method=> 'revokeNotificationForeignAuthority',
					lsid=> $lsid,
					authorityName=> $authorityName);

	return $svc_rsp->response()
		if(UNIVERSAL::isa($svc_rsp, 'LS::Service::Response'));

	return undef;
}


1;


__END__

=head1 NAME

LS::Authority - Authority service (client stub) for resources identified by LSIDs

=head1 SYNOPSIS

 use LS::ID;
 use LS::Locator;

 $lsid = LS::ID->new('urn:lsid:ncbi.nlm.nih.gov.lsid.biopathways.org:pubmed:12441807');

 $locator = LS::Locator->new;
 $authority = $locator->resolveAuthority($lsid);

 $auth_host = $authority->host();
 $auth_port = $authority->port();
 $auth_path = $authority->path();

 $resource = $authority->getResource($lsid);
 $data = $resource->getData();

=head1 DESCRIPTION

An object of the C<LS::Authority> class represents a web service
responsible for resolving LSIDs for a particular organization.
An authority service is located for a particular LSID by passing
the LSID to the C<resolveAuthority> method of an C<LS::Locator>
object. More information on LSIDs and authorities can be found at
L<http://www.omg.org/cgi-bin/doc?dtc/04-05-01>

=head1 CONSTRUCTORS

The following methods are used to construct a new C<LS::Authority> object:

=over

=item new ( $id )

This class method creates a new LS::Authority object and returns it.
The $id parameter may be an LSID in the form of a string or an LS::ID
object, in which case the authority governing the LSID is resolved using
a default LS::Locator, and the resulting authority is returned. $id
may also be a string of the form lsidauth:authority_id, in which case
the authority named by the authority ID is resolved using a default
LS::Locator, and returned.

Examples:
 
 $authority = LS::Authority->new('lsidauth:ncbi.nlm.nih.gov.lsid.biopathways.org') || warn("Error creating authority: ", &LS::Authority->errorString(), "\n");

 $authority = LS::Authority->new('urn:lsid:ncbi.nlm.nih.gov.lsid.biopathways.org:pubmed:12441807') || warn("Error creating authority: ", &LS::Authority->errorString(), "\n");
 
=item new_by_hostname ( $host, $port, $path )

This class method creates a new LS::Authority object and returns it. The
parameters are the hostname of the server on which the authority service
is located, the port number on the host, and the path to the service.

Most users will never need to call this constructor, as the usual way
to obtain an C<LS::Authority> object is to call the C<new> constructor
using an LSID or an authority ID, or to resolve the authority for an
LSID using the C<resolveAuthority> method on an C<LS::Locator> object.

Examples:

 $authority = LS::Authority->new('lsid.biopathways.org', '9090', 'authority');

=back

=head1 METHODS

=over

=item host ( )

Returns the hostname of the authority service.

=item port ( )

Returns the port number of the authority service.

=item path ( )

Returns the path of the authority service.

=item getAvailableServices( $lsid )

Queries the authority service for the available operations for the given
LSID. The LSID may either be a string or an object of class C<LS::ID>.
The return value is a string, which is a WSDL document describing the
operations, or C<undef> if an error occurs. Error messages can be
checked by calling the C<errorString> method.

Note that this method returns raw WSDL. You probably want to call
C<getResource> instead, unless you really intend to parse the WSDL
yourself.

Examples:

 $lsid = LS::ID->new('urn:lsid:ncbi.nlm.nih.gov.lsid.biopathways.org:pubmed:12441807');
 $wsdl = $authority->getAvailableServices($lsid);

 if ($wsdl) {
	print "WSDL for $lsid:\n";
	print $wsdl;
 }
 else {
 	print "Error getting operations for $lsid: ", $authority->errorString(), "\n";
 }

=item getResource ( $lsid )

Queries the authority service for the resource identified by the given
LSID. The LSID may either be a string or an object of class C<LS::ID>.
The return value is an object of class C<LS::Resource>, or C<undef>
if an error occurs. Error messages can be checked by calling the
C<errorString> method.

Examples:

 $lsid = LS::ID->new('urn:lsid:ncbi.nlm.nih.gov.lsid.biopathways.org:pubmed:12441807');
 $resource = $authority->get_resource($lsid);

 if ($resource) {
	print "The resource $lsid is valid\n";
 }
 else {
 	print "Error getting resource $lsid: ", $authority->errorString(), "\n";
 }


=item errorString ( )

This can be called either as a static method, a class method, or an
instance method. As a static or class method, it returns a description
of the last error that ocurred during a failed object creation. As an
instance method, it returns a description of the error that occurred in
the last call to an instance method on the object.

Examples:

 $authority = LS::Authority->new('lsidauth:ncbi.nlm.nih.gov.lsid.biopathways.org') || warn("Error creating authority: ", &LS::Authority::errorString(), "\n");
 
 $authority = LS::Authority->new('lsidauth:ncbi.nlm.nih.gov.lsid.biopathways.org') || warn("Error creating authority: ", &LS::Authority->errorString(), "\n");
 
 $services = $authority->getAvailableServices('urn:lsid:ncbi.nlm.nih.gov.lsid.biopathways.org:pubmed:12441807');
 
 unless ($services) {
	warn("Error getting authority WSDL: " . $authority->errorString() . "\n");
 }

=back

=head1 COPYRIGHT

Copyright (c) 2002,2003 IBM Corporation.
All rights reserved.   This program and the accompanying materials
are made available under the terms of the Common Public License v1.0
which accompanies this distribution, and is available at
L<http://www.opensource.org/licenses/cpl.php>

=cut

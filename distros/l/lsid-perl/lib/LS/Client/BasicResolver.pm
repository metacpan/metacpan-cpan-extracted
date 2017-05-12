# =====================================================================
# Copyright (c) 2002,2003 IBM Corporation 
# All rights reserved.   This program and the accompanying materials
# are made available under the terms of the Common Public License v1.0
# which accompanies this distribution, and is available at
# http://www.opensource.org/licenses/cpl.php
# 
# =====================================================================

package LS::Client::BasicResolver;

use strict;
use warnings;

use LS::ID;
use LS::Client;

use base 'LS::Client';



#
# new( %options ) - Creates a new instance of an LS::Client::BasicResolver
#
sub new {

	my ($self, %options) = @_;

	unless(ref $self) {

		$self = bless {

			authorities=> {},
			resources=> {},
		}, $self;

	}

	return $self;
}


#
# cacheAuthority( $lsid, [ $authority ] ) - Sets or retrieves an LS::Authority object for the given LSID.
#
#					    If the $authority parameter is left unspecified, the LS::Authority
#					    object for $lsid is returned.
#
#	Parameters - $lsid, Required. The LSID used to retrieve the cached authority.
#		     $authority, Optional. The LS::Authority object that will be cached for $lsid.
#
#	Returns - The LS::Authority object for the specified LSID.
#
sub cacheAuthority {

	my $self = shift;
	my $lsid = shift;

	unless(UNIVERSAL::isa($lsid, 'LS::ID')) {

		$self->recordError( 'LSID not specified' );
		$self->addStackTrace();
		die($self->errorDetails());
	}

	my $stringLSID = $lsid->as_string();

	@_ ? $self->{'authorities'}->{$stringLSID} = shift : return $self->{'authorities'}->{$stringLSID};
}


#
# cacheResource( $lsid ) - Sets or retrieves an LS::Resource object for the given LSID.
#
#	Parameters - $lsid, Required. The LSID used to lookup a particular LS::Resource.
#
#	Returns - An LS::Resource for the specified LSID.
#
sub cacheResource {

	my $self = shift;
	my $lsid = shift;

	unless(UNIVERSAL::isa($lsid, 'LS::ID') ) {

		$self->recordError( 'LSID not specified' );
		$self->addStackTrace();
		die($self->errorDetails());
	}

	my $stringLSID = $lsid->as_string();

	@_ ? $self->{'resources'}->{$stringLSID} = shift : return $self->{'resources'}->{$stringLSID};
}


#
# resolve( %options ) - Retrieves the authority WSDL for the specified LSID in the form
#			of an LS::Authority object.
#
#			This method performs the necessary steps to resolve an LSID if it is not
#			present in LS::Client::BasicResolver's cache. If the LSID has already
#			been resolved, then the cached copy of the LS::Authority object is
#			returned without querying any external resources.
#
#	Parameters - An options hash with the following keys:
#
#		lsid - Required. The LSID to resolve.
#
#	Returns - An LS::Authority for the specified LSID.
#
sub resolve {

	my ($self, %options) = @_;

	my $lsid = $options{'lsid'};

	unless(UNIVERSAL::isa($lsid, 'LS::ID')) {

		$lsid = LS::ID->new($lsid);

		unless($lsid) {

			$self->recordError( 'LSID not specified' );
			$self->addStackTrace();
			die($self->errorDetails());
		}
	}

	my $authority;

	unless( ($authority = $self->cacheAuthority($lsid)) ) {

		require LS::Locator;

		my $locator = LS::Locator->new();

		unless( ($authority = $locator->resolveAuthority($lsid)) ) {

			$self->recordError( "Unable to resolve authority." );
			$self->appendError( ($locator->errorString() || 'No details from LS::Locator') );

			$self->addStackTrace( $locator->getStackTrace() );

			die($self->errorDetails());
		}

		$self->cacheAuthority($lsid, $authority);
	}

	return $authority;
}


#
# getResource( %options ) - Retrieves an LS::Resource for the specified LSID.
#
#			    This method returns an LS::Resource object which can later be used to
#			    invoke LSID service routines such as getData and getMetadata.
#
#	Parameters - A hash of the following keys:
#
#			credentials - Optional. The LS::Client::Credentials object containing the 
#				      user's credentials for the authority.
#
#			protocol - Optional. The protocol (such as 'soap' or 'http') used for transport.
#
#			lsid - Required. The LSID that the LS::Resource will represent.
#
#
#	Returns - An LS::Resource object for the specified LSID
#
sub getResource {

	my ($self, %options) = @_;

	my $credentials = $options{'credentials'};

	my $lsid = $options{'lsid'};

	unless(UNIVERSAL::isa($lsid, 'LS::ID')) {

		$lsid = LS::ID->new($lsid);

		unless($lsid) {

			$self->recordError( 'LSID not specified' );
			$self->addStackTrace();

			die($self->errorDetails());
		}
	}

	my $authority;

	unless(($authority = $self->cacheAuthority($lsid)) ||
	       ($authority = $self->resolve(lsid=> $lsid)) ) {

		$self->appendError( 'Unable to resolve authority for LSID: ' . $lsid->as_string() );
		die($self->errorDetails());
	}

	# Authenticate to the authority
	if(UNIVERSAL::isa($credentials, 'LS::Client::Credentials')) {

		$authority->authenticate(credentials=> $credentials,
					 username=> $credentials->username(),
					 password=> $credentials->password());
	}

	my $resource;

	unless($resource = $authority->getResource($lsid)) { 

		$self->recordError( "Unable to retrieve resource for specified LSID: " . $lsid->as_string() );
		$self->appendError( ($authority->errorString() || 'No details from LS::Authority') );

		$self->addStackTrace( $authority->getStackTrace() );

		die($self->errorDetails());
	}

	$self->cacheResource($lsid, $resource);

	return $resource;
}


#
# _service_call( %options ) - A generic method to invoke the protocol specific client backend and deal
#			      with errors etc.
#
#	Parameters - A hash with the following keys:
#
#		method - Required. The name of the remote method to invoke.
#		
#		All other hash keys will be passed to getResource( )
#
#	Returns - undef in the case of an error or,
#		  The result of the remote method call.
#
sub _service_call {

	my ($self, %options) = @_;

	my $method = $options{'method'};

	unless($method) {

		$self->recordError( 'SOAP Method not specified' );
		$self->addStackTrace();
		die($self->errorDetails());
	}

	# Get the LS::Resource for the request
	my $resource = $self->getResource(%options);

	return undef 
		unless($resource);

	my $ret;
	unless( ($ret = $resource->$method())) {

		$self->recordError( "Error in method: $method." );
		$self->appendError( ($resource->errorString() || 'No details available from LS::Resource'));

		$self->addStackTrace( $resource->getStackTrace() );

		die($self->errorDetails());
	}

	return $ret;
}


#
# getMetadata( %options ) -
#
sub getMetadata {

	my ($self, %options) = @_;

	return $self->_service_call(method=> 'getMetadata',
				    %options);
}


#
# getMetadataSubset( %options ) -
#
sub getMetadataSubset {

	my ($self, %options) = @_;

	return $self->_service_call(method=> 'getMetadataSubset',
				    %options);
}


#
# getData( %options ) -
#
sub getData {

	my ($self, %options) = @_;

	return $self->_service_call(method=> 'getData',
				    %options);
}


#
# getDataByRange( %options ) -
#
sub getDataByRange {

	my ($self, %options) = @_;

	return $self->_service_call(method=> 'getDataByRange',
				    %options);
}


1;

__END__

=head1 NAME

LS::Client::BasicResolver - Simple Resolution Client for LSIDs

=head1 SYNOPSIS

 use LS::ID;
 use LS::Client::BasicResolver;

 $lsid = LS::ID->new('URN:LSID:pdb.org:PDB:112L:');

 $resolver = LS::Client::BasicResolver->new();

 $metadata = $resolver->getMetadata(lsid=> $lsid);

=head1 DESCRIPTION

LS::Client::BasicResolver provides a simple interface to resolve
LSIDs. This implementation is based on the standard found here
L<http://www.omg.org/cgi-bin/doc?dtc/04-05-01>.

=head1 CONSTRUCTORS

The following method is used to construct a new
C<LS::Client::BasicResolver> object:

=over

=item new 

This class method creates a new C<LS::Client::BasicResolver> object. 

Examples:

 $resolver = LS::Client::BasicResolver->new();

 if (!$resolver) {
 	print STDERR "Unable to create resolver object!";
 }

=back

=head1 METHODS

With the exception of C<cacheAuthority> and C<cacheResource>, all method
calls accept a hash of their parameters in the form: C<param_name=> value>


C<LS::Client::BasicResolver> supports the following methods:

=over

=item cacheAuthority ( $lsid, [ $authority ] )

Sets or retrieves an L<LS::Authority> object for the given LSID.

If the C<$authority> parameter is left unspecified, the L<LS::Authority>
object for C<$lsid> is returned.

=item cacheResource ( $lsid, [ $resource ] )

Sets or retrieves an L<LS::Resource> object for the given LSID.


=item resolve ( lsid=> $lsid )

Retrieves the authority WSDL for the specified LSID in the form
of an L<LS::Authority> object.

This method performs the necessary steps to resolve an LSID if it is not
present in L<LS::Client::BasicResolver>'s cache. If the LSID has already
been resolved, then the cached copy of the L<LS::Authority> object is
returned without querying any external resources.

=item getResource ( lsid=> $lsid, protocol=> $protocol, credentials=> $credentials )

The parameter C<lsid> must be specified while C<protocol> and C<credentials> are optional.
C<protocol> can be one of the following: C<$LS::Authority::WSDL::SOAP>,
C<$LS::Authority::WSDL::HTTP>, or C<$LS::Authority::WSDL::FTP>. The use of 
C<$LS::Authority::WSDL::FTP> is discouraged.

Retrieves an LS::Resource for the specified LSID.

This method returns an L<LS::Resource> object which can later be used to
invoke LSID service routines such as C<getData> and C<getMetadata>.

=item getData ( lsid=> $lsid )

Invokes the C<getData> service method (if available) and returns an
L<LS::Service::Response> object if successful. Otherwise, in the case of an
error or the service method not being implemented C<undef> is returned.

This is essentially:

 $resource = $resolver->getResource(lsid=> $lsid, %other_options);
 return $resource->getData();
 
See L<getResource> for additional parameters that can be passed to getData.

=item getDataByRange ( lsid=> $lsid )

Invokes C<getDataByRange>, not currently implemented.

=item getMetadata ( lsid=> $lsid )

Invokes the C<getMetadata> service method if available. The method returns
an L<LS::Service::Response> object if successful. In the case of an error
or the service method is not implemented, C<undef> is returned.

This is essentially:

 $resource = $resolver->getResource(lsid=> $lsid, %other_options);
 return $resource->getMetadata();
 
See L<getResource> for additional parameters that can be passed to getMetadata.

=item getMetadataSubset ( lsid=> $lsid )

Invokes C<getMetadataSubset>, not currently implemented.

=back

=head1 COPYRIGHT

Copyright (c) 2002,2003 IBM Corporation.
All rights reserved.   This program and the accompanying materials
are made available under the terms of the Common Public License v1.0
which accompanies this distribution, and is available at
L<http://www.opensource.org/licenses/cpl.php>


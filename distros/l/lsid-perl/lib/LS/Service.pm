# =====================================================================
# Copyright (c) 2002,2003 IBM Corporation 
# All rights reserved.   This program and the accompanying materials
# are made available under the terms of the Common Public License v1.0
# which accompanies this distribution, and is available at
# http://www.opensource.org/licenses/cpl.php
# 
# =====================================================================

# Backwards compatibility
use LS::Service::Fault;
use LS::Service::Response;
use LS::Service::Authority;
use LS::Service::Namespace;
use LS::Service::DataService;
use LS::Service::AdvancedDataService;

package LS::Service;
#
# Super-class of all LSID resolution services
#
# All protocol/encoding/transparent code should reside
# in this package.
#

use strict;
use warnings;

use vars qw( $SERVICE_METHODS );

use LS;
use LS::ID;


use base 'LS::Base';

#
# BEGIN( )
#
sub BEGIN {

	$SERVICE_METHODS = [
		'authorityService',
		'metadataService',
		'dataService',
	];
	
	LS::makeAccessorMethods($SERVICE_METHODS, __PACKAGE__);
}


#
# new( %options ) - 
#
sub new {
	
	my ($self, %options) = @_;

	unless (ref $self) {
		
		$self = bless {
			
			_auth_type=> undef,
			_auth_handler=> undef,

		}, $self;
		
	}

	$self->auth_type($options{'auth_type'});
	$self->auth_handler($options{'auth_handler'});


	return $self;
}


sub auth_type {
	
	my $self = shift;

	@_ ? $self->{'_auth_type'} = $_[0] : $self->{'_auth_type'};
}


sub auth_handler {
	
	my $self = shift;

	@_ ? $self->{'_auth_handler'} = $_[0] : $self->{'_auth_handler'};
}


# ACCESSOR
# authorityService( $authorityDispatch ) -
#

#
# authority_service - Synonym for authorityService.
#
sub authority_service {

	my $self = shift;
	return $self->authorityService(@_);
}

	
# ACCESSOR
# metadataService( $metadataDispatch ) -
#

#
# metadata_service - Synonym for metadataService.
#
sub metadata_service {

	my $self = shift;
	return $self->metadataService(@_);
}


# ACCESSOR
# dataService( $dataDispatch ) -
#

#
# data_service - Synonym for dataService.
#
sub data_service {

	my $self = shift;
	return $self->dataService(@_);
}

1;

__END__

=head1 NAME

LS::Service - Base class for authority, metadata, and data services 

=head1 SYNOPSIS

 # Import standard service framework
 use LS::Service::Authority;
 use LS::Service::DataService;
 use LS::Service::Fault;
 use LS::Service::Response;

 #
 # Use the LS::SOAP::Service subclass to create a SOAP based service
 # that executes in a standard HTTP / CGI environment
 #
 use LS::SOAP::Service transport=> 'HTTP::CGI';

 my $location = 'http://localhost:80';

 # Create the authority service
 my $authority = new LS::Service::Authority(name=> 'i3cauthority', 
					    getAvailableServices=> \&custom_service_ports,
					    authority=> 'i3c.org');
								 
 $authority->add_port(type=> $LS::Authority::WSDL::METADATA_PORT,
		      protocol=> $LS::Authority::WSDL::Constants::Protocols::SOAP,
		      location=> "$location/metadata/");

 # Add the metadata service with namespaces

 my $metadata = new LS::Service::DataService;
 $metadata->add_namespace(new LS::Service::Namespace(name=> 'formats', 
						     data_handler=> \&load_metadata));
			
 # Create a Service that contains an authority and associated metadata
 my $test_service = new LS::SOAP::Service;


 unless($use_auth) {

	$test_service->auth_type('Basic');
	$test_service->auth_handler(\&auth_me);
 } 

 $test_service->add_metadata_service($metadata);
 $test_service->add_authority_service($authority);

 $test_service->dispatch();
 
 # Authentication handler
 sub auth_me {
 
 	my ($user, $pass) = @_;
	
	return 1;
 }

 # Metadata handler
 sub load_metadata {

	my ($lsid, $accepted_formats) = @_;

	return LS::Service::Fault->fault('Invalid LSID') if(!$lsid);

	return new LS::Service::Response(type=> 'text/plain',
 					 response=> 'Metadata');
 }

 # Handler that customizes WSDL that describes how to invoke the authority
 sub custom_service_ports {
 
        my $wsdl = shift;

        $wsdl->add_port(type=> 'HTTPPort',
                        protocol=> $LS::Authority::WSDL::Constants::Protocols::HTTP,
                        location=> "$location/authority/");

        $wsdl->add_port(type=> 'SOAPPort',
                        protocol=> $LS::Authority::WSDL::Constants::Protocols::SOAP,
                        location=> "$location/authority/");

	return $wsdl;
 }

=head1 DESCRIPTION

This class provides a set of methods to easily create a full or partial.
LSID service Any combination of data, metadata or authority sevices are.
supported                                                              .

=head1 CONSTRUCTORS

=over

=item new ( %options )

Use this constructor to create a new service with the following %options
keys:

=over

 auth_type: The type of authentication. Currently unused.
 auth_handler: A boolean function that will authenticate the incoming connection.

=back

=back

=head1 METHODS

=over

=item authorityService ( $LS::Service::Authority )

Enables the authority component of an LSID service to this instance.

=item dataService ( ref $LS::Service::DataService )

Adds a data component to this LSID service instance.

=item metadataService ( ref $LS::Service::DataService )

Adds a metadata component to this LSID service instance.

=item dispatch()

Starts the service and begins accepting requests for resources.

=back

=head1 COPYRIGHT

Copyright (c) 2002,2003 IBM Corporation.
All rights reserved.   This program and the accompanying materials
are made available under the terms of the Common Public License v1.0
which accompanies this distribution, and is available at
L<http://www.opensource.org/licenses/cpl.php>

=cut
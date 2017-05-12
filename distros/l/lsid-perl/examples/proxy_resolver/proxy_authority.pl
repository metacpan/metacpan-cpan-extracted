#!/usr/bin/perl
# =====================================================================
# Copyright (c) 2002,2003 IBM Corporation 
# All rights reserved.   This program and the accompanying materials
# are made available under the terms of the Common Public License v1.0
# which accompanies this distribution, and is available at
# http://www.opensource.org/licenses/cpl.php
# 
# =====================================================================
use strict;
use warnings;

use Namespaces;

use LS::ID;

use LS::Service::Fault;
use LS::Service::Response;
use LS::Service::Authority;
use LS::Service::Namespace;
use LS::Service::DataService;
use LS::Service::AdvancedDataService;

use LS::HTTP::Service;

#
# The SOAP service will travel over HTTP to a CGI where
# all of the SOAP messages are decoded and passed up the SOAP
# stack until they reach this framework
#
use LS::SOAP::Service transport=> 'HTTP::CGI';



##############

my $location = 'http://';

if($ENV{'HTTP_HOST'} ) {

        $location .= $ENV{'HTTP_HOST'};
}
else {

	# Set this to the default hostname for this authority
        $location .= 'localhost:8080';
}

# Create the authority service
#
# name - The name of the authority
# authority - The hostname of the authority
# location - The URL to the authority 
#
my $authority = LS::Service::Authority->new(name=> 'LSIDProxy', 
					   authority=> 'proxy.lsid.biopathways.org', 
					   location=> $location);
#
# Add a Data and Metadata port for each protocol
#
# HTTP Protocol
#
$authority->addMetadataPort(endpoint=> "$location/authority/metadata",
			    protocol=> $LS::Authority::WSDL::Constants::Protocols::HTTP,
			   );

$authority->addDataPort(endpoint=> "$location/authority/data",
			protocol=> $LS::Authority::WSDL::Constants::Protocols::HTTP,
		       );


#
# SOAP Protocol
#
$authority->addMetadataPort(serviceName=> 'LSIDProxySOAP',
			    endpoint=> "$location/authority/metadata",
			    protocol=> $LS::Authority::WSDL::Constants::Protocols::SOAP,
			   );

$authority->addDataPort(serviceName=> 'LSIDProxySOAP',
			endpoint=> "$location/authority/data",
			protocol=> $LS::Authority::WSDL::Constants::Protocols::SOAP,
		       );

#
# Metadata Services
#
# Create an Advanced Metadata service that will accept _ALL_ namespaces for LSIDs
#
#
# get_data is a function reference that accepts an LSID as a parameter
#
my $metadata = LS::Service::AdvancedDataService->new();

# Add the mapping
$metadata->addNamespaceMappings( '.*'=> ':::resolver:::' );

$metadata->addNamespace(resolver->new());


my $service = new LS::SOAP::Service;

$service->metadataService($metadata);
$service->dataService($metadata);
$service->authorityService($authority);


#
# Create a HTTP service and instruct the SOAP service to
# accept HTTP queries
#
my $http_service = LS::HTTP::Service->new();
$http_service->dispatch_authority_to($authority);
$http_service->dispatch_data_to($metadata);
$http_service->dispatch_metadata_to($metadata);

$service->http_server($http_service);


#
# Dispatch to the service 
#
$service->dispatch();



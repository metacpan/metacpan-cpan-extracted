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

use i3cNamespaces;

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
my $authority = new LS::Service::Authority(name=> 'i3c', 
					   authority=> 'lsid.biopathways.org', 
					   location=> $location);
#
# Add two ports to the authority:
#
# 1. A SOAP Location for the metadata
#
# 2. A SOAP location for the data 
#
$authority->addMetadataPort(endpoint=> "$location/authority/metadata",
			    protocol=> $LS::Authority::WSDL::Constants::Protocols::HTTP,
			   );

$authority->addMetadataPort(serviceName=> 'i3cSOAP',
			    endpoint=> "$location/authority/metadata",
			    protocol=> $LS::Authority::WSDL::Constants::Protocols::SOAP,
			   );

$authority->addDataPort(serviceName=> 'i3cSOAP',
		        endpoint=> "$location/authority/data",
		  	protocol=> $LS::Authority::WSDL::Constants::Protocols::SOAP,
		       );

#
# Metadata Services
#
# Create a METADATA service that will serve 3 namespaces: formats, types, predicates
#
#
# get_data is a function reference that accepts an LSID as a parameter
#
my $metadata = LS::Service::DataService->new();

$metadata->add_namespace(formats->new());

$metadata->add_namespace(types->new());

$metadata->add_namespace(predicates->new());


#
# Service driver creation
#
# The service driver is what does all the baseline processing for the incoming 
# requests.
#
				
my $i3c_service = LS::SOAP::Service->new();


#
# Attach any additional services to the service driver
#
$i3c_service->metadata_service($metadata);
$i3c_service->authority_service($authority);


#
# Create a HTTP service and instruct the SOAP service to
# accept HTTP queries
#
my $i3c_http_service = new LS::HTTP::Service;
$i3c_http_service->dispatch_authority_to($authority);
$i3c_http_service->dispatch_metadata_to($metadata);

$i3c_service->http_server($i3c_http_service);


#
# Dispatch to the service 
#
$i3c_service->dispatch();



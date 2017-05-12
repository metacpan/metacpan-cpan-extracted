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

use hugoNamespaces;

use LS::ID;

use LS::Service::Fault;
use LS::Service::Response;
use LS::Service::Authority;
use LS::Service::Namespace;
use LS::Service::DataService;
use LS::Service::AdvancedDataService;

use LS::HTTP::Service;
use LS::RDF::SimpleDocument;

#
# The SOAP service will travel over HTTP to this mod_perl based
# authority where all of the SOAP messages are decoded and
# passed up the SOAP stack until they reach this framework
#
# UNTESTED: The package defaults to HTTP:CGI which works in most
#           cases.
#
#use LS::SOAP::Service transport=> 'HTTP::Apache';
use LS::SOAP::Service transport=> 'HTTP::CGI';

##############

my $location = 'http://';

if($ENV{'HTTP_HOST'} ) {

        $location .= $ENV{'HTTP_HOST'};
}
else {

	# Set this to the default hostname for the authority
        $location .= 'localhost:8080';
}

# Create the authority service
my $authority = LS::Service::Authority->new(
	name=> 'hugo', 
	authority=> 'gene.uc.ac.uk.lsid.biopathways.org', 
	location=> $location);
								 
#
# Add two ports to the authority:
#
# 1. A HTTP Location for the metadata
#
# 2. A SOAP location for the metadata 
#
$authority->addMetadataPort(serviceName=> 'hugoHTTP',
			    endpoint=> "$location/authority/metadata",
			    protocol=> $LS::Authority::WSDL::Constants::Protocols::HTTP,
			   );

$authority->addMetadataPort(endpoint=> "$location/authority/metadata",
			    protocol=> $LS::Authority::WSDL::Constants::Protocols::SOAP,
			   );

# Add the metadata service with namespaces

my $metadata = LS::Service::DataService->new();
$metadata->addNamespace(hugo->new());

$metadata->addNamespace(predicates->new());

my $hugo_service = LS::SOAP::Service->new();

$hugo_service->metadataService($metadata);
$hugo_service->authorityService($authority);


#
# Create a HTTP service and instruct the SOAP service to
# accept HTTP queries
#
my $hugo_http_service = LS::HTTP::Service->new();
$hugo_http_service->dispatch_authority_to($authority);
$hugo_http_service->dispatch_metadata_to($metadata);

$hugo_service->httpServer($hugo_http_service);


$hugo_service->dispatch();

__END__



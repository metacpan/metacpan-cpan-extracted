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

use URI;

use LS::ID;

use LS::Service::Fault;
use LS::Service::Response;
use LS::Service::Authority;
use LS::Service::Namespace;
use LS::Service::DataService;
use LS::Service::AdvancedDataService;

use LS::Authority::WSDL::Simple;
use LS::Authority::WSDL::Constants;

#
# The SOAP service will travel over HTTP to a CGI where
# all of the SOAP messages are decoded and passed up the SOAP
# stack until they reach this framework
#
use LS::SOAP::Service transport=> 'HTTP::CGI';


##############

my $location = 'http://localhost:8090';

# Create the authority service
#
# name - The name of the authority
# authority - The hostname of the authority
# location - The URL to the authority 
# getAvailabelServices - Function reference that will customize the data returned when 
#		       getAvailableServices is called.
#
my $authority = LS::Service::AuthorityService->new(name=> 'i3c', 
						  authority=> 'lsid.biopathways.org',
						  location=> $location,
						  getAvailableServices=> \&dynamic_ops);
#
# Add two ports to the authority:
#
# 1. A SOAP Location for the metadata
#
# 2. A SOAP location for the data 
#
my $port;

$port = LS::Authority::WSDL::Simple::MetadataPort->newMetadata(
	portName=> 'SOAPMetadata',
	endpoint=> "$location/authority/metadata",
	protocol=> $LS::Authority::WSDL::Constants::Protocols::SOAP,
  );

$authority->addPort(serviceName=> 'i3c', port=> $port);

$port = LS::Authority::WSDL::Simple::DataPort->newData(
	portName=> 'SOAPMetadata',
	endpoint=> "$location/authority/data",
	protocol=> $LS::Authority::WSDL::Constants::Protocols::SOAP,
  );
  
$authority->addPort(serviceName=> 'i3c', port=> $port);

#
# Metadata Services
#
# Create a METADATA service that will serve 3 namespaces: formats, types, predicates
#
#
# get_data is a function reference that accepts an LSID as a parameter
#
my $metadata = new LS::Service::DataService;

$metadata->add_namespace(new LS::Service::Namespace(name=> 'formats', 
						    data_handler=> \&load_metadata));

$metadata->add_namespace(new LS::Service::Namespace(name=> 'types', 
						    data_handler=> \&load_metadata));

$metadata->add_namespace(new LS::Service::Namespace(name=> 'predicates', 
						    data_handler=> \&load_metadata));


#
# Service driver creation
#
# The service driver is what does all of the processing for the incoming 
# requests.
#
				
my $i3c_service = LS::SOAP::Service->new();




#
# Attach any additional services to the service driver
#
$i3c_service->metadata_service($metadata);
$i3c_service->authority_service($authority);




#
# Dispatch to the service
#
$i3c_service->dispatch();

##############

#
# This is called when the SOAP getMetadata request comes in
#
sub load_metadata {
	
	my $lsid = shift;
		
	my $fname = $lsid->namespace() . '/' . $lsid->object() . '.metadata';

	return LS::Service::Fault->fault('Unknown LSID') 
		unless (-e $fname);

	#
	# This simple authority just reads in the data from flat files
	# organized in directories named after their namespace
	#
	my $inf;
	
	open($inf, "$fname");
	local $/ = undef;
	my $metadata= <$inf>;
	close($inf);
	
	return LS::Service::Fault->serverFault("Cannot load metadata", 600) 
		unless ($metadata);

	return $metadata;
}

#
# This adds a HTTP/CGI metadata port to the returned WSDL for each valid 
# LSID
#
sub dynamic_ops {

	my ($lsid, $wsdl) = @_;

	my $fname = $lsid->namespace() . '/' . $lsid->object() . '.metadata';

	return LS::Service::Fault->fault('Unknown LSID') 
		unless (-e $fname);

	#my $enc_uri = URI::Escape::uri_escape('urn:lsid:' . $lsid->nss);

	# 
	# $location is the location of the server
	# getMetaData is the path to the CGI that will return our results
	#
	my $port = LS::Authority::WSDL::Simple::MetadataPort->newMetadata(
		portName=> 'HTTPMetadata',
		endpoint=> "$location/authority/metadata",
		protocol=> $LS::Authority::WSDL::Constants::Protocols::HTTP,
	);
	
	$wsdl->addPort(serviceName=> 'i3cHTTP', port=> $port);

	return $wsdl;
}

__END__

# ====================================================================
# Copyright (c) 2002,2003 IBM Corporation 
# All rights reserved.   This program and the accompanying materials
# are made available under the terms of the Common Public License v1.0
# which accompanies this distribution, and is available at
# http://www.opensource.org/licenses/cpl.php
# 
# =====================================================================
package LS::Authority::WSDL::Simple;

use strict;
use warnings;

use vars qw( 	$METHODS
		$METADATA_PREFIX 
		$METADATA_SUBSET_PREFIX 
		$DATA_PREFIX
	   );

use URI;

use LS;

use LS::Authority::Mappings;

use LS::Authority::WSDL;
use LS::Authority::WSDL::Location;
use LS::Authority::WSDL::Constants;


use base 'LS::Authority::WSDL';


#
# Constants for creating built-in bindings
#
$METADATA_PREFIX = 'LSIDMetadata';
$METADATA_SUBSET_PREFIX = "${METADATA_PREFIX}Subset";

$DATA_PREFIX = 'LSIDData';

sub BEGIN {

	$METHODS = [
		'defaultServiceName',
		'authority',
		
		'metadataLocations',
		'dataLocations',
		'unknownLocations',
	];
	
	LS::makeAccessorMethods($METHODS, __PACKAGE__);
}



#
# new( %options ) -
#
sub new {
	
	my $self = shift;
	my %params = @_;

	$self = $self->SUPER::new(@_);

	$self->lsid($params{'lsid'})
		if($params{'lsid'});
	
	$self->authority($params{'authority'})
		if($params{'authority'});
	

	$self->metadataLocations( {} );
	$self->dataLocations( {} );
	$self->unknownLocations( {} );

	#
	# Default imports
	#
	$self->add_xml_import(location=> 'LSIDDataServiceHTTPBindings.wsdl',
			      namespace=> 'http://www.omg.org/LSID/2003/DataServiceHTTPBindings');

	$self->add_xml_import(location=> 'LSIDDataServiceSOAPBindings.wsdl',
			      namespace=> 'http://www.omg.org/LSID/2003/DataServiceSOAPBindings');


	#
	# Default namespaces
	#
        $self->add_namespace(prefix=>'dhb',
                             uri=>'http://www.omg.org/LSID/2003/DataServiceHTTPBindings');

        $self->add_namespace(prefix=>'dsb',
                             uri=>'http://www.omg.org/LSID/2003/DataServiceSOAPBindings');
	return $self;
}


#
# lsid( $lsid ) -
#
sub lsid {

	my ($self, $lsid) = @_;

	if ($lsid) {
		
		$lsid = LS::ID->new($lsid);
			
		unless ($lsid) {
			
			$self->recordError("Invalid LSID");
			$self->addStackTrace();
			
			return undef;
		}

		$self->{__PACKAGE__ . '__lsid'} = $lsid;
	}
	
	return $self->{__PACKAGE__ . '__lsid'};
}


#
# defaultServiceName( [ $name ] ) 
# 	Returns the name of the first service (the default service)
#


#
# addPort( %options )
#
#	Adds a LS::Authority::WSDL::Port to the specified service
#
sub addPort {

	my ($self, %options) = @_;

	unless($options{'port'} &&
	       $options{'serviceName'}) {

		$self->recordError('Missing parameters');
		$self->addStackTrace();
		
		return undef;
	}

	unless(UNIVERSAL::isa($options{'port'}, 'LS::Authority::WSDL::Port')) {

		$self->recordError('Parameter \'port\' is not an LS::Authority::WSDL::Port');
		$self->addStackTrace();
		
		return undef;
	}

	# Attempt to locate the specified service. If it does not exist,
	# create the service object and add it to the array.
	my $svc = $self->getService($options{'serviceName'});

	unless($svc) {

		$svc = LS::Authority::WSDL::ServiceDefinition->new(name=> $options{'serviceName'});
		$self->add_service($svc);
	}

	return $svc->add_port($options{'port'});
}


#
# getMetadataLocations( $serviceName )
#
#	Retreives the metadata ports for the specified service.
#	If the service name is not specified, the ports of the first 
#	service will be returned.
#
sub getMetadataLocations {

	my $self = shift;
	my $serviceName = shift;

	$serviceName = $self->defaultServiceName()
		unless($serviceName);

	return $self->metadataLocations()->{ $serviceName };
}


#
# getAllMetadataLocations( )
#
# 	Retreives all known metadata locations for this WSDL
#
sub getAllMetadataLocations {

	my $self = shift;
	
	my $locations = [];
	# TODO: Finish this function
	return $locations;
}


#
# getDataLocations( $serviceName )
#
#	Retrieves the data ports for the specified service.
#	If the service name is not specified, the ports of the 
#	first service will be returned.
#
sub getDataLocations {

	my $self = shift;
	my $serviceName = shift;
	
	$serviceName = $self->defaultServiceName()
		unless($serviceName);

	return $self->dataLocations()->{ $serviceName };
}


#
# getAllDataLocations( )
#
# 	Retreives all known data locations for this WSDL
#
sub getAllDataLocations {

	my $self = shift;
	
	my $locations = [];
	# TODO: Finish this function	
	return $locations;
}


#
# to_xml( ) - Returns the WSDL data structure as a WSDL XML document
#
sub to_xml {

	my $self = shift;

	$self->targetNamespace('http://' . $self->authority() . '/availableServices?' . ($self->lsid() ? $self->lsid()->as_string() : ''));

	return $self->SUPER::to_xml();
}


#
# from_xml( $xml ) - Builds on object based on the XML parameter
#
sub from_xml {

	my $self = shift->new();
	
	$self = $self->SUPER::from_xml(@_);
	unless(UNIVERSAL::isa($self, 'LS::Authority::WSDL::Simple')) {
		return undef;
	}

	# Parse the target namespace for the LSID and authority
	if ($self->targetNamespace() =~ m|^http://([^/]*)/availableServices\?(.*)$|) {
	
		$self->authority($1);
		$self->lsid($2);
	}
	
	# Get the first service's name and use that as a default
	$self->defaultServiceName((values(%{ $self->services() }))[0]->name())
		if(scalar(values(%{ $self->services() })) > 0);


	# Build the metadata and data location structures
	$self->buildLocations();
	
	return $self;
}


sub buildLocations {

	my $self = shift;
	
	my $metadataLocations = $self->metadataLocations();
	my $dataLocations = $self->dataLocations();
	my $unknownLocations = $self->unknownLocations();
	
	foreach my $service (values(%{ $self->services() })) {

		# Initialize the location hashes for this service if necessary
		$metadataLocations->{ $service->name() } = []
			unless(UNIVERSAL::isa($metadataLocations->{ $service->name() }, 'ARRAY'));
			
		$dataLocations->{ $service->name() } = []
			unless(UNIVERSAL::isa($dataLocations->{ $service->name() }, 'ARRAY'));
			
		$unknownLocations->{ $service->name() } = []
			unless(UNIVERSAL::isa($unknownLocations->{ $service->name() }, 'ARRAY'));
			
		foreach my $port (@{ $service->ports() }) {
			
			my $binding = $port->binding();
			my $protocol = $port->implementation()->protocol();
			
			my $location;

			# Figure out which kind of port this is: Data or Metadata
			if($binding =~ /$LS::Authority::WSDL::Simple::METADATA_PREFIX.*/) {

				$location = $metadataLocations->{ $service->name() };
			}
			elsif($binding =~ /$LS::Authority::WSDL::Simple::DATA_PREFIX.*/) {

				$location = $dataLocations->{ $service->name() };
			}
			else {

				$location = $unknownLocations->{ $service->name() };
			}

			my $method = '';
			my $url = $port->implementation->get_attr('location');
			
			if ($protocol eq ${LS::Authority::WSDL::Constants::Protocols::HTTP}) { 

				# Setup the METHOD item for HTTP
				$method = (uc($port->implementation->get_attr('verb')) || 
					   ${LS::Authority::WSDL::Constants::Protocols::HTTP_GET});
			}
			elsif ($protocol eq ${LS::Authority::WSDL::Constants::Protocols::SOAP}) {

				# Nothing specific for SOAP
			}
			elsif (0 && $protocol eq ${LS::Authority::WSDL::Constants::Protocols::FTP}) {
				# Disabled code block				
				# my $out_imp = $op->output();
				my $out_imp;
				next unless $protocol eq $out_imp->protocol();
				next unless 'get' eq $out_imp->name();

				my $path = $out_imp->get_attr('filepath');
				$path = '/' . $path unless($path =~ m|^/|);

				my $server = $port->implementation()->get_attr('server');
				$server =~ s|/+$||;

				my $username = $port->implementation()->get_attr('user');
				my $password = $port->implementation()->get_attr('password');

				$url = 'ftp://' . (($username || $password) ? ($username. ':' . $password . '@') : '') . $server . $path;

				push @{ $location },
					LS::Authority::WSDL::Location->new(
						protocol => $protocol,
						url => $url
					);
				
			}
			else {
			
				# TODO: Error message for unknown protocols?
			}


			# Store the new LS::Authority::WSDL::Location in the
			# previously determined metadata, data or unknown location hash
			push @{ $location  }, 
				LS::Authority::WSDL::Location->new(
					protocol=> $protocol,
					url=> $url,
					binding=> $binding,
					name=> $port->name(),
					parentName=> $service->name(),
					method=> $method,
				);

			
		} # End ports processing
	} # End services processing	
}


package LS::Authority::WSDL::Simple::MetadataPort;

use strict;
use warnings;

use LS::Authority::WSDL;
use LS::Authority::WSDL::Constants;


#
# new( %options ) - 
#
sub new {

	shift; # Throw away

	my (%options) = @_;

	my $portName	= $options{'portName'};

	my $binding	= $options{'binding'};
	my $protocol	= lc($options{'protocol'});
	my $endpoint	= $options{'endpoint'};

	# Validate the parameters

	my $port_impl = LS::Authority::WSDL::Implementation->new(
		protocol => $protocol,
		name => 'address',
		attr => {
			location => $endpoint,
		}
	);

	# FIXME: Error strings!
	return undef unless($port_impl);

	my $port = LS::Authority::WSDL::Port->new(
		name=> 			$portName,
		binding=> 		$binding,
		implementation=> 	$port_impl
	);

	return $port;
}


#
# newMetadata( %options ) -
#
sub newMetadata {

	shift;

	my (%options) = @_;

	my $binding = ${LS::Authority::WSDL::Simple::METADATA_PREFIX} . uc($options{'protocol'}) . 'Binding';

	$binding = LS::Authority::WSDL::Mappings->bindingToPrefix($binding) . ":$binding";

	return LS::Authority::WSDL::Simple::MetadataPort->new(
				%options,
				binding=> $binding
	);
}


#
# newMetadataSubset( %options ) -
#
sub newMetadataSubset {

	shift;

	my (%options) = @_;

	my $binding = ${LS::Authority::WSDL::Simple::METADATA_SUBSET_PREFIX} . uc($options{'protocol'}) . 'Binding'; 

	$binding = LS::Authority::WSDL::Mappings->bindingToPrefix($binding) . ":$binding";

	return LS::Authority::WSDL::Simple::MetadataPort->new(
				%options,
				binding=> $binding
	);
}


#
# newMetadataDirect( %options ) -
#
sub newMetadataDirect {

	shift;

	my (%options) = @_;

	$options{'protocol'} = ${LS::Authority::WSDL::Protocols::HTTP};

	my $binding = ${LS::Authority::WSDL::Simple::METADATA_PREFIX} . uc($options{'protocol'}) . 'BindingDirect'; 

	$binding = LS::Authority::WSDL::Mappings->bindingToPrefix($binding) . ":$binding";

	return LS::Authority::WSDL::Simple::MetadataPort->new(
				%options,
				binding=> $binding
	);
}


#
# newMetadataSubsetDirect( %options ) -
#
sub newMetadataSubsetDirect {

	shift;

	my (%options) = @_;

	$options{'protocol'} = ${LS::Authority::WSDL::Protocols::HTTP};

	my $binding = ${LS::Authority::WSDL::Simple::METADATA_SUBSET_PREFIX} . uc($options{'protocol'}) . 'BindingDirect'; 

	$binding = LS::Authority::WSDL::Mappings->bindingToPrefix($binding) . ":$binding";

	return LS::Authority::WSDL::Simple::MetadataPort->new(
				%options,
				binding=> $binding
	);
}




package LS::Authority::WSDL::Simple::DataPort;

use strict;
use warnings;

use LS::Authority::WSDL;
use LS::Authority::WSDL::Constants;


#
# new( %options ) -
#
sub new {

	shift;

	my (%options) = @_;

	my $portName	= $options{'portName'};

	my $binding	= $options{'binding'};
	my $protocol	= lc $options{'protocol'};
	my $endpoint	= $options{'endpoint'};

	# Validate the parameters

	my $port_impl;

	if($protocol eq ${LS::Authority::WSDL::Constants::Protocols::FTP}) {

		my $username = $options{'username'};
		my $password = $options{'password'};

		$port_impl = LS::Authority::WSDL::Implementation->new(
				protocol => $protocol,
				name => 'location',
				attr => {
					server => $endpoint,
					$username ? (user => $username) : (),
					$password ? (password => $password) : (),
				}
		);
	}
	else {

		$port_impl = LS::Authority::WSDL::Implementation->new(
				protocol => $protocol,
				name => 'address',
				attr => {
					location => $endpoint,
				}
		);
	}

	# FIXME: Error strings!
	return undef unless($port_impl);

	my $port = LS::Authority::WSDL::Port->new(
			name=> 			$portName,
			binding=> 		$binding,
			implementation=> 	$port_impl
	);

	return $port;
}


#
# newData( %options ) -
#
sub newData {

	shift;

	my (%options) = @_;

	my $binding = ${LS::Authority::WSDL::Simple::DATA_PREFIX} . uc($options{'protocol'}) . 'Binding';

	$binding = LS::Authority::WSDL::Mappings->bindingToPrefix($binding) . ":$binding";

	return LS::Authority::WSDL::Simple::DataPort->new(
				%options,
				binding=> $binding
	);
}


#
# newDataByRange( %options ) -
#
sub newDataByRange {

	shift;

	my (%options) = @_;

	my $binding = ${LS::Authority::WSDL::Simple::DATA_PREFIX} . uc($options{'protocol'}) . 'Binding';

	$binding = LS::Authority::WSDL::Mappings->bindingToPrefix($binding) . ":$binding";

	return LS::Authority::WSDL::Simple::DataPort->new(
				%options,
				binding=> $binding
	);
}


#
# newDataDirect( %options ) -
#
sub newDataDirect {

	shift;

	my (%options) = @_;

	$options{'protocol'} = ${LS::Authority::WSDL::Protocols::HTTP};

	my $binding = ${LS::Authority::WSDL::Simple::DATA_PREFIX} . uc($options{'protocol'}) . 'BindingDirect';

	$binding = LS::Authority::WSDL::Mappings->bindingToPrefix($binding) . ":$binding";

	return LS::Authority::WSDL::Simple::DataPort->new(
				%options,
				binding=> $binding
	);
}


#
# newDataByRangeDirect( %options ) -
#
sub newDataByRangeDirect {

	shift;

	my (%options) = @_;

	$options{'protocol'} = ${LS::Authority::WSDL::Protocols::HTTP};

	my $binding = ${LS::Authority::WSDL::Simple::DATA_PREFIX} . uc($options{'protocol'}) . 'BindingDirect';

	$binding = LS::Authority::WSDL::Mappings->bindingToPrefix($binding) . ":$binding";

	return LS::Authority::WSDL::Simple::DataPort->new(
				%options,
				binding=> $binding
	);
}



1;

__END__

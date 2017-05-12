# =====================================================================
# Copyright (c) 2002,2003 IBM Corporation 
# All rights reserved.   This program and the accompanying materials
# are made available under the terms of the Common Public License v1.0
# which accompanies this distribution, and is available at
# http://www.opensource.org/licenses/cpl.php
# 
# =====================================================================
package LS::Resource;

use strict;
use warnings;

use vars qw( @ISA );

use URI;

use LS;
use LS::ID;

use LS::Authority::WSDL::Constants;

use base 'LS::Base';



#
# new( $lsid, $authority, $wsdl ) -
#
sub new {
	my ($class, $lsid, $authority, $wsdl) = @_;

	$lsid = LS::ID->new($lsid) unless(UNIVERSAL::isa($lsid, 'LS::ID'));

	unless ($lsid) {

		LS::Resource->recordError( 'Invalid LSID' );
		LS::Resource->addStackTrace();

		return undef;
	}

	if (!$authority) {

		# Moved here, no need to have it global
		require LS::Locator;

		my $locator = LS::Locator->new();

		unless($locator) {

			LS::Resource->recordError( 'Unable to create LS::Locator object' );
			LS::Resource->appendError( (LS::Locator->errorString() || 'No error message from LS::Locator') );

			LS::Resource->addStackTrace( LS::Locator->getStackTrace() );

			return undef;
		}
		$authority = $locator->resolveAuthority($lsid);

		unless ($authority) {

			LS::Resource->recordError( 'Authority not found' );
			LS::Resource->appendError( ($locator->errorString() || 'No error message from LS::Locator') );

			return undef;
		}
	}

	if(!$wsdl) {

		my $wsdl = $authority->getAvailableServices($lsid);

		unless ($wsdl) {

			LS::Resource->recordError( 'The authority failed to get available services for the resource.');
			LS::Resource->appendError( ($authority->errorString() || 'No error message from LS::Authority') );

			return undef;
		}
	}

	require LS::Cache::Manager;

	my $self = bless {
		_lsid=> $lsid,
		_authority=> $authority,
		_wsdl=> $wsdl,

		_default_service=> undef,	# Name of the "default" service

		_services=> [ ], 		# Arrayref of service names
		_metadata_locations=> {},
		_data_locations=> {},

		_rdf_model=> undef,
		_cache=> LS::Cache::Manager->new(),
	}, $class;

	$self->_parse_wsdl($wsdl) || return;

	$self->recordError( undef );

	return $self;
}


sub authority {
	return $_[0]->{'_authority'};
}

sub lsid {
	return $_[0]->{'_lsid'};
}

sub wsdl {
	return $_[0]->{'_wsdl'};
}

sub services {
	return $_[0]->{'_services'};
}





# Deprecated
sub get_data_locations {

	my $self = shift;
	return $self->getDefaultDataLocations();
}

# Deprecated
sub get_metadata_locations {

	my $self = shift;
	return $self->getDefaultMetadataLocations();
}


#
# getDefaultDataLocations( ) - 
#
sub getDefaultDataLocations {

	my $self = shift;
	return $self->{'_data_locations'}->{ $self->{'_default_service'} };
}

#
# getDefaultMetadataLocations( ) -
#
sub getDefaultMetadataLocations {

	my $self = shift;
	return $self->{'_metadata_locations'}->{ $self->{'_default_service'} };
}

#
# getDataLocations( $serviceName ) -
#
sub getDataLocations {

	my ($self, $serviceName) = @_;
	$serviceName ? return $self->{'_data_locations'}->{ $serviceName } : return $self->{'_data_locations'};
}

#
# getMetadataLocations( $serviceName ) -
#
sub getMetadataLocations {

	my ($self, $serviceName) = @_;
	$serviceName ? return $self->{'_metadata_locations'}->{ $serviceName } : return $self->{'_metadata_locations'};
}


#
# Access to SINGLE locations
#
# getMetadataLocation( %options ) - 
#
sub getMetadataLocation {

	my $self = shift;
	my %options = @_;

	my $serviceName	= $options{'serviceName'};

	my $metadataLocation;

	#
	# Look in the default service for a metadata location, preferring 
	# one with the properties specified.
	#
	if($serviceName) {

		$options{'locations'} = $self->getMetadataLocations()->{ $serviceName };
		$metadataLocation = $self->findLocation( %options );
	}
	else {

		foreach $serviceName (keys( %{ $self->getMetadataLocations() } ) ) { 

			$options{'locations'} = $self->getMetadataLocations()->{ $serviceName };

			$metadataLocation = $self->findLocation( %options );
		}
	}

	return $metadataLocation;
}


#
# get_metadata_location( %options ) - Synonym for getMetadataLocation.
#
sub get_metadata_location {

	my $self = shift;
	return $self->getMetadataLocation( @_ );
}


#
# getDataLocation( %options ) - 
#
sub getDataLocation {

	my $self = shift;
	my (%options) = @_;

	my $serviceName	= $options{'serviceName'};

	my $dataLocation;

	if($serviceName) {

		$options{'locations'} = $self->getDataLocations()->{ $serviceName };
		$dataLocation = $self->findLocation( %options );
	}
	else {

		foreach $serviceName (keys( %{ $self->getDataLocations() } ) ) { 

			$options{'locations'} = $self->getDataLocations()->{ $serviceName };

			$dataLocation = $self->findLocation( %options );
		}
	}

	return $dataLocation;
}


#
# get_data_location( %options ) - Synonym for getDataLocation( ).
#
sub get_data_location {

	my $self = shift;
	return $self->getDataLocation( @_ );
}


#
# findLocation( %options ) -
#
sub findLocation {

	my $self = shift;

	my %options = @_;

	my $protocol 	= $options{'protocol'} || 'http';
	my $method 	= $options{'method'};

	my $locations   = $options{'locations'};

	unless($locations) {

		$self->recordError('Missing parameter \'locations\'');
		$self->addStackTrace();

		return undef;
	}

	my $foundLocation;
	foreach my $location (@{ $locations } ) {

		$foundLocation = $location;
		next unless $location->protocol() eq $protocol;

		if ($protocol eq ${LS::Authority::WSDL::Constants::Protocols::HTTP} && $method) {

			return $location if $location->method() eq $method;				
		}
		else {
			return $location;
		}

	} # end foreach for locations

	return $foundLocation;
}


#
# getMetadata( %options ) -
#
sub getMetadata {

	my ($self, %options) = @_;

	my $format = ($options{'format'} || 'application/rdf+xml');

	my $location	= $options{'location'};

	$location = $self->getMetadataLocation( %options )
		unless($location);
						    
	unless ($location) {

		$self->recordError( 'No metadata locations found' );
		$self->addStackTrace();

		return undef;
	}

	my $url = URI->new($location->url());
	
	my $metadata_rsp = $self->{'_cache'}->lookupMetadata(lsid=> $self->lsid(), 
							     portName=> $location->name(),
							     serviceName=> $location->parentName());

	unless($metadata_rsp) {

		my $base_url = $location->url();
		my $protocol = uc $location->protocol();


		my $class = 'LS::Client::' . $protocol;
		eval("require $class");

		my $client = $class->new(url=> $base_url);

		unless($client) {

			$self->recordError( "Unable to initialize client object of type $class." );
			$self->addStackTrace();

			return undef;
		}

		$metadata_rsp  = $client->getMetadata(url=> $base_url,
						      lsid=> $self->lsid(),
						      acceptedFormats=> $format);

		unless(UNIVERSAL::isa($metadata_rsp, 'LS::Service::Response')) {

			$self->recordError( "Client object: $client invoked getMetadata, " .
					    "did not return LS::Service::Response.\n");
			$self->appendError( ($client->errorString() || 'No client error string') );

			$self->addStackTrace();

			return undef;
		}

		$metadata_rsp = $self->{'_cache'}->cacheMetadata(lsid=> $self->lsid(),
							         response=> $metadata_rsp,
							         portName=> $location->name(),
							         serviceName=> $location->parentName());
	}
	
	return $metadata_rsp;
}


#
# getMetadataSubset( %options ) -
#
sub getMetadataSubset {

	my ($self, $destination, $protocol, $method) = @_;

	return undef;
}


#
# getData( %options ) -
#
sub getData {

	my ($self, %options) = @_;

	my $location = $options{'location'};

	$location = $self->getDataLocation( %options )
		unless($location);

	unless ($location) {

		$self->recordError( 'No data locations found' );
		$self->addStackTrace();

		return undef;
	}

	my $data_rsp = $self->{'_cache'}->lookupData(lsid=> $self->lsid());
	
	unless ($data_rsp) {
	
		my $base_url = $location->url();
		my $protocol = uc $location->protocol();

		my $class = 'LS::Client::' . $protocol;
		eval("require $class");

		my $client = $class->new(url=> $base_url);

		unless($client) {

			$self->recordError( "Unable to initialize client object of type $class." );
			$self->addStackTrace();

			return undef;
		}

		$data_rsp = $client->getData(url=> $base_url,
					     lsid=> $self->lsid());

		unless(UNIVERSAL::isa($data_rsp, 'LS::Service::Response')) {

			$self->recordError( "Client object: $client invoked getData, " .
					    "did not return LS::Service::Response." );

			$self->appendError( ($client->errorString() || 'No client error string') );
			$self->addStackTrace();

			return undef;
		}
	
		$data_rsp = $self->{'_cache'}->cacheData(lsid=> $self->lsid(),
							 response=> $data_rsp);
	}
	
	return $data_rsp;
}


#
# getDataByRange( %options ) -
#
sub getDataByRange {

	my ($self, %options) = @_;

	my $location = $options{'location'};

	my $start = $options{'start'};
	my $length = $options{'length'};

	$location = $self->getDataLocation( %options ) 
		unless($location);

	unless ($location) {

		$self->recordError( 'No data locations found' );
		$self->addStackTrace();

		return undef;
	}

	my $data_rsp = $self->{'_cache'}->lookupData(lsid=> $self->lsid(), 
					             start=> $start, 
						     length=> $length);
	
	unless ($data_rsp) {
	
		my $base_url = $location->url();
		my $protocol = uc $location->protocol();

		my $class = 'LS::Client::' . $protocol;
		eval("require $class;");

		my $client = $class->new(url=> $base_url);

		unless($client) {

			$self->recordError( "Unable to initialize client object of type $class." );
			$self->addStackTrace();

			return undef;
		}

		$data_rsp = $client->getDataByRange(url=> $base_url,
						   lsid=> $self->lsid(),
						   start=> $start,
						   length=> $length);

		unless(UNIVERSAL::isa($data_rsp, 'LS::Service::Response')) {

			$self->recordError( "Client object: $client invoked getDataByRange, " .
					    "did not return LS::Service::Response");
			$self->appendErorr( ($client->errorString() || 'No client error string') );

			$self->addStackTrace();

			return undef;
		}
		
		$data_rsp = $self->{'_cache'}->cacheData(lsid=> $self->lsid(), 
						         response=> $data_rsp,
						         start=> $start,
						         length=> $length);
		
	}
	
	return $data_rsp;
}

#
# _parse_wsdl ($xml ) -
#
sub _parse_wsdl {

	my ($self, $xml) = @_;

	require LS::Authority::WSDL::Simple;

	my $wsdl = LS::Authority::WSDL::Simple->from_xml($xml);
	
	unless(UNIVERSAL::isa($wsdl, 'LS::Authority::WSDL::Simple')) {
	
		return undef;
	}
	
	$self->{'_wsdl'} = $wsdl;
	$self->{'_default_service'} = $wsdl->defaultServiceName();

	# Build the service name array, the metadata and data location structures
	foreach my $svc (values(%{ $wsdl->services() }) ) {

		push @{ $self->{'_services'} }, $svc->name();

		$self->{'_metadata_locations'}->{ $svc->name() } = $wsdl->getMetadataLocations($svc->name());	
		$self->{'_data_locations'}->{ $svc->name() } = $wsdl->getDataLocations($svc->name());	
	}

	return $self;
}


sub _escape {
	my $string = $_[0];
	
	$string =~ s/&/&amp;/g;
	$string =~ s/</&lt;/g;
	$string =~ s/>/&gt;/g;

	return $string;
}




#
#
# WARNING: The following my be deprecated in future releases
#
#

sub data_locations {
	my $self = shift;

	return $self->get_data_locations;
}

sub data_location {
	my $self = shift;

	return $self->get_data_location(@_);	
}

sub get_metadata {

	my $self = shift;

	return $self->getMetadata(@_);
}

sub get_data {

	my $self = shift;

	return $self->getData(@_);
}

sub _get_rdf {
	my $self = shift;
	
	my $rdf_string = $self->get_metadata() || return;

	require RDF::Core::Model;
	require RDF::Core::Model::Parser;
	require RDF::Core::Storage::Memory;
	require RDF::Core::Evaluator;
	require RDF::Core::NodeFactory;
	require RDF::Core::Query;

	my $rdf_model = RDF::Core::Model->new(
		Storage => RDF::Core::Storage::Memory->new
	);

	my $parser = RDF::Core::Model::Parser->new(
		Model => $rdf_model,
		Source => $rdf_string,
		SourceType => 'string',
		BaseURI => 'http://www.foo.com',
	);

	eval {
		$parser->parse();
	};

	if ($@) {
		my $err_string = $@;
		$err_string =~ s/^\s+|\s+$//g;

		$self->recordError( $err_string );
		return undef;
	}
	
	my $evaluator = RDF::Core::Evaluator->new(
		Model => $rdf_model,
		Factory => RDF::Core::NodeFactory->new,
		Namespaces => {
			rdf => 'http://www.w3.org/1999/02/22-rdf-syntax-ns#',
			i3cp => 'urn:lsid:i3c.org:predicates:',
			dc => 'http://purl.org/dc/elements/1.1/',
		}
	);

	my $query = RDF::Core::Query->new(
		Evaluator => $evaluator
	);

	$self->{_rdf_model} = $rdf_model;
	$self->{_rdf_query} = $query;
	
	$self->recordError( undef );
}


sub _rdf_query {
	my $self = shift;
	my ($query_string) = @_;
	
	unless ($self->{_rdf_query}) {
		$self->_get_rdf;
		
		return unless $self->{_rdf_query};
	}


	my $rs = $self->{_rdf_query}->query($query_string);
	
	return $rs;
}


sub get_types {
	my $self = shift;

	my $rs = $self->_rdf_query('Select ?type from [' . $self->lsid->canonical() . ']->rdf:type{?type}') || return;
	
	my @types;

	foreach my $row (@$rs) {
		my $resource = $row->[0] || next;
		
		push(@types, $resource->getURI());
	}

	$self->recordError( undef );

	return \@types;
}


sub get_format {
	my $self = shift;

	my $rs = $self->_rdf_query('Select ?format from [' . $self->lsid->canonical() . ']->dc:format{?format}') || return;

	my $row = $rs->[0] || return;
	my $resource = $row->[0] || return;

	$self->recordError( undef );

	return $resource->getURI();
}


sub get_instances {
	my $self = shift;

	my $rs = $self->_rdf_query('Select ?instance, ?format from [' . $self->lsid->canonical() . ']->i3cp:storedas{?instance}->dc:format{?format}') || return;
	
	my @lsids;

	foreach my $row (@$rs) {
		my $resource = $row->[0] || next;
		my $format = $row->[1];
	
		push(@lsids, [$resource->getURI(), $format->getURI() ]);
	}

	$self->recordError( undef );
	
	return \@lsids;
}


sub get_abstract {
	my $self = shift;

	my $rs = $self->_rdf_query('Select ?abstract from ?abstract->i3cp:storedas=>[' . $self->lsid->canonical() . ']') || return;

	my $row = $rs->[0] || return;
	my $resource = $row->[0] || return;

	$self->recordError( undef );

	return $resource->getURI();
}


sub get_instances_in_format {
	my $self = shift;
	my ($format) = @_;

	$format = LS::ID->new($format) unless ref $format;
	
	if (!$format) {

		$self->recordError( 'Invalid format' );
		return;
	}
	
	my $rs = $self->_rdf_query('Select ?instance from [' . $self->lsid->canonical() . "]->i3cp:storedas{?instance}->dc:format=>[" . $format->canonical() . "]") || return;
	
	my @lsids;

	foreach my $row (@$rs) {
		my $resource = $row->[0] || next;
		
		push(@lsids, $resource->getURI());
	}

	$self->recordError( undef );
	
	return \@lsids;
}

#
#
# End deprecation warning
#
#


1;

__END__

=head1 NAME

LS::Resource - A resource identified by an LSID

=head1 SYNOPSIS

 use LS::ID;
 use LS::Locator;

 $lsid = LS::ID->new('urn:lsid:ncbi.nlm.nih.gov.lsid.biopathways.org:pubmed:12441807');

 $locator = LS::Locator->new();
 $authority = $locator->resolveAuthority($lsid);

 $resource = $authority->getResource($lsid);

or

 use LS::Resource;

 $resource = LS::Resource->new('urn:lsid:ncbi.nlm.nih.gov.lsid.biopathways.org:pubmed:12441807');


=head1 DESCRIPTION

An object of the C<LS::Resource> class represents a resource
identified by an LSID.  A resource can be either an abstract class,
or a concrete instance of that class.  More information
on LSIDs and the resources they identify can be found at 
L<http://www.omg.org/cgi-bin/doc?dtc/04-05-01>.

=head1 CONSTRUCTORS

The following method is used to construct a new C<LS::Resource> object:

=over

=item new ( $lsid, [ $authority, [$wsdl] ] )

This class method creates a new C<LS::Resource> object and
returns it.  The C<$lsid> parameter is the LSID which identifies
this resource, and can either be a string or an object of class
L<LS::ID>.  The optional C<$authority> parameter is an
object of class L<LS::Authority>, and represents the authority
service which "knows" about this resource.  If C<$authority> is 
omitted, the authority will be determined by resolving C<$lsid>
using a default L<LS::Locator> object.  The optional C<$wsdl>
parameter is a string containing a description of the interface
to the resource.  If C<$wsdl> is omitted, the description will
be obtained by calling the C<getAvailableServices> method of
the authority service.  If an error occurs during object creation,
C<undef> is returned, and an error message can be retrieved 
using the C<errorString> class method.

Most users will only call this constructor using the first 
parameter.

Examples:

 $resource = LS::Resource->new('urn:lsid:ncbi.nlm.nih.gov.lsid.biopathways.org:pubmed:12441807');

 if (!$resource) {
 	print "Error creating resource: ", &LS::Resource::errorString(), "\n";
 }

 $lsid = LS::ID->new('urn:lsid:ncbi.nlm.nih.gov.lsid.biopathways.org:pubmed:12441807');
 $another_resource = LS::Resource->new($lsid);

 if (!$another_resource) {
 	print "Error creating another resource: ", LS::Resource->errorString(), "\n";
 }

=back

=head1 METHODS

=head2 PARAMETER DETAILS

For the methods: C<getMetadata>, C<getData>, C<getMetadataLocation>, C<getMetadataLocations>,
C<getDataLocation>, and C<getDataLocations>, you may specify the following options as hash arguments:

=over

=item location

The location L<LS::Authority::WSDL::Simple::Location> object describing this location. This
is the parameter that is the most specifc and receives the highest priority in the search.

=item protocol

May be one of the following constants:
 C<$LS::Authority::WSDL::Constants::Protocols::HTTP>, C<$LS::Authority::WSDL::Constants::Protocols::SOAP>
	
The FTP protocol is discouraged:  C<$LS::Authority::WSDL::Constants::Protocols::FTP>
	
=item method

For the C<$LS::Authority::WSDL::Constants::Protocols::HTTP> protocol you can 
optionally specify either C<POST> or C<GET> directing the HTTP client
how it should retrieve the data.

=back

=over

=item authority ( )

Returns the authority service that has knowledge about this resource,
as an object of class C<LS::Authority>.

=item lsid ( )

Returns the LSID that identifies this resource, as an object 
of class C<LS::ID>.

=item getMetadata ( %options )

Retrieves the RDF metadata describing the resource.  The return value
is an L<LS::Service::Response> object containing the metadata, or C<undef>
if an error occurs.  Error messages can be checked by calling the 
C<errorString> method.

In addition to the standard method parameters, you may optionally specify
an results format string as seen in the following example:

	$resource->getMetadata(format=> 'application/xml+rdf');

This will instruct the authority for the LSID resource to only return 
metadata that is of the MIME type 'application/rdf+xml'.

See the section entitled L<PARAMETER DETAILS> for mor information about
how to pass parameters to this method.

=item getMetadataLocations ( [ $serviceName ] )

Retrieves the locations of the getMetadata 
operation of the resource for the specified C<$serviceName>. If the
C<$serviceName> is left unspecified the default or first service 
defined in the WSDL will be used.

The return value is a reference to an
array of objects of class C<LS::Authority::WSDL::Simple::Location>,
or C<undef> if the method is not available.  The location objects have 
three members, as shown in the example.

 $locations = $resource->getMetadataLocations();

 if ($locations) {
	foreach $loc (@$locations) {
		$protocol = $loc->protocol();  # a string, either 
		$url = $loc->url(); # a string

		if ($protocol eq $LS::Authority::WSDL::Constants::Protocols::HTTP) {
			$method = $loc->method(); # if protocol is HTTP, this is the HTTP method, eg 'GET'
		}
	}
 }

For more granular control over which location to return see C<getMetadataLocation>

=item getMetadataLocation ( %options )


See the section entitled L<PARAMETER DETAILS> for mor information about
how to pass parameters to this method.

=item getData ( %options )

If you need more control over the download, you can use
the C<getDataLocation> and C<getDataLocations> methods to find the URLs where
the data are located, and then pass that location to this method.

See the section entitled L<PARAMETER DETAILS> for mor information about
how to pass parameters to this method.

Examples:

 $data = $resource->getData();

 if (defined $data) {
	open FILE, '>data');
	print FILE $data;
	close FILE;
 }
 else {
	print "Error getting data: ", $resource->errorString(), "\n";	
 }


=item getDataLocations( %options )

Retrieves the locations of the getData operation for
the resource.  The return value is a reference to an
array of objects of class C<LS::Authority::WSDL::Simple::Location>,
or undef if the method is not available.  The location objects have 
three members, as shown in the example.

Examples:

 $locations = $resource->getDataLocations();

 if ($locations) {
	foreach $loc (@$locations) {
		$protocol = $loc->protocol();  # a string, either $LS::Authority::WSDL::Constants::Protocols::HTTP, $LS::Authority::WSDL::Constants::FTP, or $LS::Authority::WSDL::Constants::SOAP
		$url = $loc->url(); # a string

		if ($protocol eq $LS::Authority::WSDL::Constants::Protocols::HTTP) {
			$method = $loc->method(); # if protocol is HTTP, this is the HTTP method, eg 'GET'
		}
	}
 }

See the section entitled L<PARAMETER DETAILS> for mor information about
how to pass parameters to this method.

=item getDataLocation ( %options )

Returns the locations at which the resource's data can be found, which is
accessible using the given protocol.  If the protocol is HTTP,
an optional HTTP method can be supplied.  undef is returned
if no matching location is found.  The return value is an object of class
C<LS::Authority::WSDL::Simple::Location>, as shown above.

Examples:

 $ftp_location = $resource->getDataLocation(protocol=> $LS::Authority::WSDL::Constants::Protocols::FTP);

 $http_get_location = $resource->getDataLocation(protocol=> $LS::Authority::WSDL::Constants::Protocols::HTTP, 
 						 method=> 'GET');


=item errorString ( )

This can be called either as a static method, a class method, or an 
instance method.  As a static or class method, it returns a description
of the last error that ocurred during a failed object creation.  As
an instance method, it returns a description of the last error that 
occurred in another instance method on the object.

Examples:

 $resource = LS::Resource->new('urn:lsid:ncbi.nlm.nih.gov.lsid.biopathways.org:pubmed:12441807') || 
 	warn("Error creating resource: " . &LS::Resource::errorString() . "\n");

 $resource = LS::Resource->new('urn:lsid:ncbi.nlm.nih.gov.lsid.biopathways.org:pubmed:12441807') || 
 	warn("Error creating resource: " . LS::Resource->errorString() . "\n");

 $data = $resource->getData();

 if (defined $data) {
 	# Do something
 }
 else {
	print "Error getting data: ", $resource->errorString(), "\n";
 }

=item data_locations ( )

Deprecated. Use getDataLocations instead.

=item data_location ( $protocol, [ $method ] )

Deprecated. Use getDataLocation instead.

=back

=head1 COPYRIGHT

Copyright (c) 2002,2003 IBM Corporation.
All rights reserved.   This program and the accompanying materials
are made available under the terms of the Common Public License v1.0
which accompanies this distribution, and is available at
L<http://www.opensource.org/licenses/cpl.php>

# $Id: WSDL.pm 1814 2007-11-05 19:22:21Z edwardkawas $
# ====================================================================
# Copyright (c) 2002,2003 IBM Corporation 
# All rights reserved.   This program and the accompanying materials
# are made available under the terms of the Common Public License v1.0
# which accompanies this distribution, and is available at
# http://www.opensource.org/licenses/cpl.php
# 
# =====================================================================
package LS::Authority::WSDL;

use strict;
use warnings;

use vars qw( $METHODS %URI );

use LS;
use LS::ID;
use LS::Authority::WSDL::Constants;
use LS::Authority::WSDL::Bindings;

use base 'LS::Base';


%URI = (
	wsdl=> 'http://schemas.xmlsoap.org/wsdl/',
	http=> 'http://schemas.xmlsoap.org/wsdl/http/',
	soap=> 'http://schemas.xmlsoap.org/wsdl/soap/',
);



sub BEGIN {

	$METHODS = [
		'bindings',
		'services',
		'namespaces',
		'xmlImports',
		'targetNamespace',
		'defaultXMLNamespace',
	];
	
	LS::makeAccessorMethods($METHODS, __PACKAGE__);
}



#
# new( %options ) -
#
sub new {
	my $self = shift;

	unless(ref $self) {
		
		$self = bless {}, $self;
	}
	
	# Initialize this object
	$self->services( {} );
	$self->namespaces( {} );
	$self->xmlImports( {} );
	
	$self->bindings([]);

	$self->add_namespace(prefix=> 'wsdl', uri=> $URI{'wsdl'});
	
	return $self;
}



#
# bindings( ) -
#


#
# services( )
# 	Gets or sets the hash of services
#


#
# getService( $name ) 
# 	Gets the specified service by name
#
sub getService {

	my $self = shift;
	my ($name) = @_;

	return (exists($self->services()->{ $name })) ? $self->services()->{ $name } : undef
}


#
# authority - Gets or Sets the authority name for this WSDL document
#


#
# targetNamespace( $tns ) -
#


#
# add_binding( $binding ) -
#
sub add_binding {
	my $self = shift;
	my ($binding) = @_;
	
	push(@{ $self->bindings() }, $binding);
}


#
# add_service( $service ) -
#
sub add_service {
	
	my $self = shift;
	my $newService = shift;
	
	unless(UNIVERSAL::isa($newService, 'LS::Authority::WSDL::ServiceDefinition')) {
		return undef;
	}
	
	# FIXME: Should this be a strict check?
	if(exists($self->services()->{ $newService->name() })) {
		print STDERR "Adding duplicate service: " . $newService->name() . "\n";
	}
	
	$self->services()->{ $newService->name() } = $newService;
}


#
# add_xml_import( %options ) - 
#
sub add_xml_import { 

	my ($self, %options) = @_;

	$self->xmlImports()->{ $options{'location'} } = $options{'namespace'};
}


#
# add_namespace( %options ) -
#
sub add_namespace {

	my ($self, %options) = @_;

	if(exists($options{'defaultNamespace'})) {
	
		$self->defaultXMLNamespace($options{'defaultNamespace'});
	}
	elsif( exists($options{'prefix'}) && exists($options{'uri'})) {
	
		$self->namespaces()->{ $options{'prefix'} } = $options{'uri'};
	}
	else {
		
		# TODO: Error message?
	}
}


sub inline_std_defs {
	my $self = shift;
	
	@_ ? $self->{'_inline_std_defs'} = $_[0] : $self->{'_inline_std_defs'};
}

#
# XML Manipulation / Display methods
#
#
# xml( ) - Returns the entire document as XML if no parameters are specified.
#	   Otherwise, builds a WSDL object based on the pass parameter in XML
#
sub xml {
	my $self = shift;
	
	return (@_ ? $self->from_xml(@_) : $self->to_xml());
}

#
# imports_xml( ) - Returns the imports of this WSDL document in XML
#
sub imports_xml {

	my $self = shift;

	my $imports_xml;
	my $imports_ref = $self->xmlImports();

	foreach my $location (keys(%{ $imports_ref })) {

		$imports_xml .= '<wsdl:import namespace="' . $imports_ref->{ $location } . '" location="' . $location . '"/>' . "\n";
	}

	return $imports_xml;
}

#
# namespaces_xml( ) - Returns the namespaces of this WSDL document in XML
#
sub namespaces_xml {

	my $self = shift;

	my $ns_xml;
	my $ns_ref = $self->namespaces();

	$ns_xml = ' xmlns="' . $self->defaultXMLNamespace() . "\"\n"
		if($self->defaultXMLNamespace());
	
	$ns_xml .= ' xmlns:tns="' . $self->targetNamespace() . "\"\n";

	foreach my $prefix (keys(%{ $ns_ref })) {

		$ns_xml .= ' xmlns:' . $prefix . '="' . $ns_ref->{$prefix} . '"' . "\n";
	}

	return $ns_xml;
}


#
# services_xml( ) - Returns the services contained in this WSDL object as XML
#
sub services_xml {

	my $self = shift;

	my $service_xml;

	foreach my $service (values(%{ $self->services() })) {

		foreach my $port (@{ $service->ports() }) {

			# Add the port's protocol's namespace
			if($port->implementation()) {

				my $protocolURI = $port->implementation()->protocol();
				my $uri = LS::Authority::WSDL::Constants::Protocols::protocolToURI( $protocolURI );

				$self->add_namespace(prefix=> $port->implementation()->protocol(), 
						     uri=>$uri) 
					if($uri);
			}
		}
		
		$service_xml .= $service->xml() . "\n";
	}

	return $service_xml;
}


#
# to_xml( ) - Converts the entire WSDL object to XML
#
sub to_xml {

	my $self = shift;
	
	# This adds each port's protocol namespace to the list of namespace
	my $services_xml = $self->services_xml();

	my $ns_xml = $self->namespaces_xml();
	
	my $target_ns_xml = ' targetNamespace="' . $self->targetNamespace() . '"';

	return
		'<?xml version="1.0" ?>' . "\n" . 
		'<wsdl:definitions' . $target_ns_xml . $ns_xml . ">\n" .
		$self->imports_xml() .
		$services_xml .
		'</wsdl:definitions>';
}

#
# from_xml( ) - Creates a WSDL object based on the input XML
#
sub from_xml {

	my $self = shift->new();
	my ($xml) = @_;

	$self->services({});

	require XML::XPath;

	my $xpath = XML::XPath->new(xml => $xml);
	
	# Setup namespace mappings for the XPath queries
	$xpath->set_namespace('wsdl', $URI{'wsdl'});	

	my $service_nodes = $xpath->find("wsdl:definitions/wsdl:service");

	foreach my $service_node ($service_nodes->get_nodelist()) {
		my $service = LS::Authority::WSDL::ServiceDefinition->from_xpath_node($service_node, $xpath);
		next unless $service;

		$self->add_service($service);
	}

	# Record the targetNamespace for future use
	my $targetns_nodes = $xpath->find('wsdl:definitions/@targetNamespace');
	
	if ($targetns_nodes->size() == 1) {
		my $targetns_node = $targetns_nodes->get_node(1);
		$self->targetNamespace( $targetns_node->getNodeValue() )
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


package LS::Authority::WSDL::ServiceDefinition;

sub new {
	my $self = shift;
	my %params = @_;

	unless (ref $self) {
		$self = bless [
			undef, # name,
			[]     # ports
		], $self;
		
		$self->name($params{'name'})
			if($params{'name'});
	}
	
	return $self;
}

sub name {
	my $self = shift;
	
	@_ ? $self->[0] = $_[0] : $self->[0];
}

sub ports {
	my $self = shift;
	
	return $self->[1];
}

sub add_port {
	my $self = shift;
	
	my $port = shift;
	
	unless(UNIVERSAL::isa($port, 'LS::Authority::WSDL::Port')) {
	
		return undef;
	}

	push(@{ $self->ports() }, $port);
}

sub xml {
	
	my $self = shift;
	
	my $ports_xml = '';
	
	foreach my $port (@{ $self->ports() }) {
		
		$ports_xml .= $port->xml();
	}
	
	return
		'<wsdl:service name="' . $self->name() . '">' . "\n" .
		$ports_xml .
		'</wsdl:service>';
}

sub from_xpath_node {

	my $self = shift->new();
	my ($node, $xpath) = @_;
	
	my $name = $node->getAttribute('name') || return;
	$self->name($name);

	my $port_nodes = $xpath->find('wsdl:port', $node);

	foreach my $port_node ($port_nodes->get_nodelist()) {
		my $port = LS::Authority::WSDL::Port->from_xpath_node($port_node, $xpath);
		next unless $port;

		$self->add_port($port);
	}
	
	return $self;
}


package LS::Authority::WSDL::Port;

sub new {
	
	my ($self, %params) = @_;

	unless(ref $self) {
		$self = bless [
			undef, # name,
			undef, # binding,
			undef  # implementation
		], $self;
		
		$self->name($params{'name'}) 
			if(exists($params{'name'}) && defined($params{'name'}));
			
		$self->binding($params{'binding'}) 
			if (exists($params{'binding'}) && defined($params{'binding'}));
			
		$self->implementation($params{'implementation'})
			if (exists($params{'implementation'}) && defined($params{'implementation'}));
	}
	
	return $self;
}

sub name {
	
	my $self = shift;

	@_ ? $self->[0] = $_[0] : $self->[0];
}

sub binding {
	
	my $self = shift;

	@_ ? $self->[1] = $_[0] : $self->[1];	
}

sub implementation {
	
	my $self = shift;

	@_ ? $self->[2] = $_[0] : $self->[2];
}

sub xml {
	my $self = shift;
	
	return
		'<wsdl:port name="' . $self->name() . '"' . ($self->binding() ? ' binding="' . $self->binding() . '"' : '') . '>' . "\n" .
		($self->implementation() ? $self->implementation->xml() : '') . "\n" .
		"</wsdl:port>\n";
}

sub from_xpath_node {
	
	my $self = shift->new();
	
	my ($node, $xpath) = @_;

	my $name = $node->getAttribute('name') || return undef;
	$self->name($name);

	my $binding = $node->getAttribute('binding') || 'http://www.omg.org/LSID/2003/LSIDDataServiceUnknownBinding';
	$self->binding($binding);

	my $imp_nodes = $xpath->find('*', $node);
	return undef if($imp_nodes->size() != 1);

	my $imp_node = $imp_nodes->get_node(1);
	my $imp = LS::Authority::WSDL::Implementation->from_xpath_node($imp_node, $xpath);
	return undef unless($imp);

	$self->implementation($imp);

	return $self;
}


package LS::Authority::WSDL::Implementation;

sub new {
	my $self = shift;
	my %params = @_;

	unless(ref $self) {
		$self = bless [
			undef, # protocol,
			undef, # name,
			{}     # attributes
		], $self;

		$self->protocol($params{'protocol'}) if defined $params{'protocol'};
		$self->name($params{'name'}) if defined $params{'name'};
		$self->attr($params{'attr'}) if defined $params{'attr'};
	}
	
	return $self;	
}

sub protocol {
	
	my $self = shift;

	@_ ? $self->[0] = $_[0] : $self->[0];
}

sub name {
	
	my $self = shift;

	@_ ? $self->[1] = $_[0] : $self->[1];
}

sub attr {
	
	my $self = shift;

	@_ ? $self->[2] = $_[0] : $self->[2];
}

sub get_attr {
	
	my $self = shift;
	
	my ($name) = @_;

	return $self->attr()->{ $name };
}

sub set_attr {
	
	my $self = shift;
	
	my ($name, $value) = @_;

	$self->attr()->{ $name } = $value;
}

sub xml {
	
	my $self = shift;
	
	my %attr = %{ $self->attr() };

	my $attr_string = '';

	foreach my $name (keys(%attr)) {
		
		$attr_string .= ' ' . $name . '="' . &LS::Authority::WSDL::_escape($attr{ $name }) . '"';
	}

	return '<' . $self->protocol() . ':' . $self->name() . $attr_string . '/>';
}

sub from_xpath_node {
	
	my $self = shift->new();
	
	my ($node, $xpath) = @_;

	my $protocolURI = $node->getNamespace($node->getPrefix())->getExpanded();
	my $protocol = LS::Authority::WSDL::Constants::Protocols::uriToProtocol( $protocolURI );
	unless($protocol) {	
		die("Could not map protocol URI to a supported LSID Protocol, URI: $protocolURI");
	}

	$self->name($node->getLocalName());
	$self->protocol($protocol);

	my %attrs = ();
	my @attr_nodes = $node->getAttributes();
	
	foreach my $attr_node (@attr_nodes) {
		
		$attrs{ $attr_node->getName() } = $attr_node->getNodeValue();
	}

	$self->attr(\%attrs);

	return $self;
}

1;

__END__


=head1 NAME

LS::Authority::WSDL::Simple - WSDL document describing a resource identified by an LSID.

=head1 SYNOPSIS

 # Generating WSDL

 use LS::Authority::WSDL::Constants;
 
 use LS::Authority::WSDL::Simple;

 $wsdl = LS::Authority::WSDL::Simple->new(
	authority => 'pdb.org',
	lsid => 'URN:LSID:pdb.org:pdb/cgi/explore.cgi:2ACE-6A6L0B72:',
	name => 'PDB',
 );

 # Add a HTTP Data port
 $port = LS::Authority::WSDL::Simple::DataPort->newData(
			name=> 'HTTPData',
		 	protocol=> $LS::Authority::WSDL::Constants::Protocols::HTTP, 
		 	endpoint=> 'http://www.server-with-object.com/where/the/file/is/file.txt',
 		);

 $wsdl->addPort (
 	serviceName=> $wsdl->name(),
 	port=> $port,
 );
 
 # Add a SOAP Metadata port
 $port = LS::Authority::WSDL::Simple::MetadataPort->newMetadata(
			name=> 'SOAPMetadata',
		 	protocol=> $LS::Authority::WSDL::Constants::Protocols::SOAP, 
		 	endpoint=> 'http://www.server-with-object.com/metaDataService/', 
 		);
 		
 $wsdl->addPort(
 	serviceName=> 'metadataServiceName',
 	port=> $port,
 );

 print $wsdl->xml();

or

 # Parsing WSDL

 use LS::Authority::WSDL::Simple;

 local $/ = undef;

 open FILE, 'wsdl.xml';
 $xml = <FILE>;
 close FILE;

 my $wsdl = LS::Authority::WSDL::Simple->from_xml($xml);

 print "getData locations\n";
 
 $locations = $wsdl->getDataLocations();

 if ($locations) {
 
	foreach $loc (@$locations) {
	
		print "\t", $loc->protocol(), ': ', $loc->url(), "\n";
	}
 }

 print "getMetadata locations\n";

 $locations = $wsdl->getMetadataLocations();

 if ($locations) {
 
	foreach $loc (@$locations) {
	
		print "\t", $loc->protocol(), ': ', $loc->url(), "\n";
	}
 }

=head1 DESCRIPTION

LS::Authority::WSDL::Simple provides a simple interface for creating WSDL
documents when implementing the getAvailableOperations method in an LSID
authority service, and for parsing the WSDL on the client side.

=head1 CONSTRUCTORS

The following methods are used to construct a new LS::Authority::WSDL::Simple object:

=over

=item new ( [%options] )

This class method creates a new LS::Authority::WSDL::Simple object and
returns it.  Key/value pair arguments may be provided to initialize
locator options.  The options can also be set or modified later by
method calls described below.

=item from_xml ( $xml )

This class method creates a new LS::Authority::WSDL::Simple object and
returns it.  The $xml paramater is a string containing a valid WSDL
XML document.  The newly created object is populated by parsing
this XML document.

=back

=head1 METHODS

=over

=item name ( [$new_name] ) 

Sets and retrieves the descriptive name of the authority service that
is creating the WSDL.  This name is used to generate identifiers in the 
WSDL document, so it should be fairly short, and should not contain 
characters not allowed in XML identifiers, e.g. whitespace.

=item authority ( [$new_authority] ) 

Sets and retrieves the hostname of the authority service that is 
creating the WSDL.  This name is used to generate the targetNamespace
of the definitions, so it should be unique for each authority.

=item lsid ( [$new_lsid] )

Sets and retrieves the LSID of the resource which this WSDL document
describes.  This ID is used to generate the targetNamespace of the
definitions, so it should be unique for each resource.

=item addPort ( %keys_and_values )

Adds a port to the WSDL document.  The port is described by
supplying the following key/value pairs:

serviceName - The name of the service, contained in this WSDL object,
that will own the newly created port.

port - An object of type C<LS::Authority::WSDL::Port> describing the 
characteristics of the port. Use the helper methods from the following
classes to create the appropriate port:

C<LS::Authority::WSDL::Simple::DataPort> or
C<LS::Authority::WSDL::Simple::MetadataPort>

Generally, the methods in the above two classes support the following
parameters passed as an options hash:

=over

protocol - Specifies the transport protocol.  This can be one 
of $LS::Authority::WSDL::Protocols::HTTP, $LS::Authority::WSDL::Protocols::FTP, or
$LS::Authority::WSDL::Protocols::SOAP.

method - Specifies the HTTP method to be used, e.g. 'GET' or
'POST'.  This defaults to 'GET', and is ignored if the protocol is 
not $LS::Authority::WSDL::Protocols::HTTP.

username - Specifies the username to be used for authentication.

password - Specifies the password to be used for authentication.

endpoint - Specifies the location of the port.  For HTTP and FTP
ports, this should be the hostname:portnumber.  For SOAP ports,
this should be the complete HTTP URL.  Other SOAP transports are
not supported.

expires - Specifies whether or not an expires header message part
will be added to output message bindings for SOAP ports.  A true
value causes the message part to appear in the bindings. This is 
ignored if the protocol is not $LS::Authority::WSDL::Protocols::SOAP.

=back

Examples creating WSDL ports:

 # Add a HTTP Data port
 $port = LS::Authority::WSDL::Simple::DataPort->newData(
			name=> 'HTTPData',
		 	protocol=> $LS::Authority::WSDL::Protocols::HTTP, 
		 	endpoint=> 'http://www.server-with-object.com/where/the/file/is/file.txt',
 		);

 $wsdl->addPort (
 	serviceName=> $wsdl->name(),
 	port=> $port,
 );
 
 # Add a SOAP Metadata port
 $port = LS::Authority::WSDL::Simple::MetadataPort->newMetadata(
			name=> 'SOAPMetadata',
		 	protocol=> $LS::Authority::WSDL::Protocols::SOAP, 
		 	endpoint=> 'http://www.server-with-object.com/metaDataService/', 
 		);
 		
 $wsdl->addPort(
 	serviceName=> 'metadataServiceName',
 	port=> $port,
 );

=item getMetadataLocations( %options )

Returns the locations at which the given method of the resource may
be found.  The return value is a reference to an
array of objects of class C<LS::Authority::WSDL::Simple::Location>,
or undef if the method is not available.  The location objects have 
three members, as shown in the example.
 
 $locations = $wsdl->getMetadataLocations();

 if ($locations) {
 
	foreach $loc (@$locations) {
	
		$protocol = $loc->protocol();  # a string, either $LS::Authority::WSDL::Constants::Protocols::HTTP, 
					       # $LS::Authority::WSDL::Constants::Protocols::FTP, 
					       # or $LS::Authority::WSDL::Constants::Protocols::SOAP
					       
		$url = $loc->url(); # a string

		if ($protocol eq $LS::Authority::WSDL::Constants::Protocols::HTTP) {
		
			$method = $loc->method(); # if protocol is HTTP, this is the HTTP method, eg 'GET'
		}
	}
 }
 
=item getDataLocations( %options )

Returns an arrayref of data locations for this service. See getMetadataLocations for more
information.

=item xml ( )

Returns the WSDL document as an XML string.

=back

=head1 COPYRIGHT

Copyright (c) 2002,2003 IBM Corporation.
All rights reserved.   This program and the accompanying materials
are made available under the terms of the Common Public License v1.0
which accompanies this distribution, and is available at
L<http://www.opensource.org/licenses/cpl.php>

=cut

=head1 NAME

LS::Authority::WSDL::Simple::Location - Object describing a WSDL port's location

=head1 SYNOPSIS

 use LS::Authority::WSDL::Constants;
 use LS::Authority::WSDL::Simple;
 
 # Creata a new data location
 my $loc = LS::Authority::WSDL::Simple::Location->new(
	 	protocol=> $LS::Authority::WSDL::Constants::Protocols::HTTP,
	 	url=> 'http://www.someplace.com/data.txt',
	 	binding=> 'LSIDDataServiceHTTPBinding',
	 	method=> $LS::Authority::WSDL::Constants::Protocols::HTTP_GET,
	 	name=> 'portName',
	 	parentName=> 'Name of Parent Service',
	);
 

=head1 DESCRIPTION

=head1 METHODS

=over

=item protocol( [$protocol] )

	Returns the protocol that is used to access this location. If 
	a protocol is passed as a parameter, the protocol for this location
	will be set to the value of the parameter.
	
=item url( [$url] )

	Returns the URL endpoint of this location. If a URL is passed as a
	parametere, the URL for this location will be set to the value of 
	the parameter.

=item method( [$method] ) 

	In the case of HTTP locations, returns the method used: GET or POST.
	If a method is passed as a parameter, the method for this location
	will be set to the value of the parameter.

=item name( [$name] )

	Returns the name of this location. If a name is passed as a parameter,
	the name of this location will be set to the value of the parameter.
	
=item serviceName( [$serviceName] )

	Returns the name of the parent service for this location. If a service
	name is specified as a parameter, then the parent service name of this
	location will be set to the value of the parameter.


=back

=head1 COPYRIGHT

Copyright (c) 2002,2003 IBM Corporation.
All rights reserved.   This program and the accompanying materials
are made available under the terms of the Common Public License v1.0
which accompanies this distribution, and is available at
L<http://www.opensource.org/licenses/cpl.php>

=cut

__END__
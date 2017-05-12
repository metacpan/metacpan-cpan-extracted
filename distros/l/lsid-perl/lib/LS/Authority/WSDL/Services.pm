# ====================================================================
# Copyright (c) 2002,2003 IBM Corporation 
# All rights reserved.   This program and the accompanying materials
# are made available under the terms of the Common Public License v1.0
# which accompanies this distribution, and is available at
# http://www.opensource.org/licenses/cpl.php
# 
# =====================================================================
package LS::Authority::WSDL::Services;

use strict;
use warnings;

use vars qw( $METHODS );

use LS;

use LS::Authority::WSDL::Location;

use base 'LS::Authority::WSDL';


sub BEGIN {
	
	$METHODS = [
		'defaultServiceName',
		'methodLocations',
	];
	
	LS::makeAccessorMethods($METHODS, __PACKAGE__);
}


sub new {
	my $self = shift;
	my %params = @_;

	$self = $self->SUPER::new(@_);

	$self->methodLocations( {} );
	
	if(exists($params{'name'})) {
		$self->defaultServiceName($params{'name'});
		$self->add_service(LS::Authority::WSDL::ServiceDefinition->new(name=> $params{'name'}));
	}

	# Default imports
	$self->add_xml_import(location=> 'LSIDAuthorityServiceHTTPBindings.wsdl',
			      namespace=> 'http://www.omg.org/LSID/2003/AuthorityServiceHTTPBindings');

	$self->add_xml_import(location=> 'LSIDAuthorityServiceSOAPBindings.wsdl',
			      namespace=> 'http://www.omg.org/LSID/2003/AuthorityServiceSOAPBindings');


	# Default namespaces
        $self->add_namespace(prefix=>'ahb',
                             uri=>'http://www.omg.org/LSID/2003/AuthorityServiceHTTPBindings');

        $self->add_namespace(prefix=>'asb',
                             uri=>'http://www.omg.org/LSID/2003/AuthorityServiceSOAPBindings');

	return $self;
}



sub add_port {
	my ($self, %params) = @_;
	
	my $location = $params{location};
	my $user = $params{user};
	my $password = $params{password};

	my $protocol = $params{protocol};
	my $name = $params{name};
	my $type = $params{type};
	my $method = $params{method};
	
	my $expires = $params{expires};
	
	if ($protocol eq ${LS::Authority::WSDL::Constants::Protocols::HTTP}) {
		$method = $method ? uc($method) : 'GET';
	}
	else {
		$method = undef;
	}

	my $binding;

	if ($protocol eq ${LS::Authority::WSDL::Constants::Protocols::HTTP}) {

#		$location .= '/'
#			unless($location =~ m|/$|);

		$binding = 'ahb:LSIDAuthorityHTTPBinding';
	}
	elsif ($protocol eq ${LS::Authority::WSDL::Constants::Protocols::SOAP}) {

		$binding = 'asb:LSIDAuthoritySOAPBinding';
	}
	
	my $port_impl = LS::Authority::WSDL::Implementation->new(
		protocol => $protocol,
		name => 'address',
		attr => {
			location => ($location =~ m|^http://|i ? '' : 'http://') . $location,
		}
	);	
	
	unless(UNIVERSAL::isa($port_impl, 'LS::Authority::WSDL::Implementation')) {
	
		return undef;
	}

	my $port = LS::Authority::WSDL::Port->new(
		name=> ($name) ? $name : $type . '_name',
		binding=> $binding,
		implementation=> $port_impl
	);

	$self->services()->{ $self->defaultServiceName() }->add_port($port);
}


sub from_xml {
	my $self = shift->new();

	$self = $self->SUPER::from_xml(@_);

	# Get the first service's name and use that as a default
	$self->defaultServiceName((values(%{ $self->services() }))[0]->name())
		if(scalar(values(%{ $self->services() })) > 0);

	$self->buildServiceLocations();
	
	return $self;
}


sub buildServiceLocations {

	my $self = shift;

	foreach my $service (values(%{ $self->services() })) {

		foreach my $port (@{ $service->ports() }) {		

			my $protocol = $port->implementation()->protocol();
			my $binding = $port->binding();
			my $type = $port->name();


			my $locations = $self->methodLocations()->{ $type };

			$locations = $self->methodLocations()->{ $type } = []
				unless($locations);
			
			my $method = "";
			my $url = $port->implementation->get_attr('location');

			if ($protocol eq ${LS::Authority::WSDL::Constants::Protocols::HTTP}) {

				$method = ( uc($port->implementation->get_attr('verb')) || 'GET' );
			}
			elsif ($protocol eq ${LS::Authority::WSDL::Constants::Protocols::SOAP}) {
				# Nothing to do
			}
			else {

				# FIXME: Maybe use LS::Service::Response
				print STDERR "Unknown protocol: $protocol\n";
				return undef;
			}

			push(
				@{ $locations },
				LS::Authority::WSDL::Location->new(
					name=> $type,
					protocol=> $protocol,
					url=> $url,
					binding=> $binding,
					method=> $method,
					parentName=> $service->name(),
				)
			);
		}
	}

}


sub to_xml {

	my $self = shift;

	$self->targetNamespace('http://www.omg.org/LSID/2003/Standard/WSDL');

	return $self->SUPER::to_xml(@_);
}

1;


__END__

=head1 NAME

LS::Authority::WSDL::Services - WSDL document describing how to invoke the authority

=head1 SYNOPSIS

 # Generating WSDL

 use LS::Authority::WSDL::Services;

 $wsdl = LS::Authority::WSDL::Services->new(
	name => 'PDBAuthorityService',
 );

 $wsdl->add_port(
 	protocol => $LS::Authority::WSDL::Constants::Protocols::HTTP, 
 	location => 'http://www.authority.org/');
 );
 
 $wsdl->add_port(
 	protocol => $LS::Authority::WSDL::Constants::Protocols::SOAP, 
 	location => 'http://www.authority.org/authority/');
 );

 print $wsdl->xml;

or

 # Parsing WSDL

 use LS::Authority::WSDL::Services;

 local $/ = undef;

 open FILE, 'wsdl.xml';
 $xml = <FILE>;
 close FILE;

 my $wsdl = LS::Authority::WSDL::Services->from_xml($xml);

 print "HTTP Ports\n";
 
 $locations = $wsdl->methodLocations('HTTPPort');

 if ($locations) {
	foreach $loc (@$locations) {
		print "\t", $loc->protocol, ': ', $loc->url , "\n";
	}
 }

 print "SOAP Ports\n";

 $locations = $wsdl->methodLocations('SOAPPort');

 if ($locations) {
	foreach $loc (@$locations) {
		print "\t", $loc->protocol, ': ', $loc->url , "\n";
	}
 }

=head1 DESCRIPTION


=head1 CONSTRUCTORS

The following methods are used to construct a new LS::Authority::WSDL::Services object:

=over

=item new ( [%options] )

This class method creates a new LS::Authority::WSDL::Services object and
returns it.  Key/value pair arguments may be provided to initialize
locator options.  The options can also be set or modified later by
method calls described below.

=item from_xml ( $xml )

This class method creates a new LS::Authority::WSDL::Services object and
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

=item add_port ( %keys_and_values )

Adds a port to the WSDL document.  The port is described by
supplying the following possible key/value pairs:

protocol specifies the transport protocol.  This can be one 
of $LS::Authority::WSDL::Constants::Protocols::HTTP, 
$LS::Authority::WSDL::Constants::Protocols::SOAP.

method specifies the HTTP method to be used, e.g. 'GET' or
'POST'.  This defaults to 'GET', and is ignored if the protocol is 
not $LS::Authority::WSDL::Constants::Protocols::HTTP.

location specifies the location of the port.  For HTTP  ports
this should be the hostname:portnumber.  For SOAP ports,
this should be the complete HTTP URL.  Other SOAP transports are
not supported.

expires specifies whether or not an expires header message part
will be added to output message bindings for SOAP ports.  A true
value causes the message part to appear in the bindings. This is 
ignored if the protocol is not $LS::Authority::WSDL::Constants::Protocols::SOAP.

Examples

 $wsdl->add_port(
 	protocol => $LS::Authority::WSDL::Constants::Protocols::HTTP, 
 	location => 'www.server-with-object.com');
 );
 
 $wsdl->add_port(
 	protocol => $LS::Authority::WSDL::Constants::Protocols::SOAP, 
 	location => 'http://www.server-with-object.com/metaDataService/');
 );

=item method_locations ( $method_name )

Returns the locations at which the given method of the resource may
be found.  The return value is a reference to an
array of objects of class C<LS::Authority::WSDL::Simple::Location>,
or undef if the method is not available.  The location objects have 
three members, as shown in the example.
 
 $locations = $wsdl->method_locations('HTTPPort');

 if ($locations) {
	foreach $loc (@$locations) {
		# a string, either $LS::Authority::WSDL::Constants::Protocols::HTTP, 
		# or $LS::Authority::WSDL::Constants::Protocols::SOAP
		$protocol = $loc->protocol;  
		$url = $loc->url; # a string

		if ($protocol eq $LS::Authority::WSDL::Constants::Protocols::HTTP) {
			$method = $loc->method; # if protocol is HTTP, this is the HTTP method, eg 'GET'
		}
	}
 }

=item xml ( )

Gets the WSDL document as an XML string.

=back

=head1 COPYRIGHT

Copyright (c) 2002,2003 IBM Corporation.
All rights reserved.   This program and the accompanying materials
are made available under the terms of the Common Public License v1.0
which accompanies this distribution, and is available at
L<http://www.opensource.org/licenses/cpl.php>

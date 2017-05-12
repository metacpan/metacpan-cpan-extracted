# =====================================================================
# Copyright (c) 2002,2003 IBM Corporation 
# All rights reserved.   This program and the accompanying materials
# are made available under the terms of the Common Public License v1.0
# which accompanies this distribution, and is available at
# http://www.opensource.org/licenses/cpl.php
# 
# =====================================================================

package LS::SOAP::Service;

use strict;
use warnings;

use vars qw(@ISA $METHOD_PREFIX);

use SOAP::Lite;

use MIME::Entity;

use HTTP::Status;
use HTTP::Headers;
use HTTP::Request;
use HTTP::Response;


use LS::Service;
use LS::Service::Fault;
use LS::Service::Response;

use LS::SOAP::Fault;
use LS::SOAP::Serializer;

use LS::Authority::WSDL::Constants;


use base 'LS::Service';



$METHOD_PREFIX = '';

# A SOAP::Server object of the appropriate subclass is created, and given 
# the following settings:
#
# A custom serializer is used to allow setting/retrieval of the namespace
# prefix used on the method element, instead of using an internally generated
# one.  This allows us to use the same known prefix when we generate elements
# in the response message.  This serializer also turns autotyping off, and
# removes extraneous attributes and namespace declarations from the envelope.
#
# The default on_action handler for HTTP transport checks the SOAPAction HTTP
# header, and dies if it doesn't match the <namespace uri>#<name> of the 
# method element in the envelope.  Since the WS-I basic profile says that
# SOAPAction may contain any string (it's just a hint), we override with a noop.
#
# Custom HTTP Basic authentication processing is done via redefining the handle
# method. If authentication is enabled, the system will look for the appropriate
# headers and pass the credentials to a user defined routine.
#
#
# All of the authority, metadata, and data operations are defined in the 
# namespace http://www.ibm.com/LSID/Standard/WSDL/SchemaTypes, so we dispatch
# that URI to this instance.
#
# This is no longer true, we must accept operations in the OMG spec. 
#



#
# new -
#
sub new {

	my $self = shift;

	unless (ref $self) {
		$self = $self->SUPER::new(@_);

		$self->{'_mappings'} = {};
		$self->{'_http_server'} = undef;

		$self->mappings('http://www.ibm.com/LSID/Standard/WSDL/SchemaTypes'=> $self,
                        'http://www.omg.org/LSID/2003/AuthorityServiceSOAPBindings'=> $self,
                        'http://www.omg.org/LSID/2003/DataServiceSOAPBindings'=> $self,
                        'http://www.omg.org/LSID/2003/DataServiceHTTPBindings'=> $self,
                );

		$self -> serializer(LS::SOAP::Serializer->method_prefix($METHOD_PREFIX))
		      -> on_action(sub {})
		      -> dispatch_with($self->mappings());
	}

	return $self;
}


#
# mappings -
#
sub mappings {

	my $self = shift;

	if(scalar(@_) > 1) {

		# 2 or more params indicates a new key
		while(@_) {

			my $key = shift;
			my $value = shift;

			$self->{'_mappings'}->{$key} = $value;
		}

		if(@_) {

			$self->recordError('Odd number of parameters in hash');
			$self->addStackTrace();

			return undef;
		}
	}
	elsif(scalar(@_) == 1) {

		my $param = shift;
		if(ref $param eq 'HASH') {

			#
			# Copy the hash
			#
			%{$self->{'_mappings'}} = %{$param};

			return;
		}

		#
		# Non-hash return that key's value
		#
		return $self->{'_mappings'}->{$param};
	}

	return $self->{'_mappings'};
}


#
# httpServer -
#
sub httpServer {

	my $self = shift;
	@_ ? $self->{'_http_server'} = shift : return $self->{'_http_server'};
}


#
# http_server - Synonym for httpServer.
#
sub http_server {

	my $self = shift;
	return $self->httpServer(@_);
}


sub dispatch_authority_to {

	my $self = shift->new();

	@_ ? ($self->{'_dispatch_authority_to'} = $_[0], return $self) 
	   : return $self->{'_dispatch_authority_to'};
}


sub dispatch_metadata_to {

	my $self = shift->new();

	@_ ? ($self->{'_dispatch_metadata_to'} = $_[0], return $self) 
	   : return $self->{'_dispatch_metadata_to'};
}


sub dispatch_data_to {

	my $self = shift->new();

	@_ ? ($self->{'_dispatch_data_to'} = $_[0], return $self) 
	   : return $self->{'_dispatch_data_to'};
}

sub dispatch {

        my $self = shift;

        $self->dispatch_authority_to($self->authorityService())
                ->dispatch_data_to($self->dataService())
                ->dispatch_metadata_to($self->metadataService())
                ->handle();
}


#
# handle -
#
sub handle {
	
	my $self = shift->new();
	
	# This only works for HTTP Transportss
	if(grep(/HTTP/, @ISA)) {

		if($self->auth_handler()) {

			# If the user has provided authorization information
			# in the request, attempt to authorize them
			return if(!$self->do_auth());
		}

		#
		# Handle HTTP requests to the base authority (we just return 
		# getAvailbleServices) - OMG spec
		#
		return $self->handle_http()
			unless($ENV{'CONTENT_LENGTH'});
	}
		
	$self->SUPER::handle(@_);
}


#
# handle_http -
#
sub handle_http {

	my $self = shift;

	# FIXME: This is not a good way to do this. 
	# 	 Ideally, the LS::HTTP::Service would handle different
	#	 SOAP backends accordingly (Apache, CGI, Daemon).

	if($ENV{'REQUEST_URI'} && $ENV{'REQUEST_URI'} =~ /^\/authority(?:\/){0,1}$/) {

		#
		# All services must accept a request for the service ports WSDL
		# at http:/srvhost:srvport/authority/
		#
		my $r = new HTTP::Response(HTTP::Status::RC_OK);
		
                $r->content($self->getServices());
                $r->header('Content-Type'=> 'text/xml');
                $r->header('Content-Length'=> length($r->content()));

                binmode(STDOUT);
                print STDOUT "Status: " . $r->code() . ' ' . HTTP::Status::status_message($r->code()) . "\r\n";
                print STDOUT  $r->headers_as_string();
                print STDOUT "\r\n";
                print STDOUT $r->content() . "\r\n";
	}

	if($self->http_server()) {

		#
		# SOAP servers may optionally accept plain HTTP requests
		#

		if($ENV{'REQUEST_URI'} && ($ENV{'REQUEST_URI'} =~ /^\/authority\/\?lsid=(.*)/)) {

			# Authority communication
			$self->httpServer()->do_authority($1);
		}
		elsif($ENV{'REQUEST_URI'} && $ENV{'REQUEST_URI'} =~ /^\/authority\/metadata\/?(.*)/) {

			# Metadata communication
			$self->httpServer()->do_metadata($1);
		}
		elsif($ENV{'REQUEST_URI'} && $ENV{'REQUEST_URI'} =~ /^\/authority\/data\/?(.*)/) {

			# Data communication
			$self->httpServer()->do_data($1);
		}
		else {

			# Fault
			$self->httpServer()->do_fault();
		}

	}
}

#
# FIXME: The authentication code is a mess, do something about it
#
sub do_auth {
	
	my $self = shift;

	if($self->auth_type eq 'Basic') {

		$self->do_basic_auth();
	}

	$self->auth_fail();
	
	return undef;
}

sub do_basic_auth {

	my $self = shift;

	#
	# FIXME: A better authentication code base would be nice
	#
	# HTTP Basic Authentication
	#
	if($ENV{HTTP_CGI_AUTHORIZATION}) {
		
		my $base64creds = (split(/ /, $ENV{HTTP_CGI_AUTHORIZATION}))[1];
		
		$base64creds = MIME::Base64::decode_base64($base64creds);
		
		my ($user, $pass) = split(/\:/, $base64creds);
		
		return $self->auth_handler->($user, $pass);
	}

	return undef;	
}

sub auth_fail {

	my $self = shift;
	
	# All else fails, send the 401
	my $resp = HTTP::Response->new(401);
	$resp->content_type('text/html');
	
	print STDOUT "WWW-Authenticate: Basic realm=\"LSID\"\n";			
	print STDOUT "Status: " . $resp->as_string() . "\n";
	print STDOUT $resp->error_as_HTML();
}


#
# import -
#
sub import {

	shift;
	my %params = @_;

	# The 'transport' parameter will be used to determine the superclass
	# of LS::SOAP::Service objects.

	my $transport = $params{transport};
	$transport =~ s/^\s+|\s+$//g;

	my $parent_class;

	if ($transport) {

		$transport =~ s|/|::|g;
		my ($protocol) = split('::', $transport, 2);

		my $imp_file = "SOAP::Transport::$protocol";
		eval "require $imp_file";
		die $@ if $@;

		$parent_class = "SOAP::Transport::$transport";
	}
	else {
		$parent_class = "SOAP::Server";
	}

	unshift @ISA, $parent_class;
}



#
#
# LSID Resolution Service Methods
#
#

sub getServices {

	my ($self, %options) = @_;

	my $handler = $self->dispatch_authority_to();

	unless ($handler) {

		die LS::SOAP::Fault->faultcode('Server')
		                   ->faultstring('Internal server error')
		                   ->errorcode(500)
		                   ->description('Unable to locate handler in getServices.');
	}

	my $services;

	if ($handler->can('getServices')) {

		my @protocols = ( ${ LS::Authority::WSDL::Constants::Protocols::SOAP } );

		push @protocols, ${ LS::Authority::WSDL::Constants::Protocols::HTTP } 
			if($self->http_server());

		$services = $handler->getServices(protocols=> \@protocols);
	}
	else {

		die LS::SOAP::Fault->faultcode('Server')
		                   ->faultstring('Method Not implemented')
		                   ->errorcode(501)
		                   ->description('getServices is not implemented by this authority service.');
	}

	unless(UNIVERSAL::isa($services, 'LS::Service::Response') || 
	       UNIVERSAL::isa($services, 'LS::Service::Fault') ) { 

		#die LS::SOAP::Fault->faultcode('Server')
		                   #->faultstring('Internal processing error: returned object was not correct type')
		                   #->errorcode(500)
		                   #->description(
		                   	#$method_name . ' in package ' . 
		                   	#(ref $handler ? ref $handler : $handler) . 
		                   	#' did not return an LS::Service::Response object.'
		                     #);	
	}

	return $services->response if($services->isa('LS::Service::Response'));

	# Must be a fault at this point
	bless $services, 'LS::SOAP::Fault';
	die $services->fault();
}


sub getAvailableServices {

	my $self = shift;

	my $handler = $self->dispatch_authority_to();

	unless ($handler) {

		die LS::SOAP::Fault->faultcode('Client')
		                   ->faultstring('Unknown method')
		                   ->errorcode(101)
		                   ->description('A call was made to an unknown method getAvailableServices.');
	}

	my $services;
	my $method_name;
	
	if ($handler->can('getAvailableServices')) {

		$method_name = 'getAvailableServices';
		$services = $handler->getAvailableServices(@_);
	}
	else {

		die LS::SOAP::Fault->faultcode('Server')
		                   ->faultstring('Not implemented')
		                   ->errorcode(501)
		                   ->description('getAvailableServices is not implemented by this authority service.');
	}

	unless(UNIVERSAL::isa($services, 'LS::Service::Fault') || 
	       UNIVERSAL::isa($services, 'LS::Service::Response') ) {

		die LS::SOAP::Fault->faultcode('Server')
		                   ->faultstring('Internal processing error')
		                   ->errorcode(500)
		                   ->description(
		                   	$method_name . ' in package ' . 
		                   	(ref $handler ? ref $handler : $handler) . 
		                   	' did not return a scalar or an LS::Service::Response object.'
		                     );	
	}

	if(UNIVERSAL::isa($services, 'LS::Service::Fault')) {

		bless $services, 'LS::SOAP::Fault';
		die $services->fault();
	}

	my @ret;

	if ($services->expiration()) {

		push(
			@ret,
			SOAP::Header->name(expiration=> $services->expiration())
				    ->prefix($METHOD_PREFIX)
				    ->uri(${LS::Authority::WSDL::Constants::SCHEMA_TYPES})			
		);
	}

	return (build MIME::Entity(Data=> $services->response()), @ret);
}


sub getMetadata {

	my $self = shift;
	my $handler = $self->dispatch_metadata_to();

	unless ($handler) {

		die LS::SOAP::Fault->faultcode('Client')
		                   ->faultstring('Unknown method')
		                   ->errorcode(101)
		                   ->description('A call was made to an unknown method getMetadata.');	
	}

	unless ($handler->can('getMetadata')) {

		die LS::SOAP::Fault->faultcode('Server')
		                   ->faultstring('Not implemented')
		                   ->errorcode(501)
		                   ->description('getMetadata is not implemented by this metadata service.');
	}

	my $metadata = $handler->getMetadata(@_);

	unless(UNIVERSAL::isa($metadata, 'LS::Service::Fault') || 
	       UNIVERSAL::isa($metadata, 'LS::Service::Response') ) {

		die LS::SOAP::Fault->faultcode('Server')
		                   ->faultstring('Internal processing error')
		                   ->errorcode(500)
		                   ->description(
		                   	'getMetadata in package ' . 
		                   	(ref $handler ? ref $handler : $handler) . 
		                   	' did not return a LS::Service::Response object.'
		                     );
	}

	if($metadata->isa('LS::Service::Fault')) {

		bless $metadata, 'LS::SOAP::Fault';
		die $metadata->fault();
	}

	my @ret;

	#
	# Expiration is optional
	#
	if ($metadata->expiration()) {
		push(
			@ret,
			SOAP::Header->name(expiration=> $metadata->expiration())
				    ->prefix($METHOD_PREFIX)
				    ->uri(${LS::Authority::WSDL::Constants::SCHEMA_TYPES})			
		);
	}

	#
	# Metadata needs a type
	#
	unless($metadata->format()) {

		die LS::SOAP::Fault->faultcode('Server')
		                   ->faultstring('Internal processing error')
		                   ->errorcode(500)
		                   ->description(
		                   	'getMetadata in package ' . 
		                   	(ref $handler ? ref $handler : $handler) . 
		                   	' is missing metadata response format.'
		                     );
	}

	push(
		@ret,
		SOAP::Data->name(format=> $metadata->format())
	);

	return (build MIME::Entity(Data=> $metadata->response()), @ret);
}


sub getData {

	my $self = shift;

	my $handler = $self->dispatch_data_to();

	unless ($handler) {

		die LS::SOAP::Fault->faultcode('Client')
		                   ->faultstring('Unknown method')
		                   ->errorcode(101)
		                   ->description('A call was made to an unknown method getData.');	
	}

	unless ($handler->can('getData')) {

		die LS::SOAP::Fault->faultcode('Server')
		                   ->faultstring('Not implemented')
		                   ->errorcode(501)
		                   ->description('getData is not implemented by this data service.');
	}

	my $data = $handler->getData(@_);

	unless(UNIVERSAL::isa($data, 'LS::Service::Fault') || 
	       UNIVERSAL::isa($data, 'LS::Service::Response') ) {

		die LS::SOAP::Fault->faultcode('Server')
		                   ->faultstring('Internal processing error')
		                   ->errorcode(500)
		                   ->description(
		                   	'getData in package ' . 
		                   	(ref $handler ? ref $handler : $handler) . 
		                   	' did not return a LS::Service::Response.'
		                     );	
	}

	if(UNIVERSAL::isa($data, 'LS::Service::Fault')) {

		bless $data, 'LS::SOAP::Fault';
		die $data->fault();
	}

	return build MIME::Entity(Data=> $data->response());
}


sub getDataByRange {

	my $self = shift;

	my $handler = $self->dispatch_data_to();

	unless ($handler) {

		die LS::SOAP::Fault->faultcode('Client')
		                   ->faultstring('Unknown method')
		                   ->errorcode(101)
		                   ->description('A call was made to an unknown method getDataByRange.');	
	}

	unless ($handler->can('getDataByRange')) {

		die LS::SOAP::Fault->faultcode('Server')
		                   ->faultstring('Not implemented')
		                   ->errorcode(501)
		                   ->description('getDataByRange is not implemented by this data service.');
	}

	my $data = $handler->getDataByRange(@_);

	unless($data && 
	       ($data->isa('LS::Service::Fault') || $data->isa('LS::Service::Response')) ) {

		die LS::SOAP::Fault->faultcode('Server')
		                   ->faultstring('Internal processing error')
		                   ->errorcode(500)
		                   ->description(
		                   	'getDataByRange in package ' . 
		                   	(ref $handler ? ref $handler : $handler) . 
		                   	' did not return a LS::Service::Response object.'
		                     );	
	}

	if($data->isa('LS::Service::Fault')) {

		bless $data, 'LS::SOAP::Fault';
		die $data->fault();
	}

	return build MIME::Entity(Data=> $data->response());
}


package LS::SOAP::Response;

use strict;

sub new {
	my ($self, %params) = @_;

	unless (ref $self) {	

		$self = bless {
			_value=> undef,
			_expires=> undef,
			_attachment=> undef,
			_att_type=> undef,
		}, $self;

		$self->value($params{'value'}) if defined $params{'value'};
		$self->expires($params{'expires'}) if defined $params{'expires'};

		$self->attachment($params{'attachment'}) if defined $params{'attachment'};
		$self->expires($params{'type'}) if defined $params{'type'};
	}

	return $self;
}


sub value {

	my $self = shift->new();

	$_[0] ? ($self->{'_value'} = $_[0], return $self) : $self->{'_value'};
}


sub expires {

	my $self = shift->new();

	$_[0] ? ($self->{'_expires'} = $_[0], return $self) : $self->{'_expires'};
}

sub attachment {

	my $self = shift->new();

	$_[0] ? ($self->{'_attachment'} = $_[0], return $self) : $self->{'_attachment'};
}

sub type {

	my $self = shift->new();

	$_[0] ? ($self->{'_att_type'} = $_[0], return $self) : $self->{'_att_type'};
}

sub mime {

}


1;


__END__

=head1 NAME

LS::SOAP::Service - SOAP service for LSID authority, metadata, and data operations

=head1 SYNOPSIS

 #!/usr/bin/perl

 # This is a CGI script

 use LS::SOAP::Service transport => 'HTTP::CGI'

 LS::SOAP::Service
 	-> dispatch_authority_to('AuthorityService')
 	-> dispatch_metadata_to('MetadataService')
 	-> dispatch_data_to('DataService')
 	-> handle;


 package AuthorityService;


 sub getAvailableServices {
 	my $self = shift;
 	my ($lsid_string) = @_;

 	return "<wsdl></wsdl>";
 }
 
 
 package MetadataService;

 sub getMetadata {
 	return 'This is the metadata';
 }
 
 
 package DataService;
 
 sub getData {
 	my $self = shift;
 	my ($lsid) = @_;
 	
 	my $data = "";
 
 	return $data;
 }
 

=head1 DESCRIPTION

An object of the C<LS::SOAP::Service> class is used to implement an
LSID authority service, metadata service, or data service.  C<LS::SOAP::Service> is a subclass of
C<SOAP::Server>, and generates and accepts SOAP messages which are formatted
differently than those which are generated and accepted by C<SOAP::Server>.

An authority service must implement three methods: getAuthorityVersion, 
getKnownURIs, and getAvailableOperations, as defined at
L<http://i3c.org/workgroups/technical_architecture/resources/lsid/docs/LSIDResolution.htm>.

A metadata service must implement the getMetadata method.

A data service must implement the getData method.

A web service may either be an authority service, a metadata service, a data service,
or any combination of the three.

More information on LSIDs and authorities can be found at 
L<http://i3c.org/workgroups/technical_architecture/resources/lsid/docs/index.htm>.

=head1 METHODS

The superclass of C<LS::SOAP::Service> is determined by the C<transport>
parameter specified in the C<use> statement.  If no C<transport> parameter is
specified, the superclass is C<SOAP::Server>.  Otherwise, the superclass is 
C<SOAP::Transport::{transport}>.  C<LS::SOAP::Service> objects support the
methods of their superclass, and these additional methods:

=over

=item dispatch_authority_to ( $package_or_object )

This method is similar to the C<dispatch_to> method on SOAP::Service, except
that it only applies to the three required authority service methods: 
getAuthorityVersion, getKnownURIs, and getAvailableOperations.
Incoming messages containing calls to these methods
will be dispatched to the supplied package name or object instance.  For
backward compatibility, a the SOAP method getAvailableMethods will be treated
as a synonym of getAvailableOperations.  Either call will be dispatched
to the implementation function getAvailableOperations, if it is defined.
Otherwise, they will be dispatched to the implementation function
getAvailableMethods.


C<getAvailableServices> should return a WSDL string describing the operations 
available for the given LSID, which is passed in as a string.  It may also return
an object of type LS::SOAP::Response.

=item dispatch_metadata_to ( $package_or_object )

This method is similar to the C<dispatch_to> method on SOAP::Service, except
that it only applies to the metadata service method: getMetadata.
Incoming messages containing a calls this method
will be dispatched to the supplied package name or object instance.

C<getMetadata> should return the metadata for the given LSID, as a Base64 encoded
string.  It may also return an object of type LS::SOAP::Response.  
The LSID is passed in as a string.


=item dispatch_data_to ( $package_or_object )

This method is similar to the C<dispatch_to> method on SOAP::Service, except
that it only applies to the data service method getData.
Incoming messages containing a calls this method will be dispatched to the 
supplied package name or object instance.

C<getData> should return the data for the given LSID, as a Base64 encoded
string.  The LSID is passed in as a string.

=back

=head1 FAULTS

The LS::SOAP::FAULT class is provided to aid in creating SOAP faults.
In addition to the methods of SOAP::Fault, LS::SOAP Fault provides
get/set methods for an errorcode number and description string, which
are placed in the fault details.

=over

=item errorcode ( $num )

Sets or retrieves the numeric errorcode of the error.

=item description ( $desc_string )

Sets or retrieves a detailed, human readable description of the error.

Examples:

 sub getAvailablesServices {
 	my $self = shift;
 	my ($lsid_string) = @_;

	if (!known(LS::ID->new($lsid_string))) {
	 	die LS::SOAP::Fault->faultcode('Client')
		                   ->faultstring('Unknown LSID')
		                   ->errorcode(201)
		                   ->description(
		                   	'The LSID ' . 
		                   	$lsid_string . 
		                   	' is not known to this authority.'
		                     );
	}

	return "<wsdl></wsdl>";
 }

=back

=head1 COMPLEX RESPONSES WITH LS::SOAP::Response

Some methods allow you to return an object of type LS::SOAP::Response.
This enables you to return additional information in the header of the SOAP
response.  LS::SOAP::Response provides get/set methods for the return value
and the expiration time of the response.

=over

=item value ( $val )

Sets or retrieves the return value of the method call.

=item expires ( $date_time )

Sets or retrieves the expiration time of the result.  This value may be used
by caching clients.  The time should be in ISO8601 format, as specified in
the XML Schema specification, part 2 (http://www.w3.org/TR/xmlschema-2/#dateTime).


=back

=head1 SEE ALSO

L<LS::Authority::WSDL::Simple>

=head1 COPYRIGHT

Copyright (c) 2002,2003 IBM Corporation.
All rights reserved.   This program and the accompanying materials
are made available under the terms of the Common Public License v1.0
which accompanies this distribution, and is available at
L<http://www.opensource.org/licenses/cpl.php>

# =====================================================================
# Copyright (c) 2002,2003 IBM Corporation 
# All rights reserved.   This program and the accompanying materials
# are made available under the terms of the Common Public License v1.0
# which accompanies this distribution, and is available at
# http://www.opensource.org/licenses/cpl.php
# 
# =====================================================================
package LS::HTTP::Service;

use strict;
use warnings;

use vars qw( $METHODS );

use URI;
use HTTP::Status;
use HTTP::Response;

use LS;
use LS::Service;


use base 'LS::Service';


#
# new( %options ) -
#
sub new {

	my $self = shift;

	unless (ref $self) {

		$self = $self->SUPER::new(@_);
	}

	return $self;
}


sub dispatch_authority_to {

        my $self = shift->new;

        @_ ? ($self->{'_dispatch_authority_to'} = $_[0], return $self)
           : return $self->{'_dispatch_authority_to'};
}


sub dispatch_metadata_to {

        my $self = shift->new;

        @_ ? ($self->{'_dispatch_metadata_to'} = $_[0], return $self)
           : return $self->{'_dispatch_metadata_to'};
}


sub dispatch_data_to {

        my $self = shift->new;

        @_ ? ($self->{'_dispatch_data_to'} = $_[0], return $self)
           : return $self->{'_dispatch_data_to'};
}


#
# Internal routines used to invoke various services
#

sub do_authority {

	my ($self, $lsid) = @_;

	#
	# Make sure we have an authority service hooked up to this thing
	#
	my $handler = $self->dispatch_authority_to();

	unless($handler && $handler->can('getAvailableServices')) {

		LS::HTTP::Fault->fault('Method Not Implemented')->to_http_response();

		return undef;
	}


	$lsid = new LS::ID($lsid);

	unless(UNIVERSAL::isa($lsid, 'LS::ID')) {

		LS::HTTP::Fault->fault('Invalid LSID')->to_http_response();

		return undef;
	}

	my $services = $handler->getAvailableServices($lsid);

	unless(UNIVERSAL::isa($services, 'LS::Service::Response')) {

		if(UNIVERSAL::isa($services, 'LS::Service::Fault')) {

			bless $services, 'LS::HTTP::Fault';
			$services->to_http_response();
		}
		else {

			LS::HTTP::Fault->fault('Internal Server Error')->to_http_response();
		}

		return undef;
	}

        my $response = HTTP::Response->new(200);

        $response->header('Content-Type'=> ($services->format() || 'application/xml') );
        $response->header('Content-Length'=> length($services->response()));

        $response->content($services->response());

	$self->print_http($response);
}


sub do_metadata {

	my ($self, $params) = @_;

	my $handler = $self->dispatch_metadata_to();

	unless($handler && $handler->can('getMetadata')) {

		LS::HTTP::Fault->fault('Method Not Implemented')->to_http_response();

		return undef;
	}

	$params =~ s/^\?//;
	my @p = split /[&]/, $params;

	my %url_params;

	foreach (@p) {

		my ($option, $val) = split /[=]/;

		$url_params{$option} = URI::Escape::uri_unescape($val);
	}

	my $metadata = $handler->getMetadata($url_params{'lsid'}, $url_params{'acceptedFormats'});

	unless(UNIVERSAL::isa($metadata, 'LS::Service::Response')) {

		if(UNIVERSAL::isa($metadata, 'LS::Service::Fault')) {

			bless $metadata, 'LS::HTTP::Fault';
			$metadata->to_http_response();
		}
		else {

			LS::HTTP::Fault->fault('Internal Server Error')->to_http_response();
		}

		return undef;
	}

        my $response = HTTP::Response->new(200);

        $response->header('Content-Type'=> $metadata->format());
        $response->header('Content-Length'=> length($metadata->response()));

        $response->content($metadata->response());

	$self->print_http($response);
}


sub do_data {

	my ($self, $params) = @_;

	my $handler = $self->dispatch_data_to();

	unless($handler && $handler->can('getData')) {

		LS::HTTP::Fault->fault('Method Not Implemented')->to_http_response();

		return undef;
	}

	$params =~ s/^\?//;
	my @p = split /[&]/, $params;

	my %url_params;

	foreach (@p) {

		my ($option, $val) = split /[=]/;

		$url_params{$option} = URI::Escape::uri_unescape($val);
	}

	my $data = $handler->getData($url_params{'lsid'});

	unless(UNIVERSAL::isa($data, 'LS::Service::Response')) {

		if(UNIVERSAL::isa($data, 'LS::Service::Fault')) {

			bless $data, 'LS::HTTP::Fault';
			$data->to_http_response();
		}
		else {

			LS::HTTP::Fault->fault('Internal Server Error')->to_http_response();
		}

		return undef;
	}

        my $response = HTTP::Response->new(200);

        $response->header('Content-Type'=> ($data->format || 'application/octet-stream'));
        $response->header('Content-Length'=> length($data->response()));

        $response->content($data->response());

	$self->print_http($response);
}

sub do_fault {

        my ($self, $msg) = @_;

	return LS::HTTP::Fault->fault($msg);
}

sub handle {
	
	my $self = shift;
	
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

sub print_http {

	my ($self, $response) = @_;

        binmode(STDOUT);
        print STDOUT "Status: " . $response->code() . ' ' . HTTP::Status::status_message($response->code()) . "\r\n";
        print STDOUT  $response->headers_as_string();
        print STDOUT "\r\n";
        print STDOUT $response->content() . "\r\n";
}




#
#
# LSID Resolution Service Methods
#
#

sub getAvailableServices {

	my $self = shift;

	my $handler = $self->dispatch_authority_to;

	unless ($handler) {

		#die LS::HTTP::Fault->faultcode('Client')
		                   #->faultstring('Unknown method')
		                   #->errorcode(101)
		                   #->description('A call was made to an unknown method getAvailableServices.');
	}

	my $response;
	my $method_name;
	
	if ($handler->can('getAvailableServices')) {

		$method_name = 'getAvailableServices';
		$response = $handler->getAvailableServices(@_);
	}
	else {

		#die LS::SOAP::Fault->faultcode('Server')
		                   #->faultstring('Not implemented')
		                   #->errorcode(501)
		                   #->description('getAvailableServices is not implemented by this authority service.');
	}

	unless( (UNIVERSAL::isa($response, 'LS::Service::Response') || 
		 UNIVERSAL::isa($response, 'LS::Service::Fault')) ) {

		#die LS::SOAP::Fault->faultcode('Server')
		                   #->faultstring('Internal processing error')
		                   #->errorcode(500)
		                   #->description(
		                   	#$method_name . ' in package ' . 
		                   	#(ref $handler ? ref $handler : $handler) . 
		                   	#' did not return a scalar or an LS::SOAP::Response object.'
		                     #);	
	}

	if(UNIVERSAL::isa($response, 'LS::Service::Fault')) {

		bless $response, 'LS::HTTP::Fault';
		$response->to_http_response;

		return undef;
	}

	my @ret;
	if (ref $response eq 'LS::SOAP::Response') {

		if ($response->expires) {

			push(
				@ret, undef
				#SOAP::Header->name(expires => $response->expires)
					    #->prefix($METHOD_PREFIX)
					    #->uri($URI)			
			);
		}
	}
	
	return @ret;
}


sub getMetadata {

	my $self = shift;
	my $handler = $self->dispatch_metadata_to;

	unless ($handler) {

		#die LS::SOAP::Fault->faultcode('Client')
		                   #->faultstring('Unknown method')
		                   #->errorcode(101)
		                   #->description('A call was made to an unknown method getMetadata.');	
	}

	unless ($handler->can('getMetadata')) {

		#die LS::SOAP::Fault->faultcode('Server')
		                   #->faultstring('Not implemented')
		                   #->errorcode(501)
		                   #->description('getMetadata is not implemented by this metadata service.');
	}

	my $response = $handler->getMetadata(@_);

	unless( (UNIVERSAL::isa($response, 'LS::Service::Response') || 
		 UNIVERSAL::isa($response, 'LS::Service::Fault')) ) {

		#die LS::SOAP::Fault->faultcode('Server')
		                   #->faultstring('Internal processing error')
		                   #->errorcode(500)
		                   #->description(
		                   	#'getMetadata in package ' . 
		                   	#(ref $handler ? ref $handler : $handler) . 
		                   	#' did not return a scalar or an LS::SOAP::Response object.'
		                     #);
	}

	if(UNIVERSAL::isa($response, 'LS::Service::Fault')) {

		bless $response, 'LS::HTTP::Fault';
		$response->to_http_response;

		return undef;
	}

	my @ret;
	if (ref $response eq 'LS::HTTP::Response') {
		if ($response->expires) {
			push(
				@ret, undef
				#SOAP::Header->name(expires => $response->expires)
					    #->prefix($METHOD_PREFIX)
					    #->uri($URI)			
			);
		}
	}

	return @ret;
}


sub getData {

	my $self = shift;

	my $handler = $self->dispatch_data_to;

	unless ($handler) {

		#die LS::SOAP::Fault->faultcode('Client')
		                   #->faultstring('Unknown method')
		                   #->errorcode(101)
		                   #->description('A call was made to an unknown method getData.');	
	}

	unless ($handler->can('getData')) {

		#die LS::SOAP::Fault->faultcode('Server')
		                   #->faultstring('Not implemented')
		                   #->errorcode(501)
		                   #->description('getData is not implemented by this data service.');
	}

	my $data = $handler->getData(@_);

	unless( (UNIVERSAL::isa($data, 'LS::Service::Response') || UNIVERSAL::isa($data, 'LS::Service::Fault')) ) {

		#die LS::SOAP::Fault->faultcode('Server')
		                   #->faultstring('Internal processing error')
		                   #->errorcode(500)
		                   #->description(
		                   	#'getData in package ' . 
		                   	#(ref $handler ? ref $handler : $handler) . 
		                   	#' did not return a scalar.'
		                     #);	
	}

	if(UNIVERSAL::isa($data, 'LS::Service::Fault')) {

		bless $data, 'LS::HTTP::Fault';
		$data->to_http_response;

		return undef;
	}
}


#
# Faults for HTTP based authorities
#
package LS::HTTP::Fault;

use strict;
use warnings;


use LS;
use LS::Service::Fault;

use base 'LS::Service::Fault';


#
# new( %options ) -
#
sub new {

	my $self = shift;

	unless (ref $self) {

		$self = $self->SUPER::new(@_);
	}

	return $self;
}


#
# to_http_response( ) - 
#
sub to_http_response {

	my $self = shift;

        my $response = HTTP::Response->new(500);

        $response->content($self->message() . "\r\n\r\n" . $self->trace());

        $response->header('LSID-Error-Code'=> $self->code());
        $response->header('Content-Length'=> length($response->content()));

        binmode(STDOUT);
        print STDOUT "Status: " . $response->code() . ' ' . HTTP::Status::status_message($response->code()) . "\r\n";
        print STDOUT  $response->headers_as_string();
        print STDOUT "\r\n";
        print STDOUT $response->content() . "\r\n";
}


1;


__END__

=head1 NAME

LS::HTTP::Service - HTTP service for LSID authority, metadata, and data operations

=head1 SYNOPSIS

 #!/usr/bin/perl

 # This is a CGI script

 use LS::HTTP::Service;

 

=head1 DESCRIPTION

An object of the C<LS::HTTP::Service> class is used to implement
an LSID authority service, metadata service, or data service.
C<LS::HTTP::Service> is a subclass of C<LS::Service>.

An authority service must implement one method: getAvailableServices, as
defined at L<http://www.omg.org>.

A metadata service must implement the getMetadata method.

A data service must implement the getData method.

A web service may either be an authority service, a metadata service, a
data service, or any combination of the three.

More information on LSIDs and authorities can be found at L<>.

=head1 METHODS

methods of their superclass, and these additional methods:

=over

=item dispatch_authority_to ( $package_or_object )

This method is similar to the C<dispatch_to> method on SOAP::Service,
except that it only applies to the three required authority service
methods: getAuthorityVersion, getKnownURIs, and getAvailableOperations.
Incoming messages containing calls to these methods will be dispatched
to the supplied package name or object instance. For backward
compatibility, a the SOAP method getAvailableMethods will be treated as
a synonym of getAvailableOperations. Either call will be dispatched to
the implementation function getAvailableOperations, if it is defined.
Otherwise, they will be dispatched to the implementation function
getAvailableMethods.

C<getAvailableServices> should return a WSDL string describing the
operations available for the given LSID, which is passed in as a string.
It may also return an object of type LS::HTTP::Response.

=item dispatch_metadata_to ( $package_or_object )

This method is similar to the C<dispatch_to> method on SOAP::Service,
except that it only applies to the metadata service method: getMetadata.
Incoming messages containing a calls this method will be dispatched to
the supplied package name or object instance.

C<getMetadata> should return the metadata for the given LSID, as
a Base64 encoded string. It may also return an object of type
LS::SOAP::Response. The LSID is passed in as a string.


=item dispatch_data_to ( $package_or_object )

This method is similar to the C<dispatch_to> method on SOAP::Service,
except that it only applies to the data service method getData. Incoming
messages containing a calls this method will be dispatched to the
supplied package name or object instance.

C<getData> should return the data for the given LSID, as a Base64 encoded
string.  The LSID is passed in as a string.

=back

=head1 FAULTS

=over

=item errorcode ( $num )

Sets or retrieves the numeric errorcode of the error.

=item description ( $desc_string )

Sets or retrieves a detailed, human readable description of the error.

Examples:

 sub getAvailableOperations {
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

=head1 COMPLEX RESPONSES WITH LS::HTTP::Response

Some methods allow you to return an object of type LS::HTTP::Response.
This enables you to return additional information in the header of the
SOAP response. LS::HTTP::Response provides get/set methods for the
return value and the expiration time of the response.

=over

=item value ( $val )

Sets or retrieves the return value of the method call.

=item expires ( $date_time )

Sets or retrieves the expiration time of the result. This value
may be used by caching clients. The time should be in ISO8601
format, as specified in the XML Schema specification, part 2
(http://www.w3.org/TR/xmlschema-2/#dateTime).

=back

=head1 SEE ALSO

L<LS::Authority::WSDL::Simple>

=head1 COPYRIGHT

Copyright (c) 2002,2003 IBM Corporation.
All rights reserved.   This program and the accompanying materials
are made available under the terms of the Common Public License v1.0
which accompanies this distribution, and is available at
L<http://www.opensource.org/licenses/cpl.php>

# =====================================================================
# Copyright (c) 2002,2003 IBM Corporation 
# All rights reserved.   This program and the accompanying materials
# are made available under the terms of the Common Public License v1.0
# which accompanies this distribution, and is available at
# http://www.opensource.org/licenses/cpl.php
# 
# =====================================================================
package LS::Client::SOAP;

use strict;
use warnings;

use vars qw( $_METHOD_PREFIX );

use SOAP::Lite ;

use LS::ID;
use LS::Client;
use LS::Service::Response;
use LS::SOAP::Serializer;

use base 'LS::Client';


#
# $_METHOD_PREFIX -
#
$_METHOD_PREFIX = 'op';


#
# new( %options ) -
#
sub new {

	my ($self, %options) = @_;

	unless($options{'url'}) {

		$self->recordError('Missing url parameter in sub new');	
		$self->addStackTrace();
		die($self->errorDetails());
	}

	unless(ref $self) {

		$self = bless {
			%options,
			_err=> undef,
		}, $self;
	}

	my $soap = SOAP::Lite->serializer(LS::SOAP::Serializer->method_prefix($_METHOD_PREFIX))
			     ->on_fault(sub {})
			     ->on_action(sub { return ''; })
			     ->uri('http://www.ibm.com/LSID/Standard/WSDL/SchemaTypes')
			     ->proxy( $options{'url'} );

	unless($soap) {

		$self->recordError( "Unable to initialize SOAP proxy object for url: $options{url}" );
		$self->addStackTrace();
		die($self->errorDetails());
	}

	$self->{'_soap'} = $soap;

	return $self;
}


#
# getContent( %options ) -
#
sub getContent {

	my ($self, %options) = @_;

	unless($options{'method'}) {

		$self->recordError( 'Missing method parameter in sub getContent' );
		$self->addStackTrace();
		die($self->errorDetails());
	}
	
	my $method = $options{'method'};
	delete $options{'method'};

	my $service = $self->{'_soap'};
	my @params = @{ $options{'params'} } if($options{'params'});

	if($self->credentials()) {

		my $username = $self->credentials->username();
		my $password = $self->credentials->password();

		eval("sub SOAP::Transport::HTTP::Client::get_basic_credentials { return \"$username\"=> \"$password\"; }");
	}

	my $response = $service->call("$method"=> @params);

        unless($response) {

                $self->recordError( "Method: $method - returned an invalid response in sub getContent" );
		$self->addStackTrace();
                die($self->errorDetails());
        }

        if ($response->fault()) {

		my $errorCode = $response->fault->{'detail'}->{'errorcode'};
		my $faultString = $response->faultstring();
		my $description = $response->fault->{'detail'}->{'description'};

		my $faultMessage;

		$faultMessage = $faultString 
			if($faultString);
		
		$faultMessage .= ": Error Code $errorCode."
			if($errorCode);
		
		$faultMessage .= "\nDescription: $description"
			if($description);

                $self->recordError( $faultMessage );
		$self->addStackTrace();
                die($self->errorDetails());
        }

	return $response;
}


#
# getAvailableservices( %options ) -
#
sub getAvailableServices {

	my ($self, %options) = @_;

	unless($options{'lsid'}) {

		$self->recordError( 'Missing lsid parameter in sub getMetadata' );
		$self->addStackTrace();
		die($self->errorDetails());
	}

	my $lsid = $options{'lsid'};
	
        my $SOAPlsid = SOAP::Data->prefix('')
				 ->name(lsid=> $lsid->as_string());

	my $response = $self->getContent(method=> 'getAvailableServices',
					 params=> [ $SOAPlsid ] );

	return undef
		unless($response);

        $self->recordError( undef );

        #
        # OMG Spec: SOAP with MIME Attachments
        #
        if(UNIVERSAL::isa($response->{'_parts'}, 'ARRAY')) {
        	
	        my $entity = ${ $response->{'_parts'}->[1] };
	
	        my $body = $entity->bodyhandle();
	
		return LS::Service::Response->new(response=> $body->as_string());
        }
        
        $self->recordError('Response for getAvailableServices did not return MIME attachments');
        $self->addStackTrace();
        
        die($self->errorDetails());
}


#
# getMetadata( %options ) -
#
sub getMetadata {

	my ($self, %options) = @_;

	unless($options{'lsid'}) {

		$self->recordError( 'Missing lsid parameter in sub getMetadata' );
		$self->addStackTrace();

		die($self->errorDetails());
	}

        my $lsid = SOAP::Data->prefix('')
			     ->name(lsid=> $options{'lsid'}->as_string());


	my $acceptedFormats = $options{'acceptedFormats'} ? $options{'acceptedFormats'} : 'application/rdf+xml';
	my $formats = SOAP::Data->prefix('')
				->name(acceptedFormats=> $acceptedFormats);

	my $response = $self->getContent(method=> 'getMetadata',
					 params=> [ $lsid, $formats ] );

	return undef unless($response);

        $self->recordError( undef );

        #
        # OMG Spec: SOAP with MIME Attachments
        #
        if(UNIVERSAL::isa($response->{'_parts'}, 'ARRAY')) {
        	
	        my $entity = ${ $response->{'_parts'}->[1] };
	
	        my $body = $entity->bodyhandle();
	
		return LS::Service::Response->new(response=> $body->as_string());
        }
        
        $self->recordError('Response for getMetadata did not return MIME attachments');
        $self->addStackTrace();
        
        die($self->errorDetails());
}


#
# getMetadataSubset( %options ) -
#
sub getMetadataSubset {

	return LS::Service::Response->new(response=> '');
}


#
# getData( %options ) -
#
sub getData {

	my ($self, %options) = @_;

	unless($options{'lsid'}) {

		$self->recordError( 'Missing lsid parameter in sub getData' );
		$self->addStackTrace();
		die($self->errorDetails());
	}

	my $lsid = $options{'lsid'};

        my $SOAPlsid = SOAP::Data->prefix('')
			     ->name(lsid=> $lsid->as_string());

	my $response = $self->getContent(method=> 'getData',
					 params=> [ $SOAPlsid ] );

	return undef
		unless($response);

        $self->recordError( undef );

        #
        # OMG Spec: SOAP with MIME Attachments
        #
        if(UNIVERSAL::isa($response->{'_parts'}, 'ARRAY')) {
        	
	        my $entity = ${ $response->{'_parts'}->[1] };
	
	        my $body = $entity->bodyhandle();
	
		return LS::Service::Response->new(response=> $body->as_string());
        }
        
        $self->recordError('Response for getData did not return MIME attachments');
        $self->addStackTrace();
        
        die($self->errorDetails());
}


#
# getDataByRange( %options ) -
#
sub getDataByRange {

	my ($self, %options) = @_;

	unless($options{'lsid'} &&
	       $options{'start'} &&
	       $options{'length'} ) {

		$self->recordError( 'Missing parameters in sub getDataByRange' );
		$self->addStackTrace();

		die($self->errorDetails());
	}

	my $lsid = $options{'lsid'};
	my $start = $options{'start'};
	my $length = $options{'length'};

        my $SOAPlsid = SOAP::Data->prefix('')
			     ->name(lsid=> $lsid->as_string());

	my $SOAPstart = SOAP::Data
			->prefix('')
			->name(start=> $start );

	my $SOAPlength = SOAP::Data
			->prefix('')
			->name(length=> $length );

	my $response = $self->getContent(method=> 'getData',
					 params=> [ $SOAPlsid, $SOAPstart, $SOAPlength ] );

	return undef unless($response);

        $self->recordError( undef );

        #
        # OMG Spec: SOAP with MIME Attachments
        #
        if(UNIVERSAL::isa($response->{'_parts'}, 'ARRAY')) {
        	
	        my $entity = ${ $response->{'_parts'}->[1] };
	
	        my $body = $entity->bodyhandle();
	
		return LS::Service::Response->new(response=> $body->as_string());
        }
        
        $self->recordError('Response for getDataByRange did not return MIME attachments');
        $self->addStackTrace();
        
        die($self->errorDetails());
}



#
# FAN Stubs
#


#
# _fan_call( %options ) -
#
sub _fan_call {

	my ($self, %options) = @_;

	unless($options{'lsid'} &&
	       $options{'authorityName'} &&
	       $options{'method'} ) {

		$self->recordError( 'Missing parameters in sub notifyForeignAuthority' );
		$self->addStackTrace();

		die($self->errorDetails());
	}

	my $lsid = $options{'lsid'};
	my $authorityName = $options{'authorityName'};
	my $method = $options{'method'};

        my $SOAPlsid = SOAP::Data->prefix('')
			     ->name(lsid=> $lsid->as_string());

	my $SOAPan = SOAP::Data
			->prefix('')
			->name(authorityName=> $authorityName);

	my $response = $self->getContent(method=> $method,
					 params=> [ $SOAPlsid, $SOAPan ] );

	return undef unless($response);

        $self->recordError( undef );

	return LS::Service::Response->new(response=> $response);
}


#
#
# notifyForeignAuthority( $lsid, $authorityName ) 
#
sub notifyForeignAuthority {

	my $self = shift;

	return $self->_fan_call(method=> 'notifyForeignAuthority', @_);
}


#
#
# revokeNotifcationForeignAuthority( $lsid, $authorityName ) 
#
sub revokeNotificationForeignAuthority {

	my $self = shift;

	return $self->_fan_call(method=> 'revokeNotificationForeignAuthority', @_);
}

1; 

__END__

=head1 NAME

LS::Client::SOAP - Implements the SOAP protocol specific calls for invoking an LSID service

=head1 SYNOPSIS

 use LS::ID;
 use LS::Client::SOAP;

 $lsid = LS::ID->new('URN:LSID:pdb.org:PDB:112L:');

 $client = LS::Client::SOAP->new(url=> 'http://someauthority.org:8080/authority');

 $metadata = $client->getMetadata(lsid=> $lsid);

=head1 DESCRIPTION

C<LS::Client::SOAP> provides wrapper methods to invoke an
LSID service in a protocol specific manner as defined by
L<http://www.omg.org/cgi-bin/doc?dtc/04-05-01>.

=head1 CONSTRUCTORS

The following method is used to construct a new C<LS::Client::SOAP> object:

=over

=item new 

This class method creates a new C<LS::Client::SOAP> object. 

Examples:

 $soap = LS::Client::SOAP->new(url=> 'http://someauthority.org:8080/authority');

 if (!$soap) {
 	print STDERR "Unable to create protocol object!";
 }

=back

=head1 METHODS

C<LS::Client::SOAP> supports the following methods:

=over

=item getContent ( method=> $method, %options )

Generic method used to invoke $method and return any results from the
SOAP service.

=item getData ( lsid=> $lsid )

Invokes the getData service method (if available) and returns any data
from the authority.

=item getDataByRange ( lsid=> $lsid, start=> $start, length=> $length )

Invokes getDataByRange, see getData for more information.

=item getMetadata ( lsid=> $lsid )

Invokes getMetadata, see getData for more information.

=item getMetadataSubset ( lsid=> $lsid )

Invokes getMetadataSubset, see getData for more information.

=back

=head1 COPYRIGHT

Copyright (c) 2002,2003 IBM Corporation.
All rights reserved.   This program and the accompanying materials
are made available under the terms of the Common Public License v1.0
which accompanies this distribution, and is available at
L<http://www.opensource.org/licenses/cpl.php>



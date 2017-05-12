# =====================================================================
# Copyright (c) 2002,2003 IBM Corporation 
# All rights reserved.   This program and the accompanying materials
# are made available under the terms of the Common Public License v1.0
# which accompanies this distribution, and is available at
# http://www.opensource.org/licenses/cpl.php
# 
# =====================================================================
package LS::Service::Authority;

use strict;
use warnings;

use vars qw( $METHODS );

use LS;
use LS::ID;

use LS::Authority::WSDL::Simple;
use LS::Authority::WSDL::Services;
use LS::Authority::WSDL::Constants;

use base 'LS::Base';

sub BEGIN {

	$METHODS = [
		'name',
		'location',
		'authorityID',
	
		'services',
		'handlers',
	];
	
	LS::makeAccessorMethods($METHODS, __PACKAGE__);
}


#
# new( %options ) -
#
sub new {

	my $self = shift;
	my (%options) = @_;
	
	unless (ref $self) {
		
		$self = bless {
			_curID=> 1,
		}, $self;

		$self->services( {} );

		$self->name( $options{'name'} );
		$self->location( $options{'location'});
		
		# Accept either hash parameter name for the authority ID
		$self->authorityID( ($options{'authority'} || $options{'authorityID'}) );
		
		$self->addService($self->defaultName());		
		
		# Setup the handlers for implementation specific code
		# These are used instead of subclassing the LS::Service::Authority object
		$self->handlers( LS::Service::Authority::Handlers->new() );
		# Accept either hash parameter name for the authentication handler
		$self->handlers()->authenticate(  ($options{'auth_handler'} || $options{'authenticate'}) );
		$self->handlers()->getAvailableServices( $options{'getAvailableServices'} );
		$self->handlers()->notifyForeignAuthority( $options{'notifyForeignAuthority'} );
		$self->handlers()->revokeNotificationForeignAuthority( $options{'revokeNotificationForeignAuthority'} );
	}
	
	return $self;
}


#
# nextID( )
#
sub nextID {
	my $self = shift;
	return $self->{'_curID'}++;
}


#
# defaultName( )
#	Returns the default name for this authority
#
sub defaultName {

	my $self = shift;
	return $self->name();
}


#
# addService( $serviceName | serviceName=>$serviceName  )
#
sub addService {

	my $self = shift;
	
	my $serviceName;
	
	if(scalar(@_) == 1) {
		$serviceName = shift;
	}
	elsif(scalar(@_) % 2 == 0) {
		my (%options) = @_;
		$serviceName = $options{'serviceName'};
	}
	else {
	
		$self->recordError('Too many parameters');
		$self->addStackTrace();
		return undef;
	}

	unless($serviceName) {

		$self->recordError('Service name not specified');
		$self->addStackTrace();
		return undef;
	}

	# Only setup the service if it does not already exist
	$self->services()->{ $serviceName } = [ ]
		unless(exists($self->services()->{ $serviceName }));
}


#
# addPort( %options ) -
#
sub addPort {

	my $self = shift;
	
	my (%options) = @_;

	unless(exists($options{'port'}) &&
	       UNIVERSAL::isa($options{'port'}, 'LS::Authority::WSDL::Port') ) {

		$self->recordError('Must specifiy a port parameter of type LS::Authority::WSDL::Port');
		$self->addStackTrace();

		return undef;
	}

	# Get the default service name if unspecified
	$options{'serviceName'} = $self->defaultName() 
		unless($options{'serviceName'});

	unless(exists($self->services()->{ $options{'serviceName'} }) ) {
		$self->addService(serviceName=> $options{'serviceName'});
	}

	push( @{ $self->services()->{ $options{'serviceName'} }}, $options{'port'} );
}


#
# addDataPort( %options ) - 
#
sub addDataPort {

	my $self = shift;

	my (%options) = @_;

	unless($options{'endpoint'} && 
	       $options{'protocol'}) {

		$self->recordError('Missing endpoint or protocol parameter');
		$self->addStackTrace();

		return undef;
	}

	# Naming a port isn't important, people probably don't want to do it
	# unless they absolutely have to.
	unless($options{'portName'}) {
		$options{'portName'} = $options{'protocol'} . 'Data' . $self->nextID();
	}

	$options{'port'} = LS::Authority::WSDL::Simple::DataPort->newData( %options );

	return $self->addPort( %options );
}


#
# addMetadataPort( %options ) -
#
sub addMetadataPort {

	my $self = shift;

	my %options = @_;

	unless($options{'endpoint'} && 
	       $options{'protocol'}) {

		$self->recordError('Missing endpoint or protocol parameter');
		$self->addStackTrace();

		return undef;
	}

	unless($options{'portName'}) {
		$options{'portName'} = $options{'protocol'} . 'Metadata' . $self->nextID();
	}

	$options{'port'} = LS::Authority::WSDL::Simple::MetadataPort->newMetadata( %options );

	return $self->addPort( %options );
}



#
# Authority stubs - These stubs do minimal input checking from the SOAP Layer
#		    and then pass any parameters to custom definitions if present.
#		    The default behavior should be sufficient for most implementations.
#
#
#

#
# authenticate -
#
sub authenticate {
	
	my $self = shift;
	
	if($self->handlers()->authenticate()) {

		my @credentials = shift;
		# FIXME: CREDENTIAL OBJECT
		# FIXME: DO WE NEED THIS?	
		return $self->authenticate()->(@credentials);
	}
	
	return undef;
}


#
# getServices( %options ) -
#
sub getServices {
	
	my $self = shift;
	my (%options) = @_;

	my $servicesWSDL = LS::Authority::WSDL::Services->new(name=> 'AuthorityService');

	return LS::Service::Fault->fault('Internal Server Error') 
		unless(UNIVERSAL::isa($servicesWSDL, 'LS::Authority::WSDL::Services'));

	my $location = $self->location();

	return LS::Service::Fault->fault('Internal Server Error') 
		unless($location);

	my $protocolsProvided = $options{'protocols'};

	return LS::Service::Fault->fault('Internal Server Error') 
		unless($protocolsProvided && ref $protocolsProvided eq 'ARRAY');

        foreach(@{ $protocolsProvided }) {

                my $loc = $location;

		# For HTTP GET ports, we always add /authority/
                $loc .= '/authority/' 
                	if($_ ne ${ LS::Authority::WSDL::Constants::Protocols::HTTP });
                	
                $servicesWSDL->add_port(name=> $_ . 'Port',
					protocol=> $_,
					location=> $loc);
        }

	return LS::Service::Response->new(response=> $servicesWSDL->xml(),
					  format=> 'application/xml');
}


#
# getAvailableServices( $lsid ) -
#
sub getAvailableServices {
	
	my $self = shift;
	my ($lsid) = @_;
	
	return LS::Service::Fault->fault('Malformed LSID') 
		unless($lsid);
			
	$lsid = LS::ID->new($lsid);
	
	return LS::Service::Fault->fault('Malformed LSID') 
		unless($lsid);

	my $wsdl = LS::Authority::WSDL::Simple->new(
					authority=> $self->authorityID(),
					name=> $self->name(),
					lsid=> $lsid->as_string(),
					);

	return LS::Service::Fault->fault('Internal Server Error')
		unless(UNIVERSAL::isa($wsdl, 'LS::Authority::WSDL::Simple'));

	# Iterate over the services and their ports 
	foreach my $svc (keys(%{ $self->services() })) {

		my @ports = @{ $self->services()->{ $svc } };

		foreach my $p (@ports) {

			$wsdl->addPort(port=> $p,
				       serviceName=> $svc);
		}
	}

	#
	# Call out to the custom getAvailableServices method
	#
	if($self->handlers()->getAvailableServices()) {
		
		my $r;

		# Protect against die()
		eval {
			$r = $self->handlers()->getAvailableServices()->($lsid, $wsdl);
		};

		# Return a fault if the external method issues a die() or similar request
		$r = LS::Service::Fault->serverFault($@, 500)
			if($@);

		return $r if(UNIVERSAL::isa($r, 'LS::Service::Response') || 
			     UNIVERSAL::isa($r, 'LS::Service::Fault') );
	}

	return LS::Service::Response->new(response=> $wsdl->xml(),
					  format=> 'application/xml');
}



#
# FAN framework 
# NOTE: This could change
#


#
# notifyForeignAuthority( $lsid, $authorityName ) -
#
sub notifyForeignAuthority {

	my $self = shift;
	my ($lsid, $authorityName) = @_;

	return LS::Service::Fault->fault('Malformed LSID')
		unless($lsid);

	return LS::Service::Fault->fault('Invalid Method Call')
		unless($authorityName);
			
	$lsid = LS::ID->new($lsid);
	
	return LS::Service::Fault->fault('Malformed LSID')
		unless($lsid);

	unless($self->handlers()->notifyForeignAuthority()) {
		return LS::Service::Fault->fault('Method Not Implemented');
	}

	return $self->handlers()->notifyForeignAuthority()->($lsid, $authorityName);
}


#
# revokeNotificationForeignAuthority( $lsid, $authorityName ) -
#
sub revokeNotificationForeignAuthority {

	my $self = shift;
	my ($lsid, $authorityName) = @_;

	return LS::Service::Fault->fault('Malformed LSID')
		unless($lsid);
			
	return LS::Service::Fault->fault('Invalid Method Call')
		unless($authorityName);

	$lsid = LS::ID->new($lsid);
	
	return LS::Service::Fault->fault('Malformed LSID')
		unless($lsid);

	unless($self->handlers()->revokeNotificationForeignAuthority()) {
		return LS::Service::Fault->fault('Method Not Implemented');
	}

	return $self->handlers()->revokeNotificationForeignAuthority()->($lsid, $authorityName);
}


package LS::Service::Authority::Handlers;

use strict;
use warnings;

use vars qw( $METHODS );

use LS;

use base 'LS::Base';

sub BEGIN {

	$METHODS = [
		'authenticate',
		'getAvailableServices',
		'notifyForeignAuthority',
		'revokeNotificationForeignAuthority',
	];
	
	LS::makeAccessorMethods($METHODS, __PACKAGE__);
}

sub new {
	my $self = shift;
	return bless {}, $self;
}

1;

__END__

=head1 NAME

LS::Service::Authority - Authority service for LSID resolution

=head1 SYNOPSIS

 # Create an authority service with a metadata port
 my $location = 'http://localhost:80/authority/';

 # Create the authority service
 my $authority = new LS::Service::Authority(
					 name => 'hugo', 
					 authority => 'gene.ucl.ac.uk.lsid.myauthority.org', 
					 location => $location);
 #
 # Add a metadata port that uses SOAP
 #
 $authority->addPort(serviceName=> 'hugoSOAP',
                     port=> LS::Authority::WSDL::Simple::MetadataPort->newMetadata(portName=> 'SOAPMetadata',
                                                                                   endpoint=> "$location/authority/metadata",
                                                                                   protocol=> $LS::Authority::WSDL::Constants::Protocols::SOAP,
                                                                                  )
        );

=head1 DESCRIPTION

The L<LS::Service::Authority> object is used to create a custom LSID
Authority implementing its own getAvailableServices. Additionally, ports
can be added to the service (data, metadata as well as generic ports).

=head1 CONSTRUCTORS

=over 

=item new ( %options )

This will construct a new authority service with the options specified.

The C<%options> hash can contain the following keys:

=over

 name: The name of the authority
 authority: The hostname of the authority
 location: The authority's location in the form of a URL
 auth_handler: Reserved.
		
 getServices: A reference to a function that can add 
              information to the WSDL decribing how to invoke the authority
              
 getAvailableServices: A reference to a function that 
                       can add information in the authority's WSDL

=back

=back

=head1 METHODS

=over

=item addPort ( %options )

Add a port with the specified type, such as metadata or data, and
associated operations.

This method requires the following keys to be specified in %options:

=over

 type: Can be the string metaDataPortType or dataPortType
 protocol: $LS:Authority::WSDL::Constants::Protocols::SOAP|HTTP|FTP
 location: The URL of the port
 oprations: A hash of the operations that this port supports

=back

=item authenticate ( @credentials )

Reserved.

=item getAvailableServices ( )

Returns the default WSDL of the authority plus any custom ports and
then calls a function specified in the constructor for additional
customization.

=back

=head1 COPYRIGHT

Copyright (c) 2002,2003 IBM Corporation.
All rights reserved.   This program and the accompanying materials
are made available under the terms of the Common Public License v1.0
which accompanies this distribution, and is available at
L<http://www.opensource.org/licenses/cpl.php>

=cut
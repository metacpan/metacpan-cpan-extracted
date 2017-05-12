# =====================================================================
# Copyright (c) 2002,2003 IBM Corporation 
# All rights reserved.   This program and the accompanying materials
# are made available under the terms of the Common Public License v1.0
# which accompanies this distribution, and is available at
# http://www.opensource.org/licenses/cpl.php
# 
# =====================================================================
package LS::Service::Namespace;

use strict;
use warnings;

use vars qw( $METHODS );

use LS;
use LS::ID;

use base 'LS::Base';

sub BEGIN {

	$METHODS = [
		'name',
		
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

	unless(exists($options{'name'}) && defined($options{'name'})) {

		$self->recordError( 'LS::Service::Namespace requires a name parameter in sub new' );
		$self->addStackTrace();

		return undef;
	}
	
	unless (ref $self) {
		
		$self = bless {}, $self;

		$self->name($options{'name'});
		
		# Create the handlers for the various methods if the namespace object
		# is not subclassed
		$self->handlers( LS::Service::Namespace::Handlers->new() );
		
		$self->handlers()->getMetadata($options{'getMetadata'});
		$self->handlers()->getMetadataSubset($options{'getMetadataSubset'});
		
		$self->handlers()->getData($options{'getData'});
		$self->handlers()->getDataByRange($options{'getDataByRange'});
	}

	return $self;	
}


#
# name( $name )
#


#
# Handler wrappers - All error checking should be done in LS::Service::DataService
#

#
# getMetadata( $lsid, $format, @params )
#
sub getMetadata {

	my ($self, $lsid, $format, @params) = @_;

	unless($self->handlers()->getMetadata() ) {

		return LS::Service::Fault->fault('Method Not Implemented');
	}

	return $self->handlers()->getMetadata()->($lsid, $format, @params);
}


#
# getMetadataSubset( $lsid, @params )
#
sub getMetadataSubset {

	my ($self, $lsid, @params) = @_;

	unless($self->handlers()->getMetadataSubset()) {
		return LS::Service::Fault->fault('Method Not Implemented');
	}

	return $self->handlers()->getMetadataSubset()->($lsid, @params);
}


#
# getData( $lsid )
#
sub getData {

	my ($self, $lsid) = @_;

	unless($self->handlers()->getData()) {
		return LS::Service::Fault->fault('Method Not Implemented');
	}

	return $self->handlers()->getData()->($lsid);
}


#
# getDataByRange( $lsid, $start, $length )
#
sub getDataByRange {

	my ($self, $lsid, $start, $length) = @_;

	unless($self->handlers()->getDataByRange()) {
		return LS::Service::Fault->fault('Method Not Implemented');
	}

	return $self->handlers()->getDataByRange()->($lsid, $start, $length);
}


package LS::Service::Namespace::Handlers;

use strict;
use warnings;

use vars qw( $METHODS );

sub BEGIN {

	$METHODS = [
		'getMetadata',
		'getMetadataSubset',
		
		'getData',
		'getDataByRange',
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

LS::Service::Namespace - Namespace for data or metadata retrieval

=head1 SYNOPSIS

 package TestNamespace;

 use LS::Service;

 use vars qw( @ISA );

 @ISA = ( 'LS::Service::Namespace' );

 sub getMetadata {

 	 my $self = shift;

	 # $metadata_type is undefined for getData calls
	 my ($lsid, $requestedFormats) = @_;

	 #
	 # You must return a LS::Service::Response object with the data to be
	 # attached. Expiration headers should be provided in the SOAP envelope.
	 #
 	 # If there is an error, you can return an LS::Service::Fault object
	 #
	 return new LS::Service::Response(format=> 'text/plain',
					  response=> 'Metadata');
 }

 package Service;

 # Add a namespace to a metadata service
 my $ns = TestNamespace->new(name=> 'myNamespace');

 my $metadata = new LS::Service::DataService;
 $metadata->addNamespace($ns);


=head1 DESCRIPTION

Creates namespaces to be added to data or metadata services. Each
namespace is responsible for retrieving and formatting its data so that
it can be included in the SOAP MIME attachment. The specified function
can return a L<LS::Service::Response> object which can hold expiration,
data/metadata, format type returned to the client.

=head1 METHODS

=over

=item new ( %options )

Use this constructor to create namespaces with the following %option keys:

=over

 name: The name of the namespace as seen in the LSID (e.g myns is the namespace in urn:lsid:mylsid.org:myns:object)

=back

=back

=head1 METHODS

=over

=item getData ( $lsid )

Wrapper function for the user supplied method that will be called to
retrieve the data or metadata. The first and only parameter is the LSID
that is associated with the data or metadata

=back

=head1 COPYRIGHT

Copyright (c) 2002,2003 IBM Corporation.
All rights reserved.   This program and the accompanying materials
are made available under the terms of the Common Public License v1.0
which accompanies this distribution, and is available at
L<http://www.opensource.org/licenses/cpl.php>

=cut


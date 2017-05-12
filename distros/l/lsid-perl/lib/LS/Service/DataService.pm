# =====================================================================
# Copyright (c) 2002,2003 IBM Corporation 
# All rights reserved.   This program and the accompanying materials
# are made available under the terms of the Common Public License v1.0
# which accompanies this distribution, and is available at
# http://www.opensource.org/licenses/cpl.php
# 
# =====================================================================
package LS::Service::DataService;

use strict;
use warnings;

use vars qw( $METHODS );

use LS;
use LS::ID;

use base 'LS::Base';

sub BEGIN {

	$METHODS =[
		'location',
		'namespaces',
		
		'authenticationHandler',
	];
	
	LS::makeAccessorMethods($METHODS, __PACKAGE__);
}

#
# new( %options )
#
sub new {

	my ($self, %options) = @_;
	
	unless (ref $self) {
		
		$self = bless {}, $self;
		
		$self->authenticationHandler( ($options{'auth_handler'} || $options{'authenticate'} ) );
		
		$self->namespaces( {} );
	}
	
	return $self;	
}


#
# addNamespace( $namespace )
#
sub addNamespace {
	
	my $self = shift;
	my ($ns) = @_;
	
	unless(UNIVERSAL::isa($ns, 'LS::Service::Namespace') ) {

		$self->recordError('Namespace parameter is not a LS::Service::Namespace reference');
		$self->addStackTrace();

		return undef;
	}
	
	unless($ns->name()) {
	
		$self->recordError('LS::Service::Namespace does not have a name');
		$self->addStackTrace();

		return undef;
	}

	$self->namespaces()->{ $ns->name() } = $ns;
}


#
# add_namespace( $namespace )
# 	Synonym for addNamespace.
#
sub add_namespace {

	my $self = shift;
	return $self->addNamespace(@_);
}



#
# authenticate( )
#
sub authenticate {
	
	my $self = shift;
	
	if($self->authenticationHandler()) {
		
		my @credentials = shift;
		# FIXME: CREATE A CREDENTIALS OBJECT
		return $self->authenticationHandler()->(@credentials);
	}
	
	return undef;
}


#
# findNamespace( $namespace )
#
sub findNamespace {

	my $self = shift;
	my $namespace = shift;
	return $self->namespaces()->{ $namespace };
}


#
# Call points
#


#
# getData( $lsid )
#
sub getData {
	
	my ($self, $lsid) = @_;

	#
	# Make sure we have an LSID or a string representing an LSID
	#
	return LS::Service::Fault->fault('Malformed LSID')
		unless($lsid);

	$lsid = new LS::ID($lsid) 
		unless(UNIVERSAL::isa($lsid, 'LS::ID') );
	
	return LS::Service::Fault->fault('Malformed LSID')
		unless($lsid);
		
	my $ns = $self->findNamespace( $lsid->namespace() );
	return LS::Service::Fault->fault('Unknown LSID') 
		unless( $ns );
	
	return $ns->getData($lsid);
}


#
# getDataByRange( $lsid, $start, $length )
#
sub getDataByRange {

	my ($self, $lsid, $start, $length) = @_;

	# We need a range
	return LS::Service::Fault->fault('Internal server error') 
		unless($start && $length);

	return LS::Service::Fault->fault('Malformed LSID')
		unless($lsid);

	$lsid = new LS::ID($lsid)
		unless(UNIVERSAL::isa($lsid, 'LS::ID'));
	
	return LS::Service::Fault->fault('Malformed LSID')
		unless($lsid);

		
	my $ns = $self->findNamespace( $lsid->namespace() );
	return LS::Service::Fault->fault('Unknown LSID')
		unless($ns);
	
	return $ns->getDataByRange($lsid, $start, $length);
}


#
# getMetadata( $lsid, $format, @params )
#
sub getMetadata {
	
	my ($self, $lsid, $format, @params) = @_;

	return LS::Service::Fault->fault('Malformed LSID')
		unless($lsid);

	$lsid = new LS::ID($lsid)
		unless(UNIVERSAL::isa($lsid, 'LS::ID'));
	
	return LS::Service::Fault->fault('Malformed LSID')
		unless($lsid);
		

	my $ns = $self->findNamespace( $lsid->namespace() );
	return LS::Service::Fault->fault('Unknown LSID')
		unless( $ns );

	return $ns->getMetadata($lsid, $format, @params);
}


#
# getMetadataSubset( $lsid, $format, @params )
#
sub getMetadataSubset {
	
	my ($self, $lsid, $format, @params) = @_;

	return LS::Service::Fault->fault('Malformed LSID')
		unless($lsid);

	$lsid = new LS::ID($lsid)
		unless(UNIVERSAL::isa($lsid, 'LS::ID'));
	
	return LS::Service::Fault->fault('Malformed LSID')
		unless($lsid);
		

	my $ns = $self->findNamespace( $lsid->namespace() );
	return LS::Service::Fault->fault('Unknown LSID')
		unless($ns);
	
	return $ns->getMetadataSubset($lsid, @params);
}

1;

__END__

=head1 NAME

LS::Service::DataService - Data service for LSID resolution

=head1 SYNOPSIS

 my $ns = LS::Service::Namespace->new;

 my $metadata_or_data = new LS::Service::DataService;
 $metadata_or_data->addNamespace(new LS::Service::Namespace( $ns );

=head1 DESCRIPTION

This class provides support for acquiring the data or metadata for a list of namespaces.


=head1 CONSTRUCTORS

=over

=item new ( %options )

No options.

=back

=head1 METHODS

=over

=item addNamespace ( $LS::Service::Namespace )

Adds a namespace that the data service knows of. Whenever getData or
getMetadata is called, the service will dispatch the call to the correct
namespace. If the namespace does not exist an erro will be returned.

=item authenticate ( @credentials )

Reserved.

=item getData ( $lsid )

This call will attempt to dispatch the request to the appropriate
namespace and will return the value (the data for the LSID) to the
caller.

=item getMetadata ( $lsid, $accepted_formats )

This call will attempt to dispatch the request to the appropriate
namespace and will return the value (the data for the LSID) to the
caller.

=back

=head1 COPYRIGHT

Copyright (c) 2002,2003 IBM Corporation.
All rights reserved.   This program and the accompanying materials
are made available under the terms of the Common Public License v1.0
which accompanies this distribution, and is available at
L<http://www.opensource.org/licenses/cpl.php>

=cut

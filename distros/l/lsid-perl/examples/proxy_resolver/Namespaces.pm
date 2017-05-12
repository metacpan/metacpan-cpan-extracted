#!/usr/bin/perl
# =====================================================================
# Copyright (c) 2002,2003 IBM Corporation 
# All rights reserved.   This program and the accompanying materials
# are made available under the terms of the Common Public License v1.0
# which accompanies this distribution, and is available at
# http://www.opensource.org/licenses/cpl.php
# 
# =====================================================================
package Namespaces;

#
# Proxy namespaces
#

package resolver;

use strict;
use warnings;

use vars qw( @ISA $METHODS );

use LS::ID;

use LS::Service::Response;
use LS::Service::Fault;

use LS::Client::BasicResolver;


use base 'LS::Service::Namespace';



#
# BEGIN( ) -
#
sub BEGIN {

	$METHODS = [
			'resolver',
		];
}


# Create the accessors 
for my $field (@{ $METHODS } ) {

        no strict "refs";

        my $slot = __PACKAGE__ . $field;

        *$field = sub {

                my $self = shift;

                @_ ? $self->{ $slot } = $_[0] : $self->{ $slot };
        }
}



#
# new( %options ) -
#
sub new {
	
	my ($self, %options) = @_;

	$options{'name'} = ':::resolver:::';

	$self = $self->SUPER::new(%options);

	# Just in case..
	if($self) {

		my $client = LS::Client::BasicResolver->new();

		unless($client) {

			# FIXME: Fault or error??

			return undef;
		}

		$self->resolver( $client );
	}

	return $self;
}


#
# getData( $lsid ) -
#
sub getData {

	my ($self, $lsid) = @_;

	my $results;
	unless ( ($results = $self->resolver()->getData(lsid=> $lsid )) ) {

		return LS::Service::Fault->serverFault( $self->resolver()->errorString(), 500);
	}

	my $proxyResponse = LS::Service::Response->new();

	my $file = $results->response();

	# Eeek! I hope the data isn't large!
	my $data;

	while(<$file>) {

		$data .= $_;
	}

	$proxyResponse->response( $data );

	return $proxyResponse;
}


#
# getDataByRange( $lsid, $start, $length ) -
#
sub getDataByRange11 {

	my ($self, $lsid, $start, $length) = @_;
}


#
# getMetadata( $lsid, $type ) -
#
sub getMetadata {

	my ($self, $lsid, $type) = @_;

	my $results;
	unless ( ($results = $self->resolver()->getMetadata( lsid=> $lsid, format=> $type )) ) {

		return LS::Service::Fault->serverFault( $self->resolver()->errorString(), 500);
	}

	my $proxyResponse = LS::Service::Response->new(format=> ($results->format() || 'application/xml') );

	my $file = $results->response();

	my $data;

	while(<$file>) {

		$data .= $_;
	}

	$proxyResponse->response( $data );

	return $proxyResponse;
}


#
# getMetadataSubset( $lsid, @params ) -
#
sub getMetadataSubset11 {

	my ($self, $lsid, @params) = @_;
}


1;

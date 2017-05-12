# =====================================================================
# Copyright (c) 2002,2003 IBM Corporation 
# All rights reserved.   This program and the accompanying materials
# are made available under the terms of the Common Public License v1.0
# which accompanies this distribution, and is available at
# http://www.opensource.org/licenses/cpl.php
# 
# =====================================================================

package LS::Assigning::Service;

use strict;
use warnings;

use vars qw( @ISA );

use LS::ID;
use LS::Service;
use LS::Service::Response;

use LS::SOAP::Fault;
use LS::SOAP::Serializer;

use LS::Assigning::Serializer;

use SOAP::Lite;

use HTTP::Response;
use HTTP::Request;

use Carp qw(:DEFAULT);

# Used in the import method
@ISA = ();

#
# new( %options ) -
#
sub new {

	my ($self, %options) = @_; 

	unless(ref $self) {

		$self = $self->SUPER::new(@_);

		my %mappings  = (
				'http://www.omg.org/LSID/2003/Assigning/StandardSOAPBinding'=> $self
				);

                $self -> serializer(LS::SOAP::Serializer->new)
		      -> on_action(sub {})
                      -> dispatch_with( \%mappings );
				       
	}

	return $self;
}


#
# import( %options ) -
#
sub import {

        shift;
        my %options = @_;

        # The 'transport' parameter will be used to determine the superclass
        # of LS::Assigning::Service objects.

        my $transport = $options{'transport'};
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
# handler( $handler ) -
#
sub handler {

	my $self = shift;
	@_ ? ($self->{'_svc_handler'} = shift, return $self) : return $self->{'_svc_handler'};
}


#
# dispatch( ) -
#
sub dispatch {

	my $self = shift;

	$self->handler($self->{'_svc_handler'})
	     ->handle;
}

#
# LSID Assigning Service stubs
#


#
# genericMethod( $method, @params ) -
#
sub genericMethod {

	my $self = shift;
	my $method = shift;

	my (@params) = @_;

        unless ($self->handler) {

                die LS::SOAP::Fault->faultcode('Client')
                                   ->faultstring('Unknown method')
                                   ->errorcode(101)
                                   ->description("A call was made to an unknown method $method.");
        }

        my $rsp;

        if ($self->handler->can($method)) {

                $rsp = $self->handler->$method(@_);
        }
        else {

                die LS::SOAP::Fault->faultcode('Server')
                                   ->faultstring('Not implemented')
                                   ->errorcode(501)
                                   ->description("$method is not implemented by this service.");
        }

        unless($rsp) {

                die LS::SOAP::Fault->faultcode('Server')
                                   ->faultstring('Internal processing error returned object was not correct type')
                                   ->errorcode(500)
                                   ->description( '<![CDATA[' . Carp::longmess('Stack trace') . ']]>' );
        }

	if(UNIVERSAL::isa($rsp, 'LS::SOAP::Fault')) {

		bless $rsp, 'LS::SOAP::Fault';
		die $rsp->fault;
	}

        # Must be good
        return LS::Service::Response->new(response=> $rsp);
}


#
# assignLSID( ) -
#
sub assignLSID {

	my $self = shift;

	#
	# We just deserialized the SOAP message containing a propertyList
	# Unfortunately, the hash we get for that parameter is named
	# so all of our properties (except the last) are lost
	#
	# This fixes that problem
	#
	my $p_ref = $self->getParameters($self->{'_deserializer'}, 'assignLSID');

	my @param_array;

	$param_array[0] = $p_ref->[0]->[2];
	$param_array[1] = $p_ref->[1]->[2];

	# Now the hard part, the propertyList parameter
	my $plist_vals = $p_ref->[2]->[2];

	my $property_list = [];

	foreach my $property (@{ $plist_vals }) {

		push @{ $property_list }, { $property->[2]->[0]->[2]=> $property->[2]->[1]->[2] };
	}

	$param_array[2] = $property_list;

	my $svc_rsp = $self->genericMethod('assignLSID', @param_array);

	my $lsid = SOAP::Data->prefix('')
			     ->name('lsid')
			     ->type(lsid=> $svc_rsp->response);

	return $lsid;
}


#
# assignLSIDFromList( ) -
#
sub assignLSIDFromList {

	my $self = shift;

	my $p_ref = $self->getParameters($self->{'_deserializer'}, 'assignLSIDFromList');

	my @param_array;
	my $property_list = [];

	foreach my $property (@{ $p_ref->[0]->[2] }) {

		push @{ $property_list }, { $property->[2]->[0]->[2]=> $property->[2]->[1]->[2] };
	}

	$param_array[0] = $property_list;

	my $lsid_list = [];

	foreach my $lsid (@{ $p_ref->[1]->[2] }) {

		push @{ $lsid_list }, LS::ID->new($lsid->[2]);
	}

	$param_array[1] = $lsid_list;
	
	my $svc_rsp = $self->genericMethod('assignLSIDFromList', @param_array);

	my $lsid = SOAP::Data->prefix('')
			     ->name('lsid')
			     ->type(lsid=> $svc_rsp->response);

	return $lsid;
}


#
# getLSIDPattern( ) -
#
sub getLSIDPattern {

	my $self = shift;

	my $p_ref = $self->getParameters($self->{'_deserializer'}, 'getLSIDPattern');

	my @param_array;

	$param_array[0] = $p_ref->[0]->[2];
	$param_array[1] = $p_ref->[1]->[2];

	# Now the hard part, the propertyList parameter
	my $plist_vals = $p_ref->[2]->[2];

	my $property_list = [];

	foreach my $property (@{ $plist_vals }) {

		push @{ $property_list }, { $property->[2]->[0]->[2]=> $property->[2]->[1]->[2] };
	}

	$param_array[2] = $property_list;

	my $svc_rsp = $self->genericMethod('getLSIDPattern', @param_array);

	my $lsid_pattern = $svc_rsp->response;

	return SOAP::Data->prefix('')
			 ->name('LSIDPattern')
			 ->type(LSIDPattern=> $svc_rsp->response);
}


#
# getLSIDPatternFromList( ) -
#
sub getLSIDPatternFromList {

	my $self = shift;

	my $p_ref = $self->getParameters($self->{'_deserializer'}, 'getLSIDPattern');

	my @param_array;
	my $property_list = [];

	foreach my $property (@{ $p_ref->[0]->[2] }) {

		push @{ $property_list }, { $property->[2]->[0]->[2]=> $property->[2]->[1]->[2] };
	}

	$param_array[0] = $property_list;

	my $lsid_list = [];

	foreach my $lsid (@{ $p_ref->[1]->[2] }) {

		push @{ $lsid_list }, $lsid->[2];
	}

	$param_array[1] = $lsid_list;

	my $svc_rsp = $self->genericMethod('getLSIDPatternFromList', @param_array);

	my $lsid_pattern = $svc_rsp->response;

	return SOAP::Data->prefix('')
			 ->name('LSIDPattern')
			 ->type(LSIDPattern=> $svc_rsp->response);
}

#
# assignLSIDForNewRevision( ) -
#
sub assignLSIDForNewRevision {

	my $self = shift;

	my $svc_rsp = $self->genericMethod('assignLSIDForNewRevision', @_);

	return SOAP::Data->prefix('')
			 ->name('LSID')
			 ->type(lsid=> $svc_rsp->response);
}


#
# getAllowedPropertyNames( ) - 
#
sub getAllowedPropertyNames {

	my $self = shift;

	my $svc_rsp = $self->genericMethod('getAllowedPropertyNames', @_);

	return SOAP::Data->prefix('')
			 ->name('propertyNames')
			 ->type(propertyNameList=> $svc_rsp->response);
}


#
# getAuthoritiesAndNamespaces( ) -
#
sub getAuthoritiesAndNamespaces {

	my $self = shift;

	my $svc_rsp = $self->genericMethod('getAuthoritiesAndNamespaces', @_);

	return SOAP::Data->prefix('')
			 ->name('authorityAndNamespaces')
			 ->type(authorityNamespaceList=> $svc_rsp->response);
}

#
# WORKAROUND for buggy deserializer in SOAP::Lite
#
sub getParameters {

	my $self = shift;
	my $d = shift;
	my $method = shift; # Just in case we need this later on

	my $ids = $d->{'_ids'};

	#//Envelope//Body//method
	return $ids->[2]->[0]->[2]->[0]->[2];
}

1;

__END__

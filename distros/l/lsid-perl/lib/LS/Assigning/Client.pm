# =====================================================================
# Copyright (c) 2002,2003 IBM Corporation 
# All rights reserved.   This program and the accompanying materials
# are made available under the terms of the Common Public License v1.0
# which accompanies this distribution, and is available at
# http://www.opensource.org/licenses/cpl.php
# 
# =====================================================================

package LS::Assigning::Client;

use strict;
use warnings;

use LS;
use LS::ID;
use LS::Client;

use LS::Service::Response;

use LS::Assigning::Serializer;

use SOAP::Lite;

use base 'LS::Client';


#
# new( %options ) -
#
sub new {

        my ($self, %options) = @_;

        unless($options{'url'}) {

                LS::Base->recordError('Missing url parameter in sub new');
		LS::Base->addStackTrace();

                return undef;
        }

        unless(ref $self) {

                $self = bless {

                        %options,

                        _err=> undef,
                }, $self;
        }

        my $soap = SOAP::Lite->on_fault(sub {})
                             ->on_action(sub { return ''; })
                             ->uri('http://www.omg.org/LSID/2003/Assigning/StandardSOAPBinding')
                             ->proxy( $options{'url'} );

        unless($soap) {

                $self->recordError("Unable to initialize SOAP proxy object for url: $options{url}");
		$self->addStackTrace();

                return undef;
        }

	$self->{'_soap'} = $soap;

	return $self;
}

#
# _soap_call( %options ) -
#
sub _soap_call {

        my ($self, %options) = @_;

        unless($options{'method'}) {

                $self->recordError('Missing method parameter in sub getContent');
		$self->addStackTrace();

                return undef;
        }

        my $method = $options{'method'};
        delete $options{'method'};

        my $service = $self->{'_soap'};
        my @params = @{ $options{'params'} } if($options{'params'});

        if($self->credentials) {

                my $username = $self->credentials->username;
                my $password = $self->credentials->password;

                eval("sub SOAP::Transport::HTTP::Client::get_basic_credentials { return $username=> $password; }");
        }

        my $som = $service->call("$method"=> @params);

        unless($som) {

                $self->recordError("Method: $method - returned an invalid response in sub getContent");
		$self->addStackTrace();

                return undef;
        }

        if ($som->fault) {

                $self->{'_err'} = $som->faultstring . "\n" .
			( ref $som->faultdetail  ? $som->faultdetail->{'errorcode'} . ' - ' . $som->faultdetail->{'description'} : 'No details provided' );
                return undef;
        }

        return $som;
}

#
# assignLSID( %options ) -
#
sub assignLSID {

	my ($self, %options) = @_;

	unless($options{'authority'} && 
	       $options{'namespace'} &&
	       $options{'propertyList'}) {

                $self->recordError('Missing method parameter in sub assignLSID');
		$self->addStackTrace();

                return undef;
	}

	my $authority = SOAP::Data->prefix('')
				  ->name(authority=> $options{'authority'});

	my $namespace = SOAP::Data->prefix('')
				  ->name(namespace=> $options{'namespace'});

	my $properties = SOAP::Data->prefix('')
				   ->name('propertyList')
				   ->type(propertyList=> $options{'propertyList'} );

	my $som = $self->_soap_call(method=> 'assignLSID',
				    params=> [ $authority, $namespace, $properties ]);

	return undef unless($som);

	return LS::Service::Response->new(response=> $som->result);
}


#
# assignLSIDFromList( %options ) -
#
sub assignLSIDFromList {

	my ($self, %options) = @_;

	unless($options{'LSIDList'} &&
	       $options{'propertyList'}) {

                $self->recordError('Missing method parameter in sub assignLSIDFromList');
		$self->addStackTrace();

                return undef;
	}

	my $properties = SOAP::Data->prefix('')
			           ->name('propertyList')
				   ->type(propertyList=> $options{'propertyList'});

	my $lsids = SOAP::Data->prefix('')
			      ->name('suggestedLSIDs')
			      ->type(LSIDList=> $options{'LSIDList'} );

	my $som = $self->_soap_call(method=> 'assignLSIDFromList',
				    params=> [ $properties, $lsids ]);

	return undef unless($som);

	return LS::Service::Response->new(response=> $som->result);
}


#
# getLSIDPattern( %options ) -
#
sub getLSIDPattern {

	my ($self, %options) = @_;

	unless($options{'authority'} && 
	       $options{'namespace'} &&
	       $options{'propertyList'}) {

                $self->recordError('Missing method parameter in sub getLSIDPattern');
		$self->addStackTrace();

                return undef;
	}

	my $authority = SOAP::Data->prefix('')
				  ->name(authority=> $options{'authority'});

	my $namespace = SOAP::Data->prefix('')
				  ->name(namespace=> $options{'namespace'});

	my $properties = SOAP::Data->prefix('')
				   ->name('propertyList')
				   ->type(propertyList=> $options{'propertyList'} );

	my $som = $self->_soap_call(method=> 'getLSIDPattern',
				    params=> [ $authority, $namespace, $properties ]);

	return undef unless($som);

	return LS::Service::Response->new(response=> $som->result);
}


#
# getLSIDPatternFromList( %options ) -
#
sub getLSIDPatternFromList {

	my ($self, %options) = @_;

	unless($options{'propertyList'} &&
	       $options{'LSIDPatternList'}) {

                $self->recordError('Missing method parameter in sub getLSIDPatternFromList');
		$self->addStackTrace();

                return undef;
	}

	my $properties = SOAP::Data->prefix('')
				   ->name('propertyList')
				   ->type(propertyList=> $options{'propertyList'} );

	my $patterns = SOAP::Data->prefix('')
				 ->name('suggestedLSIDPatterns')
				 ->type(LSIDPatternList=> $options{'LSIDPatternList'} );

	my $som = $self->_soap_call(method=> 'getLSIDPatternFromList',
				    params=> [ $properties, $patterns ]);

	return undef unless($som);

	return LS::Service::Response->new(response=> $som->result);
}


#
# assignLSIDForNewRevision( %options ) - 
#
sub assignLSIDForNewRevision {

	my ($self, %options) = @_;

	unless($options{'lsid'}) {

                $self->recordError('Missing method parameter in sub assignLSIDForNewRevision');
		$self->addStackTrace();

                return undef;
	}

	my $lsid = $options{'lsid'};
	$lsid = LS::ID->new( $options{'lsid'} )->as_string if(! UNIVERSAL::isa($options{'lsid'}, 'LS::ID'));

	unless($lsid) {

		$self->recordError('Parameter is not of correct type: LS::ID in sub assignLSIDForNewRevision');
		$self->addStackTrace();

		return undef;
	}

	$lsid = $lsid->as_string;

	my $SOAPlsid = SOAP::Data->prefix('')
				 ->name('previousLSID'=> $lsid);

	my $som = $self->_soap_call(method=> 'assignLSIDForNewRevision',
				    params=> [ $SOAPlsid ]);

	return undef unless($som);

	return LS::Service::Response->new(response=> $som->result);
}


#
# getAllowedPropertyNames( %options ) -
#
sub getAllowedPropertyNames {

	my $self = shift;

	my $som = $self->_soap_call(method=> 'getAllowedPropertyNames',
				    params=> [ ]);

	return undef unless($som);

	my $p_ref = $self->getMethodResponse($som);

	my $r = [];

	foreach my $prop (@{ $p_ref->[0]->[2] }) {

		push @{ $r }, $prop->[2];
	}

	return LS::Service::Response->new(response=> $r);
}


#
# getAuthoritiesAndNamespaces( %options ) -
#
sub getAuthoritiesAndNamespaces {

	my $self = shift;

	my $som = $self->_soap_call(method=> 'getAuthoritiesAndNamespaces',
				    params=> [ ]);

	return undef unless($som);

	my $p_ref = $self->getMethodResponse($som);

	my $r = [];

	foreach my $an (@{ $p_ref->[0]->[2] }) {


		my $a = $an->[2]->[0]->[2];
		my $n = $an->[2]->[1]->[2];

		push @{ $r }, { $a=> $n };
	}

	return LS::Service::Response->new(response=> $r);
}

#
# SOAP::Lite bug
#
sub getMethodResponse {

	my $self = shift;
	my $som = shift;
	my $method = shift;

	return $som->{'_content'}->[2]->[0]->[2]->[0]->[2];
}

1;

__END__

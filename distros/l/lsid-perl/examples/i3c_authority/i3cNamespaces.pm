#!/usr/bin/perl
# =====================================================================
# Copyright (c) 2002,2003 IBM Corporation 
# All rights reserved.   This program and the accompanying materials
# are made available under the terms of the Common Public License v1.0
# which accompanies this distribution, and is available at
# http://www.opensource.org/licenses/cpl.php
# 
# =====================================================================


package formats;

use strict;
use warnings;

use LS::ID;

use LS::Service::Response;
use LS::Service::Fault;

use base 'LS::Service::Namespace';

sub new {
	
	my ($self, %options) = @_;

	$options{'name'} = 'formats';

	return $self->SUPER::new(%options);
}

sub getMetadata {

	my ($self, $lsid, $type) = @_;
		
	my $fname = $lsid->namespace . '/' . $lsid->object . '.metadata';

	return LS::Service::Fault->fault('Unknown LSID') unless (-e $fname);

	#
	# This simple authority just reads in the data from flat files
	# organized in directories named after their namespace
	#
	my $inf;
	
	open($inf, "$fname");
	local $/ = undef;
	my $metaData= <$inf>;
	close($inf);
	
	return LS::Service::Fault->serverFault("Cannot load metadata", 600) unless ($metaData);

	$type = 'application/rdf+xml' if(!$type);
	return LS::Service::Response->new(response=>$metaData,
					  format=> $type);

}

package types;

use strict;
use warnings;

use LS::ID;

use LS::Service::Response;
use LS::Service::Fault;

use base 'LS::Service::Namespace';


sub new {
	
	my ($self, %options) = @_;

	$options{'name'} = 'types';

	return $self->SUPER::new(%options);
}


sub getMetadata {

	my ($self, $lsid, $type) = @_;
		
	my $fname = $lsid->namespace . '/' . $lsid->object . '.metadata';

	return LS::Service::Fault->fault('Unknown LSID') unless (-e $fname);

	#
	# This simple authority just reads in the data from flat files
	# organized in directories named after their namespace
	#
	my $inf;
	
	open($inf, "$fname");
	local $/ = undef;
	my $metaData= <$inf>;
	close($inf);
	
	return LS::Service::Fault->serverFault("Cannot load metadata", 600) unless ($metaData);

	$type = 'application/rdf+xml' if(!$type);
	return LS::Service::Response->new(response=>$metaData,
					  format=> $type);

}

package predicates;

use strict;
use warnings;


use LS::ID;

use LS::Service::Response;
use LS::Service::Fault;

use base 'LS::Service::Namespace';

sub new {
	
	my ($self, %options) = @_;

	$options{'name'} = 'predicates';

	return $self->SUPER::new(%options);
}

sub getMetadata {

	my ($self, $lsid, $type) = @_;
		
	my $fname = $lsid->namespace . '/' . $lsid->object . '.metadata';

	return LS::Service::Fault->fault('Unknown LSID') unless (-e $fname);

	#
	# This simple authority just reads in the data from flat files
	# organized in directories named after their namespace
	#
	my $inf;
	
	open($inf, $fname);
	local $/ = undef;
	my $metaData= <$inf>;
	close($inf);
	
	return LS::Service::Fault->serverFault("Cannot load metadata", 600) unless ($metaData);

	$type = 'application/rdf+xml' if(!$type);
	return LS::Service::Response->new(response=>$metaData,
					  format=> $type);
}

1;

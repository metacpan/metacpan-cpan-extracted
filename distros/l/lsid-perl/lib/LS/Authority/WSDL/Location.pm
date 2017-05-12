# ====================================================================
# Copyright (c) 2002,2003 IBM Corporation 
# All rights reserved.   This program and the accompanying materials
# are made available under the terms of the Common Public License v1.0
# which accompanies this distribution, and is available at
# http://www.opensource.org/licenses/cpl.php
# 
# =====================================================================
package LS::Authority::WSDL::Location;

use strict;
use warnings;

use vars qw( $METHODS );

use LS;


#
# BEGIN( ) - 
#
sub BEGIN {

	$METHODS = [
		'protocol',
		'url',
		'method',
		'binding',
		'name',
		'parentName',
	];
	
	LS::makeAccessorMethods($METHODS, __PACKAGE__);
}


#
# new( %options ) -
#
sub new {
	
	my $self = shift;
	my (%params) = @_;

	unless (ref $self) {
		
		$self = bless {
			# protocol
			# url
			# method (for http protocol)
			# binding reference
			# name of the port
			# name of the parent service
		}, $self;
	}

	foreach my $parameter (@{ $METHODS }) {
	
		$self->$parameter( $params{$parameter})
			if(exists($params{$parameter}));
	}

#	$self->protocol($params{'protocol'})
#		if($params{'protocol'});
#	
#	$self->url($params{'url'})
#		if($params{'url'});
#	
#	$self->method($params{'method'})
#		if($params{'method'});
#
#	$self->name($params{'name'})
#		if($params{'name'});
#	
#	$self->parentName($params{'parentName'})
#		if($params{'parentName'});
	
	return $self;
}


1;

__END__
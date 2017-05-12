# ====================================================================
# Copyright (c) 2002,2003 IBM Corporation 
# All rights reserved.   This program and the accompanying materials
# are made available under the terms of the Common Public License v1.0
# which accompanies this distribution, and is available at
# http://www.opensource.org/licenses/cpl.php
# 
# =====================================================================
package LS::Authority::WSDL::Mappings;

use strict;
use warnings;


#
# $VERSION -
#
my $VERSION = 'OMG-04-05-01';


#
# %URI_MAPPINGS -
#
my %URI_MAPPINGS = (

	'OMG-04-05-01'=> {
			'LSIDMetadataSubsetHTTPBinding'=> 'http://www.omg.org/LSID/2003/DataServiceHTTPBindings',
			'LSIDMetadataHTTPBinding'=> 'http://www.omg.org/LSID/2003/DataServiceHTTPBindings',
			'LSIDDataHTTPBinding'=> 'http://www.omg.org/LSID/2003/DataServiceHTTPBindings',

			'LSIDMetadataSubsetSOAPBinding'=> 'http://www.omg.org/LSID/2003/DataServiceSOAPBindings',
			'LSIDMetadataSOAPBinding'=> 'http://www.omg.org/LSID/2003/DataServiceSOAPBindings',
			'LSIDDataSOAPBinding'=> 'http://www.omg.org/LSID/2003/DataServiceSOAPBindings',

			'LSIDAuthorityHTTPBinding'=> 'http://www.omg.org/LSID/2003/AuthorityServiceHTTPBindings',
			'LSIDAuthoritySOAPBinding'=> 'http://www.omg.org/LSID/2003/AuthorityServiceSOAPBindings',
			 },

);


#
# %PREFIX_MAPPINGS - 
#
my %PREFIX_MAPPINGS = (

	'OMG-04-05-01'=> {
			'LSIDMetadataSubsetHTTPBinding'=> 'dhb',
			'LSIDMetadataHTTPBinding'=> 'dhb',
			'LSIDDataHTTPBinding'=> 'dhb',

			'LSIDMetadataSubsetSOAPBinding'=> 'dsb',
			'LSIDMetadataSOAPBinding'=> 'dsb',
			'LSIDDataSOAPBinding'=> 'dsb',

			'LSIDAuthorityHTTPBinding'=> 'ahb',
			'LSIDAuthoritySOAPBinding'=> 'asb',
			 },
);


#
# uriToBinding( $uri ) -
#
sub uriToBinding {

	shift;

	my $uri = shift;

	foreach my $binding (keys(%{ $URI_MAPPINGS{ $VERSION } })) {

		return $binding if( $URI_MAPPINGS{$VERSION}->{ $binding } eq $uri);
	}

	return undef;
}


#
# bindingToURI( $binding ) -
#
sub bindingToURI {

	shift; # Throw away
	
	my $binding = shift;

	return $URI_MAPPINGS{$VERSION}->{ $binding };
}


#
# bindingToPrefix( $binding ) -
#
sub bindingToPrefix {

	shift;

	my $binding = shift;

	return $PREFIX_MAPPINGS{$VERSION}->{ $binding };
}


#
# import( %options ) -
#
sub import {

	shift;

	my (%options) = @_;

	$VERSION = ($options{'version'} || 'OMG-04-05-01');


	return 1;
}

1;

__END__

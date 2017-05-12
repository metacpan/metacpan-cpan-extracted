#!/usr/bin/perl
# =====================================================================
# Copyright (c) 2002,2003 IBM Corporation 
# All rights reserved.   This program and the accompanying materials
# are made available under the terms of the Common Public License v1.0
# which accompanies this distribution, and is available at
# http://www.opensource.org/licenses/cpl.php
# 
# =====================================================================

#
# Used to dump out the response
#
use Data::Dumper;

use LS::ID;
use LS::Assigning::Client;

my @methods = qw(
		assignLSID 
		assignLSIDFromList 
		getLSIDPattern 
		getLSIDPatternFromList 
		assignLSIDForNewRevision 
		getAllowedPropertyNames 
		getAuthoritiesAndNamespaces
	      );

#
# Interface to the client
#
my $client = LS::Assigning::Client->new(url=> 'http://127.0.0.1:8081/assigning');

#
# This hash contains all parameters necessary to make all calls
#
my %options = ( 
		    authority=> 'authority_param',
		    namespace=>'namespace_param',
		    lsid=> LS::ID->new('urn:lsid:lsid.i3c.org:formats:csv'),
		    LSIDPatternList=> [ 'pattern1', 'pattern2' ],
		    LSIDList=> [ LS::ID->new('urn:lsid:gene.ucl.ac.uk.lsid.i3c.org:hugo:MVP'), LS::ID->new('urn:lsid:lsid.i3c.org:formats:csv') ],
		    propertyList=> [ { apple=> 'orange' }, { bannanna=>'grape'} ] 

);

foreach my $method (@methods) {

	my $response = $client->$method( %options );

	unless($response) {

		print "$method ---> Error: "  . ($client->error_string || 'No error') . "\n";
	}

	print "$method response ---> " . Dumper($response);
}

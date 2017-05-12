#!/usr/bin/perl -w
# =====================================================================
# Copyright (c) 2002,2003 IBM Corporation 
# All rights reserved.   This program and the accompanying materials
# are made available under the terms of the Common Public License v1.0
# which accompanies this distribution, and is available at
# http://www.opensource.org/licenses/cpl.php
# 
# =====================================================================
use strict;

use LS::ID;

use URI; # Used to decode the URL parameter
use CGI qw(:standard); # This is a CGI

#
# Global variables
#
#
my $SELF = 'biopathways.org';


my $q = new CGI;



print $q->header;


#
# Get the LSID from the URL
#
my $lsid = &get_lsid;

if(!$lsid) {

	# Which HTTP error to return?

	die("Unable to parse LSID\n");
}

#
# Determine if the LSID is addressed to this
# authority
#

if(!$SELF eq $lsid->authority) {

	# Which HTTP error to return?
	die("Not authority for LSID");
}


#
# Determine if it exists
#
my $filename = $lsid->namespace . '/' . $lsid->object . '.metadata';  

if(-e $filename) {

        my $inf;

        if(!open($inf,$filename)) {

		# Which HTTP error to return
	}
 
        while(<$inf>) {

		print "$_\n";
	}

        close($inf);
}
else {

	# Which HTTP error to return?
	die("Unable to open LSID\n");
}



#
# Gets the LSID from the URL parameter
#
sub get_lsid {

	if(param('lsid')) {
		my $lsid = URI::Escape::uri_unescape(param('lsid'));
		return LS::ID->new($lsid);
	}

	return undef;
}


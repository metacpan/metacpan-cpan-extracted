# $Id: WSDL05.t 1504 2005-11-10 15:01:20Z evanchsa-oss $
# =====================================================================
# Copyright (c) 2002,2003 IBM Corporation 
# All rights reserved.   This program and the accompanying materials
# are made available under the terms of the Common Public License v1.0
# which accompanies this distribution, and is available at
# http://www.opensource.org/licenses/cpl.php
# 
# =====================================================================

#
# Test:
#
#	LS::Authority::WSDL
#	LS::Authority::WSDL::Service
#

use Test::More qw(no_plan);

use strict;
use warnings;

use Data::Dumper;


BEGIN { 

	use_ok( 'LS::Authority::WSDL' );
	use_ok( 'LS::Authority::WSDL::Services' );
}




sub readWSDL {

	my $filename = shift;
	
	my $data;
	ok(open(WSDL, $filename), 'Open authority WSDL file');
	local $/ = undef;
	$data = <WSDL>;
	close(WSDL);
	
	return $data;
}


#
# WSDL File: t/authority04.wsdl
#
my $wsdlData = &readWSDL('t/authority05.wsdl');
ok($wsdlData, 'WSDL file: t/authority05.wsdl');

my $wsdl = LS::Authority::WSDL::Services->from_xml($wsdlData);
isa_ok($wsdl, 'LS::Authority::WSDL::Services', 'Verify object');

cmp_ok(scalar(values(%{ $wsdl->methodLocations() })), '==', '2', 'Verify number of method locations');


# SOAP location tests

my $soapLocations = $wsdl->methodLocations()->{'soapPort'};
isa_ok($soapLocations, 'ARRAY', 'Verify locations');

cmp_ok(scalar(@{ $soapLocations }), '==', '1', 'Verify number of SOAP locations');

my $location = $soapLocations->[0];
isa_ok($location, 'LS::Authority::WSDL::Location', 'Verify location object');

cmp_ok($location->name(), 'eq', 'soapPort', 'Verify the name of the specific location');
cmp_ok($location->parentName(), 'eq', 'AuthorityService', 'Verify the parent service\'s name');
cmp_ok($location->method(), 'eq', '', 'Verify the method ');
cmp_ok($location->url(), 'eq', "http://lsid.biopathways.org/authority/", 'Verify the URL');
cmp_ok($location->protocol(), 'eq', ${LS::Authority::WSDL::Constants::Protocols::SOAP}, 'Verify the protocol');


# HTTP location tests

my $httpLocations = $wsdl->methodLocations()->{'httpPort'};
isa_ok($httpLocations, 'ARRAY', 'Verify locations');

cmp_ok(scalar(@{ $httpLocations }), '==', '1', 'Verify number of HTTP locations');

$location = $httpLocations->[0];
isa_ok($location, 'LS::Authority::WSDL::Location', 'Verify location object');

cmp_ok($location->name(), 'eq', 'httpPort', 'Verify the name of the specific location');
cmp_ok($location->parentName(), 'eq', 'AuthorityService', 'Verify the parent service\'s name');
cmp_ok($location->method(), 'eq', 'GET', 'Verify the method ');
cmp_ok($location->url(), 'eq', "http://lsid.biopathways.org", 'Verify the URL');
cmp_ok($location->protocol(), 'eq', ${LS::Authority::WSDL::Constants::Protocols::HTTP}, 'Verify the protocol');

__END__

$Log$
Revision 1.2  2005/11/10 15:01:20  evanchsa-oss
Removed dead code

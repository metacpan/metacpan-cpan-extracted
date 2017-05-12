# $Id: WSDL_ns01.t 1506 2005-11-10 15:30:48Z evanchsa-oss $
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
#	LS::Authority::WSDL::Simple
#

use Test::More qw(no_plan);

use strict;
use warnings;

use Data::Dumper;


BEGIN { 

	use_ok( 'LS::Authority::WSDL' );
	use_ok( 'LS::Authority::WSDL::Simple' );
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
my $wsdlData = &readWSDL('t/authorityns01.wsdl');
ok($wsdlData, 'WSDL file: t/authorityns01.wsdl');

my $wsdl = LS::Authority::WSDL::Simple->from_xml($wsdlData);
isa_ok($wsdl, 'LS::Authority::WSDL::Simple');

# METADATA PORTS
my $metaLoc = $wsdl->getMetadataLocations('NCBIHTTP');
isa_ok($metaLoc, 'ARRAY', 'Verify that the METADATA locations');

cmp_ok(scalar(@{ $metaLoc }), '==', '3', 'Verfiy that there is only ONE METADATA location');

for (0..2) {

	my $loc = $_ + 1;
	my $specificLoc = $metaLoc->[$_];
	isa_ok($specificLoc, 'LS::Authority::WSDL::Location', 'Verify the METADATA location is the proper object');
	
	cmp_ok($specificLoc->name(), 'eq', "HTTPMetadata${loc}", 'Verify the name of the specific location');
	cmp_ok($specificLoc->parentName(), 'eq', 'NCBIHTTP', 'Verify the parent service\'s name');
	cmp_ok($specificLoc->method(), 'eq', 'GET', 'Verify the method ');
	cmp_ok($specificLoc->url(), 'eq', "http://ncbi.nlm.nih.gov.lsid.biopathways.org:9090/authority/metadata${loc}/", 'Verify the URL');
	cmp_ok($specificLoc->protocol(), 'eq', ${LS::Authority::WSDL::Constants::Protocols::HTTP}, 'Verify the protocol');
}


__END__

$Log$
Revision 1.1  2005/11/10 15:30:48  evanchsa-oss
Added test and data for namespaced WSDL

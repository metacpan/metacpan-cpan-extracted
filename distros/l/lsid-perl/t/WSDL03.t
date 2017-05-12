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
# WSDL File: t/authority03.wsdl
#
my $wsdlData = &readWSDL('t/authority03.wsdl');
ok($wsdlData, 'WSDL file: t/authority03.wsdl');

my $wsdl = LS::Authority::WSDL::Simple->from_xml($wsdlData);
isa_ok($wsdl, 'LS::Authority::WSDL::Simple');

# METADATA PORTS
my $metaLoc = $wsdl->getMetadataLocations('NCBIHTTP');
isa_ok($metaLoc, 'ARRAY', 'Verify we have a array ref of METADATA locations');

cmp_ok(scalar(@{ $metaLoc }), '==', '1', 'Verfiy that there is only ONE METADATA location');

my $specificLoc = $metaLoc->[0];
isa_ok($specificLoc, 'LS::Authority::WSDL::Location', 'Verify the METADATA location is the proper object');

cmp_ok($specificLoc->name(), 'eq', 'HTTPMetadata', 'Verify the name of the specific location');
cmp_ok($specificLoc->parentName(), 'eq', 'NCBIHTTP', 'Verify the parent service\'s name');
cmp_ok($specificLoc->method(), 'eq', 'GET', 'Verify the method ');
cmp_ok($specificLoc->url(), 'eq', 'http://ncbi.nlm.nih.gov.lsid.biopathways.org:9090/authority/metadata/', 'Verify the URL');
cmp_ok($specificLoc->protocol(), 'eq', ${LS::Authority::WSDL::Constants::Protocols::HTTP}, 'Verify the protocol');


__END__

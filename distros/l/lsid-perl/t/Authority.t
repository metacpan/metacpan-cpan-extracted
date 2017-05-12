# =====================================================================
# Copyright (c) 2002,2003 IBM Corporation 
# All rights reserved.   This program and the accompanying materials
# are made available under the terms of the Common Public License v1.0
# which accompanies this distribution, and is available at
# http://www.opensource.org/licenses/cpl.php
# 
# =====================================================================

#
# Test LS::Locator and LS::Authority
#

use Test::More qw(no_plan);

BEGIN { 
	use_ok( 'LS' );
	use_ok( 'LS::ID' );
	use_ok( 'LS::Locator' );
	use_ok( 'LS::Authority' );
}

my $lsid = LS::ID->new('urn:lsid:testuri.org:namespace:object:revision');

isa_ok($lsid, 'LS::ID', 'Creating LSID');

my $locator = LS::Locator->new();
isa_ok($locator, 'LS::Locator', 'Created LS::Locator object');

$locator->localMappingFile('t/authorities');
cmp_ok($locator->localMappingFile(), 'eq', 't/authorities', 'Make sure the static host mapping file was set');

eval { $locator->loadLocalMappingFile() };
ok(!$@, 'Verify the local authority mappings were successfully read');

my $authority;
ok( ($authority = $locator->resolveAuthority($lsid)), 'Resolving authority for LSID: ' . $lsid->as_string() );

ok( &verifyAuthority($authority), 'Make sure the authority details are correct from resolution' );

$authority = LS::Authority->new_by_hostname($authority->host(), $authority->port(), $authority->path());

ok( &verifyAuthority($authority), 'Make sure the authority details are correct' );


#
# Test deprecated methods
#
eval { $authority->authenticate(username=> 'user', password=> 'pass'); };

ok($@, 'Make sure the deprecated method fails');


#
# Check each component of the authority
# with the information that should be in the
# authorities file.
#
sub verifyAuthority {

	my $authority = shift;

	isa_ok($authority, 'LS::Authority', 'Make sure the authority object is defined');

	cmp_ok( $authority->host(), 'eq', 'localhost', 'Verify the hostname');

	cmp_ok( $authority->port(), 'eq', '80', 'Verify the port');

	cmp_ok( $authority->path(), 'eq', '/authority.pl', 'Verify the remote path');
}

__END__


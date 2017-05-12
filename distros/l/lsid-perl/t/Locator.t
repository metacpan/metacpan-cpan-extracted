# =====================================================================
# Copyright (c) 2002,2003 IBM Corporation 
# All rights reserved.   This program and the accompanying materials
# are made available under the terms of the Common Public License v1.0
# which accompanies this distribution, and is available at
# http://www.opensource.org/licenses/cpl.php
# 
# =====================================================================

#
# Test LS::Locator
#

use Test::More qw(no_plan);

BEGIN { 

	use_ok( 'LS' );
	use_ok( 'LS::ID' );
	use_ok( 'LS::Locator' );
}

my $lsid = LS::ID->new('urn:lsid:testuri.org:namespace:object:revision');

isa_ok( $lsid, 'LS::ID', 'Verify the LSID ' );

my $locator = LS::Locator->new(nocache=> 0,
			       local=> 'testing');

isa_ok( $locator, 'LS::Locator', 'Verify that the locator' );


cmp_ok($locator->localMappingFile(), 'eq', 'testing', 'Set the filename for static mappings');


$locator->localMappingFile('t/authorities');
cmp_ok($locator->localMappingFile(), 'eq', 't/authorities', 'Reset the static mapping filename to a real value');


cmp_ok($locator->cacheAuthorities(), '==', '0', 'Make sure the locator will not cache authority information');

# Reset to default
$locator->cacheAuthorities( 1 );
$locator->loadLocalMappingFile();

my $authority;
$authority = $locator->resolveAuthority($lsid);
isa_ok($authority, 'LS::Authority', 'Verify the resolution method return object' );

$authority = $locator->resolve_authority($lsid);
isa_ok($authority, 'LS::Authority', 'Verify the alternate resolution method return object');



eval { $locator->clearCache(); };

ok(!$@, 'Verify the clean authority cache method');

eval { $locator->clear_cache(); };

ok(!$@, 'Verify the alternate clean authority cache method');


__END__

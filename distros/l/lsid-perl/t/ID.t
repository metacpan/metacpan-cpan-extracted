# =====================================================================
# Copyright (c) 2002,2003 IBM Corporation 
# All rights reserved.   This program and the accompanying materials
# are made available under the terms of the Common Public License v1.0
# which accompanies this distribution, and is available at
# http://www.opensource.org/licenses/cpl.php
# 
# =====================================================================

#
# Test the LS::ID Object
#

use Test::More;

BEGIN { 

	plan tests => 10;

	use_ok( 'LS' );
	use_ok( 'LS::ID' );
}


my $goodLSID = 'urn:LSID:testuri.org:namespace:object:revision';
my $badLSID  = 'urn:bad:lsid:you:stuff';



my $lsid;
ok( ($lsid = LS::ID->new( $goodLSID )) );

cmp_ok($lsid->as_string, 'eq', $goodLSID);

cmp_ok($lsid->canonical, 'eq', lc($goodLSID));


# Check each component
cmp_ok($lsid->authority, 'eq', 'testuri.org');

cmp_ok($lsid->namespace, 'eq', 'namespace');

cmp_ok($lsid->object, 'eq', 'object');

cmp_ok($lsid->revision, 'eq', 'revision');


# Make sure it didn't recognize the bad LSID
ok( ! LS::ID->new($badLSID) );


# ok

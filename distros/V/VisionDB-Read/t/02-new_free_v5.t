#!/usr/bin/perl -Tw

use strict;
BEGIN {
        $|  = 1;
        $^W = 1;
}

use Test::More tests => 6;

use VisionDB::Read;

can_ok( 'VisionDB::Read', (
	'new', 
	'free',
	'version', 
	'filename',
	'records',
	) ) || BAIL_OUT( "Some methods are missing, sorry..." );

SCOPE: {
	SKIP: {	
		my $db = VisionDB::Read->new('t/sampledata/test5_db');
		ok( defined $db, '->test object creation (Vision DB v.5)' ) || skip( '->v.5 object creation failed, skip related tests', 4 );
		is( $db->filename, 'test5_db', '->test filename string' );
		is( $db->version, 5, '->test recognized version' );
		is( $db->records, 9955, '->test number of records' ); 
		$db->free;
		ok( !defined $db->version, '->test object free' );
	}
}


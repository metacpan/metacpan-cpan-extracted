#!/usr/bin/perl -Tw

use strict;
BEGIN {
        $|  = 1;
        $^W = 1;
}

use Test::More tests => 9;

use VisionDB::Read;

can_ok( 'VisionDB::Read', (
	'new', 
	'free',
	'version', 
	'filename',
	'fields'
	) ) || BAIL_OUT( "Some methods are missing, sorry..." );

SCOPE: {
	SKIP: {
		my $db = VisionDB::Read->new('t/sampledata/test5_db');
		ok( defined $db, '->test object creation (Vision DB v.5)' ) || skip( '->v.5 object creation failed, skip related tests', 3 );
		is( $db->version, 5, '->test recognized version' );
		my @fields = $db->fields;
		is( scalar(@fields), 2, '->test number of fields' ); 
		is_deeply( \@fields, [0, 5] );
		$db->free;
	}
	SKIP: {
		my $db = VisionDB::Read->new('t/sampledata/test5-1_db');
		ok( defined $db, '->test object creation (Vision DB v.5)' ) || skip( '->v.5 object creation failed, skip related tests', 3 );
		is( $db->version, 5, '->test recognized version' );
		my @fields = $db->fields;
		is( scalar(@fields), 7, '->test number of fields' ); 
		is_deeply( \@fields, [0, 1, 2, 3, 5, 7, 9] );
		$db->free;
	}
}


#!/usr/bin/perl -Tw

use strict;
BEGIN {
        $|  = 1;
        $^W = 1;
}

use Test::More tests => 19;

use VisionDB::Read;

can_ok( 'VisionDB::Read', (
	'new', 
	'free',
	'version',
	'records',
	'next',
	'reset',
	'recno',
	) ) || BAIL_OUT( "Some methods are missing, sorry..." );

SCOPE: {
    SKIP: {
		my $db = VisionDB::Read->new('t/sampledata/test4_db');
		ok( defined $db, '->test object creation (Vision DB v.4)' ) || skip( '->v.4 object creation failed, skip related tests', 13 );
		is( $db->version, 4, '->test recognized version' );
		is( $db->records, 9955, '->test number of records' ); 

		my $rec;

		is( $db->reset, 0, '->test recno reset' );
		ok( $rec = $db->next, '->test get 1st record data' );
		is( $rec->data, 'e3289d5679', '->test 1st record value' );

		is( $db->recno(0), 0, '->test recno move to 1st record' );
		ok( $rec = $db->next, '->test get 1st record data' );
		is( $rec->data, 'e3289d5679', '->test 1st record value' );

		is( $db->recno(-1), 9954, '->test move recno to last record' );
		ok( $rec = $db->next, '->test get last record data' );
		is( $rec->data, '26c80ae6f0', '->test last record value' );

		is( $db->recno, -1, '->test recno at EOF' );

		$db->free;
		ok( !defined $db->version, '->test object free' );
	}

	SKIP: {
		my $db = VisionDB::Read->new('t/sampledata/test4-1_db');
		ok( defined $db, '->test object creation (Vision DB v.4)' ) || skip( '->v.4 object creation failed, skip related tests', 3 );
		is( $db->version, 4, '->test recognized version' );

		is( $db->next, undef, '->test next on an empty DB' );
		is( $db->error, 'cannot next on an empty DB', '->test error on next on an empty DB' );
		$db->free;
	}
}


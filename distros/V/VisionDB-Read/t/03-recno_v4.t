#!/usr/bin/perl -Tw

use strict;
BEGIN {
        $|  = 1;
        $^W = 1;
}

use Test::More tests => 28;

use VisionDB::Read;

can_ok( 'VisionDB::Read', (
	'new', 
	'free',
	'version',
	'records',
	'recno',
	'reset',
	) ) || BAIL_OUT( "Some methods are missing, sorry..." );

SCOPE: {
    SKIP: {
		my $db = VisionDB::Read->new('t/sampledata/test4_db');
		ok( defined $db, '->test object creation (Vision DB v.4)' ) || skip( '->v.4 object creation failed, skip related tests', 14 );
		is( $db->version, 4, '->test recognized version' );
		is( $db->records, 9955, '->test number of records' ); 

		my $rec;
		my $cnt = 0;

		while ($rec = $db->next) { $rec->dispose; $cnt++ } 
		is( $cnt, 9955, '->test read of all records' );

		is( $db->reset, 0, '->test recno reset' );
		is( $db->recno, 0, '->test recno ptr at 1st record' );

		is( $db->recno(0), 0, '->test recno move to 1st record' );
		is( $db->recno, 0, '->test recno ptr at 1st record' );

		is( $db->recno(-1), 9954, '->test move recno to last record' );
		is( $db->recno, 9954, '->test recno ptr at last record' );

		is( $db->recno(9955), undef, '->test recno set beyond EOF' );
		is( $db->error, 'requested record is beyond EOF', '->test recno set beyond EOF error' );
		is( $db->recno(-9956), undef, '->test recno set below BOF' );
		is( $db->error, 'requested record is below BOF', '->test recno set below BOF' );

		$db->free;
		ok( !defined $db->version, '->test object free' );
	}

	SKIP: {
		my $db = VisionDB::Read->new('t/sampledata/test4-1_db');
		ok( defined $db, '->test object creation (Vision DB v.4)' ) || skip( '->v.4 object creation failed, skip related tests', 11 );
		is( $db->version, 4, '->test recognized version' );
		is( $db->recno, -1, '->test recno ptr at EOF' );

		is( $db->reset, undef, '->test recno reset of an empty DB' );
		is( $db->error, 'cannot reset on an empty DB', '->test error on recno reset of an empty DB' );
		is( $db->recno, -1, '->test recno ptr at EOF' );

		is( $db->recno(0), undef, '->test recno move to 1st record of an empty DB' );
		is( $db->error, 'requested record is beyond EOF', '->test error on recno move to 1st record of an empty DB' );
		is( $db->recno, -1, '->test recno ptr at EOF' );

		is( $db->recno(-1), undef, '->test move recno to last record of an empty DB' );
		is( $db->error, 'requested record is below BOF', '->test error on recno move to last record of an empty DB' );
		is( $db->recno, -1, '->test recno ptr at EOF' );

		$db->free;
	}
}


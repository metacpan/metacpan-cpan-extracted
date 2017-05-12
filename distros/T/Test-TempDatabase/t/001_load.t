use warnings FATAL => 'all';
use strict;

use Test::More tests => 12;
use File::Temp qw(tempdir);
use File::Slurp;

BEGIN { use_ok( 'Test::TempDatabase' ); }

my $test_db = Test::TempDatabase->create(dbname => 'test_temp_db_test');
like(join('', `psql -l`), qr/test_temp_db_test/);

my $dbh = $test_db->handle;
ok($dbh->do(q{ create table test_table (a integer) }));

$dbh->do(q{ set client_min_messages to warning });
$dbh->do(q{ drop database if exists test_temp_db_test_2 });
$dbh->do(q{ create database test_temp_db_test_2 });

undef $test_db;

package FakeSchema;
sub new {
	my ($class, $dbh) = @_;
	return bless({ dbh => $dbh }, $class);
}

sub run_updates {
	my $self = shift;
	$self->{dbh}->do("create table aaa (a integer)");
}

package main;
$test_db = Test::TempDatabase->create(dbname => 'test_temp_db_test_2',
					schema => 'FakeSchema');
ok($test_db);
is_deeply($test_db->handle->selectcol_arrayref("select count(*) from aaa"), 
		[ 0 ]);
$test_db->handle->disconnect;

my $tdb3 = Test::TempDatabase->create(dbname => 'test_temp_db_test_3'
		, template => 'test_temp_db_test_2');
is_deeply($tdb3->handle->selectcol_arrayref("select count(*) from aaa"), 
		[ 0 ]);

my $h2 = $tdb3->connect;
isnt($h2, $tdb3->handle);
is_deeply($h2->selectcol_arrayref("select count(*) from aaa"), [ 0 ]);

ok($h2->do("insert into aaa values (12)"));
my $tdb4 = Test::TempDatabase->create(dbname => 'test_temp_db_test_3'
		, template => 'test_temp_db_test_2');
is_deeply($tdb4->handle->selectcol_arrayref("select count(*) from aaa"), 
		[ 0 ]);

my $td = tempdir('/tmp/temp_db_001_XXXXXX', CLEANUP => 1);
$tdb4->dump_db("$td/out.sql");
ok(-f "$td/out.sql");
like(read_file("$td/out.sql"), qr/aaa/);

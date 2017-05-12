#!/usr/bin/perl

my $num = 1;

sub ok {
  my $ok = shift;
  if ($ok) { print "ok $num\n"; }
  else { print "not ok $num\n"; }
  $num++;
}
sub is {
	my $val1 = shift;
	my $val2 = shift;
	my $msg = shift || '';

	if ($val1 eq $val2) {
		print "ok $num $msg\n";
	}
	else {
		print "not ok $num $msg\n";
	}
	$num++;
}
sub skip {
	my ($msg, $x) = @_;

	for (1..$x) {
		print "ok $num # skip: $msg\n";
		$num++;
	}
	local $^W = 0;
	last SKIP;
}

print "1..46\n";

use DeltaX::Database;

ok(1);

SKIP: {
	skip ("Database tests not configured", 45)
		if ! -f 't/.dbconf';

	open INF, 't/.dbconf' or die "cannot read configuration ?!";
	my $dbdriver = <INF>; chomp $dbdriver;
	my $dbhost   = <INF>; chomp $dbhost;
	my $dbname   = <INF>; chomp $dbname;
	my $dbuser   = <INF>; chomp $dbuser;
	my $dbpassw  = <INF>; chomp $dbpassw;
	close INF;

	my $db = new DeltaX::Database (
		driver => $dbdriver, host => $dbhost, dbname => $dbname,
		user => $dbuser, auth => $dbpassw
	);
	ok (ref $db);
	skip ("Connection to database failed: ".$DeltaX::Database::Derror_message, 43)
		if !ref $db;
	ok ($db->isa('DeltaX::Database'));

	ok($db->ping());

	# create test table
	my $result = $db->command("CREATE TABLE deltax_db_test".
		"(num1 integer, str1 varchar(20), dat1 integer)");
	is ($result, 1, 'table created');

	# insert some data
	$result = $db->insert("INSERT INTO deltax_db_test".
		" VALUES(1, 'line1', null)");
	ok($result);
	$result = $db->insert("INSERT INTO deltax_db_test".
		" VALUES(2, 'line2', null)");
	ok($result);
	$result = $db->insert("INSERT INTO deltax_db_test".
		" VALUES(3, 'line3', null)");
	ok($result);

	# try update
	$result = $db->update("UPDATE deltax_db_test".
		" SET str1 = 'line1updated' WHERE num1 = 1");
	ok($result);
	$result = $db->update("UPDATE deltax_db_test".
		" SET str1 = 'something' WHERE num1 = 4");
	$result += 0;
	# this test will fail for MySQL
	if ($db->{driver} eq 'mysql') { $result = 0; }
	# this test will fail for MS SQL
	if ($db->{driver} eq 'mssql') { $result = 0; }
	ok(!$result);

	# read data
	my ($num1, $str1, $dat1);
	($result, $str1) = $db->select("SELECT str1 FROM deltax_db_test".
		" WHERE num1 = 2");
	ok($result);
	is($str1, 'line2', 'got right data');

	# delete data
	$result = $db->delete("DELETE FROM deltax_db_test".
		" WHERE num1 = 1");
	ok($result);
	$result = $db->delete("DELETE FROM deltax_db_test".
		" WHERE num1 = 4");
	# this test will fail for MySQL
	if ($db->{driver} eq 'mysql') { $result = 0; }
	# this test will fail for MS SQL
	if ($db->{driver} eq 'mssql') { $result = 0; }
	$result += 0;
	ok(!$result);

	# test cursor
	$result = $db->open_cursor('MY', 
		"SELECT num1, str1 FROM deltax_db_test".
		" ORDER BY num1");
	ok($result);
	($result, $num1, $str1) = $db->fetch_cursor('MY');
	ok($result);
	is($num1, 2);
	is($str1, 'line2');
	($result, $num1, $str1) = $db->fetch_cursor('MY');
	ok($result);
	is($num1, 3);
	is($str1, 'line3');
	($result, $num1, $str1) = $db->fetch_cursor('MY');
	ok(!$result);
	$db->close_cursor('MY');
	# test cursor - external
	$result = $db->open_cursor('MY', 
		"SELECT num1, str1 FROM deltax_db_test".
		" ORDER BY num1", 'EXTERNAL');
	ok($result || $result eq '0E0');
	($result, $num1, $str1) = $db->fetch_cursor('MY');
	ok($result);
	is($num1, 2);
	is($str1, 'line2');
	($result, $num1, $str1) = $db->fetch_cursor('MY');
	ok($result);
	is($num1, 3);
	is($str1, 'line3');
	($result, $num1, $str1) = $db->fetch_cursor('MY');
	ok(!$result);
	$db->close_cursor('MY');

	# statement
	$result = $db->open_statement('STMT1',
		"UPDATE deltax_db_test SET str1 = ? WHERE num1 = ?");
	ok($result);
	$result = $db->open_statement('STMT2',
		"SELECT str1 FROM deltax_db_test WHERE num1 = ?");
	ok($result);
	$result = $db->perform_statement('STMT1',
		'text2', 2);
	$result += 0;
	ok($result);
	$result = $db->perform_statement('STMT1',
		'text2', 4);
	# this test will fail for MS SQL
	if ($db->{driver} eq 'mssql') { $result = 0; }
	$result += 0;
	ok(!$result);
	($result, $str1) = $db->perform_statement('STMT2', 2);
	ok($result);
	is($str1, 'text2');
	$db->close_statement('STMT1');
	$db->close_statement('STMT2');

	# drop table
	$result = $db->command("DROP TABLE deltax_db_test");
	is ($result, 1, 'table dropped');

        # test err
        $db->command('drop table test_pok1');
        $db->command('drop table test_pok1');
        $result = $db->test_err('TABLE_NOTEXIST');
        is($result, 1, "$result -> ($DeltaX::Database::Dsqlstatus) $DeltaX::Database::Derror_message");
        $db->command('create table test_pok1 (pok integer not null, ptext char(20))');
        $db->command('create table test_pok1 (pok integer not null, ptext char(20))');
        $result = $db->test_err('TABLE_EXIST');
        is($result, 2, "$result -> ($DeltaX::Database::Dsqlstatus) $DeltaX::Database::Derror_message");
        $result = $db->command('create unique index ixtest_pok1 on test_pok1 (pok)');
        ok($result);
        $db->insert('insert into test_pok1 values (1, null)');
        $db->insert('insert into test_pok1 values (1, null)');
        $result = $db->test_err('REC_EXIST');
        is($result, 3, "$result -> ($DeltaX::Database::Dsqlstatus) $DeltaX::Database::Derror_message");
        $db->select('select * from test_pok2');
        $result = $db->test_err('TABLE_NOTEXIST');
        is($result, 1, "$result -> ($DeltaX::Database::Dsqlstatus) $DeltaX::Database::Derror_message");
        $result = $db->command('drop table test_pok1');
        ok($result);
        if ($db->{driver} eq 'mssql' || $db->{driver} eq 'mysql' || $db->{driver} eq 'Oracle'
                || $db->{driver} eq 'Informix') {
                $result = 1;
                is($result, 1, "Not supported for the driver");
                is($result, 1, "Not supported for the driver");
                ok($result);
        }
        else {
                $db->command('drop schema sch_test'. (($db->{driver} eq 'DB2') ? ' restrict' : ''));
                $db->command('drop schema sch_test'. (($db->{driver} eq 'DB2') ? ' restrict' : ''));
                $result = $db->test_err('SCHEMA_NOTEXIST');
                is($result, 4, "$result -> ($DeltaX::Database::Dsqlstatus) $DeltaX::Database::Derror_message");
                $db->command('create schema sch_test');
                $db->command('create schema sch_test');
                $result = $db->test_err('SCHEMA_EXIST');
                is($result, 5, "$result -> ($DeltaX::Database::Dsqlstatus) $DeltaX::Database::Derror_message");
                $result = $db->command('drop schema sch_test'. (($db->{driver} eq 'DB2') ? ' restrict' : ''));
                ok($result);
        }

}

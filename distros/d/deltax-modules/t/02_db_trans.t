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

sub ins {
  my ($db, $num) = @_;

  my $result = $db->insert("INSERT INTO deltax_db_test VALUES($num, 'line$num')");
  ok ($result);
}

sub cnt {
  my ($db, $exp) = @_;

  my ($result, $cnt) = $db->select("SELECT COUNT(*) FROM deltax_db_test");
  is($cnt, $exp, "expecting count $exp, got $cnt");
}

print "1..44\n";

use DeltaX::Database;

ok(1);

my $db1;

SKIP: {
	skip ("Database tests not configured", 43)
		if ! -f 't/.dbconf';

	open INF, 't/.dbconf' or die "cannot read configuration ?!";
	my $dbdriver = <INF>; chomp $dbdriver;
	my $dbhost   = <INF>; chomp $dbhost;
	my $dbname   = <INF>; chomp $dbname;
	my $dbuser   = <INF>; chomp $dbuser;
	my $dbpassw  = <INF>; chomp $dbpassw;
	close INF;

        skip ("Transaction tests only for PostgreSQL", 43) if $dbdriver != 'Pg';

	$db1 = new DeltaX::Database (
		driver => $dbdriver, host => $dbhost, dbname => $dbname,
		user => $dbuser, auth => $dbpassw, autocommit => 1
	);
	ok (ref $db1);
	my $db2 = new DeltaX::Database (
		driver => $dbdriver, host => $dbhost, dbname => $dbname,
		user => $dbuser, auth => $dbpassw, autocommit => 1
	);
	ok (ref $db2);

	ok($db1->ping());
	ok($db2->ping());

	# create test table
	my $result = $db1->command("CREATE TABLE deltax_db_test".
		"(num1 integer, str1 varchar(20))");
	is ($result, 1, 'table created');

	# insert some data
        ins($db1, 1);
        ins($db2, 2);

	# check data
        cnt($db1, 2);
        cnt($db2, 2);

        # insert in db1 in transaction
        $result = $db1->transaction_begin();
        ok($result);
        ins($db1, 3);
        cnt($db1, 3);  # db1 - I see my new line
        cnt($db2, 2);  # db2 - do not see the new line
        $result = $db1->transaction_end(1); # commit
        ok($result);
        cnt($db1, 3);
        cnt($db2, 3);

        # the same, but rollback
        $result = $db1->transaction_begin();
        ok($result);
        ins($db1, 4);
        cnt($db1, 4);  # db1 - I see my new line
        cnt($db2, 3);  # db2 - do not see the new line
        $result = $db1->transaction_end(0); # rollback
        ok($result);
        cnt($db1, 3);
        cnt($db2, 3);

        # similar, no autocommit
        $db1->delete("DELETE FROM deltax_db_test");

	$db1 = new DeltaX::Database (
		driver => $dbdriver, host => $dbhost, dbname => $dbname,
		user => $dbuser, auth => $dbpassw, autocommit => 0
	);
	ok (ref $db1);
	$db2 = new DeltaX::Database (
		driver => $dbdriver, host => $dbhost, dbname => $dbname,
		user => $dbuser, auth => $dbpassw, autocommit => 0
	);
	ok (ref $db2);

	# insert some data
        ins($db1, 1);
        ins($db2, 2);

	# check data
        cnt($db1, 2);
        cnt($db2, 2);

        # insert in db1 in transaction
        $result = $db1->transaction_begin();
        ok($result);
        ins($db1, 3);
        cnt($db1, 3);  # db1 - I see my new line
        cnt($db2, 2);  # db2 - do not see the new line
        $result = $db1->transaction_end(1); # commit
        ok($result);
        cnt($db1, 3);
        cnt($db2, 3);

        # the same, but rollback
        $result = $db1->transaction_begin();
        ok($result);
        ins($db1, 4);
        cnt($db1, 4);  # db1 - I see my new line
        cnt($db2, 3);  # db2 - do not see the new line
        $result = $db1->transaction_end(0); # rollback
        ok($result);
        cnt($db1, 3);
        cnt($db2, 3);
}

if ($db1) {
  $db1->command("DROP TABLE deltax_db_test");
}

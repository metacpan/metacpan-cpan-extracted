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

print "1..23\n";

use DeltaX::Database;
use DeltaX::Session;

ok(1);

SKIP: {
	skip ("Database tests not configured", 13)
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
	skip ("Connection to database failed: ".$DeltaX::Database::Derror_message, 12)
		if !ref $db;
	ok ($db->isa('DeltaX::Database'));

	# create test table
	my $datetype = '';
	if ($dbdriver eq 'Oracle') { $datetype = 'date'; }
	if ($dbdriver eq 'Pg') { $datetype = 'timestamp'; }
	if ($dbdriver eq 'mysql') { $datetype = 'timestamp'; }
	if ($dbdriver eq 'Informix') { $datetype = 'datetime year to second'; }
	if ($dbdriver eq 'DB2') { $datetype = 'timestamp'; }
	if ($dbdriver eq 'Solid') { $datetype = 'timestamp'; }
	if ($dbdriver eq 'mssql') { $datetype = 'datetime'; }
	my $result = $db->command("CREATE TABLE deltax_db_test".
		"(sid varchar(10), sdata varchar(250), ts $datetype)");
	is ($result, 1, 'table created');

	my $sess = new DeltaX::Session(db=>$db, table_name=>'deltax_db_test');
	ok(defined $sess);
	ok($sess->isa('DeltaX::Session'));

	my $sid = '12345';
	$result = $sess->put($sid, key1=>'data1', key2=>'data2');
	ok($result);

	ok($sess->exist($sid));
	ok(!$sess->exist('23456'));

	# insert another session
	$result = $sess->put('23456', key1=>'datax1', key2=>'datax2');
	ok($result);
	ok($sess->exist('23456'));

	my %data = $sess->get($sid);
	is($data{'key1'},'data1');
	is($data{'key2'},'data2');

	# drop table
	$result = $db->command("DROP TABLE deltax_db_test");
	is ($result, 1, 'table dropped');

	$sess->free();
}

# file test
my $sess = new DeltaX::Session(file=>'t/.sessions');
ok(defined $sess);
ok($sess->isa('DeltaX::Session'));

my $sid = '12345';
$result = $sess->put($sid, key1=>'data1', key2=>'data2');
ok($result);

ok($sess->exist($sid));
ok(!$sess->exist('23456'));

# insert another session
$result = $sess->put('23456', key1=>'datax1', key2=>'datax2');
ok($result);
ok($sess->exist('23456'));

my %data = $sess->get($sid);
is($data{'key1'},'data1');
is($data{'key2'},'data2');

$sess->free();

unlink 't/.sessions';

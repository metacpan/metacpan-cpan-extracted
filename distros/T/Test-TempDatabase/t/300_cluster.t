use warnings FATAL => 'all';
use strict;

use Test::More tests => 10;
use File::Temp qw(tempdir);
use File::Slurp;

BEGIN { use_ok( 'Test::TempDatabase' ); }

my $td = tempdir('/dev/shm/temp_db_300_XXXXXX', CLEANUP => 1);
`chown postgres $td` unless $<;

my $test_db = Test::TempDatabase->new({ dbname => 'test_temp_db_test'
			, cluster_dir => $td });
isa_ok($test_db, 'Test::TempDatabase');
$test_db->create_cluster;
isnt(-f "$td/postgresql.conf", undef);

eval { $test_db->connect('template1'); };
like($@, qr#$td#);

my @ns = `netstat -l | grep PG`;
$test_db->start_server;
my @ns2 = `netstat -l | grep PG`;
is(@ns2, @ns + 1);

my $dbh = $test_db->connect('template1');
ok($dbh);
$dbh->disconnect;

$test_db->create_db;
ok($test_db->handle);

$dbh = $test_db->handle;
$dbh->do(q{ create table aaa (i integer) });
$test_db->dump_db("$td/out.sql");
ok(-f "$td/out.sql");
like(read_file("$td/out.sql"), qr/aaa/);

$test_db->drop_db;

$test_db->stop_server;
my @ns3 = `netstat -l | grep PG`;
is(@ns3, @ns);

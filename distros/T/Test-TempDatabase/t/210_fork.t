use strict;
use warnings FATAL => 'all';

use Test::More tests => 5;

BEGIN { use_ok('Test::TempDatabase'); }

Test::TempDatabase->become_postgres_user;

my $test_db = Test::TempDatabase->create(dbname => 'fork_test_db');
ok($test_db->handle->do("select 1"));

my $pid = fork || do {
	$test_db->handle->{InactiveDestroy} = 1;
	exit;
};
waitpid($pid, 0);
ok($test_db->handle->do("select 1"));

$pid = fork || exit;
waitpid($pid, 0);
eval {
	local $test_db->handle->{PrintError};
	$test_db->handle->do("select 1");
};
like($@, qr/unexpected/);

my $dbh = $test_db->connect("fork_test_db");
ok($dbh);
$dbh->disconnect;

use warnings FATAL => 'all';
use strict;

use Test::More tests => 8;
use POSIX qw(setuid);

BEGIN {
	use_ok('Test::TempDatabase');
};

Test::TempDatabase->become_postgres_user;
unlike(join('', `psql -l`), qr/test_temp_db_test/);

my $test_db = Test::TempDatabase->create(dbname => 'test_temp_db_test'
			, no_drop => 1);
$test_db->handle->do("create table aaa (a integer)");
undef $test_db;
like(join('', `psql -l`), qr/test_temp_db_test/);

$test_db = Test::TempDatabase->create(dbname => 'test_temp_db_test'
			, no_drop => 1);
$test_db->handle->do("select * from aaa");
undef $test_db;
like(join('', `psql -l`), qr/test_temp_db_test/);

Test::TempDatabase->create(dbname => 'test_temp_db_test');
unlike(join('', `psql -l`), qr/test_temp_db_test/);

for (1 .. 3) {
$test_db = Test::TempDatabase->create(dbname => 'test_temp_db_test'
		, dbi_args => { HandleError => sub { die "moo" } });
eval { $test_db->destroy };
unlike($@, qr/moo/);
}

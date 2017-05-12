use strict;
use warnings;

use DBI;
use Test::More;
use Test::PostgreSQL;
use File::Temp qw(tempdir);
use Try::Tiny;

my $base_dir = tempdir(CLEANUP => 1);

my $pgsql = try { Test::PostgreSQL->new( base_dir => $base_dir ) }
            catch { plan skip_all => $_ };

my $pid = $pgsql->pid;
my $dsn = $pgsql->dsn;
my $dbh = DBI->connect($dsn);
ok($dbh->ping, 'Connected to the first instance');
undef $dbh;
undef $pgsql; # kill 

ok(
    ! DBI->connect($dsn, undef, undef, { PrintError => 0 }),
    "Removing variable causes shutdown of the first instance"
);

# This time expect the base dir to be set up
$pgsql = Test::PostgreSQL->new(
	auto_start => 1,
	base_dir => $base_dir,
);

$dsn = $pgsql->dsn;
$dbh = DBI->connect($dsn);
ok($dbh->ping, 'Connected to second instance using the same base_dir');
undef $dbh;
undef $pgsql; # kill 

done_testing;

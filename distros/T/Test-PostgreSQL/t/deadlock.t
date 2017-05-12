#!perl
use strict;
use warnings;
use DBI;
use Test::PostgreSQL;
use Test::More;
use Try::Tiny;

my $pgsql = try { Test::PostgreSQL->new }
            catch { plan skip_all => $_ };

my $dbh = DBI->connect($pgsql->dsn);
ok($dbh, "Connected to created database.");

my $t1 = time();

$pgsql->stop;

my $elapsed = time() - $t1;
diag("elapsed: $elapsed");

ok(1, "Reached point after calling stop()");

ok($elapsed <= 12, "Shutdown took less than 12 seconds.");

done_testing;

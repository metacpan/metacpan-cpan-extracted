use strict;
use warnings;

use DBI;
use Test::More;
use Test::PostgreSQL;
use Try::Tiny;

# if we can't connect normally, unix_socket failure isn't an issue.
my $pgsql = try { Test::PostgreSQL->new }
            catch { plan skip_all => $_ };

undef $pgsql;

plan tests => 2;

ok($pgsql = Test::PostgreSQL->new(unix_socket => 1),
   'connected using unix socket');

my $dbh;

ok($dbh = DBI->connect($pgsql->dsn), 'check if db is ready');
$dbh->disconnect;

undef $pgsql;

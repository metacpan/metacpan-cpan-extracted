use Test::More;

use strict;
use warnings;

use DBI;
use Test::PostgreSQL;
use Try::Tiny;

my $pgsql = try {
    Test::PostgreSQL->new(
        dbname => 'foo',
        dbowner => 'foobaroo',
        host => 'localhost',
    )
}
catch { plan skip_all => $_ };

plan tests => 7;

ok defined $pgsql, "test instance with non-default configs";

my $have_dsn = $pgsql->dsn;

my $default_dsn = q|DBI:Pg:dbname=test;host=127.0.0.1;port=| .
                   $pgsql->port . q|;user=postgres|;

my $want_dsn = q|DBI:Pg:dbname=foo;host=localhost;port=| .
               $pgsql->port . q|;user=foobaroo|;

is $have_dsn, $want_dsn, "non-default configs DSN";

my $dbh = DBI->connect($want_dsn);
my $ping = eval { $dbh->ping };

is $@, '', "dbh ping no exception: $@";
ok $ping, "non-default configs can connect to DSN";

undef $dbh;

# Should not connect with default configs
$dbh = DBI->connect($default_dsn, undef, undef, { PrintError => 0 });

ok !defined($dbh), "non-default configs can't connect to default DSN";

my $pid = $pgsql->pid;

ok kill(0, $pid), "test Postgres instance is alive";

undef $pgsql;

# Give it 5 seconds to shut down (usually overkill)
my $watchdog = 50;

while ( kill 0, $pid and $watchdog-- ) {
    select undef, undef, undef, 0.1;
}

ok !kill(0, $pid), "test Postgres instance stopped";

use strict;
use warnings;

use DBI;
use Test::More;
use Test::Postgresql58;

my $pgsql = Test::Postgresql58->new()
    or plan skip_all => $Test::Postgresql58::errstr;

my $dsn = $pgsql->dsn;

is(
    $dsn,
    "DBI:Pg:dbname=test;host=127.0.0.1;port=@{[$pgsql->port]};user=postgres",
    'check dsn',
);

my $dbh = DBI->connect($dsn);
ok($dbh->ping, 'connected to PostgreSQL');
undef $dbh;

my $uri = $pgsql->uri;
like($uri, qr/^postgresql:\/\/postgres\@127.0.0.1/);

undef $pgsql;
ok(
    ! DBI->connect($dsn, undef, undef, { PrintError => 0 }),
    "Removing variable causes shutdown of postgresql"
);

done_testing;

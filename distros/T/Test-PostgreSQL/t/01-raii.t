use strict;
use warnings;

use DBI;
use Test::More;
use Test::PostgreSQL;
use Try::Tiny;

my $pgsql = try { Test::PostgreSQL->new }
            catch { plan skip_all => $_ };

plan tests => 5;

my $version_cmd = join ' ', (
    $pgsql->postmaster, '--version'
);

my $version_str = qx{$version_cmd};

my ($want_version) = $version_str =~ /(\d+(?:\.\d+)?)/;
my $have_version = $pgsql->pg_version;

is $have_version, $want_version, "pg_version";

# diag() here is deliberate, to show Postgres version in smoker reports
diag "PostgreSQL version: $want_version";

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
like($uri, qr/^postgresql:\/\/postgres\@127.0.0.1/, "uri");

undef $pgsql;
ok(
    ! DBI->connect($dsn, undef, undef, { PrintError => 0 }),
    "Removing variable causes shutdown of postgresql"
);

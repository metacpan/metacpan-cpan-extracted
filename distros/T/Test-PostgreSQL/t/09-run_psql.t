use Test::More;

use strict;
use warnings;

use DBI;
use Test::PostgreSQL;
use Try::Tiny;

my $pg = try { Test::PostgreSQL->new() }
         catch { plan skip_all => $_ };

plan tests => 3;

ok defined($pg), "new instance created";

my @psql_command;

# psql 9.6+ supports multiple -c commands
if ( $pg->pg_version >= 9.6 ) {
    @psql_command = (
        '-c', q|'CREATE TABLE foo (bar int)'|,
        '-c', q|'INSERT INTO foo (bar) VALUES (42)'|,
    );
}
else {
    @psql_command = (
        '-c', q|'CREATE TABLE foo (bar int); INSERT INTO foo (bar) VALUES (42);'|,
    );
}

eval { $pg->run_psql(@psql_command) };
is $@, '', "run_psql no exception" . ($@ ? ": $@" : "");


my $dbh = DBI->connect($pg->dsn);
my @row = $dbh->selectrow_array('SELECT * FROM foo');

is_deeply \@row, [42], "seed values match";

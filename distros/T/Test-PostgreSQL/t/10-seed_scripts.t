use Test::More;

use strict;
use warnings;

use DBI;
use Test::PostgreSQL;
use Try::Tiny;

my $pg = try {
    Test::PostgreSQL->new(
        seed_scripts => [
            't/seed/init.sql',
            't/seed/seed.sql',
        ],
    );
}
catch {
    plan skip_all => $_;
};

plan tests => 3;

is $@, '', "new no exception" . ($@ ? ": $@" : "");
ok defined($pg), "new instance created";

my $dbh = DBI->connect($pg->dsn);
my @row = $dbh->selectrow_array('SELECT * FROM foo');

is_deeply \@row, [42], "seed values match";

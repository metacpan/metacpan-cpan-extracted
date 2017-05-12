use strict;
use warnings;

use Test::More;
use Text::CSV::Auto;
use Text::CSV::Auto::ExportTo::MySQL;
use Try::Tiny;
use DBI;

my $dbh;
try{
    $dbh = DBI->connect(
        $ENV{'DBI_DSN'}  || 'DBI:mysql:database=test',
        $ENV{'DBI_USER'} || '',
        $ENV{'DBI_PASS'} || '',
        { RaiseError => 1, PrintError => 1, AutoCommit => 1 },
    );
}
catch {
    plan skip_all => "ERROR: $DBI::errstr Can't continue test";
};

my $auto = Text::CSV::Auto->new(
    file => 't/features.csv',
    max_rows => 2,
);
my $expected_rows = $auto->slurp();

# These fields change slightly once in the DB.
$expected_rows->[0]->{date_created} = '1980-02-08';
$expected_rows->[0]->{county_numeric} += 0;
$expected_rows->[0]->{state_numeric} += 0;
$expected_rows->[0]->{census_code} += 0;

my $exporter = Text::CSV::Auto::ExportTo::MySQL->new(
    auto       => $auto,
    connection => $dbh,
);

$exporter->export();

my $table = $exporter->table();
my $actual_rows = $dbh->selectall_arrayref("SELECT * FROM $table", {Slice=>{}});

is_deeply(
    $actual_rows,
    $expected_rows,
    'rows match in new csv',
);

done_testing;

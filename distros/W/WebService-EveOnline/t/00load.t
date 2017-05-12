#!perl -T

use Test::More tests => 2;
use DBI;

my $eve_db = ($^O =~ /MSWin/) ? "c:/windows/temp/webservice_eveonline.db" : "/tmp/webservice_eveonline.db";

my $dbh = DBI->connect("dbi:SQLite:dbname=$eve_db", "", "");

eval {
    my $res = $dbh->prepare("select name from sqlite_master where type = 'table' and name = 'map'");
    $res->execute;
    my $has_table = $res->fetchrow;

    # delete if old version of cache db (without map) is found.
    unlink $eve_db unless $has_table;
};

BEGIN {
    use_ok( 'WebService::EveOnline' );
    use_ok( 'WebService::EveOnline::Cache' );
}

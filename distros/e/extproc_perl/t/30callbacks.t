# $Id: 30callbacks.t,v 1.2 2006/08/03 16:04:28 jeff Exp $

# test callbacks

use DBI;
use Test::More tests => 2;

require 't/dbinit.pl';
my $dbh = dbinit();
my $sth;
my $tmp;

# query
init_test($dbh);
$sth = $dbh->prepare("SELECT TestPerl.func('ep_dbname_via_callback') FROM dual");
if ($sth && $sth->execute()) {
    $tmp = ($sth->fetchrow_array)[0];
}
# use "like" here since we may return the domain along with the name
like($tmp, qr/^\Q$ENV{'ORACLE_SID'}\E/i, 'query');

# DML
init_test($dbh);
$dbh->do('CREATE TABLE ep_test_table (dummy VARCHAR2(1000))');
if ($dbh->do("INSERT INTO ep_test_table VALUES('testing 1 2 3')")) {
    $sth = $dbh->prepare('SELECT dummy FROM ep_test_table');
    if ($sth && $sth->execute()) {
        $tmp = ($sth->fetchrow_array)[0];
    }
}
is($tmp, 'testing 1 2 3', 'DML');
$dbh->do('DROP TABLE ep_test_table');

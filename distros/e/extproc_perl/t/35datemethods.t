# $Id: 35datemethods.t,v 1.2 2006/08/03 16:04:28 jeff Exp $

# test date methods

use DBI;
use Test::More tests => 6;

require 't/dbinit.pl';
my $dbh = dbinit();
my $sth;
my $tmp;

$dbh->do("ALTER SESSION SET NLS_DATE_FORMAT = 'YYYY-MM-DD'");

# to_char
init_test($dbh);
if (create_extproc($dbh, 'FUNCTION ep_date_to_char(x IN DATE) RETURN VARCHAR2') && run_ddl($dbh, 'ep_date_to_char')) {
    $sth = $dbh->prepare("SELECT ep_date_to_char(to_date('2000-01-02', 'YYYY-MM-DD')) FROM dual");
    if ($sth && $sth->execute()) {
        $tmp = ($sth->fetchrow_array)[0];
    }
}
is($tmp, '2000-01-02', 'to_char');

# getdate
init_test($dbh);
if (create_extproc($dbh, 'FUNCTION ep_date_getdate(x IN DATE) RETURN VARCHAR2') && run_ddl($dbh, 'ep_date_getdate')) {
    $sth = $dbh->prepare("SELECT ep_date_getdate(to_date('2000-01-02', 'YYYY-MM-DD')) FROM dual");
    if ($sth && $sth->execute()) {
        $tmp = ($sth->fetchrow_array)[0];
    }
}
is($tmp, '2000 1 2', 'getdate');
$dbh->do('DROP FUNCTION ep_date_getdate');

# setdate
init_test($dbh);
if (create_extproc($dbh, 'FUNCTION ep_date_setdate RETURN DATE') && run_ddl($dbh, 'ep_date_setdate')) {
    $sth = $dbh->prepare("SELECT ep_date_setdate FROM dual");
    if ($sth && $sth->execute()) {
        $tmp = ($sth->fetchrow_array)[0];
    }
}
is($tmp, '2000-01-02', 'setdate');
$dbh->do('DROP FUNCTION ep_date_setdate');

# setdate_sysdate
init_test($dbh);
if (create_extproc($dbh, 'FUNCTION ep_date_setdate_sysdate RETURN DATE') && run_ddl($dbh, 'ep_date_setdate_sysdate')) {
    $sth = $dbh->prepare("SELECT ep_date_setdate_sysdate FROM dual");
    if ($sth && $sth->execute()) {
        $tmp = ($sth->fetchrow_array)[0];
    }
}
like($tmp, qr/\d{4}-\d{2}-\d{2}/, 'setdate_sysdate');
$dbh->do('DROP FUNCTION ep_date_setdate_sysdate');

# gettime
init_test($dbh);
if (create_extproc($dbh, 'FUNCTION ep_date_gettime(x IN DATE) RETURN VARCHAR2') && run_ddl($dbh, 'ep_date_gettime')) {
    $sth = $dbh->prepare("SELECT ep_date_gettime(to_date('2000-01-02 01:02:03', 'YYYY-MM-DD HH:MI:SS')) FROM dual");
    if ($sth && $sth->execute()) {
        $tmp = ($sth->fetchrow_array)[0];
    }
}
is($tmp, '1 2 3', 'gettime');
$dbh->do('DROP FUNCTION ep_date_gettime');

# settime
init_test($dbh);
$dbh->do("ALTER SESSION SET NLS_DATE_FORMAT = 'HH:MI:SS'");
if (create_extproc($dbh, 'FUNCTION ep_date_settime RETURN DATE') && run_ddl($dbh, 'ep_date_settime')) {
    $sth = $dbh->prepare("SELECT ep_date_settime FROM dual");
    if ($sth && $sth->execute()) {
        $tmp = ($sth->fetchrow_array)[0];
    }
}
is($tmp, '01:02:03', 'settime');
$dbh->do('DROP FUNCTION ep_date_settime');

# $Id: 20direct.t,v 1.5 2006/08/03 16:04:28 jeff Exp $

# test direct execution

use DBI;
use Test::More tests => 5;

require 't/dbinit.pl';
my $dbh = dbinit();
my $sth;
my $tmp;

# direct function noargs
init_test($dbh);
undef $tmp;
if (create_extproc($dbh, 'FUNCTION ep_direct_func_noargs RETURN VARCHAR2') &&
    run_ddl($dbh, 'ep_direct_func_noargs')) {
    $sth = $dbh->prepare('SELECT ep_direct_func_noargs FROM dual');
    if ($sth && $sth->execute()) {
        $tmp = ($sth->fetchrow_array)[0];
    }
}
is($tmp, 'testing 1 2 3', 'direct function noargs');
$dbh->do('DROP FUNCTION ep_direct_func_noargs');

# direct function 1 arg in varchar2
init_test($dbh);
undef $tmp;
if (create_extproc($dbh, 'FUNCTION ep_direct_func_1_in_varchar2(x IN VARCHAR2) RETURN VARCHAR2') &&
    run_ddl($dbh, 'ep_direct_func_1_in_varchar2')) {
    $sth = $dbh->prepare("SELECT ep_direct_func_1_in_varchar2('testing 1 2 3') FROM dual");
    if ($sth && $sth->execute()) {
        $tmp = ($sth->fetchrow_array)[0];
    }
}
is($tmp, 'testing 1 2 3', 'direct function 1 arg in varchar2');
$dbh->do('DROP FUNCTION ep_direct_func_1_in_varchar2');

# direct procedure noargs
init_test($dbh);
if (create_extproc($dbh, 'PROCEDURE ep_direct_proc_noargs') &&
    run_ddl($dbh, 'ep_direct_proc_noargs')) {
    ok ($dbh->do('BEGIN ep_direct_proc_noargs; END;'), 'direct procedure noargs');
}
else {
    fail('direct procedure noargs');
}
$dbh->do('DROP PROCEDURE ep_direct_proc_noargs');

# direct procedure 1 arg in varchar2
init_test($dbh);
if (create_extproc($dbh, 'PROCEDURE ep_direct_proc_1_in_varchar2(x IN VARCHAR2)') &&
    run_ddl($dbh, 'ep_direct_proc_1_in_varchar2')) {
    ok ($dbh->do("BEGIN ep_direct_proc_1_in_varchar2('testing 1 2 3'); END;"), 'direct procedure 1 arg in varchar2');
}
else {
    fail('direct procedure 1 arg in varchar2');
}
$dbh->do('DROP PROCEDURE ep_direct_proc_1_in_varchar2');

# direct procedure 2 arg out varchar2
init_test($dbh);
undef $tmp;
if (create_extproc($dbh, 'PROCEDURE ep_direct_proc_2_out_varchar2(x OUT VARCHAR2, y OUT VARCHAR2)') && run_ddl($dbh, 'ep_direct_proc_2_out_varchar2')) {
    $sth = $dbh->prepare('BEGIN ep_direct_proc_2_out_varchar2(:x, :y); END;');
    if ($sth) {
        my ($x, $y);
        $sth->bind_param_inout(':x', \$x, 1000);
        $sth->bind_param_inout(':y', \$y, 1000);
        $sth->execute();
        $tmp = "$x $y";
    }
}
is($tmp, 'testing 1 2 3', 'direct procedure 2 arg out varchar2');
$dbh->do('DROP PROCEDURE ep_direct_proc_2_out_varchar2');

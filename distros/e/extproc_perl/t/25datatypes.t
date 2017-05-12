# $Id: 25datatypes.t,v 1.3 2006/08/03 16:04:28 jeff Exp $

# test datatypes

use DBI;
use Test::More tests => 16;

require 't/dbinit.pl';
my $dbh = dbinit();
my $sth;
my $tmp;

# datatype RETURN VARCHAR2
init_test($dbh);
if (create_extproc($dbh, 'FUNCTION ep_datatype_c RETURN VARCHAR2') &&
    run_ddl($dbh, 'ep_datatype_c')) {
    $sth = $dbh->prepare('SELECT ep_datatype_c FROM dual');
    if ($sth && $sth->execute()) {
        $tmp = ($sth->fetchrow_array)[0];
    }
}
is($tmp, 'testing 1 2 3', 'datatype RETURN VARCHAR2');
$dbh->do('DROP FUNCTION ep_datatype_c');

# datatype RETURN PLS_INTEGER
init_test($dbh);
undef $tmp;
if (create_extproc($dbh, 'FUNCTION ep_datatype_i RETURN PLS_INTEGER') &&
    run_ddl($dbh, 'ep_datatype_i')) {
    $sth = $dbh->prepare('SELECT ep_datatype_i FROM dual');
    if ($sth && $sth->execute()) {
        $tmp = ($sth->fetchrow_array)[0];
    }
}
is($tmp, 123, 'datatype RETURN PLS_INTEGER');
$dbh->do('DROP FUNCTION ep_datatype_i');

# datatype RETURN REAL
init_test($dbh);
undef $tmp;
if (create_extproc($dbh, 'FUNCTION ep_datatype_r RETURN REAL') &&
    run_ddl($dbh, 'ep_datatype_r')) {
    $sth = $dbh->prepare('SELECT ep_datatype_r FROM dual');
    if ($sth && $sth->execute()) {
        $tmp = ($sth->fetchrow_array)[0];
    }
}
is($tmp, 1.23, 'datatype RETURN REAL');
$dbh->do('DROP FUNCTION ep_datatype_r');

# datatype RETURN DATE
init_test($dbh);
undef $tmp;
if (create_extproc($dbh, 'FUNCTION ep_datatype_d RETURN DATE') &&
    run_ddl($dbh, 'ep_datatype_d')) {
    $sth = $dbh->prepare('SELECT ep_datatype_d FROM dual');
    if ($sth && $sth->execute()) {
        $tmp = ($sth->fetchrow_array)[0];
    }
}
is($tmp, '02-JAN-00', 'datatype RETURN DATE');
$dbh->do('DROP FUNCTION ep_datatype_d');

# datatype IN VARCHAR2
init_test($dbh);
undef $tmp;
if (create_extproc($dbh, 'PROCEDURE ep_datatype_vIc(x IN VARCHAR2)') &&
    run_ddl($dbh, 'ep_datatype_vIc')) {
    ok($dbh->do("BEGIN ep_datatype_vIc('testing 1 2 3'); END;"),
        'datatype IN VARCHAR2');
}
else {
    fail('datatype IN VARCHAR2');
}
$dbh->do('DROP PROCEDURE ep_datatype_vIc');

# datatype IN OUT VARCHAR2
init_test($dbh);
undef $tmp;
if (create_extproc($dbh, 'PROCEDURE ep_datatype_vBc(x IN OUT VARCHAR2)') &&
    run_ddl($dbh, 'ep_datatype_vBc')) {
    $sth = $dbh->prepare('BEGIN ep_datatype_vBc(:x); END;');
    if ($sth) {
        $tmp = 'testing';
        $sth->bind_param_inout(':x', \$tmp, 1000);
        $sth->execute();
    }
}
is($tmp, 'testing 1 2 3', 'datatype IN OUT VARCHAR2');
$dbh->do('DROP PROCEDURE ep_datatype_vBc');

# datatype OUT VARCHAR2
init_test($dbh);
undef $tmp;
if (create_extproc($dbh, 'PROCEDURE ep_datatype_vOc(x OUT VARCHAR2)') &&
    run_ddl($dbh, 'ep_datatype_vOc')) {
    $sth = $dbh->prepare('BEGIN ep_datatype_vOc(:x); END;');
    if ($sth) {
        $sth->bind_param_inout(':x', \$tmp, 1000);
        $sth->execute();
    }
}
is($tmp, 'testing 1 2 3', 'datatype OUT VARCHAR2');
$dbh->do('DROP PROCEDURE ep_datatype_vOc');

# datatype IN PLS_INTEGER
init_test($dbh);
undef $tmp;
if (create_extproc($dbh, 'PROCEDURE ep_datatype_vIi(x IN PLS_INTEGER)') &&
    run_ddl($dbh, 'ep_datatype_vIi')) {
    ok($dbh->do("BEGIN ep_datatype_vIi(123); END;"),
        'datatype IN PLS_INTEGER');
}
else {
    fail('datatype IN PLS_INTEGER');
}
$dbh->do('DROP PROCEDURE ep_datatype_vIi');

# datatype IN OUT PLS_INTEGER
init_test($dbh);
undef $tmp;
if (create_extproc($dbh, 'PROCEDURE ep_datatype_vBi(x IN OUT PLS_INTEGER)') &&
    run_ddl($dbh, 'ep_datatype_vBi')) {
    $sth = $dbh->prepare('BEGIN ep_datatype_vBi(:x); END;');
    if ($sth) {
        $tmp = 123;
        $sth->bind_param_inout(':x', \$tmp, 1000);
        $sth->execute();
    }
}
is($tmp, 246, 'datatype IN OUT PLS_INTEGER');
$dbh->do('DROP PROCEDURE ep_datatype_vBi');

# datatype OUT PLS_INTEGER
init_test($dbh);
undef $tmp;
if (create_extproc($dbh, 'PROCEDURE ep_datatype_vOi(x OUT PLS_INTEGER)') &&
    run_ddl($dbh, 'ep_datatype_vOi')) {
    $sth = $dbh->prepare('BEGIN ep_datatype_vOi(:x); END;');
    if ($sth) {
        $sth->bind_param_inout(':x', \$tmp, 1000);
        $sth->execute();
    }
}
is($tmp, 123, 'datatype OUT PLS_INTEGER');
$dbh->do('DROP PROCEDURE ep_datatype_vOi');

# datatype IN REAL
init_test($dbh);
undef $tmp;
if (create_extproc($dbh, 'PROCEDURE ep_datatype_vIr(x IN REAL)') &&
    run_ddl($dbh, 'ep_datatype_vIr')) {
    ok($dbh->do("BEGIN ep_datatype_vIr(1.23); END;"),
        'datatype IN REAL');
}
else {
    fail('datatype IN REAL');
}
$dbh->do('DROP PROCEDURE ep_datatype_vIr');

# datatype IN OUT REAL
init_test($dbh);
undef $tmp;
if (create_extproc($dbh, 'PROCEDURE ep_datatype_vBr(x IN OUT REAL)') &&
    run_ddl($dbh, 'ep_datatype_vBr')) {
    $sth = $dbh->prepare('BEGIN ep_datatype_vBr(:x); END;');
    if ($sth) {
        $tmp = 1.23;
        $sth->bind_param_inout(':x', \$tmp, 1000);
        $sth->execute();
    }
}
is($tmp, sprintf("%2g", 2.46), 'datatype IN OUT REAL');
$dbh->do('DROP PROCEDURE ep_datatype_vBr');

# datatype OUT REAL
init_test($dbh);
undef $tmp;
if (create_extproc($dbh, 'PROCEDURE ep_datatype_vOr(x OUT REAL)') &&
    run_ddl($dbh, 'ep_datatype_vOr')) {
    $sth = $dbh->prepare('BEGIN ep_datatype_vOr(:x); END;');
    if ($sth) {
        $sth->bind_param_inout(':x', \$tmp, 1000);
        $sth->execute();
    }
}
is($tmp, sprintf("%2g", 1.23), 'datatype OUT REAL');
$dbh->do('DROP PROCEDURE ep_datatype_vOr');

# datatype IN DATE
init_test($dbh);
undef $tmp;
if (create_extproc($dbh, 'PROCEDURE ep_datatype_vId(x IN DATE)') &&
    run_ddl($dbh, 'ep_datatype_vId')) {
    ok($dbh->do("BEGIN ep_datatype_vId(to_date('2000-01-02', 'YYYY-MM-DD')); END;"),
        'datatype IN DATE');
}
else {
    fail('datatype IN DATE');
}
$dbh->do('DROP PROCEDURE ep_datatype_vId');

# datatype IN OUT DATE
init_test($dbh);
undef $tmp;
if (create_extproc($dbh, 'PROCEDURE ep_datatype_vBd(x IN OUT DATE)') &&
    run_ddl($dbh, 'ep_datatype_vBd')) {
    $sth = $dbh->prepare(q{
        DECLARE d DATE := to_date('2000-01-02', 'YYYY-MM-DD');
        BEGIN
           ep_datatype_vBd(d);
           :x := to_char(d, 'YYYY-MM-DD');
        END;
    });
    if ($sth) {
        $sth->bind_param_inout(':x', \$tmp, 1000);
        $sth->execute();
    }
}
is($tmp, '2001-02-03', 'datatype IN OUT DATE');
$dbh->do('DROP PROCEDURE ep_datatype_vBd');

# datatype OUT DATE
init_test($dbh);
undef $tmp;
if (create_extproc($dbh, 'PROCEDURE ep_datatype_vOd(x OUT DATE)') &&
    run_ddl($dbh, 'ep_datatype_vOd')) {
    $sth = $dbh->prepare(q{
        DECLARE d DATE;
        BEGIN
           ep_datatype_vOd(d);
           :x := to_char(d, 'YYYY-MM-DD');
        END;
    });
    if ($sth) {
        $sth->bind_param_inout(':x', \$tmp, 1000);
        $sth->execute();
    }
}
is($tmp, '2000-01-02', 'datatype OUT DATE');
$dbh->do('DROP PROCEDURE ep_datatype_vOd');

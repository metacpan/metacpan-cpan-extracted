# $Id: 02status_view.t,v 1.2 2006/08/03 16:04:28 jeff Exp $

# test config view

use DBI;
use Test::More tests => 6;

require 't/dbinit.pl';
my $dbh = dbinit();
my $sth;

# extproc_perl_version
init_test($dbh);
$sth = $dbh->prepare('SELECT extproc_perl_version FROM eptest_perl_status');
if ($sth && $sth->execute()) {
    my $tmp = ($sth->fetchrow_array)[0];
    like($tmp, qr/extproc_perl/, 'extproc_perl_version');
}
else {
    fail('extproc_perl_version');
}

# debug_status
init_test($dbh);
$sth = $dbh->prepare('SELECT debug_status FROM eptest_perl_status');
if ($sth && $sth->execute()) {
    my $tmp = ($sth->fetchrow_array)[0];
    is(uc($tmp), 'DISABLED', 'debug_status');
}
else {
    fail('debug_status');
}

# debug_file (debugging is disabled, so this should be null)
init_test($dbh);
$sth = $dbh->prepare('SELECT debug_file FROM eptest_perl_status');
if ($sth && $sth->execute()) {
    my $tmp = ($sth->fetchrow_array)[0];
    is(uc($tmp), '', 'debug_file');
}
else {
    fail('debug_file');
}

# package
init_test($dbh);
$sth = $dbh->prepare('SELECT package FROM eptest_perl_status');
if ($sth && $sth->execute()) {
    my $tmp = ($sth->fetchrow_array)[0];
    like($tmp, qr/ExtProc::Session\d+/, 'package');
}
else {
    fail('package');
}

# errno (should be undef)
init_test($dbh);
$sth = $dbh->prepare('SELECT errno FROM eptest_perl_status');
if ($sth && $sth->execute()) {
    my $tmp = ($sth->fetchrow_array)[0];
    ok(!defined($tmp), 'errno');
}
else {
    fail('errno');
}

# errsv (should be undef)
init_test($dbh);
$sth = $dbh->prepare('SELECT errsv FROM eptest_perl_status');
if ($sth && $sth->execute()) {
    my $tmp = ($sth->fetchrow_array)[0];
    ok(!defined($tmp), 'errsv');
}
else {
    fail('errsv');
}

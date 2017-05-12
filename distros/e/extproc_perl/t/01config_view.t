# $Id: 01config_view.t,v 1.2 2006/08/03 16:04:28 jeff Exp $

# test config view

use DBI;
use Test::More tests => 12;

require 't/dbinit.pl';
my $dbh = dbinit();
my $sth;

# bootstrap_file
init_test($dbh);
$sth = $dbh->prepare('SELECT bootstrap_file FROM eptest_perl_config');
if ($sth && $sth->execute()) {
    my $tmp = ($sth->fetchrow_array)[0];
    like($tmp, qr/testboot\.pl$/, 'bootstrap_file');
}
else {
    fail('bootstrap_file');
}

# code_table
init_test($dbh);
$sth = $dbh->prepare('SELECT code_table FROM eptest_perl_config');
if ($sth && $sth->execute()) {
    my $tmp = ($sth->fetchrow_array)[0];
    is(uc($tmp), 'EPTEST_USER_PERL_SOURCE', 'code_table');
}
else {
    fail('code_table');
}

# inc_path
init_test($dbh);
$sth = $dbh->prepare('SELECT inc_path FROM eptest_perl_config');
if ($sth && $sth->execute()) {
    my $tmp = ($sth->fetchrow_array)[0];
    like($tmp, qr/ExtProc\/blib\/lib/, 'inc_path');
}
else {
    fail('inc_path');
}

# debug_directory
init_test($dbh);
$sth = $dbh->prepare('SELECT debug_directory FROM eptest_perl_config');
if ($sth && $sth->execute()) {
    my $tmp = ($sth->fetchrow_array)[0];
    is($tmp, '/tmp', 'inc_path');
}
else {
    fail('debug_directory');
}

# max_code_size
init_test($dbh);
$sth = $dbh->prepare('SELECT max_code_size FROM eptest_perl_config');
if ($sth && $sth->execute()) {
    my $tmp = ($sth->fetchrow_array)[0];
    like($tmp, qr/\d+/, 'max_code_size');
}
else {
    fail('max_code_size');
}

# max_sub_args
init_test($dbh);
$sth = $dbh->prepare('SELECT max_sub_args FROM eptest_perl_config');
if ($sth && $sth->execute()) {
    my $tmp = ($sth->fetchrow_array)[0];
    like($tmp, qr/\d+/, 'max_sub_args');
}
else {
    fail('max_sub_args');
}

# trusted_code_directory
init_test($dbh);
$sth = $dbh->prepare('SELECT trusted_code_directory FROM eptest_perl_config');
if ($sth && $sth->execute()) {
    my $tmp = ($sth->fetchrow_array)[0];
    like($tmp, qr/\/t$/, 'trusted_code_directory');
}
else {
    fail('trusted_code_directory');
}

# tainting
init_test($dbh);
$sth = $dbh->prepare('SELECT tainting FROM eptest_perl_config');
if ($sth && $sth->execute()) {
    my $tmp = ($sth->fetchrow_array)[0];
    is(uc($tmp), 'ENABLED', 'tainting');
}
else {
    fail('tainting');
}

# ddl_format
init_test($dbh);
$sth = $dbh->prepare('SELECT ddl_format FROM eptest_perl_config');
if ($sth && $sth->execute()) {
    my $tmp = ($sth->fetchrow_array)[0];
    is(uc($tmp), 'STANDARD', 'ddl_format');
}
else {
    fail('ddl_format');
}

# session_namespace
init_test($dbh);
$sth = $dbh->prepare('SELECT session_namespace FROM eptest_perl_config');
if ($sth && $sth->execute()) {
    my $tmp = ($sth->fetchrow_array)[0];
    is(uc($tmp), 'ENABLED', 'session_namespace');
}
else {
    fail('session_namespace');
}

# package_subs
init_test($dbh);
$sth = $dbh->prepare('SELECT package_subs FROM eptest_perl_config');
if ($sth && $sth->execute()) {
    my $tmp = ($sth->fetchrow_array)[0];
    is(uc($tmp), 'DISABLED', 'package_subs');
}
else {
    fail('package_subs');
}

# reparse_subs
init_test($dbh);
$sth = $dbh->prepare('SELECT reparse_subs FROM eptest_perl_config');
if ($sth && $sth->execute()) {
    my $tmp = ($sth->fetchrow_array)[0];
    is(uc($tmp), 'DISABLED', 'reparse_subs');
}
else {
    fail('reparse_subs');
}

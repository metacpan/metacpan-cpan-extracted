#!/usr/bin/perl
#
# Non-regression tests for oEdtk::DBAdmin against an in-memory SQLite database.
#
# The whole file is skipped when DBD::SQLite is not available, so the suite
# never reports a false failure on a machine without it.
#
# _get_col_meta relies on column_info, which DBD::SQLite 1.78 returns with undef
# field values; the public cache %oEdtk::DBAdmin::_csv_import_type_cache is
# therefore primed to drive the truncation / '' -> NULL logic deterministically.
#
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../lib";
use lib "$FindBin::Bin/lib";
use Test::More;
use File::Temp qw(tempfile);
use TestOEdtk qw(quiet_require memory_dbh mute);

quiet_require('oEdtk::DBAdmin');

my $dbh = memory_dbh();
plan skip_all => 'DBD::SQLite is not available' unless defined $dbh;

# Isolate the global import-type cache for the duration of this test file.
local %oEdtk::DBAdmin::_csv_import_type_cache = ();

# --- structure creation -----------------------------------------------------
oEdtk::DBAdmin::create_table_TRACKING($dbh, 'edtk_tracking', 2);
is(oEdtk::DBAdmin::_table_exists($dbh, 'edtk_tracking'), 1,
   'create_table_TRACKING creates the table');
ok(eval { $dbh->prepare('select ed_k2_VAL from edtk_tracking'); 1 },
   'create_table_TRACKING creates the key columns up to maxkeys');

oEdtk::DBAdmin::create_table_ADMIN($dbh);
is(oEdtk::DBAdmin::_table_exists($dbh, 'edtk_admin'), 1,
   'create_table_ADMIN creates the table');

# --- insert_tData : truncation and '' -> NULL -------------------------------
$dbh->do('create table t_ins (ed_name varchar(5), ed_num integer, ed_dt date)');
$oEdtk::DBAdmin::_csv_import_type_cache{"t_ins\0sqlite"} = {
	ed_name => { numeric => 0, blank_to_null => 0, size => 5 },
	ed_num  => { numeric => 1, blank_to_null => 1, size => 0 },
	ed_dt   => { numeric => 0, blank_to_null => 1, size => 0 },
};

my @cols = qw(ed_name ed_num ed_dt);
ok(oEdtk::DBAdmin::insert_tData(dbh => $dbh, table => 't_ins',
                                tCols => \@cols, tData => ['abcdef', '7', '2026-07-09']),
   'insert_tData returns true');
my $row = $dbh->selectrow_arrayref('select ed_name, ed_num, ed_dt from t_ins');
is($row->[0], 'abcde',      'insert_tData truncates a text value to the column size');
is($row->[1], 7,            'insert_tData stores an integer value');
is($row->[2], '2026-07-09', 'insert_tData stores a date value unchanged');

oEdtk::DBAdmin::insert_tData(dbh => $dbh, table => 't_ins',
                             tCols => \@cols, tData => ['abc', '', '']);
my $row2 = $dbh->selectrow_arrayref('select ed_num, ed_dt from t_ins where ed_name = ?', undef, 'abc');
is($row2->[0], undef, 'insert_tData turns an empty numeric value into NULL');
is($row2->[1], undef, 'insert_tData turns an empty date value into NULL');

# --- csv_import : row-by-row path -------------------------------------------
my ($cfh, $cfile) = tempfile('oedtk_csv_XXXXXX', SUFFIX => '.csv', UNLINK => 1);
print $cfh "ed_name,ed_num,ed_dt\n";
print $cfh "zzz,99,2026-07-09\n";
close($cfh);
my ($count, $msg) = oEdtk::DBAdmin::csv_import($dbh, 't_ins', $cfile, {});
is($count, 1, 'csv_import inserts the data line');
is($msg, ' lines inserted', 'csv_import returns the insert-count message');

# --- copy_table -------------------------------------------------------------
$dbh->do('create table t_src (a integer)');
$dbh->do('insert into t_src values (1)');
$dbh->do('insert into t_src values (2)');
is(mute(sub { oEdtk::DBAdmin::copy_table($dbh, 't_src', 't_dst', '-create') }), 1,
   'copy_table returns 1 when it creates the target');
is(oEdtk::DBAdmin::_table_exists($dbh, 't_dst'), 1,
   'copy_table creates the target table');
my ($n) = $dbh->selectrow_array('select count(*) from t_dst');
is($n, 2, 'copy_table copies every row');

$dbh->do('create table t_empty (a integer)');
is(mute(sub { oEdtk::DBAdmin::copy_table($dbh, 't_empty', 't_none', '-create') }), 1,
   'copy_table returns 1 on an empty source');
is(oEdtk::DBAdmin::_table_exists($dbh, 't_none'), 0,
   'copy_table does not create the target when the source is empty');

# --- db_drop_table ----------------------------------------------------------
oEdtk::DBAdmin::db_drop_table($dbh, 't_dst');
is(oEdtk::DBAdmin::_table_exists($dbh, 't_dst'), 0,
   'db_drop_table removes the table');

# --- _get_col_meta : norm_id is mandatory -----------------------------------
eval { oEdtk::DBAdmin::_get_col_meta($dbh, 't_ins', undef) };
like($@, qr/norm_id manquant/, '_get_col_meta dies when norm_id is missing');

# --- paths not portable to SQLite (documented, not exercised) --------------
SKIP: {
	skip 'historicize_table uses TRUNCATE, unsupported by SQLite', 1;
	oEdtk::DBAdmin::historicize_table($dbh, 't_src', 'BAK');
}
SKIP: {
	skip '_db_with_lock reconnects through a real DSN', 1;
	oEdtk::DBAdmin::_db_with_lock(CFG => {}, code => sub { });
}

done_testing();

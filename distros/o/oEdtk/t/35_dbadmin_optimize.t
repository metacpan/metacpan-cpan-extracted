#!/usr/bin/perl
#
# Tests for the routine table-maintenance path of oEdtk::DBAdmin:
#   - _db_maintenance_commands(): the per-engine (repair, optimize) templates,
#   - admin_optimize_db(): the end-to-end operation on a live SQLite handle.
#
# The point of the templates is engine coverage: every driver class must have a
# command for both phases, PostgreSQL must no longer use VACUUM FULL in the hot
# path, and SQLite must be served by ANALYZE.
#
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../lib";
use lib "$FindBin::Bin/lib";
use Test::More;
use DBI;
use File::Temp     qw(tempdir);
use oEdtk::Config  qw(config_read);
use oEdtk::DBAdmin qw(schema_Create admin_optimize_db);

# --- per-engine command coverage ---------------------------------------------
my @CLASSES = qw(NC mysql Oracle PostgreSQL SQLite);
for my $class (@CLASSES) {
	my ( $repair, $optm ) = oEdtk::DBAdmin::_db_maintenance_commands($class);
	is( ref $repair, 'HASH', "commands($class): repair is a hash" );
	is( ref $optm,   'HASH', "commands($class): optimize is a hash" );
	ok( defined $repair->{$class}, "commands($class): a repair template is declared" );
	ok( defined $optm->{$class},   "commands($class): an optimize template is declared" );
	like( $repair->{$class}, qr/\S/, "commands($class): repair template is non-empty" );
	like( $optm->{$class},   qr/\S/, "commands($class): optimize template is non-empty" );
}

# PostgreSQL must not lock the table with VACUUM FULL in the routine path.
{
	my ( undef, $optm ) = oEdtk::DBAdmin::_db_maintenance_commands('PostgreSQL');
	unlike( $optm->{'PostgreSQL'}, qr/vacuum\s+full/i,
		'PostgreSQL: no VACUUM FULL in the hot path' );
	like( $optm->{'PostgreSQL'}, qr/vacuum\s+analyze\s+%s/i, 'PostgreSQL: VACUUM ANALYZE is used' );
}

# SQLite has no per-table VACUUM: it must run ANALYZE.
{
	my ( $repair, $optm ) = oEdtk::DBAdmin::_db_maintenance_commands('SQLite');
	like( $optm->{'SQLite'},   qr/analyze\s+%s/i, 'SQLite: ANALYZE %s is used' );
	like( $repair->{'SQLite'}, qr/^select 1/i,    'SQLite: repair is a portable no-op' );
}

# MySQL templates must carry the %s placeholder, otherwise sprintf is skipped.
{
	my ( $repair, $optm ) = oEdtk::DBAdmin::_db_maintenance_commands('mysql');
	like( $repair->{'mysql'}, qr/%s/, 'mysql: repair template has a %s placeholder' );
	like( $optm->{'mysql'},   qr/%s/, 'mysql: optimize template has a %s placeholder' );
}

# --- end-to-end on a live SQLite handle --------------------------------------
{
	my $dir  = tempdir( 'oedtk_optimize_XXXXXX', CLEANUP => 1 );
	my $file = "$dir/main.db";
	my $dbh  = DBI->connect( "dbi:SQLite:dbname=$file", '', '',
		{ RaiseError => 1, PrintError => 0, AutoCommit => 1 } );
	schema_Create($dbh);

	my $cfg = config_read('EDTK_DB');
	$cfg->{'EDTK_DBI_DSN'}       = "dbi:SQLite:dbname=$file";
	$cfg->{'EDTK_DBI_DSN_BAK'}   = '';     # no backup buffer: stay on the main handle
	$cfg->{'EDTK_DB_CHECK_AUTO'} = 'NO';

	my $rc = eval { admin_optimize_db( CFG => $cfg ) };
	is( $@,  '', 'admin_optimize_db: does not die on a SQLite main database' );
	is( $rc, 1,  'admin_optimize_db: returns 1' );

	$dbh->disconnect;
}

done_testing();

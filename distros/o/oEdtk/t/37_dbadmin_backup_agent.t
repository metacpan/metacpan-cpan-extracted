#!/usr/bin/perl
#
# Tests for oEdtk::DBAdmin::db_backup_agent, the archive-and-purge routine called
# by oEdtk::Outmngr::omgr_purge_fs. Using a SQLite handle and scratch tables whose
# names are injected through a CFG hash, it checks that:
#   - rows older than EDTK_ENTIRE_YEARS_KEPT are archived then purged, recent rows
#     are kept,
#   - the archive is a full snapshot of the table (all rows, not just the old ones),
#   - a second run on the same day keeps the existing archive instead of losing it.
#
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../lib";
use lib "$FindBin::Bin/lib";
use Test::More;
use DBI;
use File::Temp     qw(tempdir);
use POSIX          qw(strftime);
use oEdtk::DBAdmin qw(db_backup_agent);

my $dbh = DBI->connect( 'dbi:SQLite:dbname=:memory:', '', '',
	{ RaiseError => 1, PrintError => 0, AutoCommit => 1 } );

$dbh->do('create table t_trk  (ed_tstamp   varchar(14), ed_x varchar(8))');
$dbh->do('create table t_meta (ed_dtedtion varchar(8),  ed_x varchar(8))');
$dbh->do('create table t_acq  (ed_dtpost   varchar(8),  ed_x varchar(8))');

# Old rows (2019, purged) and recent rows (2026, kept).
$dbh->do("insert into t_trk  values ('20190101000000','o'), ('20261201000000','n')");
$dbh->do("insert into t_meta values ('20190101','o'), ('20261201','n')");
$dbh->do("insert into t_acq  values ('20190101','o'), ('20261201','n')");

my $cfg = {
	EDTK_ENTIRE_YEARS_KEPT => 5,
	EDTK_DBI_TRACKING      => 't_trk',
	EDTK_DBI_OUTMNGR       => 't_meta',
	EDTK_DBI_ACQUIT        => 't_acq',
};

sub count_of {
	my ( $dbh, $table ) = @_;
	my ($n) = $dbh->selectrow_array("select count(*) from $table");
	return $n;
}

# --- no retention window configured -> no-op ---------------------------------
ok(
	db_backup_agent( $dbh, { EDTK_DBI_TRACKING => 't_trk' } ),
	'db_backup_agent: no-op when EDTK_ENTIRE_YEARS_KEPT is unset'
);
is( count_of( $dbh, 't_trk' ), 2, 'db_backup_agent: nothing purged without a retention window' );

# --- first run ----------------------------------------------------------------
ok( db_backup_agent( $dbh, $cfg ), 'db_backup_agent: first run returns true' );

my $suffix = strftime( '%Y%m%d', localtime ) . '_BAK';
for my $case (
	[ 't_trk',  'ed_tstamp',   2 ],
	[ 't_meta', 'ed_dtedtion', 2 ],
	[ 't_acq',  'ed_dtpost',   2 ],
	)
{
	my ( $table, $datecol, $snapshot ) = @$case;
	my $archive = "${table}_$suffix";
	ok( oEdtk::DBAdmin::_db_object_exists( $dbh, 'table', $archive ),
		"$table: archive $archive created" );
	is( count_of( $dbh, $archive ), $snapshot, "$table: archive is a full snapshot" );
	is( count_of( $dbh, $table ),   1,         "$table: only the recent row remains" );
	my ($old) = $dbh->selectrow_array(
		"select count(*) from $table where $datecol < '20210101' and ed_x = 'o'");
	is( $old, 0, "$table: old row purged" );
}

# --- second run on the same day ----------------------------------------------
ok( db_backup_agent( $dbh, $cfg ), 'db_backup_agent: second run returns true' );
is( count_of( $dbh, "t_trk_$suffix" ),
	2, 'db_backup_agent: existing same-day archive is kept (not lost)' );
is( count_of( $dbh, 't_trk' ), 1, 'db_backup_agent: second run purges nothing new' );

$dbh->disconnect;
done_testing();

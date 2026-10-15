#!/usr/bin/perl
#
# Unit tests for the backup-buffer repatriation of oEdtk::DBAdmin
# (db_backup_available / db_backup_pending / db_reconcile_backup).
#
# Both the main database and the backup buffer are SQLite files, so the test is
# self-contained. It checks: detection of pending rows, repatriation into the
# main database, idempotence on a re-run, natural-key de-duplication, the drain
# of the buffer, the dry-run mode, and the anti-loop guard (backup == main).
#
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../lib";
use lib "$FindBin::Bin/lib";
use Test::More;
use File::Temp qw(tempdir);
use DBI;
use oEdtk::Config qw(config_read);
use oEdtk::DBAdmin
	qw(schema_Create create_table_TRACKING db_connect db_reconcile_backup db_backup_pending db_backup_available);

my $dir       = tempdir( 'oedtk_reconcile_XXXXXX', CLEANUP => 1 );
my $main_file = "$dir/main.db";
my $bak_file  = "$dir/bak.db";

my $main = DBI->connect( "dbi:SQLite:dbname=$main_file",
	'', '', { RaiseError => 1, PrintError => 0, AutoCommit => 1 } );
my $bak = DBI->connect( "dbi:SQLite:dbname=$bak_file", '', '',
	{ RaiseError => 1, PrintError => 0, AutoCommit => 1 } );
schema_Create($main);
schema_Create($bak);

# schema_Create does not create the tracking table (db_connect does)
create_table_TRACKING( $main, 'edtk_tracking', 10 );
create_table_TRACKING( $bak,  'edtk_tracking', 10 );

my $cfg = config_read('EDTK_DB');
$cfg->{'EDTK_DBI_DSN'}       = "dbi:SQLite:dbname=$main_file";
$cfg->{'EDTK_DBI_DSN_BAK'}   = "dbi:SQLite:dbname=$bak_file";
$cfg->{'EDTK_DB_CHECK_AUTO'} = 'NO';

# --- fixtures: rows accumulated in the backup buffer ------------------------
$bak->do(
'insert into edtk_tracking (ed_tstamp, ed_sngl_id, ed_seq, ed_app, ed_user, ed_corp) values (?,?,?,?,?,?)',
	undef, '20260101000000', 'S1', 1, 'APP', 'u1', 'corp'
);
$bak->do(
'insert into edtk_tracking (ed_tstamp, ed_sngl_id, ed_seq, ed_app, ed_user, ed_corp) values (?,?,?,?,?,?)',
	undef, '20260101000001', 'S2', 2, 'APP', 'u2', 'corp'
);
$bak->do( 'insert into edtk_id (ed_id_date, ed_id_value, ed_id_chanel_out) values (?,?,?)',
	undef, '2026-01-01', 'ID1', 'CH1' );
$bak->do(
'insert into edtk_acq (ed_seqlot, ed_lotname, ed_dtpost, ed_nbfaces, ed_nbplis) values (?,?,?,?,?)',
	undef, '1', 'LOTA', '20260101', 4, 2
);

# one tracking row is ALSO already present in the main database -> must be skipped
$main->do(
'insert into edtk_tracking (ed_tstamp, ed_sngl_id, ed_seq, ed_app, ed_user, ed_corp) values (?,?,?,?,?,?)',
	undef, '20260101000000', 'S1', 1, 'APP', 'u1', 'corp'
);

sub count {
	my ( $dbh, $table ) = @_;
	my ($n) = $dbh->selectrow_array("select count(*) from $table");
	return $n;
}

# --- availability / anti-loop guard ------------------------------------------
ok( db_backup_available($cfg), 'db_backup_available: distinct backup detected' );
{
	my %same = ( %$cfg, EDTK_DBI_DSN_BAK => $cfg->{'EDTK_DBI_DSN'} );
	ok( !db_backup_available( \%same ),
		'db_backup_available: backup == main -> false (anti-loop)' );
}

# --- detection ----------------------------------------------------------------
my $pending = db_backup_pending($cfg);
is( $pending->{'edtk_tracking'}, 2, 'db_backup_pending: 2 tracking rows waiting' );
is( $pending->{edtk_acq},        1, 'db_backup_pending: 1 acq row waiting' );
is( $pending->{edtk_id},         1, 'db_backup_pending: 1 id row waiting' );

# --- dry run must not write nor drain ----------------------------------------
my $dry = db_reconcile_backup( $main, CFG => $cfg, dry_run => 1 );
is( $dry->{written}, 0, 'dry_run: nothing written' );
is( count( $main, 'edtk_tracking' ), 1, 'dry_run: main untouched' );
is( count( $bak,  'edtk_tracking' ), 2, 'dry_run: buffer untouched' );

# --- real repatriation --------------------------------------------------------
my $r = db_reconcile_backup( $main, CFG => $cfg );
ok( $r->{ok}, 'db_reconcile_backup: ok' );
is( $r->{tables}{'edtk_tracking'}{written}, 1, 'tracking: 1 written' );
is( $r->{tables}{'edtk_tracking'}{skipped}, 1, 'tracking: 1 skipped (already in main)' );
is( $r->{tables}{'edtk_id'}{written},       1, 'id: 1 written' );
is( $r->{tables}{'edtk_acq'}{written},      1, 'acq: 1 written' );

is( count( $main, 'edtk_tracking' ), 2, 'main tracking now holds 2 rows' );
is( count( $main, 'edtk_id' ),       1, 'main id now holds 1 row' );
is( count( $main, 'edtk_acq' ),      1, 'main acq now holds 1 row' );
is( count( $bak,  'edtk_tracking' ), 0, 'buffer tracking drained' );
is( count( $bak,  'edtk_acq' ),      0, 'buffer acq drained' );
is( count( $bak,  'edtk_id' ),       0, 'buffer id drained' );

# --- idempotence: a second run does nothing ----------------------------------
my $r2 = db_reconcile_backup( $main, CFG => $cfg );
is( $r2->{written},                  0, 're-run: nothing written (idempotent)' );
is( count( $main, 'edtk_tracking' ), 2, 're-run: no duplicate' );

# --- on_backup flag ----------------------------------------------------------
ok( !oEdtk::DBAdmin::db_on_backup($main), 'db_on_backup: main handle is not the backup' );

# --- db_connect records the backup fallback ---------------------------------
{
	my %fcfg = %$cfg;
	$fcfg{'EDTK_DBI_DSN'}          = "dbi:SQLite:dbname=$dir/missing/dead.db";    # cannot open
	$fcfg{'EDTK_DBI_DSN_USER'}     = '';
	$fcfg{'EDTK_DBI_DSN_PASS'}     = '';
	$fcfg{'EDTK_DBI_DSN_BAK_USER'} = '';
	$fcfg{'EDTK_DBI_DSN_BAK_PASS'} = '';
	$fcfg{'EDTK_WAITRUN'}          = 0;
	my $fb =
		db_connect( \%fcfg, 'EDTK_DBI_DSN', { AutoCommit => 1, PrintError => 0, RaiseError => 0 } );
	ok( $fb, 'db_connect: fell back to the backup when the main is unreachable' );
	ok( oEdtk::DBAdmin::db_on_backup($fb),
		'db_connect: on_backup flag set on the fallback handle' );
	ok(
		oEdtk::DBAdmin::_table_exists( $fb, 'edtk_tracking' ),
		'db_connect: backup schema prepared (tracking exists)'
	);
	$fb->disconnect;
}

done_testing();

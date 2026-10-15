#!/usr/bin/perl
#
# Integration test for the Lot 1 multi-DB compatibility work of oEdtk::DBAdmin.
#
# It creates scratch tables (and their indexes) through create_table_* on every
# reachable engine, then re-creates them to prove "CREATE ... IF NOT EXISTS" is
# emulated correctly, and finally drops them. Engines that are not reachable are
# skipped with a message, so the script is safe to run anywhere.
#
# Usage: perl -Ilib t/test_lot1_compat.pl
#
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../lib";
use lib "$FindBin::Bin/lib";
use DBI;
use oEdtk::DBAdmin qw(create_table_DISTRIB create_table_AGREGE create_table_TRACKING
	create_table_ID create_table_OUTMNGR);

my @ENGINES = (
	{ name => 'SQLite', dsn => "dbi:SQLite:dbname=/tmp/oedtk_lot1.sqlite", user => '', pass => '' },
	{
		name => 'PostgreSQL',
		dsn  => 'dbi:Pg:dbname=oedtk;host=localhost;port=5432',
		user => 'oedtk',
		pass => 'dev_oedtk_test'
	},
	{
		name => 'MariaDB',
		dsn  => 'DBI:mysql:database=oedtk;host=127.0.0.1;port=3307',
		user => 'oedtk',
		pass => 'dev_oedtk_test'
	},
);

# table kind => (create callback, table name, drop order)
my @TABLES = (
	{
		name   => 'edtk_test_trk',
		create => sub { create_table_TRACKING( $_[0], 'edtk_test_trk', 10 ) }
	},
	{ name => 'edtk_id', create => sub { create_table_ID( $_[0] ) } }
	,    # name hardcoded in the function
	{ name => 'edtk_test_om', create => sub { create_table_OUTMNGR( $_[0], 'edtk_test_om' ) } },
	{
		name   => 'edtk_test_distrib',
		create => sub { create_table_DISTRIB( $_[0], 'edtk_test_distrib' ) }
	},
	{ name => 'edtk_agrege', create => sub { create_table_AGREGE( $_[0] ) } }
	,    # name hardcoded in the function
);

# MySQL uppercases CREATE statements, so a table may be stored in UPPER case.
# Probe both cases through the module's own existence helper.
sub has_table {
	my ( $dbh, $table ) = @_;
	return 1 if eval { oEdtk::DBAdmin::_db_object_exists( $dbh, 'table', $table ) };
	return 1 if eval { oEdtk::DBAdmin::_db_object_exists( $dbh, 'table', uc $table ) };
	return 0;
}

sub drop_table {
	my ( $dbh, $table ) = @_;
	eval { $dbh->do("drop table if exists $table") };
	eval { $dbh->do( "drop table if exists " . uc $table ) };
}

my $fail = 0;
for my $e (@ENGINES) {
	print "\n=== $e->{name} ===\n";
	my $dbh = eval {
		DBI->connect( $e->{dsn}, $e->{user}, $e->{pass},
			{ RaiseError => 0, PrintError => 0, AutoCommit => 1 } );
	};
	if ( !$dbh ) {
		print "  SKIP (not reachable): $DBI::errstr\n";
		next;
	}
	my $driver = oEdtk::DBAdmin::_db_check_driver_name($dbh);
	print "  driver: $driver\n";

	my ( $ok, $ko ) = ( 0, 0 );
	for my $t (@TABLES) {
		my $name = $t->{name};

		# cleanup any leftover from a previous run (both cases)
		drop_table( $dbh, $name );

		# 1st creation, then a 2nd (idempotency of IF NOT EXISTS emulation)
		$t->{create}->($dbh);
		my $first = has_table( $dbh, $name );
		my $err   = $dbh->errstr;
		$t->{create}->($dbh);

		if ($first) { $ok++; printf( "  ok   create %-18s\n", $name ) }
		else { $ko++; printf( "  FAIL create %-18s : %s\n", $name, ( $err // 'table absent' ) ) }
	}

	# drop everything
	drop_table( $dbh, $_->{name} ) for @TABLES;
	my $left = grep { has_table( $dbh, $_->{name} ) } @TABLES;
	print "  drop: ", ( $left ? "FAIL ($left left)" : "ok" ), "\n";
	$fail++ if $ko or $left;

	$dbh->disconnect;
}
print "\n", ( $fail ? "FAILED ($fail engine(s))\n" : "ALL ENGINES OK\n" );
exit( $fail ? 1 : 0 );

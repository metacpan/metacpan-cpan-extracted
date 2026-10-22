#!/usr/bin/perl
#
# Non-regression tests for the pure helpers of oEdtk::DBAdmin and oEdtk::Util.
#
# No database connection is required: the driver-dependent helpers are driven by
# a fake $dbh hashref of the shape { Driver => { Name => '...' } }.
#
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../lib";
use lib "$FindBin::Bin/lib";
use Test::More;
use Time::HiRes ();
use TestOEdtk   qw(quiet_require);

quiet_require($_) for qw(oEdtk::DBAdmin oEdtk::Util);

# --- oEdtk::DBAdmin::_pg_csv_field : PostgreSQL CSV quoting ------------------
is( oEdtk::DBAdmin::_pg_csv_field( undef, ',', '"' ), '',   '_pg_csv_field undef is empty' );
is( oEdtk::DBAdmin::_pg_csv_field( '',    ',', '"' ), '""', '_pg_csv_field empty is quoted' );
is( oEdtk::DBAdmin::_pg_csv_field( 'abc', ',', '"' ), 'abc',
	'_pg_csv_field plain value unchanged' );
is( oEdtk::DBAdmin::_pg_csv_field( 'a,b', ',', '"' ), '"a,b"', '_pg_csv_field quotes a separator' );
is( oEdtk::DBAdmin::_pg_csv_field( 'a"b', ',', '"' ),
	'"a""b"', '_pg_csv_field doubles the quote char' );
is( oEdtk::DBAdmin::_pg_csv_field( "a\nb", ',', '"' ),
	"\"a\nb\"", '_pg_csv_field quotes a newline' );

# --- oEdtk::DBAdmin::_pg_encoding_name : PG encoding -> Encode name ----------
is( oEdtk::DBAdmin::_pg_encoding_name('UTF8'),    'UTF-8',       'UTF8 maps to UTF-8' );
is( oEdtk::DBAdmin::_pg_encoding_name('LATIN1'),  'ISO-8859-1',  'LATIN1 maps to ISO-8859-1' );
is( oEdtk::DBAdmin::_pg_encoding_name('LATIN9'),  'ISO-8859-15', 'LATIN9 maps to ISO-8859-15' );
is( oEdtk::DBAdmin::_pg_encoding_name('WIN1252'), 'CP1252',      'WIN1252 maps to CP1252' );
is( oEdtk::DBAdmin::_pg_encoding_name('SQL_ASCII'),
	'UTF-8', 'unknown SQL_ASCII falls back to UTF-8' );
is( oEdtk::DBAdmin::_pg_encoding_name('BOGUS'), 'UTF-8', 'unknown encoding falls back to UTF-8' );
is( oEdtk::DBAdmin::_pg_encoding_name(undef),   'UTF-8', 'undef encoding falls back to UTF-8' );
is( oEdtk::DBAdmin::_pg_encoding_name(''),      'UTF-8', 'empty encoding falls back to UTF-8' );

# --- oEdtk::DBAdmin::_make_clean_val : truncation and '' -> NULL -------------
my $col_meta = {
	NUM  => { numeric       => 1, blank_to_null => 1, size => 5 },
	TXT  => { size          => 5 },
	DATE => { blank_to_null => 1 },
};
my $clean = oEdtk::DBAdmin::_make_clean_val($col_meta);
is( $clean->( 'TXT',     undef ),    undef,   '_make_clean_val undef stays undef' );
is( $clean->( 'TXT',     '' ),       '',      '_make_clean_val empty text stays empty' );
is( $clean->( 'NUM',     '' ),       undef,   '_make_clean_val empty numeric becomes NULL' );
is( $clean->( 'DATE',    '' ),       undef,   '_make_clean_val empty date becomes NULL' );
is( $clean->( 'TXT',     'abcdef' ), 'abcde', '_make_clean_val truncates to the column size' );
is( $clean->( 'TXT',     'abc' ),    'abc',   '_make_clean_val keeps short values' );
is( $clean->( 'UNKNOWN', 'x' ),      'x',     '_make_clean_val leaves unknown columns untouched' );

# --- oEdtk::DBAdmin::_clean_row : positional plan, same contract (plan D61 O3) -
# The row-by-row loops clean each field through a positional plan (_clean_row)
# instead of a closure call per field. This guards that the fast path returns
# exactly what the _make_clean_val closure returns, on the same metadata.
my @pcols = qw(TXT NUM DATE UNKNOWN);
my $plan  = oEdtk::DBAdmin::_make_clean_plan( $col_meta, \@pcols );
my @rows  = (
	[ undef,    '',          'x',    'y' ],    # undef / blank / passthrough
	[ 'abcdef', '123456789', '',     '' ],     # truncation, size, blank -> NULL
	[ 'ab',     '7',         '2025', 'z' ],    # short values
	['ab'],                                    # short row: missing fields -> NULL
);
for my $r (@rows) {
	is_deeply(
		[ oEdtk::DBAdmin::_clean_row( $plan, $r ) ],
		[ map { $clean->( $pcols[$_], $r->[$_] ) } 0 .. $#pcols ],
		'_clean_row matches _make_clean_val for row [' . join( ',', map { $_ // '~' } @$r ) . ']'
	);
}

# --- oEdtk::DBAdmin::_norm_identifiers : driver-dependent identifier case ----
{
	my ( $id, $table, @cols ) =
		oEdtk::DBAdmin::_norm_identifiers( { Driver => { Name => 'SQLite' } },
		'My.Table', [ 'A', ' B ' ] );
	is( $id->(' Foo '), 'foo',      'norm_id lower-cases and trims (non-MySQL)' );
	is( $table,         'my.table', '_norm_identifiers lower-cases the table' );
	is_deeply( \@cols, [ 'a', 'b' ], '_norm_identifiers lower-cases the columns' );
}
{
	my ( $id, $table, @cols ) =
		oEdtk::DBAdmin::_norm_identifiers( { Driver => { Name => 'mysql' } }, 'My.Table', ['a'] );
	is( $id->(' foo '), 'FOO',      'norm_id upper-cases and trims (MySQL)' );
	is( $table,         'MY.TABLE', '_norm_identifiers upper-cases the table (MySQL)' );
	is_deeply( \@cols, ['A'], '_norm_identifiers upper-cases the columns (MySQL)' );
}

# --- oEdtk::DBAdmin::_db_check_driver_name : driver identification ----------
is( oEdtk::DBAdmin::_db_check_driver_name( { Driver => { Name => 'SQLite' } } ),
	'SQLite', '_db_check_driver_name SQLite' );
is( oEdtk::DBAdmin::_db_check_driver_name( { Driver => { Name => 'Oracle' } } ),
	'Oracle', '_db_check_driver_name Oracle' );
is( oEdtk::DBAdmin::_db_check_driver_name( { Driver => { Name => 'Pg' } } ),
	'PostgreSQL', '_db_check_driver_name Pg' );
is( oEdtk::DBAdmin::_db_check_driver_name( { Driver => { Name => 'mysql' } } ),
	'mysql', '_db_check_driver_name mysql' );
is( oEdtk::DBAdmin::_db_check_driver_name( { Driver => { Name => 'Bogus' } } ),
	'NC', '_db_check_driver_name unknown driver' );
is( oEdtk::DBAdmin::_db_check_driver_name(undef), 'NC', '_db_check_driver_name undef handle' );

# --- oEdtk::DBAdmin::_sql_fixup : driver-specific SQL rewriting --------------
# The closing paren is excluded from the captured VALUES list, so the last
# empty string is left untouched; the VALUES keyword is upper-cased.
is(
	oEdtk::DBAdmin::_sql_fixup(
		{ Driver => { Name => 'Pg' } },
		"insert into t values ('a', '', '')", 0
	),
	"insert into t VALUES ('a', NULL, '')",
	'_sql_fixup turns inner empty strings into NULL for PostgreSQL'
);

# The replacement re-introduces a leading space, yielding a double space before '='.
is(
	oEdtk::DBAdmin::_sql_fixup(
		{ Driver => { Name => 'Pg' } },
		"update t set c = '' where id = 1", 0
	),
	"update t set c  = NULL where id = 1",
	'_sql_fixup rewrites SET col = \'\' for PostgreSQL'
);
is(
	oEdtk::DBAdmin::_sql_fixup(
		{ Driver => { Name => 'SQLite' } },
		'create table t (c VARCHAR2(10))', 0
	),
	'create table t (c VARCHAR(10))',
	'_sql_fixup converts VARCHAR2 to VARCHAR for non-Oracle drivers'
);
is(
	oEdtk::DBAdmin::_sql_fixup(
		{ Driver => { Name => 'Oracle' } },
		'create table t (c VARCHAR2(10))', 0
	),
	'create table t (c VARCHAR2(10))',
	'_sql_fixup keeps VARCHAR2 for Oracle'
);
is(
	oEdtk::DBAdmin::_sql_fixup( { Driver => { Name => 'mysql' } }, 'select 1 from t', 1 ),
	'SELECT 1 FROM T',
	'_sql_fixup upper-cases MySQL statements when mysqlCasse is set'
);

# MariaDB reports Driver.Name 'MariaDB' and is deliberately left untouched: some
# MySQL-clients rely on case-sensitive processing, so no forced case is applied.
is(
	oEdtk::DBAdmin::_sql_fixup( { Driver => { Name => 'MariaDB' } }, 'select 1 from t', 1 ),
	'select 1 from t',
	'_sql_fixup leaves MariaDB statements untouched (no forced case)'
);

# INSERT/REPLACE are excluded from the forced case even for MySQL.
is(
	oEdtk::DBAdmin::_sql_fixup( { Driver => { Name => 'mysql' } }, 'insert into t values (1)', 1 ),
	'insert into t values (1)',
	'_sql_fixup never upper-cases INSERT/REPLACE for MySQL'
);

# --- oEdtk::Util::_uc_hash_keys : in-place key upper-casing ------------------
my %h   = ( aa => 1, BB => 2 );
my $ref = oEdtk::Util::_uc_hash_keys( \%h );
is( $ref, \%h, '_uc_hash_keys returns the same reference' );
is_deeply( \%h, { AA => 1, BB => 2 }, '_uc_hash_keys upper-cases every key in place' );

# --- oEdtk::DBAdmin::_pg_burst_decision : force_copy precedence --------------
{
	my ( $elt, $why ) =
		oEdtk::DBAdmin::_pg_burst_decision( { force_copy => 1 }, {}, '/nonexistent.csv' );
	is( $elt, 0,                 '_pg_burst_decision: force_copy selects COPY' );
	is( $why, 'force_copy => 1', '_pg_burst_decision: force_copy reason is explicit' );

	( $elt, $why ) = oEdtk::DBAdmin::_pg_burst_decision(
		{ force_copy => 1, pg_copy_staging => 1, burst_mo => 0.001 },
		{}, '/nonexistent.csv' );
	is( $elt, 0,                 'force_copy wins over pg_copy_staging => 1' );
	is( $why, 'force_copy => 1', 'force_copy wins before burst_mo' );

	( $elt, $why ) = oEdtk::DBAdmin::_pg_burst_decision( { force_copy => 0, pg_copy_staging => 1 },
		{}, '/nonexistent.csv' );
	is( $elt, 1,                      'a false force_copy leaves pg_copy_staging in charge' );
	is( $why, 'pg_copy_staging => 1', 'the pg_copy_staging reason is unchanged' );

	( $elt, $why ) =
		oEdtk::DBAdmin::_pg_burst_decision( { pg_copy_staging => 0 }, {}, '/nonexistent.csv' );
	is( $elt, 0, 'an absent force_copy leaves the existing decision unchanged' );
	is( $why, 'pg_copy_staging => 0', 'the existing COPY reason is unchanged' );
}

# --- oEdtk::DBAdmin::_elapsed_seconds : whole seconds for edtk_admin ---------
# DBAdmin imports time() from Time::HiRes, so a raw delta is fractional;
# edtk_admin.ed_action_duration is integer and PostgreSQL rejects it.
{
	my $t0 = Time::HiRes::time();
	my $d  = oEdtk::DBAdmin::_elapsed_seconds( $t0 - 5.5 );
	like( $d, qr/\A[0-9]+\z/, '_elapsed_seconds returns an integer' );
	is( $d, 5, '_elapsed_seconds truncates the fractional part' );
}

# --- oEdtk::DBAdmin::_schema_change_key_sql : portable key-change DDL ---------
# PostgreSQL and Oracle build a separate unique index and attach it; reusing the
# constraint name for the index made the ADD CONSTRAINT fail on PostgreSQL.
{
	my @cols = qw( ed_idldoc ed_seqdoc ed_idseqpg ed_idjob );

	my ( $sql, $err ) = oEdtk::DBAdmin::_schema_change_key_sql( 'PostgreSQL', 'EDTK_INDEX', \@cols,
		'edtk_index_pkey' );
	is( $err, undef, 'PostgreSQL key change has no error' );
	is_deeply(
		$sql,
		[
			'alter table EDTK_INDEX drop constraint edtk_index_pkey',
			'create unique index if not exists ux_EDTK_INDEX on EDTK_INDEX ( '
				. join( ', ', @cols ) . ' )',
'alter table EDTK_INDEX add constraint pk_EDTK_INDEX primary key using index ux_EDTK_INDEX',
		],
		'PostgreSQL attaches the pre-built unique index'
	);

	( $sql, $err ) =
		oEdtk::DBAdmin::_schema_change_key_sql( 'Oracle', 'EDTK_INDEX', \@cols, 'EDTK_INDEX_PK' );
	is( $err, undef, 'Oracle key change has no error' );
	is_deeply(
		$sql,
		[
			'alter table EDTK_INDEX drop constraint EDTK_INDEX_PK',
			'create unique index if not exists ux_EDTK_INDEX on EDTK_INDEX ( '
				. join( ', ', @cols ) . ' )',
			'alter table EDTK_INDEX add constraint pk_EDTK_INDEX primary key ( '
				. join( ', ', @cols )
				. ' ) using index ux_EDTK_INDEX',
		],
		'Oracle attaches the pre-built unique index with its column list'
	);

	( $sql, $err ) = oEdtk::DBAdmin::_schema_change_key_sql( 'mysql', 'EDTK_INDEX', \@cols, undef );
	is( $err, undef, 'MySQL key change has no error' );
	is_deeply(
		$sql,
		[
			'alter table EDTK_INDEX drop primary key',
			'alter table EDTK_INDEX add primary key ( ' . join( ', ', @cols ) . ' )',
		],
		'MySQL swaps the primary key in place'
	);

	( $sql, $err ) =
		oEdtk::DBAdmin::_schema_change_key_sql( 'SQLite', 'EDTK_INDEX', \@cols, undef );
	is_deeply( $sql, [], 'SQLite renders no key-change DDL' );
	is(
		$err,
		'changing the key in place is not supported on SQLite',
		'SQLite reports that the key cannot be changed in place'
	);

	( $sql, $err ) =
		oEdtk::DBAdmin::_schema_change_key_sql( 'PostgreSQL', 'EDTK_INDEX', \@cols, undef );
	is_deeply( $sql, [], 'a missing constraint name renders no DDL' );
	like( $err, qr/cannot find the primary-key constraint/, 'the missing constraint is reported' );
}

# --- oEdtk::DBAdmin::_schema_scan_table : case-insensitive table lookup ------
# PostgreSQL stores the unquoted EDTK_INDEX as edtk_index while the shipped
# configuration keeps the historical upper-case name.
{
	my $scan = {
		tables => {
			edtk_index => {
				columns => [
					{ name => 'ed_idldoc', size => 36,    pk => 1 },
					{ name => 'ed_seqdoc', size => undef, pk => 2 },
				],
			},
		},
	};
	is(
		oEdtk::DBAdmin::_schema_scan_table( $scan, 'EDTK_INDEX' ),
		$scan->{tables}{edtk_index},
		'an upper-case config name finds the lower-case table'
	);
	is(
		oEdtk::DBAdmin::_schema_scan_table( $scan, 'edtk_index' ),
		$scan->{tables}{edtk_index},
		'an exact name still finds the table'
	);
	is( oEdtk::DBAdmin::_schema_scan_table( $scan, 'EDTK_MISSING' ),
		undef, 'an absent table is undefined' );

	my $f = oEdtk::DBAdmin::_schema_features( $scan, 'EDTK_INDEX' );
	is( $f->{idldoc_size}, 36, '_schema_features resolves the table case-insensitively' );
	is_deeply( $f->{key}, [ 'ed_idldoc', 'ed_seqdoc' ], 'the key is read off the resolved table' );
}

done_testing();

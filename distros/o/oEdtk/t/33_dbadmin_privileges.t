#!/usr/bin/perl
#
# Tests for oEdtk::DBAdmin::db_check_privileges -- the best-effort probe that
# reports whether the connected DB user may CREATE, DROP, INDEX, ALTER and
# create SEQUENCE objects.
#
# The probe only reads the data dictionary and never dies. This file checks it
# against:
#   * a real in-memory SQLite handle (no privilege model => always allowed);
#   * a lightweight mock $dbh that answers the catalog queries the PostgreSQL,
#     MySQL/MariaDB and Oracle backends issue -- so those branches are covered
#     without any of those servers running locally.
#
# The whole file is pure ASCII on purpose.
#
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../lib";
use lib "$FindBin::Bin/lib";
use Test::More;
use TestOEdtk qw(quiet_require memory_dbh mute);

quiet_require('oEdtk::DBAdmin');

# --- minimal mock handle ----------------------------------------------------
# Answers the catalog queries by matching a SQL fragment, exactly like the
# probe would get from a real driver, and exposes the {'Driver'}{'Name'} shape
# _db_check_driver_name() reads.
{

	package MockDBH;

	sub new {
		my ( $class, %a ) = @_;
		return bless {
			Driver => { Name => $a{driver} },
			sr     => $a{sr}   || {},    # sql fragment => selectrow_array list
			sall   => $a{sall} || {},    # sql fragment => selectall_arrayref rows
			scol   => $a{scol} || {},    # sql fragment => selectcol_arrayref cols
			boom   => $a{boom},          # make every query die when set
		}, $class;
	}

	sub _find {
		my ( $self, $table, $sql ) = @_;
		die $self->{boom} if $self->{boom};
		for my $frag ( keys %{ $self->{$table} } ) {
			return $self->{$table}{$frag} if index( $sql, $frag ) >= 0;
		}
		return undef;
	}

	sub selectrow_array {
		my ( $s, $sql ) = @_;
		my $r = $s->_find( 'sr', $sql );
		return defined $r ? @$r : ();
	}
	sub selectall_arrayref { my ( $s, $sql ) = @_; return $s->_find( 'sall', $sql ) // []; }
	sub selectcol_arrayref { my ( $s, $sql ) = @_; return $s->_find( 'scol', $sql ) // []; }
}

# Call the probe with logger output silenced.
sub probe {
	my ( $dbh, %opt ) = @_;
	return mute( sub { oEdtk::DBAdmin::db_check_privileges( $dbh, %opt ) } );
}

# --- the function is part of the public API ---------------------------------
ok( oEdtk::DBAdmin->can('db_check_privileges'), 'db_check_privileges is defined' );

# --- SQLite: no privilege model, CREATE and DROP assumed allowed -----------
if ( my $sq = memory_dbh() ) {
	my $r = probe($sq);
	is( $r->{driver},   'SQLite', 'sqlite: driver is reported' );
	is( $r->{checked},  1,        'sqlite: probe ran' );
	is( $r->{create},   1,        'sqlite: CREATE assumed allowed' );
	is( $r->{drop},     1,        'sqlite: DROP assumed allowed' );
	is( $r->{index},    1,        'sqlite: INDEX assumed allowed' );
	is( $r->{alter},    1,        'sqlite: ALTER assumed allowed' );
	is( $r->{sequence}, 1,        'sqlite: SEQUENCE assumed allowed' );
	is_deeply( $r->{missing}, [], 'sqlite: nothing reported as missing' );
}
else {
	diag 'DBD::SQLite not available, skipping the SQLite branch';
}

# --- an empty or undef handle is not fatal ----------------------------------
{
	my $r = probe(undef);
	is( $r->{driver},  'NC', 'undef handle: driver NC' );
	is( $r->{checked}, 0,    'undef handle: not checked' );
	is_deeply( $r->{missing}, [], 'undef handle: nothing reported as missing' );
}

# --- unknown driver: reported but left unchecked ----------------------------
{
	my $r = probe( MockDBH->new( driver => 'Weird' ) );
	is( $r->{driver},  'NC', 'unknown driver: NC' );
	is( $r->{checked}, 0,    'unknown driver: not checked' );
	is_deeply( $r->{missing}, [], 'unknown driver: nothing reported as missing' );
}

# --- PostgreSQL: superuser always passes ------------------------------------
{
	my $dbh = MockDBH->new( driver => 'Pg', sr => { 'rolsuper' => [1] } );
	my $r   = probe($dbh);
	is( $r->{driver}, 'PostgreSQL', 'pg superuser: driver reported' );
	is( $r->{create}, 1,            'pg superuser: CREATE allowed' );
	is( $r->{drop},   1,            'pg superuser: DROP allowed' );
	is_deeply( $r->{missing}, [], 'pg superuser: nothing missing' );
}

# --- PostgreSQL: full rights (create + owns a table) ------------------------
{
	my $dbh = MockDBH->new(
		driver => 'Pg',
		sr     => {
			'rolsuper'               => [0],
			'has_database_privilege' => [1],
			'bool_or'                => [1],
		}
	);
	my $r = probe($dbh);
	is( $r->{create}, 1, 'pg owner: CREATE allowed' );
	is( $r->{drop},   1, 'pg owner: DROP allowed' );
	is_deeply( $r->{missing}, [], 'pg owner: nothing missing' );
}

# --- PostgreSQL: no rights at all => two alerts -----------------------------
{
	my $dbh = MockDBH->new(
		driver => 'Pg',
		sr     => {
			'rolsuper'               => [0],
			'has_database_privilege' => [0],
			'bool_or'                => [0],
		}
	);
	my $r = probe($dbh);
	is( $r->{create}, 0, 'pg no-rights: CREATE denied' );
	is( $r->{drop},   0, 'pg no-rights: DROP denied' );
	is_deeply(
		$r->{missing},
		[ 'CREATE', 'DROP', 'INDEX', 'ALTER', 'SEQUENCE' ],
		'pg no-rights: every right reported missing'
	);
}

# --- PostgreSQL: ownership looked up for a specific table ------------------
{
	my $dbh = MockDBH->new(
		driver => 'Pg',
		sr     => {
			'rolsuper'               => [0],
			'has_database_privilege' => [1],
			'relname = ?'            => [1],
		}
	);
	my $r = probe( $dbh, table => 'edtk_admin' );
	is( $r->{drop},  1, 'pg table ownership: DROP allowed for that table' );
	is( $r->{index}, 1, 'pg table ownership: INDEX allowed for that table' );
	is( $r->{alter}, 1, 'pg table ownership: ALTER allowed for that table' );
}

# --- MySQL: ALL PRIVILEGES on *.* --------------------------------------------
{
	my $dbh = MockDBH->new(
		driver => 'MySQL',
		sr     => { 'DATABASE()'  => ['oedtk'] },
		sall   => { 'SHOW GRANTS' => [ ["GRANT ALL PRIVILEGES ON *.* TO 'u'\@'%'"] ] }
	);
	my $r = probe($dbh);
	is( $r->{driver},   'mysql', 'mysql: driver reported' );
	is( $r->{create},   1,       'mysql all: CREATE allowed' );
	is( $r->{drop},     1,       'mysql all: DROP allowed' );
	is( $r->{index},    1,       'mysql all: INDEX allowed' );
	is( $r->{alter},    1,       'mysql all: ALTER allowed' );
	is( $r->{sequence}, 1,       'mysql all: SEQUENCE allowed' );
	is_deeply( $r->{missing}, [], 'mysql all: nothing missing' );
}

# --- MySQL: CREATE + DROP scoped to the current database --------------------
{
	my $dbh = MockDBH->new(
		driver => 'mysql',
		sr     => { 'DATABASE()'  => ['oedtk'] },
		sall   => { 'SHOW GRANTS' => [ ['GRANT CREATE, DROP ON `oedtk`.* TO \'u\'@\'%\''] ] }
	);
	my $r = probe($dbh);
	is( $r->{create}, 1, 'mysql scoped: CREATE allowed' );
	is( $r->{drop},   1, 'mysql scoped: DROP allowed' );
	is( $r->{index},  0, 'mysql scoped: INDEX denied (no INDEX/ALTER)' );
	is( $r->{alter},  0, 'mysql scoped: ALTER denied' );
	is_deeply( $r->{missing}, [ 'INDEX', 'ALTER' ], 'mysql scoped: INDEX and ALTER missing' );
}

# --- MySQL: only SELECT on another scope => two alerts ----------------------
{
	my $dbh = MockDBH->new(
		driver => 'mysql',
		sr     => { 'DATABASE()' => ['oedtk'] },
		sall   => {
			'SHOW GRANTS' => [
				["GRANT SELECT ON `otherdb`.* TO 'u'\@'%'"], ["GRANT USAGE ON *.* TO 'u'\@'%'"],
			]
		}
	);
	my $r = probe($dbh);
	is( $r->{create}, 0, 'mysql limited: CREATE denied' );
	is( $r->{drop},   0, 'mysql limited: DROP denied' );
	is_deeply(
		$r->{missing},
		[ 'CREATE', 'DROP', 'INDEX', 'ALTER', 'SEQUENCE' ],
		'mysql limited: every right reported missing'
	);
}

# --- Oracle: CREATE TABLE, no DROP ANY TABLE (H11: the owner drops its own) --
{
	my $dbh = MockDBH->new(
		driver => 'Oracle',
		scol   => { 'USER_SYS_PRIVS' => ['CREATE TABLE'] }
	);
	my $r = probe($dbh);
	is( $r->{driver},   'Oracle', 'oracle: driver reported' );
	is( $r->{create},   1,        'oracle: CREATE allowed' );
	is( $r->{drop},     1,        'oracle: DROP allowed (owns the tables)' );
	is( $r->{index},    1,        'oracle: INDEX allowed (owns the tables)' );
	is( $r->{alter},    1,        'oracle: ALTER allowed (owns the tables)' );
	is( $r->{sequence}, 0,        'oracle: SEQUENCE denied' );
	is_deeply( $r->{missing}, ['SEQUENCE'], 'oracle: only SEQUENCE reported missing' );
}

# --- Oracle: both system privileges -----------------------------------------
{
	my $dbh = MockDBH->new(
		driver => 'Oracle',
		scol   => { 'USER_SYS_PRIVS' => [ 'CREATE TABLE', 'DROP ANY TABLE' ] }
	);
	my $r = probe($dbh);
	is( $r->{create}, 1, 'oracle full: CREATE allowed' );
	is( $r->{drop},   1, 'oracle full: DROP allowed' );
	is_deeply( $r->{missing}, ['SEQUENCE'], 'oracle full: only SEQUENCE reported missing' );
}

# --- a failing probe is caught: no die, error reported ----------------------
{
	my $dbh = MockDBH->new( driver => 'Pg', boom => 'catalog unavailable' );
	my $r;
	my $lived = eval { $r = probe($dbh); 1 };
	ok( $lived, 'a failing probe does not die' );
	is( $r->{checked}, 0, 'failing probe: marked unchecked' );
	like( $r->{error}, qr/catalog unavailable/, 'failing probe: error is reported' );
	is_deeply( $r->{missing}, [], 'failing probe: nothing reported as missing' );
}

done_testing();

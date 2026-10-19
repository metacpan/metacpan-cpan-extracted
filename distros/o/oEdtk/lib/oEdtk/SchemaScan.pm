package oEdtk::SchemaScan;

# Driver-neutral schema introspection, shared by tools/schema_snapshot.pl (the
# golden snapshots) and oEdtk::DBAdmin::schema_Detect (step S51a of the
# fork-integration plan, decision D16).
#
# This module loads no oEdtk code on purpose: the snapshot tool must stay free of
# the oEdtk banner that oEdtk.pm prints at load time (it would corrupt the JSON it
# writes). It returns a plain data structure -- per table, the ordered columns
# (name, declared type and size, nullability, default, position, key rank) and the
# secondary indexes. Pure ASCII.

use strict;
use warnings;

use Exporter 'import';
our @EXPORT_OK = qw( scan_schema driver_of size_from_type );

our $VERSION = 2.1126;

# The driver name from a DSN, in the tool's vocabulary (undef when unsupported).
sub driver_of {
	my ($dsn) = @_;
	return 'Pg'     if $dsn =~ /^dbi:Pg:/i;
	return 'mysql'  if $dsn =~ /^dbi:mysql:/i;
	return 'SQLite' if $dsn =~ /^dbi:SQLite:/i;
	return;
}

# The driver name of a live handle, normalised to the same vocabulary.
sub _driver_of_dbh {
	my ($dbh) = @_;
	my $name = $dbh->{Driver}{Name} // '';
	return 'Pg'     if $name =~ /^pg$/i;
	return 'mysql'  if $name =~ /mysql/i;
	return 'SQLite' if $name =~ /sqlite/i;
	return $name;
}

# The declared size of a type such as "VARCHAR2(36)" or "varchar(36)"; undef when
# the type carries no length (INTEGER, CHAR, ...).
sub size_from_type {
	my ($type) = @_;
	my $size;
	$size = $1 if defined $type && $type =~ /\(\s*(\d+)/;
	return $size;
}

# ---------------------------------------------------------------------------
# Per-driver introspection: each returns { table => { columns => [...],
# indexes => [...] } }, columns ordered by position.
# ---------------------------------------------------------------------------
sub _scan_pg {
	my ($dbh) = @_;
	my %tables;

	my $cols = $dbh->prepare(
		"SELECT table_name, column_name, data_type, character_maximum_length,
                numeric_precision, is_nullable, column_default, ordinal_position
           FROM information_schema.columns
          WHERE table_schema NOT IN ('pg_catalog','information_schema')
          ORDER BY table_name, ordinal_position"
	);
	$cols->execute;
	while ( my $r = $cols->fetchrow_hashref ) {
		my $size = $r->{character_maximum_length};
		$size = $r->{numeric_precision} if !defined $size;
		push @{ $tables{ $r->{table_name} }{columns} },
			{
			name     => $r->{column_name},
			type     => $r->{data_type},
			size     => ( defined $size              ? 0 + $size : undef ),
			nullable => ( $r->{is_nullable} eq 'YES' ? 1         : 0 ),
			default  => $r->{column_default},
			pos      => 0 + $r->{ordinal_position},
			pk       => 0,
			};
	}

	my $pk = $dbh->prepare(
		"SELECT tc.table_name, kcu.column_name, kcu.ordinal_position
           FROM information_schema.table_constraints tc
           JOIN information_schema.key_column_usage kcu
             ON tc.constraint_name = kcu.constraint_name
            AND tc.table_schema = kcu.table_schema
          WHERE tc.constraint_type = 'PRIMARY KEY'"
	);
	$pk->execute;
	while ( my $r = $pk->fetchrow_hashref ) {
		my $t = $tables{ $r->{table_name} } or next;
		for my $c ( @{ $t->{columns} } ) {
			$c->{pk} = 0 + $r->{ordinal_position} if $c->{name} eq $r->{column_name};
		}
	}

	my $idx = $dbh->prepare(
		"SELECT t.relname AS table_name, i.relname AS index_name,
                ix.indisunique AS is_unique, ix.indisprimary AS is_primary,
                a.attname AS column_name, k.ord AS ord
           FROM pg_index ix
           JOIN pg_class i ON i.oid = ix.indexrelid
           JOIN pg_class t ON t.oid = ix.indrelid
           JOIN pg_namespace n ON n.oid = t.relnamespace
           JOIN LATERAL unnest(ix.indkey) WITH ORDINALITY AS k(attnum, ord) ON true
           JOIN pg_attribute a ON a.attrelid = t.oid AND a.attnum = k.attnum
          WHERE n.nspname NOT IN ('pg_catalog','information_schema')
            AND NOT ix.indisprimary
          ORDER BY t.relname, i.relname, k.ord"
	);
	$idx->execute;
	my %seen;
	while ( my $r = $idx->fetchrow_hashref ) {
		my $key = "$r->{table_name}\0$r->{index_name}";
		if ( !$seen{$key} ) {
			$seen{$key} = 1;
			push @{ $tables{ $r->{table_name} }{indexes} },
				{ name => $r->{index_name}, unique => 0 + $r->{is_unique}, columns => [] };
		}
		push @{ $tables{ $r->{table_name} }{indexes}[-1]{columns} }, $r->{column_name};
	}

	return \%tables;
}

sub _scan_mysql {
	my ($dbh) = @_;
	my %tables;

	my $cols = $dbh->prepare(
		"SELECT table_name, column_name, data_type, character_maximum_length,
                numeric_precision, is_nullable, column_default, ordinal_position
           FROM information_schema.columns
          WHERE table_schema = DATABASE()
          ORDER BY table_name, ordinal_position"
	);
	$cols->execute;
	while ( my $r = $cols->fetchrow_hashref ) {
		my $size = $r->{character_maximum_length};
		$size = $r->{numeric_precision} if !defined $size;
		push @{ $tables{ $r->{table_name} }{columns} },
			{
			name     => $r->{column_name},
			type     => $r->{data_type},
			size     => ( defined $size              ? 0 + $size : undef ),
			nullable => ( $r->{is_nullable} eq 'YES' ? 1         : 0 ),
			default  => $r->{column_default},
			pos      => 0 + $r->{ordinal_position},
			pk       => 0,
			};
	}

	my $stat = $dbh->prepare(
		"SELECT table_name, index_name, non_unique, column_name, seq_in_index
           FROM information_schema.statistics
          WHERE table_schema = DATABASE()
          ORDER BY table_name, index_name, seq_in_index"
	);
	$stat->execute;
	my %seen;
	while ( my $r = $stat->fetchrow_hashref ) {
		if ( $r->{index_name} eq 'PRIMARY' ) {
			my $t = $tables{ $r->{table_name} } or next;
			for my $c ( @{ $t->{columns} } ) {
				$c->{pk} = 0 + $r->{seq_in_index} if $c->{name} eq $r->{column_name};
			}
			next;
		}
		my $key = "$r->{table_name}\0$r->{index_name}";
		if ( !$seen{$key} ) {
			$seen{$key} = 1;
			push @{ $tables{ $r->{table_name} }{indexes} },
				{
				name    => $r->{index_name},
				unique  => ( $r->{non_unique} ? 0 : 1 ),
				columns => [],
				};
		}
		push @{ $tables{ $r->{table_name} }{indexes}[-1]{columns} }, $r->{column_name};
	}

	return \%tables;
}

sub _scan_sqlite {
	my ($dbh) = @_;
	my %tables;

	my @names = map { $_->[0] } @{
		$dbh->selectall_arrayref(
"SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%' ORDER BY name"
		)
	};

	for my $tbl (@names) {
		my $ti = $dbh->selectall_arrayref("PRAGMA table_info('$tbl')");
		my @cols;
		for my $c (@$ti) {
			my ( $cid, $name, $type, $notnull, $dflt, $pk ) = @$c;
			push @cols,
				{
				name     => $name,
				type     => $type,
				size     => size_from_type($type),
				nullable => ( $notnull ? 0 : 1 ),
				default  => $dflt,
				pos      => 0 + $cid + 1,
				pk       => 0 + ( $pk // 0 ),
				};
		}
		$tables{$tbl}{columns} = \@cols;

		my @idxs;
		for my $ix ( @{ $dbh->selectall_arrayref("PRAGMA index_list('$tbl')") } ) {
			my ( $seq, $iname, $unique ) = @$ix;
			my @ic = map { $_->[2] } @{ $dbh->selectall_arrayref("PRAGMA index_info('$iname')") };
			push @idxs, { name => $iname, unique => ( $unique ? 1 : 0 ), columns => \@ic };
		}
		$tables{$tbl}{indexes} = \@idxs if @idxs;
	}

	return \%tables;
}

# Introspect a live handle. Returns { driver => ..., tables => { ... } }.
sub scan_schema {
	my ($dbh) = @_;
	my $driver = _driver_of_dbh($dbh);
	my $tables =
		  $driver eq 'Pg'     ? _scan_pg($dbh)
		: $driver eq 'mysql'  ? _scan_mysql($dbh)
		: $driver eq 'SQLite' ? _scan_sqlite($dbh)
		:                       die "scan_schema: unsupported driver '$driver'\n";
	return { driver => $driver, tables => $tables };
}

1;

=head1 NAME

oEdtk::SchemaScan - driver-neutral database schema introspection

=head1 SYNOPSIS

    use oEdtk::SchemaScan qw(scan_schema);

    my $schema = scan_schema($dbh);
    # { driver => 'Pg', tables => { 'T' => { columns => [...], indexes => [...] } } }

=head1 DESCRIPTION

Introspects a live database handle and returns a plain data structure: for each
table, the ordered columns (name, declared type and size, nullability, default,
position, key rank) and the secondary indexes. It supports PostgreSQL,
MySQL/MariaDB and SQLite. It loads no oEdtk code on purpose, so a snapshot tool
can use it without the load banner. It is shared by C<tools/schema_snapshot.pl>
and C<oEdtk::DBAdmin>'s schema detection.

=head1 FUNCTIONS

=head2 scan_schema

    my $schema = scan_schema($dbh);

Introspect C<$dbh> and return a hash reference with the C<driver> and C<tables>
keys. An unsupported driver is an error.

=head2 driver_of

    my $driver = driver_of($dsn);

Return the tool's driver name (C<Pg>, C<mysql> or C<SQLite>) for a DSN, or undef
when the DSN is not supported.

=head2 size_from_type

    my $size = size_from_type($type);

Return the declared length of a type such as C<VARCHAR2(36)>, or undef when the
type carries no length.

The per-driver scanners C<_scan_pg>, C<_scan_mysql> and C<_scan_sqlite>, and the
C<_driver_of_dbh> helper, are internal and are not part of the public API.

=head1 AUTHOR

The oEdtk team.

=cut

package oEdtk::DBAdmin;

use DBI;
use oEdtk::Config qw(config_read);
use oEdtk::logger qw(logger $LOGGERLEVEL $WARN2LOGGER);
use POSIX         qw(strftime);
use Scalar::Util  qw(looks_like_number);
use Digest::MD5   ();
use strict;
use Text::CSV;
use Encode qw(encode find_encoding);
use warnings;
use Data::Dumper qw(Dumper);

# check sql : https://www.eversql.com
# SHOW CREATE DATABASE oEdtk;

use Exporter;
our $VERSION     = 2.1120;
our $VERSION_TXT = $VERSION =~ s/\./_/gr;
our @ISA         = qw(Exporter);
our @EXPORT_OK   = qw(
	acheck_db_admin_on_connect
	acheck_db_admin
	agrege_idJob
	copy_table
	create_SCHEMA
	schema_Create
	schema_Upgrade
	schema_Detect
	schema_Report
	schema_Manifest
	schema_MigrationPlan
	schema_Historize
	schema_Revert
	schema_Additive
	schema_StaleWarning
	create_lot_sequence
	create_table_TRACKING
	create_table_OUTMNGR
	create_table_DISTRIB
	create_table_ACQUIT
	create_table_ACQMGENTECH
	create_table_SCHEMA_HISTORY
	create_table_ADMIN
	create_table_AGREGE
	create_table_DATAGROUPS
	create_table_FILIERES
	create_table_ID
	create_table_INDEX
	create_table_LOTS
	create_table_PARA
	create_table_REFIDDOC
	create_table_SUPPORTS
	csv_import
	db_backup_agent
	db_backup_available
	db_backup_pending
	db_backup_prepare
	db_reconcile_backup
	db_on_backup
	db_check_privileges
	db_invalidate_meta_cache
	db_connect
	db_drop_table
	get_columns_names
	historicize_table
	insert_tData
	schema_History_add
	move_table
	admin_optimize_db
	@INDEX_COLS
	@TRACKER_COLS
);

my $_LOCAL_EDTK_WAITRUN = 0;
my $CONNECT_COUNT       = 0;
our %_csv_import_type_cache;
my $_DB_ENGINE_CACHE;

# PostgreSQL bulk-load tuning (used by _load_csv_pg_copy / _pg_load_tx).
use constant PG_COPY_SYNC_OFF =>
	'SET LOCAL synchronous_commit = off';    # relax fsync for this transaction only
use constant PG_COPY_ANALYZE    => 'ANALYZE %s';    # refresh planner stats after a bulk load
use constant PG_COPY_BLOCK_SIZE => 1 << 20;         # bytes fed per pg_putcopydata call

# Positions in the acknowledgement (ACQUIT) file, the fork's format (D-S53).
# _acquit_table_INDEX and _acquit_API read these fields; together they locate the
# indexed items whose mailing-out date and status the acknowledgement stamps.
use constant ACQ_FIELD_LOT    => 2;     # mailing batch id (sub-batch)
use constant ACQ_FIELD_PLI    => 7;     # folded-item file name, "name_number"
use constant ACQ_FIELD_IDDEST => 11;    # recipient id in the management system
use constant ACQ_FIELD_DTLOT  => 25;    # batch reception date (its year prefix)
use constant ACQ_FIELD_EXPED  => 26;    # mailing-out date (DATEEXPED)
use constant ACQ_FIELD_STATUS => 29;    # acknowledgement status

sub move_table {
	&logger( 4,
		"method oEdtk::DBAdmin::move_table is deprecated you should use oEdtk::DBAdmin::copy_table"
	);

	copy_table(@_);
	1;
}

sub copy_table {
	my ( $dbh, $table_source, $table_cible, $create_option ) = @_;
	$create_option ||= "";

	# check if source is empty
	my $sql_check_source = "SELECT CASE WHEN COUNT(*) > 0 THEN 1 ELSE 0 END FROM " . $table_source;
	my $sth              = $dbh->prepare($sql_check_source);
	do { local $sth->{PrintError} = 0; $sth->execute() }
		or &logger( 3, "SQL execute failed " . $sth->err . "-" . $sth->errstr );
	my $result = $sth->fetchrow_array;
	unless ($result) {
		&logger( 4, "Source $table_source is empty, copy aborted" );
		return 1;
	}

	# preparing the data copy from source to target
	&logger( 4, "Data from $table_source will be copyed into $table_cible" );

	if ( $create_option =~ /-create/i ) {
		my $sql_create = "CREATE TABLE " . $table_cible . " AS SELECT * FROM " . $table_source;

		# on error, DIE so no other operation runs against the databases (db_backup_agent, ...)
		_db_do_log(
			$dbh,
			_sql_fixup( $dbh, $sql_create, 'casse' ),
			"ERROR: can't create $table_cible",
			fatal => 1
		);

	}
	else {
		my $sql_insert = "INSERT INTO  " . $table_cible . " SELECT * FROM " . $table_source;

		# on error, DIE so no other operation runs against the databases (db_backup_agent, ...)
		_db_do_log(
			$dbh,
			_sql_fixup( $dbh, $sql_insert, 'casse' ),
			"ERROR: can't insert into $table_cible",
			fatal => 1
		);
	}

	&logger( 4, "Insert DONE into $table_cible" );
	1;
}

sub _load_csv_mysql_infile {
	my ( $dbh, $tablename, $fi, $params ) = @_;

	# read the header line: it holds the field names and the insert order
	open( my $fh, '<', $fi ) or die "ERROR: Cannot open file \"$fi\": $!\n";
	my $fields = <$fh>;
	chomp($fields);
	$fields =~ s/\"+//g;
	close($fh);

	# https://www.perlmonks.org/?node_id=1058110  => insert data inline

	# https://docstore.mik.ua/orelly/linux/dbi/ch04_05.htm
	# https://metacpan.org/pod/DBI

# https://metacpan.org/pod/DBD::mysql
# http://samisd2003.free.fr/WinLAMP/MYSQL/load-data.html
# https://tecfa.unige.ch/guides/mysql/man/manuel_LOAD_DATA.html
# https://dev.mysql.com/doc/refman/8.0/en/load-data.html
# https://stackoverflow.com/questions/59993844/error-loading-local-data-is-disabled-this-must-be-enabled-on-both-the-client
# https://dzone.com/articles/mysql-57-utf8mb4-and-the-load-data-infile
# => mysql> set global local_infile=true; + in the DSN config ";mysql_local_infile=true"
# -1 - 1062-Duplicate entry

	my $sep       = $params->{'sep_char'};
	my $local_opt = $params->{'local_opt'} || "";
	if ( $local_opt !~ m/local/i ) {
		$local_opt = "";
	}
	else {
		$local_opt = "LOCAL";
	}

	$local_opt = $params->{'local_opt'} || "";
	my $sql =
		  "LOAD DATA $local_opt INFILE ? INTO TABLE $tablename CHARACTER SET latin1 "
		. " FIELDS TERMINATED BY '"
		. $sep
		. "' ENCLOSED BY '"
		. $params->{'quote_char'} . "' "
		. " LINES TERMINATED BY '" . '\n' . "'"
		. " IGNORE 1 LINES "
		. "($fields)";

	##  OPTIONALLY ENCLOSED BY '"'
	##  REPLACE

	&logger( 7, "_load_csv_mysql_local_infile trying : $sql" );

	my $count = _db_do_log( $dbh, $sql, "SQL execute failed", bind => [$fi] );

	if ( $count !~ m/^\d+$/ ) {    # or $count = "0E0") {
		return ( -1, &logger( 3, "$count-ERROR LOAD INFILE-$@ $!" . $dbh::errstr ) );
	}

	my $rows = _count_csv_rows( $fi, $params );
	&logger( 4, "bulk insert into $tablename via LOAD DATA INFILE: $rows rows" );
	return ( $count, " lines inserted" );
}

sub _load_csv_mysql_local_infile {
	my ( $dbh, $tablename, $fi, $params ) = @_;

	# read the header line: it holds the field names and the insert order
	open( my $fh, '<', $fi ) or die "ERROR: Cannot open file \"$fi\": $!\n";
	my $fields = <$fh>;
	chomp($fields);
	$fields =~ s/\"+//g;
	close($fh);

	my $sep = $params->{'sep_char'};
	my $sql =
		  "LOAD DATA LOCAL INFILE ? INTO TABLE $tablename CHARACTER SET latin1 "
		. " FIELDS TERMINATED BY '"
		. $sep
		. "' ENCLOSED BY '"
		. $params->{'quote_char'} . "' "
		. " LINES TERMINATED BY '" . '\n' . "'"
		. " IGNORE 1 LINES "
		. "($fields)";
	&logger( 7, $sql );

	##  OPTIONALLY ENCLOSED BY '"'
	##  REPLACE

	&logger( 7, "_load_csv_mysql_local_infile trying : $sql" );

	my $count = _db_do_log( $dbh, $sql, "SQL execute failed", bind => [$fi] );

	if ( $count !~ m/^\d+$/ ) {    # or $count = "0E0") {

		#		&logger (3, "$count-ERROR LOAD INFILE-$@ $!".$dbh::errstr);
		return ( -1, &logger( 3, "$count-ERROR LOAD INFILE-$@ $!" . ( $dbh::errstr || "" ) ) );
	}

	# Refresh the planner statistics after the bulk load (parity with the PG COPY path).
	eval { local $dbh->{PrintError} = 0; $dbh->do("analyze table $tablename"); 1 }
		or &logger( 7, "_load_csv_mysql_local_infile: analyze table $tablename failed: $@" );

	my $rows = _count_csv_rows( $fi, $params );
	&logger( 4, "bulk insert into $tablename via LOAD DATA LOCAL INFILE: $rows rows" );
	return ( $count, " lines inserted" );
}

# ============================================================
# PRIVATE : serialize one CSV field (RFC4180 style).
#   undef    => unquoted empty field => read as NULL by COPY (NULL '')
#   ''       => force-quoted ""      => read as empty string (clean_val parity)
#   otherwise=> quoted only when needed (sep, quote, CR or LF inside)
# ============================================================
sub _pg_csv_field {
	my ( $val, $sep, $quo ) = @_;
	return '' unless defined $val;
	return $val
		unless $val eq ''
		|| index( $val, $sep ) >= 0
		|| index( $val, $quo ) >= 0
		|| $val =~ /[\r\n]/;
	( my $esc = $val ) =~ s/\Q$quo\E/$quo$quo/g;
	return $quo . $esc . $quo;
}

# ============================================================
# PRIVATE : clean then serialize one CSV record for COPY. The per-column
# cleaning flags are passed positionally ($blank_to_null and $col_size,
# precomputed from the column metadata) so no hash lookup or closure runs per
# value ; the result matches the _make_clean_val contract (truncation, and
# '' => NULL for numeric/date columns). Fields are serialized with
# _pg_csv_field. Debug logs are guarded so their message is not built when the
# level is disabled.
# ============================================================
sub _pg_csv_row {
	my ( $data, $cols, $sep, $quo, $blank_to_null, $col_size ) = @_;
	my @out;
	for my $i ( 0 .. $#{$cols} ) {
		my $v = $data->[$i];
		if ( defined $v ) {
			if ( $v eq '' ) {
				if ( $blank_to_null->[$i] ) {
					&logger( 7, "clean_val: col '$cols->[$i]' numeric/date, '' => undef" )
						if $LOGGERLEVEL >= 7;
					$v = undef;
				}
			}
			elsif ( $col_size->[$i] && length($v) > $col_size->[$i] ) {
				&logger( 6,
						  "clean_val: col '$cols->[$i]' truncated from "
						. length($v)
						. " to $col_size->[$i] chars" )
					if $LOGGERLEVEL >= 6;
				$v = substr( $v, 0, $col_size->[$i] );
			}
		}
		push @out, _pg_csv_field( $v, $sep, $quo );
	}
	return join( $sep, @out );
}

# ============================================================
# PRIVATE : build the COPY ... FROM STDIN byte supplier for one CSV source.
# The returned coderef yields up to PG_COPY_BLOCK_SIZE bytes of cleaned,
# client_encoding-encoded CSV per call, or undef at end of stream, and dies on
# a CSV parse error (the message carries the line number). Rows are cleaned and
# serialized by _pg_csv_row; $$count_ref is incremented per data record (the
# header is skipped). A fresh supplier is built for each COPY attempt so the
# one retry path (a rare deferral failure) re-reads the source. Encode is
# concatenative, so encoding whole blocks is equivalent to encoding each row.
# ============================================================
sub _pg_csv_supplier {
	my ( $fi, $params, $cols, $blank_to_null, $col_size, $count_ref, $enc ) = @_;
	my $sep = $params->{'sep_char'};
	my $quo = $params->{'quote_char'};

	open( my $fh, '<', $fi ) or die "ERROR: Cannot open file \"$fi\": $!\n";
	my $csv = Text::CSV->new(
		{
			binary     => 1,
			sep_char   => $sep,
			quote_char => $quo
		}
	);
	unless ( $csv->getline($fh) ) {    # skip the header record
		close($fh);
		die "ERROR: cannot read header of \"$fi\"\n";
	}

	my $closed = 0;
	return sub {
		return if $closed;
		my $eof   = 0;
		my $bytes = 0;
		my @rows;

		# Collect whole rows and join() them once per block. Appending to a scalar
		# and resetting it every block is quadratic and dominated the load ; join()
		# allocates the whole block in a single pass.
		while ( $bytes < PG_COPY_BLOCK_SIZE ) {
			my $data = $csv->getline($fh);
			if ( !defined $data ) {
				unless ( $csv->eof ) {
					die "CSV parse error near line "
						. ( $$count_ref + 1 )
						. " in \"$fi\": "
						. ( $csv->error_diag // 'unknown' ) . "\n";
				}
				$eof = 1;
				last;
			}
			my $row = _pg_csv_row( $data, $cols, $sep, $quo, $blank_to_null, $col_size );
			push @rows, $row;
			$bytes += length($row) + 1;    # +1 for the newline added by join()
			$$count_ref++;
		}
		if ($eof) { $closed = 1; close($fh); }
		return unless @rows;
		my $chunk = join( "\n", @rows ) . "\n";
		$chunk = encode( $enc, $chunk ) if defined $enc;
		return $chunk;
	};
}

# Map a PostgreSQL client_encoding name to an Encode name.
# Text::CSV (binary=>1) returns decoded characters, so values must be
# re-encoded to the session client_encoding before COPY reads the bytes.
sub _pg_encoding_name {
	my ($pg) = @_;
	my $n = uc( $pg // '' );
	$n =~ s/[^A-Z0-9]//g;
	my %map = (
		UTF8    => 'UTF-8',
		UNICODE => 'UTF-8',
		LATIN1  => 'ISO-8859-1',
		LATIN2  => 'ISO-8859-2',
		LATIN3  => 'ISO-8859-3',
		LATIN4  => 'ISO-8859-4',
		LATIN5  => 'ISO-8859-9',
		LATIN6  => 'ISO-8859-10',
		LATIN7  => 'ISO-8859-13',
		LATIN8  => 'ISO-8859-14',
		LATIN9  => 'ISO-8859-15',
		LATIN10 => 'ISO-8859-16',
	);
	return $map{$n} if exists $map{$n};
	return "CP$1"   if $n =~ /^WIN(\d+)$/;
	return $n       if $n ne '' && defined find_encoding($n);
	return 'UTF-8';
}

# ============================================================
# PRIVATE : count the CSV data records (header excluded) so a bulk
# load can report how many rows it is about to inject. getline (not
# parse) is used so a quoted field may span several physical lines.
# Returns the number of data records, or -1 when the file is unreadable.
# ============================================================
sub _count_csv_rows {
	my ( $fi, $params ) = @_;
	open( my $fh, '<', $fi ) or return -1;
	my $csv = Text::CSV->new(
		{
			binary     => 1,
			sep_char   => $params->{'sep_char'}   // ',',
			quote_char => $params->{'quote_char'} // '"',
		}
	);
	$csv->getline($fh);    # skip the header record
	my $rows = 0;
	while (1) {
		my $data = $csv->getline($fh);
		last if !defined $data;
		$rows++;
	}
	close($fh);
	return $rows;
}

# ============================================================
# PRIVATE : run a COPY ... FROM STDIN, feeding it from $next_block -- a
# coderef that returns the next chunk of serialized bytes (undef at end of
# stream) and dies on a producer error (e.g. a CSV parse error). Feeding whole
# blocks instead of one line per call keeps the per-record overhead out of the
# COPY loop. The COPY is aborted best-effort on failure.
# Returns the error message, or undef on success.
# ============================================================
sub _pg_copy_stdin {
	my ( $dbh, $sql, $next_block ) = @_;
	my $emsg;
	my $copy_live = 0;
	eval {
		local $dbh->{PrintError} = 0;
		$dbh->do($sql);
		$copy_live = 1;
		while ( defined( my $chunk = $next_block->() ) ) {
			defined $dbh->pg_putcopydata($chunk)
				or die( $dbh->errstr || "pg_putcopydata failed" );
		}
		$copy_live = 0;    # pg_putcopyend always ends the COPY
		$dbh->pg_putcopyend();
		1;
	} or $emsg = $@;
	$emsg ||= ( $dbh->err ? $dbh->errstr : '' );
	if ($emsg) {
		eval { $dbh->pg_putcopyend() } if $copy_live;    # abort a live COPY
		return $emsg;
	}
	return;
}

# ============================================================
# PRIVATE : quote a PostgreSQL identifier ("" doubling).
# ============================================================
sub _pg_quote_ident {
	my ($name) = @_;
	( my $s = $name ) =~ s/"/""/g;
	return '"' . $s . '"';
}

# ============================================================
# PRIVATE : list the DDL a bulk COPY may drop up-front and rebuild
# afterwards, so every inserted row does not have to maintain it.
# Standalone secondary indexes and unique / foreign-key constraints are always
# returned ; the primary key is returned only when $defer_pk is true. Any index
# a foreign key depends on -- including a primary key referenced by an external
# foreign key -- is left untouched. Returns { drop => [sql...], create => [sql...] }.
# ============================================================
sub _pg_deferrable_ddl {
	my ( $dbh, $table, $defer_pk ) = @_;
	my ($oid) = $dbh->selectrow_array( "SELECT to_regclass(?)::oid", undef, $table );
	return { drop => [], create => [] } unless $oid;

	my ( @drop, @create );

	# Secondary indexes that back no constraint and are referenced by no FK.
	my $idx = $dbh->selectall_arrayref(
		"SELECT n.nspname, c.relname, pg_get_indexdef(i.indexrelid)"
			. " FROM pg_index i"
			. " JOIN pg_class c ON c.oid = i.indexrelid"
			. " JOIN pg_namespace n ON n.oid = c.relnamespace"
			. " WHERE i.indrelid = ? AND NOT i.indisprimary"
			. "   AND NOT EXISTS (SELECT 1 FROM pg_constraint k WHERE k.conindid = i.indexrelid)",
		undef, $oid
	);
	foreach my $r (@$idx) {
		my ( $nsp, $name, $def ) = @$r;
		push @drop,   "DROP INDEX " . _pg_quote_ident($nsp) . "." . _pg_quote_ident($name);
		push @create, $def;
	}

	# Unique and foreign-key constraints on this table -- plus the primary key
	# when $defer_pk is set -- except any whose index a foreign key depends on.
	my $cons = $dbh->selectall_arrayref(
		"SELECT c.conname, pg_get_constraintdef(c.oid) FROM pg_constraint c"
			. " WHERE c.conrelid = ? AND c.contype IN ('u','f'"
			. ( $defer_pk ? ",'p'" : "" ) . ")"
			. "   AND NOT (c.contype IN ('u','p') AND EXISTS (SELECT 1 FROM pg_constraint k"
			. "                                             WHERE k.conindid = c.conindid"
			. "                                               AND k.contype = 'f'))",
		undef, $oid
	);
	foreach my $r (@$cons) {
		my ( $cname, $cdef ) = @$r;
		my $cid = _pg_quote_ident($cname);
		push @drop,   "ALTER TABLE $table DROP CONSTRAINT $cid";
		push @create, "ALTER TABLE $table ADD CONSTRAINT $cid $cdef";
	}

	return { drop => \@drop, create => \@create };
}

# ============================================================
# PRIVATE : load into $tablename inside one transaction from $make_supplier
# (called once per attempt to obtain a fresh COPY byte supplier), optionally
# after dropping the deferrable DDL and relaxing synchronous_commit for that
# transaction only (SET LOCAL). Rebuilds the DDL and commits ; a failure rolls
# the data AND the DDL back. A caller-managed transaction (AutoCommit already
# off) is left open. Returns ('ok',''), ('defer',$err) when the DDL could not be
# dropped, or ('fail',$err) on any other error.
# ============================================================
sub _pg_load_tx {
	my ( $dbh, $tablename, $sql, $make_supplier, $ddl ) = @_;
	my $own   = $dbh->{AutoCommit} ? 1 : 0;
	my $phase = 'begin';
	my $ok    = eval {
		$dbh->begin_work if $own;
		eval { local $dbh->{PrintError} = 0; $dbh->do(PG_COPY_SYNC_OFF); 1 }
			or &logger( 4, "_pg_load_tx: SET LOCAL failed: $@" );
		$phase = 'defer';
		foreach my $s ( @{ $ddl->{drop} } ) {
			$dbh->do($s) or die( $dbh->errstr || "drop failed: $s" );
		}
		$phase = 'copy';
		my $err = _pg_copy_stdin( $dbh, $sql, $make_supplier->() );
		die $err if defined $err;
		$phase = 'rebuild';
		foreach my $s ( @{ $ddl->{create} } ) {
			$dbh->do($s) or die( $dbh->errstr || "create failed: $s" );
		}
		$dbh->commit if $own;
		1;
	};
	return ( 'ok', '' ) if $ok;

	my $err = $@ // '';
	eval { $dbh->rollback } if $own && !$dbh->{AutoCommit};
	$err =~ s/\s+\z//;
	return ( $phase eq 'defer' ? 'defer' : 'fail', $err );
}

# ============================================================
# PRIVATE : bulk load a CSV file into a PostgreSQL table with
# COPY ... FROM STDIN (native equivalent of LOAD DATA LOCAL INFILE).
# Rows are cleaned through the same _get_col_meta / _make_clean_val contract
# (truncation, '' => NULL for numeric/date) and streamed straight into COPY, so
# no temporary file is written. $norm_id comes from _norm_identifiers
# (PostgreSQL identifiers are lowercase).
# Returns ($count, " lines inserted") on success, (-1, "...") on failure.
# ============================================================
sub _load_csv_pg_copy {
	my ( $dbh, $tablename, $fi, $params, $norm_id ) = @_;

	my $sep = $params->{'sep_char'};
	my $quo = $params->{'quote_char'};

	# COPY reads the bytes in the session client_encoding; encode rows to
	# match what the row-by-row DBI path would send.
	my $enc = _pg_encoding_name( eval { $dbh->selectrow_array('SHOW client_encoding') } );
	&logger( 7, "_load_csv_pg_copy: client_encoding=" . ( $enc // 'raw' ) );

	# Read the header record for column names and insertion order.
	# getline (not parse) so a quoted field may span several physical lines.
	open( my $fh, '<', $fi )
		or return ( -1, &logger( 3, "_load_csv_pg_copy: cannot open \"$fi\": $!" ) );
	my $csv = Text::CSV->new(
		{
			binary     => 1,
			sep_char   => $sep,
			quote_char => $quo
		}
	);
	my $hdr = $csv->getline($fh);
	unless ($hdr) {
		close($fh);
		return ( -1, &logger( 3, "_load_csv_pg_copy: cannot read header of \"$fi\"" ) );
	}
	close($fh);
	my @cols = map { $norm_id->($_) } @$hdr;

	# Same column metadata as the row-by-row path, flattened into positional
	# arrays so the per-row loop does no hash lookup.
	my $col_meta      = _get_col_meta( $dbh, $tablename, $norm_id );
	my @blank_to_null = map { ( $col_meta->{$_} // {} )->{blank_to_null} ? 1 : 0 } @cols;
	my @col_size      = map { ( $col_meta->{$_} // {} )->{size} // 0 } @cols;

	# COPY ... FROM STDIN : NULL '' makes an unquoted empty field a NULL.
	my $sql =
		  "COPY $tablename ("
		. join( ',', @cols ) . ")"
		. " FROM STDIN WITH (FORMAT csv, DELIMITER '"
		. $sep . "',"
		. " QUOTE '"
		. $quo
		. "', NULL '')";
	&logger( 7, $sql );

	# $make_supplier returns a fresh byte supplier for each COPY attempt so the
	# single retry path re-reads the source ; $count is reset on every attempt.
	my $count         = 0;
	my $make_supplier = sub {
		$count = 0;
		_pg_csv_supplier( $fi, $params, \@cols, \@blank_to_null, \@col_size, \$count, $enc );
	};

	# Default path (pg_copy_optimize unset or true) : load inside one
	# transaction, dropping the target table's secondary indexes and unique /
	# foreign-key constraints (plus the primary key when pg_copy_defer_pk is
	# set) for the duration of the COPY, relaxing synchronous_commit for that
	# transaction only and refreshing the planner statistics at the end. If the
	# DDL cannot be dropped, the load is retried once without deferral. Passing
	# pg_copy_optimize => 0 keeps the historical plain COPY.
	my ( $status, $emsg ) = ( 'ok', '' );
	if ( $params->{'pg_copy_optimize'} // 1 ) {
		my $ddl = eval { _pg_deferrable_ddl( $dbh, $tablename, $params->{'pg_copy_defer_pk'} ) };
		&logger( 4, "_load_csv_pg_copy: deferral lookup failed: $@" ) unless $ddl;
		$ddl ||= { drop => [], create => [] };
		( $status, $emsg ) = _pg_load_tx( $dbh, $tablename, $sql, $make_supplier, $ddl );
		if ( $status eq 'defer' ) {
			&logger( 4, "_load_csv_pg_copy: deferral unavailable ($emsg), retrying without it" );
			( $status, $emsg ) =
				_pg_load_tx( $dbh, $tablename, $sql, $make_supplier, { drop => [], create => [] } );
		}
	}
	else {
		my $err = _pg_copy_stdin( $dbh, $sql, $make_supplier->() );
		( $status, $emsg ) = defined $err ? ( 'fail', $err ) : ( 'ok', '' );
	}

	if ( $status ne 'ok' ) {
		chomp( $emsg //= '' );
		return ( -1, &logger( 3, "_load_csv_pg_copy: COPY into $tablename failed: $emsg" ) );
	}

	# Refresh the planner statistics for the freshly loaded table (best effort).
	eval { local $dbh->{PrintError} = 0; $dbh->do( sprintf( PG_COPY_ANALYZE, $tablename ) ); 1 }
		or &logger( 4, "_load_csv_pg_copy: ANALYZE $tablename failed: $@" );

	&logger( 4, "bulk insert into $tablename via COPY ... FROM STDIN: $count rows" );
	return ( $count, " lines inserted" );
}

# ============================================================
# PRIVATE: normalize SQL identifiers
# according to the driver case (uc for MySQL/MariaDB, lc otherwise)
# ============================================================
sub _norm_identifiers {
	my ( $dbh, $table, $cols_ref ) = @_;

	my $driver   = lc( $dbh->{Driver}{Name} // '' );
	my $is_mysql = ( $driver =~ /mysql|mariadb/ ) ? 1 : 0;
	my $norm_id =
		$is_mysql
		? sub { my $s = $_[0]; $s =~ s/^\s+|\s+$//g; return uc($s) }
		: sub { my $s = $_[0]; $s =~ s/^\s+|\s+$//g; return lc($s) };

	# Normalize the table name, keeping the schema when present
	my $norm_table = join( '.', map { $norm_id->($_) } split( /\./, $table, 2 ) );

	# Normalize the columns (optional)
	my @norm_cols = map { $norm_id->($_) } @{ $cols_ref // [] };

	return ( $norm_id, $norm_table, @norm_cols );
}

# ============================================================
# PRIVATE: column metadata for one table
# Returns { col_name => { numeric => 1, size => N } }
# The keys are normalized through $norm_id (supplied by _norm_identifiers)
# $table must already be normalized by the caller
# ============================================================

sub _get_col_meta {
	my ( $dbh, $table, $norm_id ) = @_;

	# $norm_id is mandatory - always supplied by _norm_identifiers
	die "_get_col_meta: norm_id missing" unless defined $norm_id;

	my $driver    = lc( $dbh->{Driver}{Name} // '' );
	my $cache_key = lc($table) . "\0" . $driver;
	return $_csv_import_type_cache{$cache_key}
		if exists $_csv_import_type_cache{$cache_key};

	my %meta;
	eval {
		# $table is already normalized by the caller: split without re-normalizing
		my ( $schema, $table_name ) =
			$table =~ /^(\w+)\.(\w+)$/
			? ( $1, $2 )
			: ( undef, $table );

		my $sth = $dbh->column_info( undef, $schema, $table_name, undef );

		# Fallback for drivers that do not support column_info (e.g. SQLite)
		# Degraded mode: column names without type or size
		unless ( defined $sth ) {
			&logger( 5,
				"_get_col_meta: column_info unsupported for '$table_name', fallback SELECT" );
			my $sth2 = $dbh->prepare("SELECT * FROM $table WHERE 1=0");
			$sth2->execute();
			for my $col ( @{ $sth2->{NAME} } ) {
				my $norm_col = $norm_id->($col);
				$meta{$norm_col} = { numeric => 0, size => 0 };
				&logger( 7, "_get_col_meta (fallback): col=$norm_col" );
			}
			$_csv_import_type_cache{$cache_key} = \%meta;
			return;
		}

		my %num_codes = map { $_ => 1 } ( 2, 3, 4, 5, 6, 7, 8, -5, -6, -7 );
		my $found     = 0;
		while ( my $row = $sth->fetchrow_hashref ) {
			$found++;
			my $col  = $norm_id->( $row->{COLUMN_NAME} // '' );
			my $type = $row->{DATA_TYPE} // 0;
			my $name = lc( $row->{TYPE_NAME} // '' );
			my $size = $row->{COLUMN_SIZE} // 0;

			my $by_name = (
				$name =~ m{
                ^( int[248]? | integer | smallint | bigint
                 | serial | bigserial | smallserial
                 | numeric | decimal | number
                 | float[48]? | real | double(\s+precision)?
                 | money | tinyint | mediumint )$
            }xi
			) ? 1 : 0;
			my $is_num = ( $num_codes{$type} || $by_name ) ? 1 : 0;

			# COLUMN_SIZE is a usable character length for truncation only
			# for text types. For numeric, date, time, etc. types, column_info
			# (in particular DBD::Pg) returns the internal storage size (e.g.
			# date(4), like an int4), which wrongly truncates values (e.g. a
			# date "2026-07-09" cut down to "2026" before the insert).
			my $is_text = (
				$name =~ m{
                ^( varchar | character(\s+varying)? | char | bpchar | text )
            }xi
			) ? 1 : 0;

			# Types that need the '' => NULL conversion on insert: the
			# numeric ones (already covered by is_num) plus the date/time
			# types, for which PostgreSQL rejects an empty string
			# ('ERROR: invalid input syntax for type date: ""').
			my $is_datetime = (
				$name =~ m{
                ^( date | time | timestamp(tz)? | datetime )
            }xi
			) ? 1 : 0;
			my $blank_to_null = ( $is_num || $is_datetime ) ? 1 : 0;

			$meta{$col} = {
				numeric       => $is_num,
				blank_to_null => $blank_to_null,
				size          => ( $is_text ? $size : 0 ),
			};
			&logger( 7,
"_get_col_meta: col=$col TYPE=$name($size) is_num=$is_num is_text=$is_text blank_to_null=$blank_to_null"
			);
		}
		&logger( 5, "_get_col_meta: $found columns for '$table_name'" );
	};
	if ($@) {
		&logger( 3, "_get_col_meta: column_info failed for $table: $@" );
	}

	$_csv_import_type_cache{$cache_key} = \%meta;
	return \%meta;
}

# Drops the column-metadata cache used by csv_import (keyed by table + driver).
# Call it after a schema change (schema_Create / schema_Upgrade) so the next import
# re-reads the columns instead of reusing a stale description.
sub db_invalidate_meta_cache {
	%_csv_import_type_cache = ();
	return 1;
}

# ============================================================
# PRIVATE: clean one value according to the column metadata
# (numeric type, max size)
# ============================================================
sub _make_clean_val {
	my ($col_meta) = @_;
	return sub {
		my ( $col, $val ) = @_;
		return undef unless defined $val;    ## no critic (ProhibitExplicitReturnUndef)
		my $m = $col_meta->{$col} // {};

		if ( $val eq '' ) {
			if ( $m->{blank_to_null} ) {
				&logger( 7, "clean_val: col '$col' numeric/date, '' => undef" );
				return undef;    ## no critic (ProhibitExplicitReturnUndef)
			}
			return $val;
		}

		if ( $m->{size} && length($val) > $m->{size} ) {
			my $truncated = substr( $val, 0, $m->{size} );
			&logger( 6,
				"clean_val: col '$col' truncated from " . length($val) . " to $m->{size} chars" );
			return $truncated;
		}

		return $val;
	};
}

sub insert_tData {

	# Example call:
	#   my $ret = insert_tData(
	#       dbh   => $dbh,
	#       table => $cfg->{'EDTK_DBI_TRACKING'},
	#       tCols => \@cols,
	#       tData => \@tData
	#   );
	my (%p) = @_;

	my ( $norm_id, $norm_table, @norm_cols ) =
		_norm_identifiers( $p{'dbh'}, $p{'table'}, $p{'tCols'} );

	my $col_meta  = _get_col_meta( $p{'dbh'}, $norm_table, $norm_id );
	my $clean_val = _make_clean_val($col_meta);

	&logger( 7, "Table : $norm_table" );
	&logger( 7, "NB Data : " . scalar @{ $p{'tData'} } );
	&logger( 7, "Data : " . Dumper( $p{'tData'} ) );

	my $sql =
		  "INSERT INTO "
		. $norm_table . " ("
		. join( ',', @norm_cols ) . ")"
		. " VALUES ("
		. join( ',', ('?') x @norm_cols ) . ")";
	&logger( 7, $sql );

	my $sth = $p{'dbh'}->prepare_cached($sql);
	do {
		local $sth->{PrintError} = 0;
		$sth->execute( map { $clean_val->( $norm_cols[$_], $p{'tData'}[$_] ) } 0 .. $#norm_cols );
		}
		or &logger( 3, "SQL execute failed " . $sth->err . "-" . $sth->errstr );
	1;
}

# ============================================================
# PUBLIC: import a CSV file into a table
# API unchanged
# ============================================================
sub csv_import {
	my ( $dbh, $table, $in, $params ) = @_;
	$params->{'mode'}         = $params->{'mode'}         || "insert";
	$params->{'sep_char'}     = $params->{'sep_char'}     || ',';
	$params->{'quote_char'}   = $params->{'quote_char'}   || '"';
	$params->{'local_infile'} = $params->{'local_infile'} || "no";
	$params->{'ref_col'}      = $params->{'ref_col'}      || 0;         # merge match column (D-S53)

	# Normalize the driver and the table name
	# $norm_id is kept to normalize the CSV columns after reading the header
	my ( $norm_id, $norm_table ) = _norm_identifiers( $dbh, $table );

	if (   $params->{'local_infile'} =~ /try/i
		&& $params->{'mode'} !~ /merge/i
		&& $dbh->{'Name'}    =~ m/mysql_local_infile\=true/i )
	{
		&logger( 7,
			"'mysql_local_infile=true' detected in DSN by csv_import, trying local infile" );
		return _load_csv_mysql_local_infile( $dbh, $norm_table, $in, $params );
	}

	# PostgreSQL: COPY ... FROM STDIN is the native equivalent of LOAD DATA LOCAL INFILE.
	# Enabled automatically for the Pg driver (merge mode keeps the row-by-row path).
	if ( $params->{'mode'} !~ /merge/i
		&& _db_check_driver_name($dbh) eq "PostgreSQL" )
	{
		&logger( 7, "PostgreSQL driver detected by csv_import, trying COPY FROM STDIN" );
		return _load_csv_pg_copy( $dbh, $norm_table, $in, $params, $norm_id );
	}

	open( my $fh, '<', $in ) or die "ERROR: Cannot open index file \"$in\": $!\n";
	my $csv = Text::CSV->new(
		{
			binary     => 1,
			sep_char   => $params->{'sep_char'},
			quote_char => $params->{'quote_char'}
		}
	);

	my ( $line, $lines_inserted, $rv );
	if ( defined $params->{'header'} ) {
		$line = $params->{'header'};
	}
	else {
		$line = <$fh>;
	}
	$csv->parse($line);

	# The CSV columns are normalized through $norm_id after reading the header,
	# since they are only known at that point (unlike insert_tData)
	my @cols = map { $norm_id->($_) } $csv->fields();

	if ( defined $params->{'ignore_first_line'} ) {
		$line = <$fh>;
	}

	# $norm_table and $norm_id are consistent: the %$col_meta keys
	# are in the same case as @cols
	my $col_meta  = _get_col_meta( $dbh, $norm_table, $norm_id );
	my $clean_val = _make_clean_val($col_meta);

	# The merge looks up the existing row on the column named by ref_col (D-S53;
	# the fork hard-coded the first column). The default 0 keeps M's behaviour.
	my $refcol = $params->{'ref_col'};

	while (<$fh>) {
		$lines_inserted++;
		$csv->parse($_);
		my @data = $csv->fields();
		my ( $sql, $sth, $seqlot );

		if ( $params->{'mode'} =~ /merge/i ) {
			$sql =
				  "SELECT "
				. $cols[$refcol]
				. " FROM "
				. $norm_table
				. " WHERE "
				. $cols[$refcol] . " = ?";
			&logger( 8, "Select from $norm_table : $sql" );
			$sth = $dbh->prepare_cached($sql);
			do {
				local $sth->{PrintError} = 0;
				$sth->execute( $clean_val->( $cols[$refcol], $data[$refcol] ) );
				}
				or &logger( 3, "SQL execute failed " . $sth->err . "-" . $sth->errstr );
			$seqlot = $sth->fetchrow_hashref();

			# fetchrow_hashref returns keys in the driver's native case:
			# normalize so the comparison with the match column is reliable
			if ( defined $seqlot ) {
				$seqlot = { map { $norm_id->($_) => $seqlot->{$_} } keys %$seqlot };
			}
		}

		if ( defined $seqlot && defined $seqlot->{ $cols[$refcol] } ) {
			$sql =
				  "UPDATE "
				. $norm_table . " SET "
				. join( '=?, ', @cols ) . "=? "
				. " WHERE "
				. $cols[$refcol] . " = ?";
			&logger( 8, "Update $norm_table : $sql" );
			$sth = $dbh->prepare_cached($sql);
			do {
				local $sth->{PrintError} = 0;
				$sth->execute( ( map { $clean_val->( $cols[$_], $data[$_] ) } 0 .. $#cols ),
					$clean_val->( $cols[$refcol], $data[$refcol] ) );
				}
				or &logger( 3, "SQL execute failed " . $sth->err . "-" . $sth->errstr );
		}
		else {
			$sql =
				  "INSERT INTO "
				. $norm_table . " ("
				. join( ',', @cols ) . ")"
				. " VALUES ("
				. join( ',', ('?') x @cols ) . ")";
			&logger( 7, "Insert into $norm_table : $sql" );
			$sth = $dbh->prepare_cached($sql);
			do {
				local $sth->{PrintError} = 0;
				$sth->execute( map { $clean_val->( $cols[$_], $data[$_] ) } 0 .. $#cols );
				}
				or &logger( 3, "SQL execute failed " . $sth->err . "-" . $sth->errstr );
		}

		# Acquittal (D-S53): the acknowledgement file also stamps the mailing-out
		# date on the indexed items and, when configured, hands the document to
		# the API callable (EDTK_ACQUIT_API). A malformed date, an absent
		# callable or a driver that cannot run the lookup is a log line, never
		# fatal (the fork croaked on a malformed date).
		if ( $params->{'timestamp'} ) {
			my $exped = $data[ACQ_FIELD_EXPED];
			if ( defined $exped && $exped ne '' ) {
				if ( $exped !~ /^20[0-9]+$/ ) {
					&logger( 3, "csv_import: acknowledgement date '$exped' is not a valid date" );
				}
				else {
					my $acfg = eval { config_read( 'EDTK_DB', 'SERVICES' ) };
					if ( ref $acfg eq 'HASH' ) {
						my $idx = $acfg->{'EDTK_DBI_OUTMNGR'};
						_acquit_table_INDEX( $dbh, \@data, $idx ) if defined $idx && length $idx;
						_acquit_API( $dbh, \@data, $acfg );
					}
				}
			}
		}

		if ( $sth->err && ( $sth->err > 0 || $sth->err =~ m/0E/ ) ) {
			$rv = $sth->err . "-" . $sth->errstr;
		}
	}

	close($fh);
	if ($rv) {
		&logger( -1, $rv );
		return ( -1, " - $rv" );
	}
	else {
		$lines_inserted //= 0;
		&logger( 5, "$lines_inserted lines inserted from $in" );
		return ( $lines_inserted, " lines inserted" );
	}
}

###### ORACLE VERSION OF THE MERGE, DIFFERENT FROM THE POSTGRESQL ONE
#MERGE INTO table_name USING table_reference ON (condition)
#  WHEN MATCHED THEN
#  UPDATE SET column1 = value1 [, column2 = value2 ...]
#  WHEN NOT MATCHED THEN
#  INSERT (column1 [, column2 ...]) VALUES (value1 [, value2 ...

#MERGE INTO Table1 T1
#  USING (SELECT Id, Meschamps FROM Table2) T2
#    ON ( T1.Id = T2.Id ) -- Join condition
#WHEN MATCHED THEN -- If true
#  UPDATE SET T1.Meschamps = T2.Meschamps
#WHEN NOT MATCHED THEN -- If false
#  INSERT (T1.ID, T1.MesChamps) VALUES ( T2.ID, T2.MesChamps);

###### VERSION POSTGRESQL
#MERGE INTO table [[AS] alias]
#USING [table-ref | query]
#ON join-condition
#[WHEN MATCHED [AND condition] THEN MergeUpdate | DELETE | DO NOTHING | RAISE ERROR]
#[WHEN NOT MATCHED [AND condition] THEN MergeInsert | DO NOTHING | RAISE ERROR]
#MergeUpdate is
#
#UPDATE SET { column = { expression | DEFAULT } |
#( column [, ...] ) = ( { expression | DEFAULT } [, ...] ) }
#[, ...]
#(yes, there is no WHERE clause here)
#MergeInsert is
#INSERT [ ( column [, ...] ) ]
#{ DEFAULT VALUES | VALUES ( { expression | DEFAULT } [, ...] )
#[, ...]}

sub _db_connect1 {
	my ( $cfg, $dsnvar, $dbargs ) = @_;
	my $dbh;
	my $dsn = $cfg->{$dsnvar};
	$_LOCAL_EDTK_WAITRUN = $cfg->{EDTK_WAITRUN};

	&logger( 5, "Connecting to DSN $dsn, $dsnvar" );

	# TODO review attribute handling for displaying error messages:
	# https://docstore.mik.ua/orelly/linux/dbi/ch04_05.htm

	# connection handled in a timed loop: 3 attempts with an increasing pause
	for ( my $i = 0 ; $i < 3 ; $i++ ) {
		sleep( $_LOCAL_EDTK_WAITRUN * $i );
		eval {
			$dbh = DBI->connect( $dsn, $cfg->{"${dsnvar}_USER"}, $cfg->{"${dsnvar}_PASS"}, $dbargs )
				;    ## xxxx
		};

		if ($@) {

			# on a connection failure, try again
			&logger( 4, "DBI connection missmatch to $dsnvar, we try 3 times" );
			&logger( 4, "Error message was : $@" );

		}
		else {
			# if it looks fine, we are done

			if (
					$CONNECT_COUNT == 1
				and $dsnvar ne "EDTK_DBI_PARAM"

				#and ($cfg->{EDTK_DB_CHECK_AUTO}||"YES")!~/NO/i
				#and (defined $cfg->{EDTK_DB_CHECK_AUTO} && $cfg->{EDTK_DB_CHECK_AUTO} =~/YES/i)
				and ( $cfg->{EDTK_DB_CHECK_AUTO} =~ /YES/i )
				and looks_like_number( $cfg->{EDTK_DB_MAX_DAYS_KEPT} )
				and looks_like_number( $cfg->{EDTK_DB_MAX_DAYS_KEPT_STATS} )
				and looks_like_number( $cfg->{EDTK_DB_MAX_DAYS_TRACKED} )
				)
			{
				my ( $level, $return ) = acheck_db_admin_on_connect( $dbh, $cfg );
				&logger( $level, "$return-$dsn" );
			}
			$CONNECT_COUNT++;

			$i = 4;
		}
	}
	return $dbh;
}

sub db_connect {
	my ( $cfg, $dsnvar, $dbargs ) = @_;

	#	$dbargs->{'RaiseError'} = 1;

	# Turning tracking off in a Test environment (D-S53) opens no handle at all:
	# callers receive undef and skip their database work. This is the fork's test
	# (EDTK_TYPE_ENV = Test and EDTK_TRACK_MODE = NONE).
	return
		if ( ( $cfg->{'EDTK_TYPE_ENV'} // '' ) eq 'Test'
		&& ( uc( $cfg->{'EDTK_TRACK_MODE'} // '' ) eq 'NONE' ) );

	# This avoids problems with PostgreSQL where in some cases, the column
	# names are lowercase instead of uppercase, defaukt set as uc.
	$dbargs->{'FetchHashKeyName'} = $cfg->{EDTK_DB_FetchHashKeyName} || 'NAME_uc';

	#$dbh = DBI->connect($dsn, $user, $password,
	#                    { RaiseError => 1, AutoCommit => 0 });

	# Connect to the database.
	my $dbh = _db_connect1( $cfg, $dsnvar, $dbargs );

	# If we could not connect to the database server, try
	# to connect to the backup database server if there is one.
	if ( !defined $dbh ) {
		if ( defined $cfg->{"${dsnvar}_BAK"} )
		{    # TODO the setting should be added in the backup database (procedure that creates it)
			&logger( 4,
				"Could not connect to main database server: " . ( $DBI::errstr || "not defined" ) );
			$dbh = _db_connect1( $cfg, "${dsnvar}_BAK", $dbargs );

			if ( !defined $dbh ) {
				die "ERROR: Could not connect to backup database server : "
					. ( $DBI::errstr || "not defined" ) . "\n";
			}

			# Store-and-forward: flag that we are writing on the backup buffer and
			# make sure it can hold the event tables. db_reconcile_backup will copy
			# the accumulated rows back once the main server is reachable again.
			$dbh->{'private_oEdtk_on_backup'} = 1;
			&logger( 3,
"Writing to the BACKUP database (main unreachable): data is buffered and will be repatriated."
			);
			eval { db_backup_prepare($dbh); };
		}
		else {
			die "ERROR: Could not connect to database server : "
				. ( $DBI::errstr || "not defined" ) . "\n";
		}
	}

	if ( _table_exists( $dbh, $cfg->{'EDTK_DBI_TRACKING'} ) ) {

		# silent soft check
	}
	else {
		create_table_TRACKING( $dbh, $cfg->{'EDTK_DBI_TRACKING'}, $cfg->{'EDTK_MAX_USER_KEY'} );
	}

	return $dbh;
}

# Run a DML statement, routing any driver error through the logger (see the
# &logger calls below) rather than letting DBI's PrintError dump the raw message
# to STDERR. Returns do()'s result (truthy even for 0 rows, "0E0", as DBI does)
# or undef on failure. Never dies: pass fatal => 1 to log then re-raise (so $@
# carries the message); pass bind => [..] for placeholder arguments.
sub _db_do_log {
	my ( $dbh, $sql, $msg, %opt ) = @_;
	my $res = do {
		local $dbh->{PrintError} = 0;
		local $dbh->{RaiseError} = 0;
		eval { $dbh->do( $sql, undef, @{ $opt{bind} // [] } ) };
	};
	return $res if defined $res;
	my $full = $msg . ": " . ( $dbh->errstr // $@ // 'unknown error' );
	die &logger( -1, $full ) if $opt{fatal};
	&logger( 3, $full );
	return;
}

sub _table_exists {
	my ( $dbh, $table_name ) = @_;

	# universal soft and silent check

	# table_info takes 4 arguments: catalog, schema, table, type
	# Pass undef for the global filters and target the table name
	my $sth = $dbh->table_info( undef, undef, $table_name, 'TABLE' );

	# If fetchrow_array returns a row, the table exists
	my @info = $sth->fetchrow_array();

	return @info ? 1 : 0;
}

# Job on request
sub acheck_db_admin2 {
	my (%p) = @_;
	my $date = strftime( "%Y-%m-%d", localtime );

	my $dbh = db_connect( $p{CFG}, 'EDTK_DBI_DSN' );
	eval { schema_StaleWarning( $dbh, cfg => $p{CFG} ); };
	my ($last) =
		$dbh->selectrow_array( 'select 1 from edtk_admin where ed_action_date = ?', undef, $date );
	$dbh->disconnect;
	return if $last;

	_db_with_lock(
		CFG  => $p{CFG},
		code => sub {
			my $dbh = shift;
			_db_maintenance( DBH => $dbh, CFG => $p{CFG}, rotate => 1, purge => 1 );
		}
	);
}

sub acheck_db_admin {

	# EXAMPLE CALL:
	# acheck_db_admin (CFG => $cfg);
	# in Auto mode, a single daily run is performed
	my %p = @_;

	#	print $p{TEST} . " for TEST\n";
	#	print $p{maxTime} . " for maxTime\n";
	#	print $p{tableau} . " for array\n";
	#	print $p{tableau}[2] . " for array[2]\n";

	#	my $time =time;
	my $date = strftime "%Y-%m-%d", localtime;
	my ( $sth, $sql );
	&logger( 4, "ACHECK lookup" );

	# LOOK FOR THE LAST ACTION ON THE ADMIN TABLE
	$sql =
"select ed_action_date, ed_action_pid, ed_action_status, ed_action_duration, ed_oedtk_release from edtk_admin "
		. " where ed_action_date = '"
		. $date
		. "'  ";    #order by ed_action_date desc limit 1";
	&logger( 7, $sql );

	$p{DBH} = db_connect( $p{CFG}, 'EDTK_DBI_DSN' );
	eval { schema_StaleWarning( $p{DBH}, cfg => $p{CFG} ); };
	$sth = $p{DBH}->prepare($sql) or return ( 3, $p{DBH}->errstr );
	do { local $sth->{PrintError} = 0; $sth->execute() }
		or &logger( 3, "SQL execute failed " . $sth->err . "-" . $sth->errstr );

	# HAS AN ADMINISTRATION ACTION ALREADY BEEN DONE TODAY ?
	my @tValues = $p{DBH}->selectrow_array( $sql, undef )
		;           # or warn ("ERROR: in acheck_db_admin_on_connect, message is " . $dbh->errstr);
	my $rc = $sth->finish;
	$p{DBH}->disconnect;

	if ( $tValues[0] and $date eq $tValues[0] ) {
		&logger(
			5,
			(
					  "Previously done, ACHECK Last EDTK_DB_MAX_DAYS check : "
					. $tValues[0] . " PID "
					. $tValues[1]
			)
		);
		return ( 5,
			( "ACHECK Last EDTK_DB_MAX_DAYS check : " . $tValues[0] . " PID " . $tValues[1] ) );
	}

	return _acheck_request_for_db( CFG => $p{CFG} );
}

sub _acheck_request_for_db {

	# example call
	# _acheck_request_for_db (CFG => $cfg, DBH => $dbh);
	my %p = @_;

	my $time = time;
	my $date = strftime "%Y-%m-%d", localtime;
	my $pid  = $$;
	my ( $rc, $sth, $sql, $insert, $reportActions );

	# REQUEST A TICKET TO CARRY OUT THE ACTIONS
	$insert =
'insert into edtk_admin (ed_action_date, ed_action_pid, ed_action_status, ed_oedtk_release) '
		. ' values (?, ?, ?, ?) ';
	$p{DBH} = db_connect( $p{CFG}, 'EDTK_DBI_DSN' );
	$sth = $p{DBH}->prepare_cached($insert);

	eval {
		do { local $sth->{PrintError} = 0; $sth->execute( $date, $pid, "START", $VERSION ) }
			or &logger( 3, "SQL execute failed " . $sth->err . "-" . $sth->errstr );
	};
	if ($@) {
		&logger( 3, "ERROR: $@ into $insert" );
	}

	# CHECK THAT WE HOLD THE LOCK FOR THE ACTION
	# LOOK FOR THE LAST ACTION ON THE ADMIN TABLE
	$sql =
"select ed_action_date, ed_action_pid, ed_action_status, ed_action_duration, ed_oedtk_release from edtk_admin "
		. " where ed_action_date = '"
		. $date
		. "'  ";    #order by ed_action_date desc limit 1";
	&logger( 7, $sql );

	$sth = $p{DBH}->prepare($sql);
	do { local $sth->{PrintError} = 0; $sth->execute() }
		or &logger( 3, "SQL execute failed " . $sth->err . "-" . $sth->errstr );
	my @tValues = do { local $p{DBH}->{PrintError} = 0; $p{DBH}->selectrow_array( $sql, undef ) }
		or &logger( 3, "ERROR: in acheck_db_admin_on_connect, message is " . $p{DBH}->errstr );
	$reportActions = "ACHECK Check 1 : " . $tValues[0] . " PID " . $tValues[1];
	$rc            = $sth->finish;
	$p{DBH}->disconnect;

	if ( $date eq $tValues[0] and $pid eq $tValues[1] ) {
		&logger( 5, $reportActions );
		$reportActions .= _acheck_db_rotate( CFG => $p{CFG} );
		$reportActions .= _acheck_db_purges( CFG => $p{CFG} );

	}
	else {
		# another process took the action, giving up
		&logger( 6, "failed, process locked" );
		return ( 5, $reportActions );
	}

	# End of the run
	$time = time - $time;
	$sql =
'update edtk_admin set ed_action_status = ?, ed_action_duration = ? where ed_action_date = ?';
	&logger( 7, $sql );

	$p{DBH} = db_connect( $p{CFG}, 'EDTK_DBI_DSN' );
	_db_do_log(
		$p{DBH}, $sql,
		"ERROR: can't update ED_ACTION_STATUS",
		bind => [ "DONE", $time, $date ]
	);

	$rc = $sth->finish;
	$p{DBH}->disconnect;
	return ( 4, $reportActions );
}

sub _acheck_db_purges {
	my %p = @_;

	#	my $time =time;
	#	my $date =strftime "%Y-%m-%d", localtime;
	#	my $day  =strftime "%d", localtime;
	my ( $sql, $insert, $result, $reportActions );

	#	my $DAYS_KEPT_time			= time - (86400*$p{CFG}->{EDTK_DB_MAX_DAYS_KEPT});
	my $DAYS_TRACKED_time    = time - ( 86400 * $p{CFG}->{EDTK_DB_MAX_DAYS_TRACKED} );
	my $DAYS_KEPT_STATS_time = time - ( 86400 * $p{CFG}->{EDTK_DB_MAX_DAYS_KEPT_STATS} );
	my $DAYS_AGREGED_time    = time -
		( 86400 * ( $p{CFG}->{EDTK_DB_MAX_DAYS_AGREGED} || $p{CFG}->{EDTK_DB_MAX_DAYS_TRACKED} ) );

	### STATS PURGES ###
	# PURGE FROM OEDTK_ADMIN
	$sql = "delete from edtk_admin where ed_action_date < '"
		. ( strftime "%Y-%m-%d", localtime($DAYS_TRACKED_time) ) . "'";
	&logger( 7, $sql );

	$p{DBH} = db_connect( $p{CFG}, 'EDTK_DBI_DSN' );
	$result = _db_do_log( $p{DBH}, $sql, "ERROR: can't update edtk_admin" ) or return;
	$p{DBH}->disconnect;
	&logger( 6, "RESULT = " . ( $result || 0 ) . " for $sql" );
	$reportActions = "ACHECK PURGE edtk_admin=" . ( $result || 0 );

	# PURGE FROM EDTK_DBI_TRACKING
	$sql =
		  "delete from "
		. $p{CFG}->{'EDTK_DBI_TRACKING'}
		. " where ed_tstamp < '"
		. ( strftime "%Y%m%d", localtime($DAYS_TRACKED_time) )
		. "000000'";
	&logger( 7, $sql );

	$p{DBH} = db_connect( $p{CFG}, 'EDTK_DBI_DSN' );
	$result = _db_do_log( $p{DBH}, $sql, "ERROR: can't update " . $p{CFG}->{'EDTK_DBI_TRACKING'} )
		or return;
	$p{DBH}->disconnect;
	&logger( 6, "RESULT = " . ( $result || 0 ) . " for $sql" );
	$reportActions .= "-PURGE TRACKING=" . ( $result || 0 );

	# PURGE FROM EDTK_DBI_DISTRIB_STATS
	$sql =
		  "delete from "
		. $p{CFG}->{'EDTK_DBI_DISTRIB_STATS'}
		. " where ed_dtlot < '"
		. ( strftime "%Y-%m-%d", localtime($DAYS_KEPT_STATS_time) )
		. "'";    # note: NOT REGEXP_LIKE (ED_DTLOT, '\d\d\d\d-\d\d-\d\d') does not work on MySQL...
	&logger( 7, $sql );

	$p{DBH} = db_connect( $p{CFG}, 'EDTK_DBI_DSN' );
	$result =
		_db_do_log( $p{DBH}, $sql, "ERROR: can't update " . $p{CFG}->{'EDTK_DBI_DISTRIB_STATS'} )
		or return;
	$p{DBH}->disconnect;
	&logger( 6, "RESULT = " . ( $result || 0 ) . " for $sql" );
	$reportActions .= "-PURGE DISTRIB_S=" . ( $result || 0 );

	# PURGE FROM OUTMNGR_STATS
	$sql =
		  "delete from "
		. $p{CFG}->{'EDTK_DBI_OUTMNGR_STATS'}
		. " where ed_dtlot < '"
		. ( strftime "%Y-%m-%d", localtime($DAYS_KEPT_STATS_time) ) . "'";
	&logger( 7, $sql );

	$p{DBH} = db_connect( $p{CFG}, 'EDTK_DBI_DSN' );
	$result =
		_db_do_log( $p{DBH}, $sql, "ERROR: can't update " . $p{CFG}->{'EDTK_DBI_OUTMNGR_STATS'} )
		or return;
	$p{DBH}->disconnect;
	&logger( 6, "RESULT = " . ( $result || 0 ) . " for $sql" );
	$reportActions .= "-PURGE OUTMNGR_S=" . ( $result || 0 );

	# PURGE FROM EDTK_AGREGE
	$sql =
		  "delete from edtk_agrege "
		. " where ed_dtlot < '"
		. ( strftime "%Y-%m-%d", localtime($DAYS_AGREGED_time) ) . "'";
	&logger( 7, $sql );

	$p{DBH} = db_connect( $p{CFG}, 'EDTK_DBI_DSN' );
	$result = _db_do_log( $p{DBH}, $sql, "ERROR: can't update EDTK_AGREGE" ) or return;
	$p{DBH}->disconnect;
	&logger( 6, "RESULT = " . ( $result || 0 ) . " for $sql" );
	$reportActions .= "-PURGE AGREGE=" . ( $result || 0 );

	### EDTK_ID ###
	# PURGE FROM EDTK_ID
	$sql =
		  "delete from edtk_id"
		. " where ed_id_date < '"
		. ( strftime "%Y-%m-%d", localtime($DAYS_TRACKED_time) ) . "'";
	&logger( 7, $sql );

	$p{DBH} = db_connect( $p{CFG}, 'EDTK_DBI_DSN' );
	$result =
		_db_do_log( $p{DBH}, $sql, "ERROR: can't update " . $p{CFG}->{'EDTK_DBI_OUTMNGR_STATS'} );
	$p{DBH}->disconnect;
	&logger( 6, "RESULT = " . ( $result || 0 ) . " for $sql" );
	$reportActions .= "-PURGE EDTK_ID=" . ( $result || 0 );

	return &logger( 4, $reportActions );
}

sub _acheck_db_rotate {
	my %p = @_;

	#	my $time =time;
	#	my $date =strftime "%Y-%m-%d", localtime;
	#	my $day  =strftime "%d", localtime;
	#	my $pid  =$$;
	my ( $sql, $insert, $result, $reportActions );
	$p{DBH} = db_connect( $p{CFG}, 'EDTK_DBI_DSN' );

	# Repatriate any pending backup rows before rotating / purging.
	eval { _db_maybe_reconcile( $p{DBH}, $p{CFG} ); };
	my $stamp = strftime "%Y%m%d%H%M%S", localtime;

	my $DAYS_KEPT_time       = time - ( 86400 * $p{CFG}->{EDTK_DB_MAX_DAYS_KEPT} );
	my $DAYS_KEPT_STATS_time = time - ( 86400 * $p{CFG}->{EDTK_DB_MAX_DAYS_KEPT_STATS} );
	my $DAYS_TRACKED_time    = time - ( 86400 * $p{CFG}->{EDTK_DB_MAX_DAYS_TRACKED} );
	my $DAYS_AGREGED_time    = time -
		( 86400 * ( $p{CFG}->{EDTK_DB_MAX_DAYS_AGREGED} || $p{CFG}->{EDTK_DB_MAX_DAYS_TRACKED} ) );

	### ROTATIONS ###
	### EDTK_AGREGE ###
	# MOVE DATA TO EDTK_AGREGE
	$sql =
		  "insert into edtk_agrege "
		. "select "
		. "i.ed_source, "
		. "d.ed_chanel_out, "
		. "i.ed_refiddoc, "
		. "i.ed_idproduct, "
		. "i.ed_dtedtion, "
		. "count(distinct d.ed_idldoc) as ed_cntd_idldoc, "
		. "count(d.ed_idseqpg) as ed_cnt_idseqpg, "
		. "d.ed_dtlot, "
		. "d.ed_idlot, "
		. "d.ed_idjob, "
		. $stamp
		. " from "
		. $p{CFG}->{'EDTK_DBI_OUTMNGR'}
		. " as i "
		. "inner join "
		. $p{CFG}->{'EDTK_DBI_DISTRIB'}
		. " as d on d.ed_idldoc = i.ed_idldoc "
		. "and d.ed_idseqpg = i.ed_idseqpg "
		. "and d.ed_seqdoc = i.ed_seqdoc "
		. "and d.ed_idjob = i.ed_idjob "
		. "where d.ed_dtlot < '"
		. ( strftime "%Y-%m-%d", localtime($DAYS_KEPT_time) ) . "' "
		. "group by "
		. "i.ed_source, "
		. "d.ed_chanel_out, "
		. "i.ed_refiddoc, "
		. "i.ed_idproduct,"
		. "i.ed_dtedtion, "
		. "d.ed_dtlot, "
		. "d.ed_idlot, "
		. "d.ed_idjob ";
	&logger( 7, "SQL = $sql" );

	$result = _db_do_log( $p{DBH}, $sql, "ERROR: can't update EDTK_AGREGE", fatal => 1 );
	&logger( 6, "RESULT = " . ( $result || 0 ) . " for $sql" );
	$reportActions .= "-MV AGREGE=" . ( $result || 0 );

	### DISTRIB ###
	# MOVE DATA FROM DISTRIB TO DISTRIB_STATS
	$sql =
		  "insert into "
		. $p{CFG}->{'EDTK_DBI_DISTRIB_STATS'}
		. " select * from "
		. $p{CFG}->{'EDTK_DBI_DISTRIB'}
		. " where ed_dtlot < '"
		. ( strftime "%Y-%m-%d", localtime($DAYS_KEPT_time) ) . "'";
	&logger( 7, $sql );

	$result =
		_db_do_log( $p{DBH}, $sql, "ERROR: can't update " . $p{CFG}->{'EDTK_DBI_DISTRIB_STATS'} )
		or return;
	&logger( 6, "RESULT = " . ( $result || 0 ) . " for $sql" );
	$reportActions .= "-MV DISTRIB=" . ( $result || 0 );

	# CLEAN DISTRIB
	$sql =
		  "delete from "
		. $p{CFG}->{'EDTK_DBI_DISTRIB'}
		. " where ed_dtlot < '"
		. ( strftime "%Y-%m-%d", localtime($DAYS_KEPT_time) ) . "'";
	&logger( 7, $sql );

	$result =
		_db_do_log( $p{DBH}, $sql, "ERROR: can't update " . $p{CFG}->{'EDTK_DBI_DISTRIB_STATS'} );
	&logger( 6, "RESULT = " . ( $result || 0 ) . " for $sql" );
	$reportActions .= "/" . ( $result || 0 );

	### OUTMNGR ###
	# MOVE DATA FROM OUTMNGR TO OUTMNGR_STATS
	$sql =
		  "insert into "
		. $p{CFG}->{'EDTK_DBI_OUTMNGR_STATS'}
		. " select * from "
		. $p{CFG}->{'EDTK_DBI_OUTMNGR'}
		. " where ed_dtlot < '"
		. ( strftime "%Y-%m-%d", localtime($DAYS_KEPT_time) ) . "'";
	&logger( 7, $sql );

	$result =
		_db_do_log( $p{DBH}, $sql, "ERROR: can't update " . $p{CFG}->{'EDTK_DBI_OUTMNGR_STATS'} );
	&logger( 6, "RESULT = " . ( $result || 0 ) . " for $sql" );
	$reportActions .= "-MV OUTMNGR=" . ( $result || 0 );

	# CLEAN OUTMNGR
	$sql =
		  "delete from "
		. $p{CFG}->{'EDTK_DBI_OUTMNGR'}
		. " where ed_dtlot < '"
		. ( strftime "%Y-%m-%d", localtime($DAYS_KEPT_time) ) . "'";
	&logger( 7, $sql );

	$result =
		_db_do_log( $p{DBH}, $sql, "ERROR: can't update " . $p{CFG}->{'EDTK_DBI_OUTMNGR_STATS'} );
	&logger( 6, "RESULT = " . ( $result || 0 ) . " for $sql" );
	$reportActions .= "/" . ( $result || 0 );

	$p{DBH}->disconnect;
	return ( 4, $reportActions );
}

sub agrege_idJob {

	# EXAMPLE CALL:
	# agrege_idJob (CFG => $cfg, IDJOB => 'IdJob');
	my %p     = @_;
	my $stamp = strftime "%Y%m%d%H%M%S", localtime;
	&logger( 6, "p{CFG} = " . $p{CFG} . " - p{IDJOB} " . $p{IDJOB} );

	my ( $sql, $insert, $result, $reportActions );
	$p{DBH} = db_connect( $p{CFG}, 'EDTK_DBI_DSN' );

	# Repatriate any pending backup rows before aggregating.
	eval { _db_maybe_reconcile( $p{DBH}, $p{CFG} ); };

	### ROTATIONS JobID ###
	### EDTK_AGREGE ###
	# MOVE DATA TO EDTK_AGREGE

	$sql =
		  "insert into edtk_agrege "
		. "select "
		. "i.ed_source, "
		. "d.ed_chanel_out, "
		. "i.ed_refiddoc, "
		. "i.ed_idproduct, "
		. "i.ed_dtedtion, "
		. "count(distinct d.ed_idldoc) as ed_cntd_idldoc, "
		. "count(d.ed_idseqpg) as ed_cnt_idseqpg, "
		. "d.ed_dtlot, "
		. "d.ed_idlot, "
		. "d.ed_idjob, "
		. $stamp
		. " from "
		. $p{CFG}->{'EDTK_DBI_OUTMNGR'}
		. " as i "
		. "inner join "
		. $p{CFG}->{'EDTK_DBI_DISTRIB'}
		. " as d on d.ed_idldoc = i.ed_idldoc "
		. "and d.ed_idseqpg = i.ed_idseqpg "
		. "and d.ed_seqdoc = i.ed_seqdoc "
		. "and d.ed_idjob = i.ed_idjob "
		. "where d.ed_idjob = '"
		. $p{IDJOB} . "' "
		. "group by "
		. "i.ed_source, "
		. "d.ed_chanel_out, "
		. "i.ed_refiddoc, "
		. "i.ed_idproduct,"
		. "i.ed_dtedtion, "
		. "d.ed_dtlot, "
		. "d.ed_idlot, "
		. "d.ed_idjob ";
	&logger( 7, "SQL = $sql" );

	$result = _db_do_log( $p{DBH}, $sql, "ERROR: can't update edtk_agrege", fatal => 1 );
	&logger( 6, "RESULT = " . ( $result || 0 ) . " for $sql" );
	$reportActions .= "-MV AGREGE=" . ( $result || 0 );

	### DISTRIB ###
	# MOVE DATA FROM DISTRIB TO DISTRIB_STATS
	$sql =
		  "insert into "
		. $p{CFG}->{'EDTK_DBI_DISTRIB_STATS'}
		. " select * from "
		. $p{CFG}->{'EDTK_DBI_DISTRIB'}
		. " where ed_idjob = '"
		. $p{IDJOB} . "'";
	&logger( 7, $sql );

	$result =
		_db_do_log( $p{DBH}, $sql, "ERROR: can't update " . $p{CFG}->{'EDTK_DBI_DISTRIB_STATS'} )
		or do { $p{DBH}->disconnect; return ( 4, $reportActions ); };
	&logger( 6, "RESULT = " . ( $result || 0 ) . " for $sql" );
	$reportActions .= "-MV DISTRIB=" . ( $result || 0 );

	# CLEAN DISTRIB
	$sql = "delete from " . $p{CFG}->{'EDTK_DBI_DISTRIB'} . " where ed_idjob = '" . $p{IDJOB} . "'";
	&logger( 7, $sql );

	$result =
		_db_do_log( $p{DBH}, $sql, "ERROR: can't update " . $p{CFG}->{'EDTK_DBI_DISTRIB_STATS'} );
	&logger( 6, "RESULT = " . ( $result || 0 ) . " for $sql" );
	$reportActions .= "/" . ( $result || 0 );

	### OUTMNGR ###
	# MOVE DATA FROM OUTMNGR TO OUTMNGR_STATS
	$sql =
		  "insert into "
		. $p{CFG}->{'EDTK_DBI_OUTMNGR_STATS'}
		. " select * from "
		. $p{CFG}->{'EDTK_DBI_OUTMNGR'}
		. " where ed_idjob = '"
		. $p{IDJOB} . "'";
	&logger( 7, $sql );

	$result =
		_db_do_log( $p{DBH}, $sql, "ERROR: can't update " . $p{CFG}->{'EDTK_DBI_OUTMNGR_STATS'} );
	&logger( 6, "RESULT = " . ( $result || 0 ) . " for $sql" );
	$reportActions .= "-MV OUTMNGR=" . ( $result || 0 );

	# CLEAN OUTMNGR
	$sql = "delete from " . $p{CFG}->{'EDTK_DBI_OUTMNGR'} . " where ed_idjob = '" . $p{IDJOB} . "'";
	&logger( 7, $sql );

	$result =
		_db_do_log( $p{DBH}, $sql, "ERROR: can't update " . $p{CFG}->{'EDTK_DBI_OUTMNGR_STATS'} );
	&logger( 6, "RESULT = " . ( $result || 0 ) . " for $sql" );
	$reportActions .= "/" . ( $result || 0 );

	$p{DBH}->disconnect;
	return ( 4, $reportActions );
}

sub acheck_db_admin_on_connect {

	# https://www.forknerds.com/reduce-the-size-of-mysql/
	# my ($level, $return) = acheck_db_admin_on_connect ($dbh, $cfg);
	my $dbh = shift;
	my $cfg = shift;

	eval { schema_StaleWarning( $dbh, cfg => $cfg ); };

	my $time = time;
	my $date = strftime "%Y-%m-%d", localtime;
	my $day  = strftime "%d",       localtime;
	my $pid  = $$;
	my ( $sth, $sql, $insert, $result, $reportActions );

	my $DAYS_KEPT_time       = time - ( 86400 * $cfg->{EDTK_DB_MAX_DAYS_KEPT} );
	my $DAYS_KEPT_STATS_time = time - ( 86400 * $cfg->{EDTK_DB_MAX_DAYS_KEPT_STATS} );
	my $DAYS_TRACKED_time    = time - ( 86400 * $cfg->{EDTK_DB_MAX_DAYS_TRACKED} );
	my $DAYS_AGREGED_time =
		time - ( 86400 * ( $cfg->{EDTK_DB_MAX_DAYS_AGREGED} || $cfg->{EDTK_DB_MAX_DAYS_TRACKED} ) );

	#my $EDTK_DB_CHECK_MONTH_DAY = $cfg->{EDTK_DB_CHECK_MONTH_DAY} || 0; # to remove

	# Repatriate any pending backup rows before the maintenance check.
	eval { _db_maybe_reconcile( $dbh, $cfg ); };

	&logger( 4, "ACHECK Check START" );

	#LOOK FOR THE LAST ACTION ON THE ADMIN TABLE
	$sql =
"select ed_action_date, ed_action_pid, ed_action_status, ed_action_duration, ed_oedtk_release from edtk_admin "
		. " where ed_action_date = '"
		. $date
		. "'  ";    #order by ed_action_date desc limit 1";
	&logger( 7, $sql );

	$sth = $dbh->prepare($sql) or return ( 3, $dbh->errstr );

	do { local $sth->{PrintError} = 0; $sth->execute() }
		or &logger( 3, "SQL execute failed " . $sth->err . "-" . $sth->errstr );

	# HAS AN ADMINISTRATION ACTION ALREADY BEEN DONE TODAY ?
	my @tValues = $dbh->selectrow_array( $sql, undef )
		;           # or warn ("ERROR: in acheck_db_admin_on_connect, message is " . $dbh->errstr);
	if ( $tValues[0] and $date eq $tValues[0] ) {
		&logger(
			6,
			(
					  "Previously done, ACHECK Last EDTK_DB_MAX_DAYS check : "
					. $tValues[0] . " PID "
					. $tValues[1]
			)
		);
		return ( 5,
			( "ACHECK Last EDTK_DB_MAX_DAYS check : " . $tValues[0] . " PID " . $tValues[1] ) );
	}

	# OTHERWISE, REQUEST A TICKET TO CARRY OUT THE ACTION
	$insert =
'insert into edtk_admin (ed_action_date, ed_action_pid, ed_action_status, ed_oedtk_release) '
		. ' values (?, ?, ?, ?) ';
	$sth = $dbh->prepare_cached($insert);

	eval {
		do { local $sth->{PrintError} = 0; $sth->execute( $date, $pid, "START", $VERSION ) }
			or &logger( 3, "SQL execute failed " . $sth->err . "-" . $sth->errstr );
	};
	if ($@) {
		&logger( 3, "ERROR: $@ into $insert" );
	}

	# CHECK THAT WE HOLD THE LOCK FOR THE ACTION
	$sth = $dbh->prepare($sql);
	do { local $sth->{PrintError} = 0; $sth->execute() }
		or &logger( 3, "SQL execute failed " . $sth->err . "-" . $sth->errstr );
	@tValues = do { local $dbh->{PrintError} = 0; $dbh->selectrow_array( $sql, undef ) }
		or &logger( 3, "ERROR: in acheck_db_admin_on_connect, message is " . $dbh->errstr );
	$reportActions = "ACHECK Check 2 : " . $tValues[0] . " PID " . $tValues[1];

	if ( $date eq $tValues[0] and $pid eq $tValues[1] ) {
		&logger( 5, $reportActions );

		# _db_admin_actions;
	}
	else {
		# another process did the action, giving up
		return ( 5, $reportActions );
	}

	### PURGES ###
	# PURGE FROM OEDTK_ADMIN
	$sql = "delete from edtk_admin where ed_action_date < '"
		. ( strftime "%Y-%m-%d", localtime($DAYS_TRACKED_time) ) . "'";
	&logger( 7, $sql );

	$result = _db_do_log( $dbh, $sql, "ERROR: can't update EDTK_ADMIN" ) or return;
	&logger( 6, "RESULT = " . ( $result // 0 ) . " for $sql" );
	$reportActions = "ACHECK PURGE edtk_admin=" . ( $result // 0 );

	# PURGE FROM EDTK_DBI_TRACKING
	$sql =
		  "delete from "
		. $cfg->{'EDTK_DBI_TRACKING'}
		. " where ed_tstamp < '"
		. ( strftime "%Y%m%d", localtime($DAYS_TRACKED_time) )
		. "000000'";
	&logger( 7, $sql );

	$result = _db_do_log( $dbh, $sql, "ERROR: can't update " . $cfg->{'EDTK_DBI_TRACKING'} )
		or return;
	&logger( 6, "RESULT = " . ( $result // 0 ) . " for $sql" );
	$reportActions .= "-PURGE tracking=" . ( $result // 0 );

	# PURGE FROM EDTK_DBI_DISTRIB_STATS
	$sql =
		  "delete from "
		. $cfg->{'EDTK_DBI_DISTRIB_STATS'}
		. " where ed_dtlot < '"
		. ( strftime "%Y-%m-%d", localtime($DAYS_KEPT_STATS_time) )
		. "'";    # note: NOT REGEXP_LIKE (ED_DTLOT, '\d\d\d\d-\d\d-\d\d') does not work on MySQL...
	&logger( 7, $sql );

	$result = _db_do_log( $dbh, $sql, "ERROR: can't update " . $cfg->{'EDTK_DBI_DISTRIB_STATS'} )
		or return;
	&logger( 6, "RESULT = " . ( $result // 0 ) . " for $sql" );
	$reportActions .= "-PURGE distrib_s=" . ( $result // 0 );

	# PURGE FROM OUTMNGR_STATS
	$sql =
		  "delete from "
		. $cfg->{'EDTK_DBI_OUTMNGR_STATS'}
		. " where ed_dtlot < '"
		. ( strftime "%Y-%m-%d", localtime($DAYS_KEPT_STATS_time) ) . "'";
	&logger( 7, $sql );

	$result = _db_do_log( $dbh, $sql, "ERROR: can't update " . $cfg->{'EDTK_DBI_OUTMNGR_STATS'} )
		or return;
	&logger( 6, "RESULT = " . ( $result // 0 ) . " for $sql" );
	$reportActions .= "-PURGE outmngr_s=" . ( $result // 0 );

	# PURGE FROM EDTK_AGREGE
	$sql =
		  "delete from edtk_agrege "
		. " where ed_dtlot < '"
		. ( strftime "%Y-%m-%d", localtime($DAYS_AGREGED_time) ) . "'";
	&logger( 7, $sql );

	$result = _db_do_log( $dbh, $sql, "ERROR: can't update EDTK_AGREGE" ) or return;
	&logger( 6, "RESULT = " . ( $result // 0 ) . " for $sql" );
	$reportActions .= "-PURGE agrege=" . ( $result // 0 );
	my $stamp = strftime "%Y%m%d%H%M%S", localtime;

	### MOVE / PURGE ###
	### EDTK_AGREGE ###
	# MOVE DATA TO EDTK_AGREGE
	$sql =
		  "insert into edtk_agrege "
		. "select "
		. "i.ed_source, "
		. "d.ed_chanel_out, "
		. "i.ed_refiddoc, "
		. "i.ed_idproduct, "
		. "i.ed_dtedtion, "
		. "count(distinct d.ed_idldoc) as ed_cntd_idldoc, "
		. "count(d.ed_idseqpg) as ed_cnt_idseqpg, "
		. "d.ed_dtlot, "
		. "d.ed_idlot, "
		. "d.ed_idjob, "
		. $stamp
		. " from "
		. $cfg->{'EDTK_DBI_OUTMNGR'}
		. " as i "
		. "inner join "
		. $cfg->{'EDTK_DBI_DISTRIB'}
		. " as d on d.ed_idldoc = i.ed_idldoc "
		. "and d.ed_idseqpg = i.ed_idseqpg "
		. "and d.ed_seqdoc = i.ed_seqdoc "
		. "and d.ed_idjob = i.ed_idjob "
		. " where d.ed_dtlot < '"
		. ( strftime "%Y-%m-%d", localtime($DAYS_KEPT_time) ) . "'"
		. "group by "
		. "i.ed_source, "
		. "d.ed_chanel_out, "
		. "i.ed_refiddoc, "
		. "i.ed_idproduct,"
		. "i.ed_dtedtion, "
		. "d.ed_dtlot, "
		. "d.ed_idlot, "
		. "d.ed_idjob ";
	&logger( 7, "SQL = $sql" );

	$result = _db_do_log( $dbh, $sql, "ERROR: can't update EDTK_AGREGE", fatal => 1 );
	&logger( 6, "RESULT = " . ( $result // 0 ) . " for $sql" );
	$reportActions .= "-MV agrege=" . ( $result // 0 );

	### DISTRIB ###
	# MOVE DATA FROM DISTRIB TO DISTRIB_STATS
	$sql =
		  "insert into "
		. $cfg->{'EDTK_DBI_DISTRIB_STATS'}
		. " select * from "
		. $cfg->{'EDTK_DBI_DISTRIB'}
		. " where ed_dtlot < '"
		. ( strftime "%Y-%m-%d", localtime($DAYS_KEPT_time) ) . "'";
	&logger( 7, $sql );

	$result = _db_do_log( $dbh, $sql, "ERROR: can't update " . $cfg->{'EDTK_DBI_DISTRIB_STATS'} )
		or return;
	&logger( 6, "RESULT = " . ( $result // 0 ) . " for $sql" );
	$reportActions .= "-MV distrib=" . ( $result // 0 );

	# CLEAN DISTRIB
	$sql =
		  "delete from "
		. $cfg->{'EDTK_DBI_DISTRIB'}
		. " where ed_dtlot < '"
		. ( strftime "%Y-%m-%d", localtime($DAYS_KEPT_time) ) . "'";
	&logger( 7, $sql );

	$result = _db_do_log( $dbh, $sql, "ERROR: can't update " . $cfg->{'EDTK_DBI_DISTRIB_STATS'} );
	&logger( 6, "RESULT = " . ( $result // 0 ) . " for $sql" );
	$reportActions .= "/" . ( $result // 0 );

	### OUTMNGR ###
	# MOVE DATA FROM OUTMNGR TO OUTMNGR_STATS
	$sql =
		  "insert into "
		. $cfg->{'EDTK_DBI_OUTMNGR_STATS'}
		. " select * from "
		. $cfg->{'EDTK_DBI_OUTMNGR'}
		. " where ed_dtlot < '"
		. ( strftime "%Y-%m-%d", localtime($DAYS_KEPT_time) ) . "'";
	&logger( 7, $sql );

	$result = _db_do_log( $dbh, $sql, "ERROR: can't update " . $cfg->{'EDTK_DBI_OUTMNGR_STATS'} );
	&logger( 6, "RESULT = " . ( $result // 0 ) . " for $sql" );
	$reportActions .= "-MV outmngr=" . ( $result // 0 );

	# CLEAN OUTMNGR
	$sql =
		  "delete from "
		. $cfg->{'EDTK_DBI_OUTMNGR'}
		. " where ed_dtlot < '"
		. ( strftime "%Y-%m-%d", localtime($DAYS_KEPT_time) ) . "'";
	&logger( 7, $sql );

	$result = _db_do_log( $dbh, $sql, "ERROR: can't update " . $cfg->{'EDTK_DBI_OUTMNGR_STATS'} );
	&logger( 6, "RESULT = " . ( $result // 0 ) . " for $sql" );
	$reportActions .= "/" . ( $result // 0 );

	### EDTK_ID ###
	# PURGE FROM EDTK_ID
	$sql =
		  "delete from edtk_id"
		. " where ed_id_date < '"
		. ( strftime "%Y-%m-%d", localtime($DAYS_TRACKED_time) ) . "'";
	&logger( 7, $sql );

	$result = _db_do_log( $dbh, $sql, "ERROR: can't update " . $cfg->{'EDTK_DBI_OUTMNGR_STATS'} );
	&logger( 6, "RESULT = " . ( $result // 0 ) . " for $sql" );
	$reportActions .= "-PURGE edtk_id=" . ( $result // 0 );

	# End of the run
	$time = time - $time;
	$sql =
'update edtk_admin set ed_action_status = ?, ed_action_duration = ? where ed_action_date = ?';
	_db_do_log(
		$dbh, $sql,
		"ERROR: can't update ED_ACTION_STATUS",
		bind => [ "DONE", $time, $date ]
	);

	return ( 4, $reportActions );
}

our @TRACKER_COLS = (
	[ 'ed_tstamp',  'varchar2(14) not null' ],    # timestamp of event
	[ 'ed_sngl_id', 'varchar2(36) not null' ]
	,    # ed_idldoc single id : 36-char UUID (S70, D1); was the 16-digit YWWWDHHMMSSPPPP.r format
	[ 'ed_seq', 'integer      not null' ],    # sequence
	[ 'ed_app', 'varchar2(20) not null' ],    #xx ed_refiddoc application name

	[ 'ed_user',    'varchar2(10) not null' ], # user for the job or request
	[ 'ed_corp',    'varchar2(8)  not null' ], # entity related
	[ 'ed_account', 'varchar2(8)' ],           # administrative account
	[ 'ed_mod_ed',  'char(1)' ],               # editing mode (undef, batch, tp, web, mail, probing)
	[ 'ed_job_evt', 'char(1)' ]
	, # level of the event (job (default), spool, document, line, warning, error, halt (critic), reject)
	[ 'ed_obj_typ',   'varchar2(3)' ],    # to define the object concerned
	[ 'ed_obj_count', 'integer' ],        # number of objects attached to the event
	[ 'ed_child_typ', 'varchar2(3)' ],    # to define the object concerned
	[ 'ed_child_id',  'varchar2(36)' ]
	,    # ed_idldoc single id : 36-char UUID (S70, D1); was the 16-digit YWWWDHHMMSSPPPP.r format
	[ 'ed_parent_id', 'varchar2(36)' ]
	,    # ed_idldoc single id : 36-char UUID (S70, D1); was the 16-digit YWWWDHHMMSSPPPP.r format

	[ 'ed_host', 'varchar2(32)' ]
	,    # hostname for input stream of this document (max length for smtp is 31, could be 255...)
	[ 'ed_source',  'varchar2(128)' ],    # input stream of this document
	[ 'ed_message', 'varchar2(256)' ]     # treatment message

);

sub create_table_TRACKING {
	my ( $dbh, $table, $maxkeys ) = @_;

	my $sql = "create table if not exists $table ("
		. join( ', ', map { "$$_[0] $$_[1]" } @TRACKER_COLS ) . ", ";

	foreach my $i ( 0 .. $maxkeys ) {
		$sql .= " ed_k${i}_NAME VARCHAR2(8),";    # Name of key $i
		$sql .= " ed_k${i}_VAL VARCHAR2(128)";    # Value of key $i
		$sql .= "," unless ( $i == $maxkeys );
	}
	$sql .= " )";
	$sql .= _db_engine_clause($dbh);
	&logger( 7, $sql );
	_db_do_ddl( $dbh, $sql ) or &logger( 4, $dbh->errstr );

	#	my $idx = "ix_".$table."_".$VERSION_TXT;
	my $idx = "ix_" . $table;
	$sql = "create index if not exists $idx on $table " . " (ed_tstamp);";
	&logger( 7, $sql );
	_db_do_ddl( $dbh, $sql )
		or &logger( 4, $dbh->errstr )
		if ( _db_check_driver_name($dbh) ne "SQLite" );

}

sub db_drop_table {
	my ( $dbh, $table ) = @_;
	my $sql = "drop table $table";

	_db_do_ddl( $dbh, $sql ) or &logger( 4, $dbh->errstr );
}

# ============================================================
# Backup-buffer ("store-and-forward") repatriation.
#
# When the main database server is unreachable, db_connect silently falls back
# to the ${dsnvar}_BAK database (a SQLite buffer) and every write accumulates
# there. The routines below are the missing "return" half: they detect pending
# rows and copy them back into the main database, idempotently.
#
# Design note: no high-water-mark table is kept. Repatriation is made
# idempotent by an "insert if the natural key is absent" test plus a full drain
# of the buffer on success, so a crash or a re-run cannot duplicate nor lose a
# row. The buffer holds only event tables: edtk_agrege is recomputed from its
# sources and edtk_admin is per-database coordination, so both are excluded.
# ============================================================

# Is a distinct backup database configured?
sub db_backup_available {
	my ($cfg) = @_;
	return 0 unless $cfg && defined $cfg->{'EDTK_DBI_DSN_BAK'};
	my $main = $cfg->{'EDTK_DBI_DSN'}     // '';
	my $bak  = $cfg->{'EDTK_DBI_DSN_BAK'} // '';
	return 0 if $bak eq '';
	return 0 if $bak eq $main;    # anti-loop guard: backup == main
	return 1;
}

# Does this handle point at the backup buffer?
sub db_on_backup {
	my ($dbh) = @_;
	return ( defined $dbh && $dbh->{'private_oEdtk_on_backup'} ) ? 1 : 0;
}

# Open the backup buffer (never fatal, never blocking).
sub _db_backup_connect {
	my ($cfg) = @_;
	return unless db_backup_available($cfg);
	my %bcfg = ( %$cfg, EDTK_WAITRUN => 0 );    # no retry loop for a probe
	my $bak  = eval {
		_db_connect1(
			\%bcfg,
			'EDTK_DBI_DSN_BAK',
			{
				FetchHashKeyName => $cfg->{'EDTK_DB_FetchHashKeyName'} || 'NAME_uc',
				AutoCommit       => 1
			}
		);
	};
	return $bak;
}

# Tables repatriated from the buffer, in dependency order, with the natural key
# used for the idempotent "insert if absent" test.
sub _backup_table_registry {
	my ($cfg) = @_;
	my @t;
	push @t,
		{ table => $cfg->{'EDTK_DBI_TRACKING'}, keys => [qw(ed_tstamp ed_sngl_id ed_seq ed_app)] }
		if $cfg->{'EDTK_DBI_TRACKING'};
	push @t, { table => $cfg->{'EDTK_DBI_ACQUIT'}, keys => [qw(ed_seqlot ed_lotname ed_dtpost)] }
		if $cfg->{'EDTK_DBI_ACQUIT'};
	push @t, { table => 'edtk_id', keys => [qw(ed_id_value)] };
	push @t,
		{
		table => $cfg->{'EDTK_DBI_OUTMNGR'},
		keys  => [qw(ed_idldoc ed_seqdoc ed_idseqpg ed_idjob)]
		}
		if $cfg->{'EDTK_DBI_OUTMNGR'};
	push @t,
		{
		table => $cfg->{'EDTK_DBI_DISTRIB'},
		keys  => [qw(ed_idldoc ed_seqdoc ed_idseqpg ed_idjob)]
		}
		if $cfg->{'EDTK_DBI_DISTRIB'};
	return @t;
}

# Guarantee the backup buffer can hold the event tables (resolves TODO in db_connect).
sub db_backup_prepare {
	my ($bak_dbh) = @_;
	return 0 unless defined $bak_dbh;
	my $ok = eval {
		my $cfg = config_read('EDTK_DB');
		schema_Create($bak_dbh);

		# schema_Create does not create the tracking table (db_connect does), but
		# the buffer must be able to hold tracking rows.
		unless ( _table_exists( $bak_dbh, $cfg->{'EDTK_DBI_TRACKING'} ) ) {
			create_table_TRACKING(
				$bak_dbh,
				$cfg->{'EDTK_DBI_TRACKING'},
				$cfg->{'EDTK_MAX_USER_KEY'}
			);
		}
		1;
	};
	&logger( 3, "db_backup_prepare: could not prepare the backup schema: $@" ) unless $ok;
	return $ok ? 1 : 0;
}

# Count pending rows per buffer table (read-only detection).
sub db_backup_pending {
	my ($cfg) = @_;
	my %pending;
	return \%pending unless db_backup_available($cfg);
	my $bak = _db_backup_connect($cfg);
	unless ($bak) {
		&logger( 7, "db_backup_pending: backup database unreachable" );
		return \%pending;
	}
	for my $t ( _backup_table_registry($cfg) ) {
		my $n = eval { my ($c) = $bak->selectrow_array("select count(*) from $t->{table}"); $c };
		$pending{ $t->{table} } = $n if defined $n && $n > 0;
	}
	eval { $bak->disconnect };
	return \%pending;
}

# Copy the pending rows of ONE buffer table into the main database, then drain
# the buffer table when the whole batch succeeded. Idempotent.
sub _reconcile_one_table {
	my ( $main, $bak, $t, %p ) = @_;
	my $table = $t->{table};
	my @keys  = @{ $t->{keys} };
	my $out   = { read => 0, written => 0, skipped => 0, ok => 1 };

	# The buffer only carries the tables that were actually written, so a table
	# missing here is normal, not an error. Check it silently and return: with DBI's
	# default PrintError the probe would otherwise print "relation does not exist".
	my $n = do {
		local $bak->{PrintError} = 0;
		local $bak->{RaiseError} = 0;
		eval { my ($c) = $bak->selectrow_array("select count(*) from $table"); $c };
	};
	unless ( defined $n ) {
		&logger( 7, "_reconcile_one_table: '$table' absent from the backup" );
		return $out;
	}
	return $out if $n == 0;
	if ( $p{dry_run} ) { $out->{read} = $n; return $out; }

	my $sth_rd = $bak->prepare("select * from $table");
	unless ( $sth_rd && $sth_rd->execute ) {
		&logger( 3,
			"_reconcile_one_table: cannot read '$table' from the backup: "
				. ( $bak->errstr // '' ) );
		$out->{ok} = 0;
		return $out;
	}
	my $raw_cols = $sth_rd->{NAME};    # buffer column names (raw order)

	my ( $norm_id, $norm_table, @norm_cols ) = _norm_identifiers( $main, $table, $raw_cols );
	my $meta  = _get_col_meta( $main, $norm_table, $norm_id );
	my $clean = _make_clean_val($meta);

	my @uk         = map { $norm_id->($_) } @keys;
	my $sql_exists = "select 1 from $norm_table where " . join( ' and ', map { "$_ = ?" } @uk );
	my $sql_insert =
		  "insert into $norm_table ("
		. join( ',', @norm_cols ) . ")"
		. " values ("
		. join( ',', ('?') x @norm_cols ) . ")";
	my $sth_chk = $main->prepare($sql_exists);
	my $sth_ins = $main->prepare($sql_insert);
	&logger( 7, "_reconcile_one_table: $table exists=[$sql_exists]" );

	while ( my $row = $sth_rd->fetchrow_arrayref ) {
		$out->{read}++;

		# Map values by NAME (not position) so that a column-order divergence
		# between the buffer and the main schema cannot corrupt the data.
		my %by_name;
		for my $i ( 0 .. $#$raw_cols ) { $by_name{ $norm_id->( $raw_cols->[$i] ) } = $row->[$i]; }

		my $dup = eval {
			local $sth_chk->{PrintError} = 0;
			$sth_chk->execute( map { $clean->( $_, $by_name{$_} ) } @uk );
			my ($x) = $sth_chk->fetchrow_array;
			$sth_chk->finish;
			$x;
		};
		if ($dup) { $out->{skipped}++; next; }

		my $ok = eval {
			local $sth_ins->{PrintError} = 0;
			$sth_ins->execute( map { $clean->( $_, $by_name{$_} ) } @norm_cols );
			1;
		};
		if ($ok) { $out->{written}++ }
		else {
			&logger( 3,
				"_reconcile_one_table: insert into '$table' failed: " . ( $main->errstr // $@ ) );
			$out->{ok} = 0;
			last;
		}
	}
	$sth_rd->finish;

	# Drain the buffer table only when the whole batch was written.
	if ( $out->{ok} && !$p{keep_backup} ) {
		my $d = eval { local $bak->{PrintError} = 0; $bak->do("delete from $table"); };
		unless ( defined $d ) {
			&logger( 3,
				"_reconcile_one_table: could not drain '$table': " . ( $bak->errstr // '' ) );
			$out->{ok} = 0;
		}
	}
	return $out;
}

# PUBLIC: copy every pending row of the backup buffer back into the main DB.
# Never dies; returns a report hashref.
#   %opt: CFG => $cfg, tables => [ {table=>,keys=>[]} ], dry_run => 1, keep_backup => 1
sub db_reconcile_backup {
	my ( $main_dbh, %p ) = @_;
	my $cfg = $p{CFG} || config_read('EDTK_DB');
	my $res = { driver => _db_check_driver_name($main_dbh), tables => {}, written => 0, ok => 1 };

	unless ( db_backup_available($cfg) ) {
		&logger( 7, "db_reconcile_backup: no distinct backup database configured, nothing to do" );
		return $res;
	}
	if ( db_on_backup($main_dbh) ) {
		&logger( 7, "db_reconcile_backup: current handle is the backup itself, skipping" );
		return $res;
	}

	my $bak = _db_backup_connect($cfg);
	unless ($bak) {
		&logger( 3, "db_reconcile_backup: backup database unreachable, no repatriation" );
		$res->{ok}    = 0;
		$res->{error} = 'backup unreachable';
		return $res;
	}

	my @tables = $p{tables} ? @{ $p{tables} } : _backup_table_registry($cfg);
	&logger( 4, "checking if backup data needs reconciliation ..." );

	for my $t (@tables) {
		my $r = _reconcile_one_table( $main_dbh, $bak, $t, %p );
		$res->{tables}{ $t->{table} } = $r;
		$res->{written} += $r->{written};
		$res->{ok} = 0 unless $r->{ok};
	}
	eval { $bak->disconnect };
	return $res;
}

# Best-effort hook: repatriate before a maintenance operation. Never fatal.
sub _db_maybe_reconcile {
	my ( $dbh, $cfg ) = @_;
	return unless defined $dbh && defined $cfg && db_backup_available($cfg);
	eval {
		my $r = db_reconcile_backup( $dbh, CFG => $cfg );
		&logger( 3,
			"db_reconcile_backup: " . $r->{written} . " row(s) repatriated from the backup buffer" )
			if ( $r->{written} || 0 ) > 0;
	};
	&logger( 3, "db_reconcile_backup failed: $@" ) if $@;
	return;
}

sub historicize_table {
	my ( $dbh, $table, $suffixe ) = @_;
	my $table_cible = $table . "_" . $suffixe;

	copy_table( $dbh, $table, $table_cible, '-create' );

	# SQLite has no TRUNCATE statement; DELETE achieves the same move of the data.
	my $sql =
		( _db_check_driver_name($dbh) eq 'SQLite' )
		? "delete from $table"
		: "truncate table $table";
	&logger( 7, $sql );

	_db_do_log( $dbh, _sql_fixup( $dbh, $sql, 'casse' ), "ERROR: can't $sql", fatal => 1 );
}

sub create_table_ADMIN {
	my $dbh   = shift;
	my $table = "edtk_admin";

	my $sql = "create table if not exists $table ";
	$sql .= "( ed_action_date     date not null";
	$sql .= ", ed_action_pid      integer not null";
	$sql .= ", ed_action_status   varchar2(16)";
	$sql .= ", ed_action_duration integer";
	$sql .= ", ed_oedtk_release   varchar2(8) not null";
	$sql .= ", primary key (ed_action_date)";
	$sql .= " )";
	$sql .= _db_engine_clause($dbh);
	&logger( 7, $sql );

	_db_do_ddl( $dbh, $sql ) or &logger( 4, $dbh->errstr );
}

sub create_table_ID {
	my $dbh   = shift;
	my $table = "edtk_id";

	my $sql = "create table if not exists $table ";
	$sql .= "( ed_id_date       date not null";         # 2021-05-19
	$sql .= ", ed_id_value      varchar2(25) unique";
	$sql .= ", ed_id_chanel_out varchar2(32)";
	$sql .= ", primary key (ed_id_value)";
	$sql .= " )";
	$sql .= _db_engine_clause($dbh);

	&logger( 7, $sql );

	_db_do_ddl( $dbh, $sql ) or &logger( 4, $dbh->errstr );

	#	my $idx = "ix_".$table."_".$VERSION_TXT;
	my $idx = "ix_" . $table;
	$sql = "create index if not exists $idx on $table (ed_id_date);";
	&logger( 7, $sql );
	_db_do_ddl( $dbh, $sql ) or &logger( 4, $dbh->errstr );

}

sub create_table_FILIERES {
	my $dbh   = shift;
	my $table = "edtk_filieres";

	my $sql = "create table if not exists $table ";
	$sql .= "( ed_idfiliere varchar2(5) unique";     #
	$sql .= ", ed_priorite integer unique";          #
	$sql .= ", ed_idmanufact varchar2(16)";
	$sql .= ", ed_designation varchar2(64)";         #
	$sql .= ", ed_actif char(1) not null";    # flag: whether that business line (filiere) is active
	$sql .= ", ed_typed char(1) not null";    #
	$sql .= ", ed_modedi char(1) not null";   #
	$sql .= ", ed_idgplot varchar2(16) not null";    #
	$sql .= ", ed_nbbacprn integer not null";        #
	$sql .= ", ed_nbencmax integer";
	$sql .= ", ed_minfeuil_l integer";
	$sql .= ", ed_maxfeuil_l integer";
	$sql .= ", ed_feuilpli integer";
	$sql .= ", ed_minplis integer";
	$sql .= ", ed_maxplis integer not null";
	$sql .= ", ed_poids_pli integer";                # maximum weight of the folded item in the line
	$sql .= ", ed_ref_env varchar2(8) not null";
	$sql .= ", ed_formflux varchar2(3) not null";
	$sql .= ", ed_sort varchar2(128) not null";
	$sql .= ", ed_direction varchar2(4) not null";
	$sql .= ", ed_postcomp varchar2(8) not null";
	$sql .= ", primary key (ed_idfiliere, ed_priorite)";
	$sql .= " )";
	$sql .= _db_engine_clause($dbh);
	&logger( 7, $sql );

	_db_do_ddl( $dbh, $sql ) or &logger( 4, $dbh->errstr );
}

sub create_table_LOTS {
	my $dbh   = shift;
	my $table = "edtk_lots";

	my $sql = "create table if not exists $table ";
	$sql .= "( ed_idlot varchar2(8) not null"
		;    # rendre unique ? -> alter table edtk_lots modify ed_idlot varchar2(8) not null
	$sql .= ", ed_priorite integer   unique";          #
	$sql .= ", ed_idappdoc varchar2(20)";              #
	$sql .= ", ed_refiddoc varchar2(20) not null";     #
	$sql .= ", ed_cpdest varchar2(10)";                #
	$sql .= ", ed_filter varchar2(64)";                #
	$sql .= ", ed_refenc varchar2(32)";                #
	$sql .= ", ed_groupby varchar2(16)";
	$sql .= ", ed_lotname varchar2(64) not null";      #
	$sql .= ", ed_idgplot varchar2(16) not null";
	$sql .= ", ed_idmanufact varchar2(16) not null";
	$sql .= ", ed_consigne varchar2(250) ";            #
	$sql .= ", primary key (ed_idlot, ed_priorite)";
	$sql .= " )";
	$sql .= _db_engine_clause($dbh);
	&logger( 7, $sql );

	_db_do_ddl( $dbh, $sql ) or &logger( 4, $dbh->errstr );
}

sub create_table_REFIDDOC {
	my $dbh   = shift;
	my $table = "edtk_refiddoc";

	my $sql = "create table if not exists $table ";
	$sql .= "( ed_refiddoc varchar2(20) unique";
	$sql .= ", ed_corp varchar2(8) not null";                    # entity related to the document
	$sql .= ", ed_catdoc char(1) not null";
	$sql .= ", ed_portadr char(1) not null";
	$sql .= ", ed_massmail char(1) not null";
	$sql .= ", ed_edocshare char(1) not null";
	$sql .= ", ed_typed char(1) not null";
	$sql .= ", ed_modedi char(1) not null";
	$sql .= ", ed_pgorien varchar2(2)";
	$sql .= ", ed_formatp varchar2(2)";
	$sql .= ", ed_refimp_p1 varchar2(16)";
	$sql .= ", ed_refimp_ps varchar2(16)";
	$sql .= ", ed_refimp_refiddoc varchar2(64)";
	$sql .= ", ed_mail_referent varchar2(300)";                  # referent mail for doc validation
	$sql .= ", primary key (ed_refiddoc, ed_corp, ed_catdoc)";
	$sql .= " )";
	$sql .= _db_engine_clause($dbh);
	&logger( 7, $sql );

	_db_do_ddl( $dbh, $sql ) or &logger( 4, $dbh->errstr );
}

sub create_table_SUPPORTS {
	my $dbh   = shift;
	my $table = "edtk_supports";

	my $sql = "create table if not exists $table ";
	$sql .= "( ed_refimp varchar2(16) unique";     #
	$sql .= ", ed_typimp char(1) not null";
	$sql .= ", ed_formatp varchar2(2) not null";
	$sql .= ", ed_poidsunit integer not null";
	$sql .= ", ed_feuimax integer";
	$sql .= ", ed_poidsmax integer";
	$sql .= ", ed_bac_insert integer";
	$sql .= ", ed_copygroup varchar2(16)";
	$sql .= ", ed_optctrl varchar2(8)";
	$sql .= ", ed_debvalid varchar2(8)";
	$sql .= ", ed_finvalid varchar2(8)";
	$sql .= ", primary key (ed_refimp)";
	$sql .= " )";
	$sql .= _db_engine_clause($dbh);
	&logger( 7, $sql );

	_db_do_ddl( $dbh, $sql ) or &logger( 4, $dbh->errstr );
}

our @DISTRIB_COLS = (
	[ 'ed_idldoc', 'varchar2(36) not null' ]
	,    # document id within the page-layout batch ed_sngl_id widened to 36
	[ 'ed_idseqpg', 'integer not null' ],  # page sequence number [doc] within the page-layout batch
	[ 'ed_seqdoc',  'integer not null' ],  # document sequence number within the batch
	[ 'ed_idjob',   'varchar2(25) not null' ],    # job id

	[ 'ed_idlot',     'varchar2(8)' ],            # batch id
	[ 'ed_seqlot',    'varchar2(7)' ],            # mailing batch id (sub-batch)
	[ 'ed_dtlot',     'varchar2(10)' ],           # creation date of the mailing batch
	[ 'ed_idfiliere', 'varchar2(5)' ],            # production line id
	[ 'ed_seqpgdoc',  'integer' ],                # page sequence number within the document
	[ 'ed_nbpgdoc',   'integer' ],                # number of pages (sides) of the document

	# add
	[ 'ed_workflow',   'varchar2(32)' ],    # workflow on which the metadata was produced	++ new ++
	[ 'ed_chanel_out', 'varchar2(32)' ],    # distribution/output channel						++ new ++

	[ 'ed_idged', 'varchar2(25)' ]

);

sub create_table_DISTRIB {
	my ( $dbh, $table ) = @_;

	my $sql =
		"create table if not exists $table (" . join( ', ', map { "$$_[0] $$_[1]" } @DISTRIB_COLS )

		#			. ", primary key (ed_idldoc, ed_seqdoc, ed_idseqpg, ed_idjob, ed_chanel_out)"
		. " )";
	$sql .= _db_engine_clause($dbh);
	&logger( 7, $sql );

	_db_do_ddl( $dbh, $sql ) or &logger( 4, $dbh->errstr );

	#	my $idx = "ix_".$table."_".$VERSION_TXT;
	my $idx = "ix_" . $table;

	$sql = "create index if not exists $idx on $table "
		. " (ed_idldoc, ed_seqdoc, ed_idseqpg, ed_idjob, ed_chanel_out, ed_dtlot);";
	&logger( 7, $sql );
	_db_do_ddl( $dbh, $sql ) or &logger( 4, $dbh->errstr );

	# Rotation / maintenance predicates. Rows are selected and deleted by job
	# (agrege_idJob, _acheck_db_rotate) and by batch date (rotation). The composite
	# index above leads with ed_idldoc, so neither predicate can use it: dedicated
	# indexes are required (verified with EXPLAIN: seq scan -> index scan).
	for my $spec ( [ 'job', 'ed_idjob' ], [ 'dtlot', 'ed_dtlot' ] ) {
		my ( $sfx, $col ) = @$spec;
		$sql = "create index if not exists ${idx}_$sfx on $table ($col);";
		&logger( 7, $sql );
		_db_do_ddl( $dbh, $sql ) or &logger( 4, $dbh->errstr );
	}

}

our @AGREGE_COLS = (
	[ 'ed_source',      'varchar2(128)' ],           # input stream of this document
	[ 'ed_chanel_out',  'varchar2(32)' ],            # distribution/output channel
	[ 'ed_refiddoc',    'varchar2(25) not null' ],   # id in the document repository
	[ 'ed_idproduct',   'varchar2(8)' ],             # product id
	[ 'ed_dtedtion',    'varchar2(8) not null' ],    # edition date, the one printed on the document
	[ 'ed_cntd_idldoc', 'integer not null' ],        # distinct count of document ids
	[ 'ed_cnt_idseqpg', 'integer not null' ]
	,    # count of page sequence [doc] within the page-layout batch
	[ 'ed_dtlot', 'varchar2(10)' ],             # creation date of the mailing batch
	[ 'ed_idlot', 'varchar2(8)' ],              # batch id
	[ 'ed_idjob', 'varchar2(25) not null' ],    # job id
	[ 'ed_tstamp', 'varchar2(14) not null'
	]    # timestamp of event # TODO see how upgrade handles differing field counts

);

sub create_table_AGREGE {
	my ($dbh) = @_;
	my $table = "edtk_agrege";

	my $sql = "create table if not exists $table ("
		. join( ', ', map { "$$_[0] $$_[1]" } @AGREGE_COLS ) . " )";
	$sql .= _db_engine_clause($dbh);
	&logger( 7, $sql );

	_db_do_ddl( $dbh, $sql ) or &logger( 4, $dbh->errstr );

	#	my $idx = "ix_".$table."_".$VERSION_TXT;
	my $idx = "ix_" . $table;
	$sql = "create index if not exists $idx on $table "
		. " (ed_source, ed_chanel_out, ed_refiddoc, ed_idproduct, ed_dtedtion, ed_dtlot, ed_idlot);";
	&logger( 7, $sql );
	_db_do_ddl( $dbh, $sql ) or &logger( 4, $dbh->errstr );

}

sub create_table_PARA {
	my $dbh   = shift;
	my $table = "edtk_test_para";

	my $sql = "create table if not exists $table ";
	$sql .= "( ed_para_refiddoc varchar2(20) not null";
	$sql .= ", ed_para_corp varchar2(8) not null";                  # entity related to the document
	$sql .= ", ed_id       integer unique";                         #
	$sql .= ", ed_tstamp   varchar2(14) not null";                  # timestamp of event
	$sql .= ", ed_textbloc varchar2(512)";
	$sql .= ", primary key (ed_para_refiddoc, ed_para_corp, ed_id)";
	$sql .= " )";
	$sql .= _db_engine_clause($dbh);
	&logger( 7, $sql );

	_db_do_ddl( $dbh, $sql ) or &logger( 4, $dbh->errstr );
}

sub create_table_DATAGROUPS {
	my $dbh   = shift;
	my $table = "edtk_test_datagroups";

	my $sql = "create table if not exists $table ";
	$sql .= "( ed_dgps_refiddoc varchar2(20) not null";
	$sql .= ", ed_id   integer not null";
	$sql .= ", ed_data varchar2(64)";
	$sql .= " )";
	$sql .= _db_engine_clause($dbh);

	&logger( 7, $sql );

	_db_do_ddl( $dbh, $sql ) or die &logger( -1, $dbh->errstr );

	#	my $idx = "ix_".$table."_".$VERSION_TXT;
	my $idx = "ix_" . $table;
	$sql = "create index if not exists $idx on $table " . " (ed_dgps_refiddoc, ed_id);";
	&logger( 7, $sql );
	_db_do_ddl( $dbh, $sql ) or &logger( 4, $dbh->errstr );

}

sub create_table_ACQUIT {
	my $dbh   = shift;
	my $table = "edtk_acq";

	my $sql = "create table if not exists $table ";
	$sql .= "( ed_seqlot  varchar2(7)  not null"
		; # mailing batch id (sub-batch) update edtk_acq set ed_seqlot = substr('1'|| ed_seqlot,-7);
	$sql .= ", ed_lotname varchar2(16) not null";    #
	$sql .= ", ed_dtpost  varchar2(8)  not null";    # mailing-out date
	$sql .= ", ed_dtprint varchar2(8)";              # print date
	$sql .= ", ed_nbfaces integer   	not null"
		;    # number of sides of the batch (accounting sides, including blank recto/verso sides)
	$sql .= ", ed_nbplis  integer 		not null";    # number of documents in the folded item
	$sql .= ", ed_dtpost2 varchar2(8)";           # mailing-out date
	$sql .= ", ed_dtcheck varchar2(8)";           # check date
	$sql .= ", ed_status  varchar2(4)";           # check status
	$sql .= ", primary key (ed_seqlot, ed_lotname, ed_dtpost)";
	$sql .= " )";
	$sql .= _db_engine_clause($dbh);

	&logger( 7, $sql );

	_db_do_ddl( $dbh, $sql ) or &logger( 4, $dbh->errstr );
}

# Acquittal, step 1 (D-S53): stamp the mailing-out date and the acknowledgement
# status on the indexed items the acknowledgement line refers to. The batch id,
# the folded-item number and the recipient id select the rows; the reception
# year disambiguates batches of the same number across years.
sub _acquit_table_INDEX {
	my ( $dbh, $data, $table ) = @_;
	my ($pli)  = ( ( $data->[ACQ_FIELD_PLI] // '' ) =~ m/_(\d*)\z/ );
	my $lot    = $data->[ACQ_FIELD_LOT];
	my $annee  = substr( $data->[ACQ_FIELD_DTLOT], 0, 4 );
	my $exped  = substr( $data->[ACQ_FIELD_EXPED], 0, 8 );
	my $iddest = $data->[ACQ_FIELD_IDDEST];
	my $status = $data->[ACQ_FIELD_STATUS];

	my $sql = "UPDATE $table SET ED_DTPOSTE=?, ED_STATUS=?"
		. " WHERE ED_SEQLOT=? AND ED_IDDEST=? AND SUBSTR(ED_DTLOT,1,4)=? AND ED_IDPLI=?";
	my $sth = $dbh->prepare($sql);
	$sth->execute( $exped, $status, $lot, $iddest, $annee, $pli )
		or &logger( 3, "acquit_index: update failed: " . $sth->errstr );
	if ( $sth->rows == 0 ) {
		&logger( 3,
			"acquit_index: no indexed item for lot $lot, id_dest $iddest, year $annee, item $pli" );
	}
	return 0;
}

# The document id of the acknowledged batch's first page: "idldoc_seqpg" with the
# page sequence padded to 7 digits. undef when the lookup finds nothing or the
# driver rejects the statement.
sub _acquit_docid {
	my ( $dbh, $table, $data ) = @_;
	return unless defined $table && length $table;
	my $lot    = $data->[ACQ_FIELD_LOT];
	my $annee  = substr( $data->[ACQ_FIELD_DTLOT], 0, 4 );
	my $exped  = substr( $data->[ACQ_FIELD_EXPED], 0, 8 );
	my $iddest = $data->[ACQ_FIELD_IDDEST];
	my $status = $data->[ACQ_FIELD_STATUS];

	# The fork built the id with a driver-specific concatenation and lpad(); the
	# page sequence is padded here in Perl instead (portable across the SGBDs).
	my $sql =
		  "SELECT ED_IDLDOC, ED_IDSEQPG FROM $table"
		. " WHERE ED_DTPOSTE=? AND ED_STATUS=? AND ED_SEQLOT=? AND ED_IDDEST=? AND SUBSTR(ED_DTLOT,1,4)=?"
		. " AND ED_IDSEQPG=(SELECT MIN(ED_IDSEQPG) FROM $table WHERE ED_STATUS=? AND ED_SEQLOT=? AND ED_IDDEST=?)";
	my $row = eval {
		my $sth = $dbh->prepare($sql);
		$sth->execute( $exped, $status, $lot, $iddest, $annee, $status, $lot, $iddest ) or return;
		$sth->fetchrow_arrayref();
	};
	return unless ref $row eq 'ARRAY' && defined $row->[0];
	my $seqpg = defined $row->[1] ? $row->[1] + 0 : 0;
	return sprintf( '%s_%07d', $row->[0], $seqpg );
}

# Acquittal, step 2 (D-S53, D24): hand the acknowledged document to the callable
# named in EDTK_ACQUIT_API ("Module::function", validated and loaded by
# oEdtk::Ext). The document id is the batch's first page; when the batch is not
# the weekly one the batch id is passed instead (the fork's fallback). An absent
# or failing callable is a log line, never fatal: the mainline default is no API
# acquittal, and user-specific variants live in oEUser.
sub _acquit_API {
	my ( $dbh, $data, $cfg ) = @_;
	my $name = $cfg->{'EDTK_ACQUIT_API'};
	unless ( defined $name && length $name ) {
		&logger( 5, "acquit_api: EDTK_ACQUIT_API is not set, no API acquittal" );
		return 0;
	}

	my $exped = substr( $data->[ACQ_FIELD_EXPED], 0, 8 );
	my $docid = _acquit_docid( $dbh, $cfg->{'EDTK_DBI_OUTMNGR'}, $data );
	$docid = $data->[ACQ_FIELD_LOT] unless defined $docid;

	require oEdtk::Ext;
	eval { oEdtk::Ext::call_named_callable( $cfg, 'EDTK_ACQUIT_API', $docid, $exped, $cfg ) };
	&logger( 3, "acquit_api: callable '$name' failed: $@" ) if $@;
	return 0;
}

our @INDEX_COLS = (

	#	NB : " primary key (ed_idldoc, ed_seqdoc, ed_idseqpg, ed_idjob)"

	# INDEX COMPOSITION SECTION
	[ 'ed_refiddoc', 'varchar2(25) not null' ],    # id in the document repository
	[ 'ed_idldoc',   'varchar2(36) not null' ]
	,    # document id within the page-layout batch ed_sngl_id widened to 36
	[ 'ed_idseqpg', 'integer not null' ],  # page sequence number [doc] within the page-layout batch
	[ 'ed_seqdoc',  'integer not null' ],  # document sequence number within the batch
	[ 'ed_idjob',   'varchar2(25) not null' ],    # Job id

	# SECTION DOCUMENT
	[ 'ed_dtedtion', 'varchar2(8) not null' ],    # edition date, the one printed on the document
	[ 'ed_cpdest',   'varchar2(10)' ],            # recipient postal code
	[ 'ed_villdest', 'varchar2(38)' ],            # recipient city
	[ 'ed_iddest',   'varchar2(25)' ],            # recipient id in the management system
	[ 'ed_nomdest',  'varchar2(38)' ],            # recipient name
	[ 'ed_idemet',   'varchar2(10)' ],            # sender id
	[ 'ed_typprod',  'varchar(16)' ],             # production type associated with the batch
	[ 'ed_portadr',  'char(1)' ],                 # flag: document carries an address
	[ 'ed_adrln1',   'varchar2(38)' ],            # address line 1
	[ 'ed_cleged1',  'varchar2(32)' ],            # archiving system key
	[ 'ed_adrln2',   'varchar2(38)' ],            # address line 2
	[ 'ed_cleged2',  'varchar2(20)' ],            # archiving system key
	[ 'ed_adrln3',   'varchar2(38)' ],            # address line 3
	[ 'ed_cleged3',  'varchar2(20)' ],            # archiving system key
	[ 'ed_adrln4',   'varchar2(38)' ],            # address line 4
	[ 'ed_cleged4',  'varchar2(20)' ],            # archiving system key
	[ 'ed_adrln5',   'varchar2(38)' ],            # address line 5
	[ 'ed_corp',     'varchar2(8) not null' ],    # issuing entity of the page
	[ 'ed_doclib',   'varchar2(32)' ],            # merge library associated with the page
	[ 'ed_refimp',   'varchar2(16)' ],            # pre-printed, printed or insert reference
	[ 'ed_adrln6',   'varchar2(38)' ],            # address line 6
	[ 'ed_source',   'varchar2(8) not null' ],    # index source or ed_corp entity
	[ 'ed_owner',    'varchar2(10)' ],    # document owner (used in document management / archiving)
	[ 'ed_host',     'varchar2(32)' ],    # hostname of the machine this entry came from
	[ 'ed_ididx',    'varchar2(8) ' ],    # index id
	[ 'ed_catdoc',   'char(1)' ],         # document category
	[ 'ed_codrupt',  'varchar2(8)' ],     # burst forcing code

	# INDEX BATCHING SECTION
	[ 'ed_idlot',      'varchar2(8)' ],     # batch id
	[ 'ed_seqlot',     'varchar2(7)' ],     # mailing batch id (sub-batch)
	[ 'ed_dtlot',      'varchar2(10)' ],    # creation date of the mailing batch
	[ 'ed_idfiliere',  'varchar2(5)' ],     # production line id
	[ 'ed_seqpgdoc',   'integer' ],         # page sequence number within the document
	[ 'ed_nbpgdoc',    'integer' ],         # number of pages (sides) of the document
	[ 'ed_poidsunit',  'integer' ],         # weight of the print or insert in mg
	[ 'ed_nbenc',      'integer' ],         # number of inserts in the doc
	[ 'ed_encpds',     'integer' ],         # weight of the inserts in the doc
	[ 'ed_bac_insert', 'integer' ],         # Tray or insert call

	# INDEX EDITION SECTION
	[ 'ed_typed',   'char(1)' ],            # edition type (black / full color)
	[ 'ed_modedi',  'char(1)' ],            # edition mode (simplex / duplex) => recto / verso
	[ 'ed_formatp', 'varchar2(2)' ],        # paper format (a4 / a3 ...)
	[ 'ed_pgorien', 'varchar2(2)' ]
	,    # edition orientation (portrait / reverseportrait / landscape / reverse landscape)
	[ 'ed_formflux', 'varchar2(3)' ],    # edition stream format (afp / pdf / ...)

	#	['ed_formdef',	'varchar2(8)'],			# formdef afp
	#	['ed_pagedef',	'varchar2(8)'],			# pagedef afp
	#	['ed_forms',	'varchar2(8)'],			# Forms

	# INDEX FOLDING SECTION
	[ 'ed_idpli',       'integer' ],         # folded-item id
	[ 'ed_nbdocpli',    'integer' ],         # number of documents in the folded item
	[ 'ed_numpgpli',    'integer' ],         # page (side) number in the folded item
	[ 'ed_nbpgpli',     'integer' ],         # number of pages (sides) of the folded item
	[ 'ed_nbfpli',      'integer' ],         # number of sheets of the folded item
	[ 'ed_listerefenc', 'varchar2(64)' ],    # list of inserts in the folded item
	[ 'ed_pdspli',      'integer' ],         # weight of the folded item in mg
	[ 'ed_typobj',      'char(1)' ],         # object type in the folded item	xxxxxx  conserver ?
	[ 'ed_status',      'varchar2(8)' ]
	,    # batching status (mailing-out date or status depending on the version)
	[ 'ed_dtposte', 'varchar2(8)' ]
	,    # to remove : batching status (mailing-out date or status depending on the version)

	# ADD
	[ 'ed_workflow',   'varchar2(32)' ],    # workflow on which the metadata was produced	++ new ++
	[ 'ed_chanel_out', 'varchar2(32)' ],    # distribution/output channel						++ new ++
	[ 'ed_country',    'varchar2(5)' ],     # recipient country code							++ new ++
	[ 'ed_idcontract', 'varchar2(16)' ],    # contract id							++ new ++
	[ 'ed_idproduct',  'varchar2(8)' ],     # Product id							++ NEW ++
		# ECM SECTION (fork F): document-management columns the standard schema lacked.
		# Sizes = max(F, M); EDTK_ACQMGENTECH itself is carried by the oEUser extension.
	[ 'ed_typdoc',  'varchar2(4)' ],     # document type (ECM)
	[ 'ed_idcoll',  'varchar2(16)' ],    # collection id (ECM)
	[ 'ed_idmnt',   'varchar2(10)' ],    # archive id from the extension (annexe E)
	[ 'ed_cleged5', 'varchar2(20)' ],    # archiving system key (ECM)
	[ 'ed_idpmsir', 'varchar2(18)' ]     # PM/SIR archive id (ECM)

);

sub create_table_OUTMNGR {
	my ( $dbh, $table, %opt ) = @_;

	# The primary key carries ed_idjob in M's default mode (EDTK_DB_PK_IDJOB=yes).
	# Option pk_idjob => 0 builds the F-shaped key without it (D16).
	my $pk_idjob = exists $opt{pk_idjob} ? $opt{pk_idjob} : _pk_idjob_default();
	my @pk       = qw(ed_idldoc ed_seqdoc ed_idseqpg);
	push @pk, 'ed_idjob' if $pk_idjob;

	my $sql =
		  "create table if not exists $table ("
		. join( ', ', map { "$$_[0] $$_[1]" } @INDEX_COLS ) . ", "
		. " primary key ("
		. join( ', ', @pk ) . ")" . " )";
	$sql .= _db_engine_clause($dbh);
	&logger( 7, $sql );

	_db_do_ddl( $dbh, $sql ) or &logger( 4, $dbh->errstr );

	#	my $idx = "ix_".$table."_".$VERSION_TXT;
	my $idx = "ix_" . $table;
	$sql = "create index if not exists $idx on $table " . " (ed_dtedtion, ed_seqlot, ed_typprod);";
	&logger( 7, $sql );
	_db_do_ddl( $dbh, $sql ) or &logger( 4, $dbh->errstr );
}

sub create_lot_sequence {

	# USED FOR BATCH CREATION IN Outmngr.pm
	my $dbh = shift;

	if ( _db_check_driver_name($dbh) eq "SQLite" ) {

		# SQLite has no SEQUENCE object: emulate EDTK_IDLOT with a one-row counter
		# table cycling 0..999 (read back by _get_seqlot in Outmngr.pm). MySQL uses
		# its own AUTO_INCREMENT emulation and is skipped by the caller.
		_db_do_ddl( $dbh, "create table if not exists edtk_idlot_seq (id_val integer not null)" )
			or &logger( 4, $dbh->errstr );
		do {
			local $dbh->{PrintError} = 0;
			$dbh->do(
"insert into edtk_idlot_seq (id_val) select 0 where not exists (select 1 from edtk_idlot_seq)"
			);
			}
			or &logger( 4, $dbh->errstr );
		return 1;
	}

	# method valid for most DBMS except MySQL
	my $sql = "create sequence if not exists edtk_idlot minvalue 0 maxvalue 999 cycle";
	_db_do_ddl( $dbh, $sql ) or &logger( 4, $dbh->errstr );
	return 1;
}

# ============================================================
# Fork-F API delegates. T is a superset of F (PLAN, annexe E): the names F
# exported are kept, wired to T's own implementation.
# ============================================================

# F: create_SCHEMA( $dbh, $table, $maxkeys ) built the whole F schema.
# T: the canonical schema_Create, plus the TRACKING table F also created.
sub create_SCHEMA {
	my ($dbh) = @_;
	schema_Create($dbh);
	my $cfg = eval { config_read('EDTK_DB') };
	create_table_TRACKING( $dbh, $cfg->{'EDTK_DBI_TRACKING'}, $cfg->{'EDTK_MAX_USER_KEY'} )
		if $cfg && $cfg->{'EDTK_DBI_TRACKING'};
	return 0;
}

# F: create_table_INDEX( $dbh, $table ) created the page-layout index table.
# T: that table is create_table_OUTMNGR; its key follows EDTK_DB_PK_IDJOB (D16).
sub create_table_INDEX {
	my ( $dbh, $table ) = @_;
	create_table_OUTMNGR( $dbh, $table );
	return 0;
}

# F: get_columns_names( $dbh, $table ) read all_tab_columns (Oracle only).
# T: read the driver-neutral column catalogue; names keep the catalogue's case.
sub get_columns_names {
	my ( $dbh, $table ) = @_;
	return () unless defined $dbh && defined $table;

	my @cols;
	my $sth = $dbh->column_info( undef, undef, $table, undef );
	if ( defined $sth ) {
		while ( my $row = $sth->fetchrow_hashref ) {
			my $name = $row->{COLUMN_NAME};
			push @cols, $name if defined $name;
		}
	}

	# Fallback for drivers without column_info: the statement's NAME list.
	unless (@cols) {
		my $sel = eval { $dbh->prepare("select * from $table where 1=0") };
		if ($sel) {
			$sel->execute();
			@cols = @{ $sel->{NAME} // [] };
		}
	}
	return @cols;
}

# Default of the primary-key mode, from EDTK_DB_PK_IDJOB (D16): 'yes' gives M's
# shape (ed_idjob in the key) unless the configuration says otherwise.
sub _pk_idjob_default {
	my $cfg = eval { config_read('EDTK_DB') };
	return 1 unless $cfg && defined $cfg->{'EDTK_DB_PK_IDJOB'};
	my $v = lc( $cfg->{'EDTK_DB_PK_IDJOB'} );
	return ( $v eq 'no' || $v eq '0' || $v eq 'false' || $v eq 'n' ) ? 0 : 1;
}

# ============================================================
# Optional schema extension (oEUser::Schema, D19). The module has a fixed name,
# carries data only, and is absent from the standard distribution; when it is
# not installed only the standard schema is built.
# ============================================================

# Load and validate oEUser::Schema::extra(); an empty hashref when absent.
sub _schema_extra {
	require oEdtk::Ext;
	return {} unless oEdtk::Ext::require_optional('oEUser::Schema');
	my $extra = eval { oEUser::Schema::extra() };
	return {} unless ref $extra eq 'HASH' && %$extra;
	return _validate_schema_extra($extra);
}

# Validate the extension structure: identifiers and column types only.
sub _validate_schema_extra {
	my ($extra) = @_;
	my %types   = map { $_ => 1 } qw( VARCHAR2 VARCHAR CHAR INTEGER NUMBER DATE TIMESTAMP );
	my $tables  = $extra->{tables}  // {};
	my $columns = $extra->{columns} // {};

	for my $table ( keys %$tables ) {
		die "ERROR: oEUser::Schema::extra(): invalid table name '$table'\n"
			unless $table =~ /\A[A-Z][A-Z0-9_]*\z/;

		my $defs = $columns->{$table};
		die "ERROR: oEUser::Schema::extra(): no columns for table '$table'\n"
			unless ref $defs eq 'ARRAY' && @$defs;

		for my $col (@$defs) {
			my $name = $col->{name} // '';
			die "ERROR: oEUser::Schema::extra(): invalid column name '$name' in '$table'\n"
				unless $name =~ /\A[A-Z][A-Z0-9_]*\z/;
			my $type = uc( $col->{type} // '' );
			die "ERROR: oEUser::Schema::extra(): invalid type '$type' for $table.$name\n"
				unless $types{$type};
		}

		my $pk = $tables->{$table}{primary_key} // [];
		die "ERROR: oEUser::Schema::extra(): primary_key of '$table' must be a list\n"
			unless ref $pk eq 'ARRAY';
	}
	return $extra;
}

# Build the CREATE TABLE of one extension table from its definition.
sub _create_table_extra {
	my ( $dbh, $table, $spec, $defs ) = @_;

	my @cols = map {
		my $type = uc( $_->{type} );
		$type .= "(" . $_->{size} . ")" if defined $_->{size} && $_->{size} ne '';
		my $null = $_->{nullable} ? '' : ' not null';
		"$_->{name} $type$null";
	} @$defs;

	my $sql = "create table if not exists $table ( " . join( ', ', @cols );
	my $pk  = $spec->{primary_key};
	$sql .= ", primary key ( " . join( ', ', @$pk ) . " )" if ref $pk eq 'ARRAY' && @$pk;
	$sql .= " )";
	$sql .= _db_engine_clause($dbh);
	&logger( 7, $sql );
	_db_do_ddl( $dbh, $sql ) or &logger( 4, $dbh->errstr );
	return 1;
}

# Apply every table of the extension; returns the number of tables applied.
sub _schema_create_extra {
	my ($dbh) = @_;
	my $extra = _schema_extra();
	for my $table ( sort keys %{ $extra->{tables} // {} } ) {
		_create_table_extra( $dbh, $table, $extra->{tables}{$table}, $extra->{columns}{$table} );
	}
	return scalar keys %{ $extra->{tables} // {} };
}

# F: create_table_ACQMGENTECH( $dbh, $table ). The acquisition table belongs to
# the oEUser::Schema extension (D19), which is optional: the extension is loaded
# through an eval (see _schema_extra). When it is not installed -- or does not
# define the table -- there is nothing to create and the call is a silent no-op,
# so oEdtk keeps running standalone without oEUser. Fixed arity: the table name
# defaults to EDTK_ACQMGENTECH.
sub create_table_ACQMGENTECH {
	my ( $dbh, $table ) = @_;
	$table //= 'EDTK_ACQMGENTECH';

	my $extra = _schema_extra();
	my $spec  = $extra->{tables}{$table};
	my $defs  = $extra->{columns}{$table};
	return 0 unless $spec && $defs;

	_create_table_extra( $dbh, $table, $spec, $defs );
	return 0;
}

# ============================================================
# Schema-level detection and history (S51a, PLAN). schema_Detect inspects a live
# base through the driver-neutral oEdtk::SchemaScan and tells which of the three
# documented shapes it shows -- F (the fork), M (mainline 2.1109) or T (the
# integrated target) -- or 'mixte' when the observed features match no single
# one. It reads the data dictionary only and writes nothing; the report is meant
# to be printed by an operator before any migration (--check-only).
#
# Discriminators, on the index table named EDTK_DBI_OUTMNGR:
#   * whether the primary key carries ed_idjob (D16);
#   * whether the ECM columns the fork added are present (S50);
#   * the declared width of ed_idldoc (F=17, M=25, T=36, D9).
# ============================================================

# The ECM columns the fork appended to the index table, absent from M.
our @SCHEMA_ECM_COLS = qw( ed_typdoc ed_idcoll ed_idmnt ed_cleged5 ed_idpmsir );

# Document-id widths of the three shapes (D9).
use constant SCHEMA_IDLDOC_F => 17;
use constant SCHEMA_IDLDOC_M => 25;
use constant SCHEMA_IDLDOC_T => 36;

# The three documented shapes, as the feature set each one shows.
sub _schema_level_defs {
	return (
		F => { idjob_in_key => 0, ecm => 0, idldoc_min => 0, idldoc_max => SCHEMA_IDLDOC_M },
		M => {
			idjob_in_key => 1,
			ecm          => 0,
			idldoc_min   => SCHEMA_IDLDOC_M,
			idldoc_max   => SCHEMA_IDLDOC_M
		},
		T => {
			idjob_in_key => 1,
			ecm          => scalar @SCHEMA_ECM_COLS,
			idldoc_min   => SCHEMA_IDLDOC_T,
			idldoc_max   => 9999
		},
	);
}

# The discriminators of one table, read off a SchemaScan result.
sub _schema_features {
	my ( $scan, $table ) = @_;
	my $t = $scan->{tables}{$table};
	return unless $t;

	my @cols = @{ $t->{columns} // [] };
	my %col  = map { lc( $_->{name} ) => $_ } @cols;
	my @key  = map { lc $_->{name} } sort { $a->{pk} <=> $b->{pk} } grep { $_->{pk} } @cols;

	return {
		table        => $table,
		key          => \@key,
		idjob_in_key => ( grep { $_ eq 'ed_idjob' } @key ) ? 1 : 0,
		ecm          => scalar( grep { exists $col{$_} } @SCHEMA_ECM_COLS ),
		idldoc_size  => ( $col{ed_idldoc} ? $col{ed_idldoc}{size} : undef ),
	};
}

# Diff one table's live columns against a [name, ddl type] reference list.
# Returns ( \@missing, \@shrink ). An absent table makes every reference column
# missing. READ-ONLY: it works off the caller's SchemaScan result, writes nothing.
sub _schema_col_diff {
	my ( $scan, $table, $cols ) = @_;
	my ( @missing, @shrink );
	my $t    = $table ? $scan->{tables}{$table}                                 : undef;
	my %live = $t     ? map { lc( $_->{name} ) => $_ } @{ $t->{columns} // [] } : ();
	for my $c (@$cols) {
		my ( $name, $type ) = @$c;
		my $n = lc $name;
		unless ( $live{$n} ) {
			push @missing, $name;
			next;
		}
		my $want = oEdtk::SchemaScan::size_from_type($type);
		my $have = $live{$n}{size};
		push @shrink, "$name ($have < $want)"
			if defined $want && defined $have && $have < $want;
	}
	return ( \@missing, \@shrink );
}

# Features, level and the index-table column diff, all from a single scan. An
# absent index table keeps empty missing/shrink, as schema_Detect always did.
sub _schema_assess {
	my ( $scan, $index_table ) = @_;
	my $f     = _schema_features( $scan, $index_table );
	my $level = _schema_classify($f);
	my ( $missing, $shrink ) =
		$f ? _schema_col_diff( $scan, $index_table, \@INDEX_COLS ) : ( [], [] );
	return ( $f, $level, $missing, $shrink );
}

# Which documented shape a feature set matches; 'mixte' when none does.
sub _schema_classify {
	my ($f) = @_;
	return 'absente' unless $f;
	my %def = _schema_level_defs();
	for my $lvl ( sort keys %def ) {
		my $d = $def{$lvl};
		next unless $f->{idjob_in_key} == $d->{idjob_in_key};
		next unless $f->{ecm} == $d->{ecm};
		next unless defined $f->{idldoc_size};
		return $lvl
			if $f->{idldoc_size} >= $d->{idldoc_min} && $f->{idldoc_size} <= $d->{idldoc_max};
	}
	return 'mixte';
}

# Build the readable report from a schema_Detect result.
sub _schema_report_lines {
	my (%p) = @_;
	my @lines;
	push @lines, "schema level: $p{level}";
	push @lines, "driver: $p{driver}";
	push @lines, "index table: $p{table}";
	if ( my $f = $p{features} ) {
		push @lines, "  primary key: " . join( ', ', @{ $f->{key} } );
		push @lines, "  ed_idjob in key: $f->{idjob_in_key}";
		push @lines, "  ECM columns present: $f->{ecm}/" . scalar @SCHEMA_ECM_COLS;
		push @lines,
			"  ed_idldoc width: " . ( defined $f->{idldoc_size} ? $f->{idldoc_size} : 'n/a' );
	}
	push @lines, "missing vs T: " .  ( @{ $p{missing} } ? join( ', ', @{ $p{missing} } ) : 'none' );
	push @lines, "narrowed vs T: " . ( @{ $p{shrink} }  ? join( ', ', @{ $p{shrink} } )  : 'none' );
	push @lines, "verdict: " .       ( $p{ok} ? 'conforms to T' : 'does not conform to T' );
	return \@lines;
}

# Inspect a live base and report its schema level against the T definitions.
# Options: index_table => 'name' (defaults to EDTK_DBI_OUTMNGR from the config).
# READ-ONLY: every statement is a SELECT / PRAGMA; nothing is written.
sub schema_Detect {
	my ( $dbh, %opt ) = @_;
	require oEdtk::SchemaScan;

	my $cfg         = eval { config_read('EDTK_DB') } || {};
	my $index_table = $opt{index_table} // $cfg->{'EDTK_DBI_OUTMNGR'} // 'edtk_outmngr';

	my $scan = oEdtk::SchemaScan::scan_schema($dbh);
	my ( $f, $level, $missing, $shrink ) = _schema_assess( $scan, $index_table );

	my $ok     = ( $level eq 'T' && !@$missing && !@$shrink ) ? 1 : 0;
	my $report = _schema_report_lines(
		level    => $level,
		driver   => $scan->{driver},
		table    => $index_table,
		features => $f,
		missing  => $missing,
		shrink   => $shrink,
		ok       => $ok,
	);

	return {
		driver      => $scan->{driver},
		index_table => $index_table,
		level       => $level,
		features    => $f,
		missing     => $missing,
		shrink      => $shrink,
		ok          => $ok,
		report      => $report,
	};
}

# The report of schema_Detect as printable text.
sub schema_Report {
	my ($res) = @_;
	return join( "\n", @{ $res->{report} // [] } ) . "\n";
}

# READ-ONLY assessment of the index table AND the tracking table against T.
# Returns a probe hash; stale is set when either table does not conform.
sub _schema_stale_probe {
	my ( $scan, $cfg, $index_table, $tracking_table ) = @_;

	my ( $f, $level, $i_missing, $i_shrink ) = _schema_assess( $scan, $index_table );

	my ( $t_missing, $t_shrink ) = ( [], [] );
	if ( defined $tracking_table && length $tracking_table ) {
		( $t_missing, $t_shrink ) = _schema_col_diff( $scan, $tracking_table, \@TRACKER_COLS );
	}

	my $index_ok = ( $level eq 'T' && !@$i_missing && !@$i_shrink ) ? 1 : 0;
	my $track_ok = ( !@$t_missing  && !@$t_shrink ) ? 1 : 0;

	return {
		stale          => ( $index_ok && $track_ok ) ? 0 : 1,
		level          => $level,
		index_table    => $index_table,
		tracking_table => $tracking_table,
		index_missing  => $i_missing,
		index_shrink   => $i_shrink,
		track_missing  => $t_missing,
		track_shrink   => $t_shrink,
		cfg            => $cfg,
	};
}

# Render a ( missing, narrowed ) pair as "missing=a,b narrowed=x (y<z)".
sub _schema_diff_text {
	my ( $missing, $shrink ) = @_;
	return
		  '(missing='
		. ( @$missing ? join( ',', @$missing ) : 'none' )
		. ' narrowed='
		. ( @$shrink ? join( ',', @$shrink ) : 'none' ) . ')';
}

# The remediation hint. The password VALUE is never printed.
sub _schema_fix_command {
	my ($cfg) = @_;
	my $dsn = $cfg->{EDTK_DBI_DSN} // '';
	$dsn =~ s/(pass(word)?=)[^;]*/$1***/gi;    # mask an inline secret, if any
	$dsn = '<dsn>' unless length $dsn;
	my $user = $cfg->{EDTK_DBI_DSN_USER};
	my $cmd  = "perl lib/db_migrate.pl --check-only --dsn $dsn ; then";
	$cmd .= " perl lib/db_migrate.pl --additive --dsn $dsn";
	$cmd .= " --user $user" if defined $user && length $user;
	$cmd .= ' --pass <pass>';
	return $cmd;
}

# The one-line operator message for a stale schema (see _schema_stale_probe).
sub _schema_stale_message {
	my ($p) = @_;
	my @parts = ("database schema is STALE vs T (level=$p->{level})");
	push @parts, "$p->{index_table} " . _schema_diff_text( $p->{index_missing}, $p->{index_shrink} )
		if ( @{ $p->{index_missing} } || @{ $p->{index_shrink} } );
	push @parts,
		"$p->{tracking_table} " . _schema_diff_text( $p->{track_missing}, $p->{track_shrink} )
		if ( ( defined $p->{tracking_table} && length $p->{tracking_table} )
		&& ( @{ $p->{track_missing} } || @{ $p->{track_shrink} } ) );
	push @parts, 'to fix: ' . _schema_fix_command( $p->{cfg} );
	return join( '; ', @parts );
}

# Report a stale schema ONCE, READ-ONLY, never fatal. Options: cfg, index_table,
# tracking_table (all default to the EDTK_DB configuration). Returns the probe
# when a warning was emitted, undef otherwise. It never writes to the database.
sub schema_StaleWarning {
	my ( $dbh, %opt ) = @_;
	return unless $dbh;

	my $cfg            = $opt{cfg} || ( eval { config_read('EDTK_DB') } || {} );
	my $index_table    = $opt{index_table}    // $cfg->{'EDTK_DBI_OUTMNGR'} // 'edtk_outmngr';
	my $tracking_table = $opt{tracking_table} // $cfg->{'EDTK_DBI_TRACKING'};

	# A warn()/die() below must not re-enter the oEdtk::Tracking __WARN__/__DIE__
	# handlers (they would call track() recursively). Neutralize them for this
	# call only; they are restored on return, so Halt-tracking still works.
	return do {
		local $SIG{__WARN__} = 'DEFAULT';
		local $SIG{__DIE__}  = 'DEFAULT';
		eval {
			require oEdtk::SchemaScan;
			my $scan = oEdtk::SchemaScan::scan_schema($dbh);
			my $p    = _schema_stale_probe( $scan, $cfg, $index_table, $tracking_table );
			return unless $p->{stale};
			&logger( 3, _schema_stale_message($p) );
			return $p;
		};
	};
}

# Additive detection / migration history (S51a). Kept out of schema_Create on
# purpose: adding it there would change the T golden schema.
sub create_table_SCHEMA_HISTORY {
	my ( $dbh, $table ) = @_;
	$table //= 'edtk_schema_history';

	my $sql = "create table if not exists $table ";
	$sql .= "( ed_hist_date varchar2(14) not null";    # detection / migration timestamp
	$sql .= ", ed_hist_from varchar2(8)";              # source level (F, M, T, mixte)
	$sql .= ", ed_hist_to varchar2(8)";                # target level
	$sql .= ", ed_hist_mode varchar2(16)";             # check / historize / additive
	$sql .= ", ed_hist_tool varchar2(32)";             # tool and version
	$sql .= ", ed_hist_counts varchar2(255)";          # row counts, "k=v;k=v"
	$sql .= " )";
	$sql .= _db_engine_clause($dbh);
	&logger( 7, $sql );

	_db_do_ddl( $dbh, $sql ) or &logger( 4, $dbh->errstr );
	return 0;
}

# Append one history row. Named parameters: date, from, to, mode, tool and
# counts (a hash ref, stored as a compact "k=v;k=v" string).
sub schema_History_add {
	my ( $dbh, %p ) = @_;
	my $table = $p{table} // 'edtk_schema_history';
	create_table_SCHEMA_HISTORY( $dbh, $table );

	my $date = $p{date} // strftime( '%Y%m%d%H%M%S', localtime );
	my $tool = $p{tool} // __PACKAGE__ . " $VERSION";

	my $counts = $p{counts};
	my $ctext  = '';
	if ( ref $counts eq 'HASH' ) {
		$ctext = join( ';',
			map { "$_=" . ( defined $counts->{$_} ? $counts->{$_} : '' ) } sort keys %$counts );
	}
	elsif ( defined $counts ) {
		$ctext = "$counts";
	}
	$ctext = substr( $ctext, 0, 255 );

	local $dbh->{PrintError} = 0;
	my $ok = $dbh->do(
		"insert into $table "
			. "(ed_hist_date,ed_hist_from,ed_hist_to,ed_hist_mode,ed_hist_tool,ed_hist_counts) "
			. "values (?,?,?,?,?,?)",
		undef, $date, $p{from}, $p{to}, $p{mode}, $tool, $ctext
	);
	&logger( 4, $dbh->errstr ) unless $ok;
	return $ok ? 1 : 0;
}

# ============================================================
# Update by historisation (S51b, PLAN annexe D, decision D17). The recommended
# procedure: build a T-shaped target, copy the data by NAMED columns, validate by
# counts and checksums, switch over, and KEEP the old schema as history. The
# service schema is never modified in place; nothing is ever dropped.
#
# Portable algorithm (mirrors schema_Upgrade's timestamped rename):
#   1. rename every live table to <table><HIST_SEP><stamp> (kept, not dropped);
#   2. build the T target under the original names (schema_Create + extension);
#   3. copy the common columns by name, then validate (count + md5 checksum);
#   4. give the kept history its indexes back under non-colliding names;
#   5. keep the stamped tables and append one EDTK_SCHEMA_HISTORY row.
# Atomicity: on a driver with transactional DDL (SQLite, PostgreSQL) the whole
# run is one transaction, so any failure rolls the service schema back. On the
# others (MariaDB, MySQL, Oracle) the captured renames are inverted explicitly.
# Nothing is written by schema_MigrationPlan (--check-only / --dry-run).
# ============================================================

use constant SCHEMA_HIST_SEP => '_hist_';

# The ordered, de-duplicated list of tables the migration covers: the fixed base
# tables, the configuration-driven ones, the tracking table and any extension
# table. This is the same set schema_Create (plus create_table_TRACKING) builds.
sub schema_Manifest {
	my ($cfg) = @_;
	$cfg //= eval { config_read('EDTK_DB') } || {};

	my @fixed = qw( edtk_acq edtk_admin edtk_agrege edtk_filieres edtk_id edtk_lots
		edtk_refiddoc edtk_supports );
	my @cfg = grep { defined && length }
		map { $cfg->{$_} }
		qw( EDTK_DBI_OUTMNGR EDTK_DBI_OUTMNGR_STATS EDTK_DBI_DISTRIB EDTK_DBI_DISTRIB_STATS );
	my @track = grep { defined && length } ( $cfg->{'EDTK_DBI_TRACKING'} );
	my @ext   = sort keys %{ _schema_extra()->{tables} // {} };

	my %seen;
	return grep { !$seen{$_}++ } ( @fixed, @cfg, @track, @ext );
}

# Drivers whose DDL is transactional: a failure can roll the whole run back.
sub _schema_txn_ddl {
	my ($dbh) = @_;
	my $driver = _db_check_driver_name($dbh);
	return ( $driver eq 'SQLite' || $driver eq 'PostgreSQL' ) ? 1 : 0;
}

# Rename a table, driver-neutrally (MariaDB/MySQL use RENAME TABLE).
sub _schema_rename_table {
	my ( $dbh, $from, $to ) = @_;
	my $driver = _db_check_driver_name($dbh);
	my $sql =
		( $driver eq 'mysql' )
		? "rename table $from to $to"
		: "alter table $from rename to $to";
	&logger( 7, $sql );
	return _db_do_ddl( $dbh, $sql );
}

# A history name that is free: <table>_hist_<stamp>[_n] when taken.
sub _schema_hist_name {
	my ( $dbh, $table, $stamp ) = @_;
	my $base = $table . SCHEMA_HIST_SEP . $stamp;
	my $name = $base;
	my $n    = 1;
	$name = $base . '_' . $n++ while _table_exists( $dbh, $name );
	return $name;
}

# The secondary indexes of a table, as portable specs (name, unique, columns).
# Best effort: an unreadable catalogue (unsupported driver) yields none.
sub _schema_index_specs {
	my ( $dbh, $table ) = @_;
	require oEdtk::SchemaScan;
	my $scan = eval { oEdtk::SchemaScan::scan_schema($dbh) } or return [];
	my $t    = $scan->{tables}{$table}                       or return [];
	return [
		map  { { name => $_->{name}, unique => $_->{unique}, columns => $_->{columns} } }
		grep { $_->{name} !~ /^sqlite_autoindex_/ } @{ $t->{indexes} // [] }
	];
}

# On SQLite/PostgreSQL/Oracle index names are unique per schema, so after the
# rename the history table still owns the original names and the target's
# "CREATE INDEX IF NOT EXISTS" would be skipped. Drop the history's indexes to
# free the names. MariaDB/MySQL index names are table-scoped and never collide,
# so nothing is touched there.
sub _schema_release_indexes {
	my ( $dbh, $table, $specs ) = @_;
	return if _db_check_driver_name($dbh) eq 'mysql';
	for my $ix (@$specs) {
		eval { _db_do_ddl( $dbh, "drop index $ix->{name}" ) };
	}
	return;
}

# Recreate index specs on a table, appending $suffix to each name (empty to
# restore the original names). Best effort: never throws.
sub _schema_restore_indexes {
	my ( $dbh, $table, $specs, $suffix ) = @_;
	return if _db_check_driver_name($dbh) eq 'mysql';
	for my $ix (@$specs) {
		my $u    = $ix->{unique} ? 'unique ' : '';
		my $cols = join( ', ', @{ $ix->{columns} } );
		next unless length $cols;
		eval {
			_db_do_ddl( $dbh,
				"create ${u}index if not exists $ix->{name}$suffix on $table ( $cols )" );
		};
	}
	return;
}

# The ordered column names of a table (catalogue read).
sub _schema_columns {
	my ( $dbh, $table ) = @_;
	return get_columns_names( $dbh, $table );
}

# The primary-key columns of a table, in key order (lower-cased). Best effort:
# an unreadable catalogue yields none and the caller falls back to all columns.
sub _schema_key_columns {
	my ( $dbh, $table ) = @_;
	require oEdtk::SchemaScan;
	my $scan = eval { oEdtk::SchemaScan::scan_schema($dbh) } or return ();
	my $t    = $scan->{tables}{$table}                       or return ();
	return map { lc $_->{name} }
		sort { $a->{pk} <=> $b->{pk} } grep { $_->{pk} } @{ $t->{columns} // [] };
}

# The columns common to a source and a target, in the target's order. Returned
# as the target spelling so the INSERT list and the SELECT list agree.
sub _schema_common_columns {
	my ( $dbh, $source, $target ) = @_;
	my @src = _schema_columns( $dbh, $source );
	my %src = map { lc($_) => $_ } @src;
	return grep { exists $src{ lc($_) } } _schema_columns( $dbh, $target );
}

# INSERT ... SELECT with NAMED column lists (never positional).
sub _schema_copy_named {
	my ( $dbh, $source, $target, $cols ) = @_;
	my $list = join( ', ', @$cols );
	my $sql  = "insert into $target ( $list ) select $list from $source";
	&logger( 7, $sql );
	local $dbh->{PrintError} = 0;
	$dbh->do($sql);
	return defined $dbh->err ? 0 : 1;
}

# A driver-neutral md5 over a table's rows, projected on $cols and ordered by
# $order. Used to prove the copy preserved every value of the common columns.
sub _schema_checksum {
	my ( $dbh, $table, $cols, $order ) = @_;
	my $list = join( ', ', @$cols );
	my $sql  = "select $list from $table";
	$sql .= " order by " . join( ', ', @$order ) if @$order;
	my $sth = $dbh->prepare($sql);
	$sth->execute;
	my $md5 = Digest::MD5->new;
	while ( my @row = $sth->fetchrow_array ) {
		$md5->add( join( "\x1f", map { defined $_ ? $_ : "\x00" } @row ), "\n" );
	}
	return $md5->hexdigest;
}

# Build the T target once, in a throwaway in-memory SQLite base, to learn each
# table's columns and the DDL schema_Create emits. Best effort: {} on failure.
sub _schema_target_model {
	my ($cfg) = @_;
	$cfg //= eval { config_read('EDTK_DB') } || {};
	my %model;
	eval {
		my $m =
			DBI->connect( 'dbi:SQLite:dbname=:memory:', '', '',
			{ RaiseError => 1, PrintError => 0, AutoCommit => 1 } )
			or return;
		{
			local $m->{PrintError} = 0;
			eval { create_lot_sequence($m) };
			eval { schema_Create($m) };
			eval {
				create_table_TRACKING(
					$m,
					$cfg->{'EDTK_DBI_TRACKING'},
					$cfg->{'EDTK_MAX_USER_KEY'}
				);
			}
				if $cfg->{'EDTK_DBI_TRACKING'};
		}
		my $rows =
			$m->selectall_arrayref(
"select name, sql from sqlite_master where type='table' and name not like 'sqlite_%' order by name"
			);
		for my $r (@$rows) {
			my ( $name, $ddl ) = @$r;
			my @cols = map { lc } _schema_columns( $m, $name );
			$model{ lc $name } = { name => $name, columns => \@cols, ddl => $ddl };
		}
		$m->disconnect;
	};
	return \%model;
}

# Read-only plan for an update by historisation (--check-only / --dry-run). It
# reports the detected level, the per-table column sets and the copy SQL. It
# writes nothing: every statement it prepares is a SELECT / PRAGMA.
sub schema_MigrationPlan {
	my ( $dbh, %opt ) = @_;
	my $cfg      = eval { config_read('EDTK_DB') } || {};
	my $manifest = $opt{manifest} // [ schema_Manifest($cfg) ];
	my $model    = _schema_target_model($cfg);
	my $detect   = schema_Detect( $dbh, %opt );
	my $stamp    = $opt{stamp} // '<stamp>';

	my @tables;
	my @copy_sql;
	for my $t (@$manifest) {
		my $has    = _table_exists( $dbh, $t );
		my $target = $model->{ lc $t };
		my @tcols  = $target ? @{ $target->{columns} } : ();
		my ( $src, $rows ) = ( [], 0 );
		if ($has) {
			$src = [ map { lc } _schema_columns( $dbh, $t ) ];
			($rows) = $dbh->selectrow_array("select count(*) from $t");
		}
		my %s = map { $_ => 1 } @$src;
		my %d = map { $_ => 1 } @tcols;

		# Common columns in the target's order (lower-cased, name-matched).
		my @common    = grep { $s{$_} } @tcols;
		my @dropped   = grep { !$d{$_} } @$src;     # present in source, absent in T
		my @defaulted = grep { !$s{$_} } @tcols;    # absent in source, filled by T

		push @tables,
			{
			name      => $t,
			present   => ( $has ? 1 : 0 ),
			rows      => ( $rows + 0 ),
			common    => \@common,
			dropped   => \@dropped,
			defaulted => \@defaulted,
			};
		if ( $has && @common ) {
			my $list = join( ', ', @common );
			my $hist = $t . SCHEMA_HIST_SEP . $stamp;
			push @copy_sql, "insert into $t ( $list ) select $list from $hist";
		}
	}

	my @report;
	push @report, "schema level: $detect->{level}";
	push @report, "driver: $detect->{driver}";
	push @report, "target level: T";
	push @report, "history stamp: $stamp";
	push @report, sprintf( "tables: %d", scalar @tables );
	for my $t (@tables) {
		push @report,
			sprintf(
			"  %-28s source rows=%-6d common=%-3d dropped=%-3d defaulted=%d",
			$t->{name}, $t->{rows},
			scalar @{ $t->{common} },
			scalar @{ $t->{dropped} },
			scalar @{ $t->{defaulted} }
			);
	}

	return {
		level    => $detect->{level},
		driver   => $detect->{driver},
		stamp    => $stamp,
		tables   => \@tables,
		copy_sql => \@copy_sql,
		model    => $model,
		detect   => $detect,
		report   => \@report,
	};
}

# Perform the update by historisation. Options: stamp, manifest, checkpoint (a
# code ref called after each table's copy; a die aborts and rolls back),
# keep_old (default 1 -- the stamped tables are kept) and force (act even when
# the base is already T). An already T base is a no-op (result field noop => 1).
# Returns a result hash.
sub schema_Historize {
	my ( $dbh, %opt ) = @_;
	my $cfg      = eval { config_read('EDTK_DB') } || {};
	my $manifest = $opt{manifest} // [ schema_Manifest($cfg) ];
	my $stamp    = $opt{stamp}    // strftime( '%Y%m%d_%H%M%S', localtime );
	my $detect   = schema_Detect( $dbh, %opt );
	my $txn      = _schema_txn_ddl($dbh);
	my $own      = $dbh->{AutoCommit} ? 1 : 0;

	# Idempotent replay: an already T-conformant base is left untouched (no new
	# history snapshot). Detection keys on the index table (EDTK_DBI_OUTMNGR).
	if ( !$opt{force} && $detect->{level} eq 'T' && $detect->{ok} ) {
		return {
			ok      => 1,
			noop    => 1,
			from    => 'T',
			to      => 'T',
			stamp   => $stamp,
			renamed => [],
			rows    => {},
		};
	}

	my @renamed;    # [ table, hist_name, index_specs ]
	my %rows;       # table => source row count

	my $run = sub {
		$dbh->begin_work if $own && $txn;

		# 1. move every live table aside (kept) and free its index names.
		for my $t (@$manifest) {
			next unless _table_exists( $dbh, $t );
			my $specs = _schema_index_specs( $dbh, $t );
			my $hist  = _schema_hist_name( $dbh, $t, $stamp );
			die "rename failed: $t -> $hist\n"
				unless _schema_rename_table( $dbh, $t, $hist );
			_schema_release_indexes( $dbh, $hist, $specs );
			push @renamed, [ $t, $hist, $specs ];
		}

		# 2. build the T target under the original names (extension included).
		schema_Create($dbh);
		create_table_TRACKING( $dbh, $cfg->{'EDTK_DBI_TRACKING'}, $cfg->{'EDTK_MAX_USER_KEY'} )
			if $cfg->{'EDTK_DBI_TRACKING'};

		# 3. copy the common columns by name, then validate.
		for my $pair (@renamed) {
			my ( $t, $hist ) = @$pair;
			my @common = _schema_common_columns( $dbh, $hist, $t );
			die "no common column between $hist and $t\n" unless @common;
			my @order = _schema_key_columns( $dbh, $t );
			@order = @common unless @order;

			die "copy failed: $hist -> $t\n"
				unless _schema_copy_named( $dbh, $hist, $t, \@common );

			my ($ns) = $dbh->selectrow_array("select count(*) from $hist");
			my ($nt) = $dbh->selectrow_array("select count(*) from $t");
			die "row count differs on $t: source=$ns target=$nt\n" if $ns != $nt;
			$rows{$t} = $ns + 0;

			my $cs = _schema_checksum( $dbh, $hist, \@common, \@order );
			my $ct = _schema_checksum( $dbh, $t,    \@common, \@order );
			die "checksum differs on $t\n" if $cs ne $ct;

			$opt{checkpoint}->($t) if $opt{checkpoint};
		}

		# 4. give the kept history its indexes back, under names that cannot
		# collide with the freshly built target's.
		for my $pair (@renamed) {
			my ( $t, $hist, $specs ) = @$pair;
			_schema_restore_indexes( $dbh, $hist, $specs, SCHEMA_HIST_SEP . $stamp );
		}

		$dbh->commit if $own && $txn;
		return 1;
	};

	my $ok = eval { $run->(); 1 };
	unless ($ok) {
		my $err = $@ // 'unknown error';
		if ( $own && $txn ) {
			eval { $dbh->rollback };
		}
		else {

			# No transactional DDL: invert the captured renames explicitly.
			for my $pair ( reverse @renamed ) {
				my ( $t, $hist, $specs ) = @$pair;
				eval {
					_db_do_ddl( $dbh, "drop table if exists $t" );
					_schema_rename_table( $dbh, $hist, $t );
					_schema_restore_indexes( $dbh, $t, $specs, '' );
				};
			}
		}
		&logger( 4, "schema_Historize: aborted, service schema untouched: $err" );
		return {
			ok      => 0,
			from    => $detect->{level},
			to      => 'T',
			stamp   => $stamp,
			renamed => \@renamed,
			error   => $err,
		};
	}

	# 5. keep the stamped tables and log one history row (outside the txn).
	schema_History_add(
		$dbh,
		from   => $detect->{level},
		to     => 'T',
		mode   => ( $opt{keep_old} // 1 ) ? 'historize' : 'historize-drop',
		counts => \%rows,
	);
	return {
		ok      => 1,
		from    => $detect->{level},
		to      => 'T',
		stamp   => $stamp,
		renamed => \@renamed,
		rows    => \%rows,
	};
}

# Invert a historisation before resuming the service (annexe D step 8): put the
# stamped tables back under their original names, dropping the current target.
# Options: stamp (required, the one the migration used).
sub schema_Revert {
	my ( $dbh, %opt ) = @_;
	my $cfg   = eval { config_read('EDTK_DB') } || {};
	my $stamp = $opt{stamp}
		or die "schema_Revert: a stamp is required\n";
	my $manifest = $opt{manifest} // [ schema_Manifest($cfg) ];
	my $txn      = _schema_txn_ddl($dbh);
	my $own      = $dbh->{AutoCommit} ? 1 : 0;

	my @done;
	my $ok = eval {
		$dbh->begin_work if $own && $txn;
		for my $t (@$manifest) {
			my $hist = $t . SCHEMA_HIST_SEP . $stamp;
			next unless _table_exists( $dbh, $hist );
			_db_do_ddl( $dbh, "drop table if exists $t" );
			die "revert failed: $hist -> $t\n" unless _schema_rename_table( $dbh, $hist, $t );
			push @done, $t;
		}
		$dbh->commit if $own && $txn;
		1;
	};
	unless ($ok) {
		my $err = $@ // 'unknown error';
		eval { $dbh->rollback } if $own && $txn;
		&logger( 4, "schema_Revert: aborted: $err" );
		return { ok => 0, stamp => $stamp, error => $err };
	}
	schema_History_add(
		$dbh,
		from   => 'T',
		to     => 'T',
		mode   => 'revert',
		counts => { tables => scalar @done },
	);
	return { ok => 1, stamp => $stamp, reverted => \@done };
}

# ============================================================
# Update by in-place additive delta (S51c, PLAN annexe D "Mode additif"). For the
# cases WITHOUT a key change: ADD COLUMN, column widening and CREATE ... IF NOT
# EXISTS. Strictly monotone: never a DROP, never a narrowing, never a rename. A
# NOT NULL column is only added to a populated table when the target definition
# carries a default. With --with-constraints the primary key may change: a
# duplicate pre-check runs first, then the key is swapped on the drivers that
# allow it. Everything runs in one transaction where DDL is transactional
# (SQLite, PostgreSQL); elsewhere it is applied statement by statement.
# ============================================================

# The T target's per-table column metadata, read off a throwaway in-memory SQLite
# built with the very schema_Create T ships. Returns the SchemaScan tables hash
# (name => { columns => [...], indexes => [...] }). Best effort: {} on failure.
sub _schema_target_scan {
	my ($cfg) = @_;
	$cfg //= eval { config_read('EDTK_DB') } || {};
	my %tables;
	eval {
		my $m =
			DBI->connect( 'dbi:SQLite:dbname=:memory:', '', '',
			{ RaiseError => 1, PrintError => 0, AutoCommit => 1 } )
			or return;
		{
			local $m->{PrintError} = 0;
			eval { create_lot_sequence($m) };
			eval { schema_Create($m) };
			eval {
				create_table_TRACKING(
					$m,
					$cfg->{'EDTK_DBI_TRACKING'},
					$cfg->{'EDTK_MAX_USER_KEY'}
				);
			}
				if $cfg->{'EDTK_DBI_TRACKING'};
		}
		require oEdtk::SchemaScan;
		my $scan = oEdtk::SchemaScan::scan_schema($m);
		%tables = %{ $scan->{tables} // {} };
		$m->disconnect;
	};
	return \%tables;
}

# The primary-key columns of a SchemaScan table hash, in key order (lower-cased).
sub _schema_pk_of {
	my ($tbl) = @_;
	return map { lc $_->{name} }
		sort { $a->{pk} <=> $b->{pk} } grep { $_->{pk} } @{ $tbl->{columns} // [] };
}

# The ADD COLUMN statement for a target column, per driver. The type string comes
# from the T target model (already portable: VARCHAR(n), integer, char(1)).
sub _schema_add_column_sql {
	my ( $driver, $table, $col ) = @_;
	my $name = $col->{name};
	my $type = $col->{type} // 'varchar2(255)';
	my $nn   = ( defined $col->{nullable} && !$col->{nullable} ) ? ' not null'                : '';
	my $def  = defined $col->{default}                           ? " default $col->{default}" : '';
	return "alter table $table add ( $name $type$def$nn )" if $driver eq 'Oracle';
	return "alter table $table add column $name $type$nn$def";
}

# Widen a character column to $size, per driver. Returns undef when the driver
# cannot alter a column type in place (SQLite has no such statement).
sub _schema_widen_sql {
	my ( $driver, $table, $col, $size ) = @_;
	return if $driver eq 'SQLite';
	my $name = $col->{name};
	my $type = "varchar2($size)";
	if ( $driver eq 'mysql' ) {
		my $nn  = ( defined $col->{nullable} && !$col->{nullable} ) ? ' not null' : '';
		my $def = defined $col->{default} ? " default $col->{default}"            : '';
		return "alter table $table modify $name $type$nn$def";
	}
	return "alter table $table alter column $name type $type" if $driver eq 'PostgreSQL';
	return "alter table $table modify $name $type";    # Oracle
}

# How many duplicate groups a column combination has (0 = the combination is a
# valid key). Run before any new unique constraint (S51c pre-check).
sub _schema_has_duplicates {
	my ( $dbh, $table, $cols ) = @_;
	my $list = join( ', ', @$cols );
	my ($n) = $dbh->selectrow_array(
		"select count(*) from ( select $list from $table group by $list having count(*) > 1 ) d");
	return $n + 0;
}

# The name of a table's current primary-key constraint, or undef. Best effort.
sub _schema_pk_constraint_name {
	my ( $dbh, $table ) = @_;
	my $driver = _db_check_driver_name($dbh);
	if ( $driver eq 'PostgreSQL' ) {
		my ($n) = $dbh->selectrow_array(
			"select conname from pg_constraint where conrelid = ?::regclass and contype = 'p'",
			undef, $table );
		return $n;
	}
	elsif ( $driver eq 'Oracle' ) {
		my ($n) = $dbh->selectrow_array(
"select constraint_name from user_constraints where table_name = upper(?) and constraint_type = 'P'",
			undef, $table
		);
		return $n;
	}
	return;
}

# Swap a table's primary key for a duplicate-free column set, per driver. On
# SQLite a key cannot be changed without rebuilding the table, which is out of
# scope for an additive delta. Returns an (ok, error) pair.
sub _schema_change_key {
	my ( $dbh, $table, $cols ) = @_;
	my $driver = _db_check_driver_name($dbh);
	my $list   = join( ', ', @$cols );
	return ( 0, "changing the key in place is not supported on $driver" )
		if $driver eq 'SQLite' || $driver eq 'NC';

	if ( $driver eq 'mysql' ) {
		return ( 0, "alter table $table drop primary key" )
			unless eval { _db_do_ddl( $dbh, "alter table $table drop primary key" ) };
		return ( 0, "alter table $table add primary key ( $list )" )
			unless eval { _db_do_ddl( $dbh, "alter table $table add primary key ( $list )" ) };
		return ( 1, undef );
	}

	# PostgreSQL / Oracle: drop the existing key, attach the new one.
	my $pkname = _schema_pk_constraint_name( $dbh, $table );
	_db_do_ddl( $dbh, "alter table $table drop constraint $pkname" ) if defined $pkname;
	my $ix = "pk_" . $table;
	_db_do_ddl( $dbh, "create unique index if not exists $ix on $table ( $list )" );
	return ( 0, "alter table $table add constraint $ix primary key" )
		unless
		eval { _db_do_ddl( $dbh, "alter table $table add constraint $ix primary key ( $list )" ) };
	return ( 1, undef );
}

# Perform the in-place additive update. Options: manifest, with_constraints (0|1),
# checkpoint (a code ref called after each table) and force. A base that already
# conforms to T with nothing to add or widen is a no-op (result field noop => 1).
# Returns a result hash: created (list), added (table => [cols]), widened
# (table => [ {col,from,to} ]), key_changed (list), violations (list) and error.
sub schema_Additive {
	my ( $dbh, %opt ) = @_;
	my $cfg      = eval { config_read('EDTK_DB') } || {};
	my $manifest = $opt{manifest} // [ schema_Manifest($cfg) ];
	my $detect   = schema_Detect( $dbh, %opt );
	my $driver   = _db_check_driver_name($dbh);
	my $txn      = _schema_txn_ddl($dbh);
	my $own      = $dbh->{AutoCommit} ? 1 : 0;

	my $target = _schema_target_scan($cfg);

	my @created;
	my %added;
	my %widened;
	my @key_changed;
	my @violations;

	my $run = sub {
		$dbh->begin_work if $own && $txn;

		require oEdtk::SchemaScan;
		my $scan = oEdtk::SchemaScan::scan_schema($dbh);

		# 1. add the missing columns, widen the narrower ones and, when asked,
		# change the key -- on the tables that already exist.
		for my $t (@$manifest) {
			my $tbl     = $target->{$t}       or next;
			my $live    = $scan->{tables}{$t} or next;
			my %sc      = map { lc( $_->{name} ) => $_ } @{ $live->{columns} // [] };
			my ($nrows) = $dbh->selectrow_array("select count(*) from $t");
			$nrows += 0;

			for my $col ( @{ $tbl->{columns} // [] } ) {
				my $key = lc $col->{name};
				if ( !exists $sc{$key} ) {
					my $notnull = ( defined $col->{nullable} && !$col->{nullable} ) ? 1 : 0;
					if ( $notnull && !defined $col->{default} && $nrows > 0 ) {
						push @violations,
							"$t.$col->{name}: NOT NULL without a default on a populated table";
						next;
					}
					my $sql = _schema_add_column_sql( $driver, $t, $col );
					die "add column failed on $t.$col->{name}\n" unless _db_do_ddl( $dbh, $sql );
					push @{ $added{$t} }, $col->{name};
					next;
				}
				my $s = $sc{$key};
				next unless defined $col->{size} && defined $s->{size};
				if ( $col->{size} > $s->{size} ) {
					my $sql = _schema_widen_sql( $driver, $t, $col, $col->{size} );
					next                                    unless defined $sql;
					die "widen failed on $t.$col->{name}\n" unless _db_do_ddl( $dbh, $sql );
					push @{ $widened{$t} },
						{ col => $col->{name}, from => $s->{size}, to => $col->{size} };
				}
				elsif ( $col->{size} < $s->{size} ) {
					push @violations, "narrowing refused: $t.$col->{name} $s->{size}->$col->{size}";
				}
			}

			# Change the key only when explicitly asked to.
			my @spk = _schema_pk_of($live);
			my @tpk = _schema_pk_of($tbl);
			if ( @tpk && join( ',', @spk ) ne join( ',', @tpk ) ) {
				if ( !$opt{with_constraints} ) {
					push @violations,
						  "$t: key differs ( "
						. join( ',', @spk ) . " -> "
						. join( ',', @tpk )
						. " ); use --with-constraints";
				}
				else {
					my $dup = _schema_has_duplicates( $dbh, $t, \@tpk );
					die "duplicate rows on $t ( " . join( ',', @tpk ) . " ): $dup\n" if $dup;
					my ( $kok, $kerr ) = _schema_change_key( $dbh, $t, \@tpk );
					die "key change failed on $t: $kerr\n" unless $kok;
					push @key_changed, $t;
				}
			}

			$opt{checkpoint}->($t) if $opt{checkpoint};
		}

		# 2. create the still-missing tables last, once the existing ones carry
		# every column their indexes reference (schema_Create is "IF NOT EXISTS").
		for my $t (@$manifest) {
			push @created, $t unless $scan->{tables}{$t};
		}
		if (@created) {
			schema_Create($dbh);
			create_table_TRACKING( $dbh, $cfg->{'EDTK_DBI_TRACKING'}, $cfg->{'EDTK_MAX_USER_KEY'} )
				if $cfg->{'EDTK_DBI_TRACKING'};
		}

		$dbh->commit if $own && $txn;
		return 1;
	};

	my $ok = eval { $run->(); 1 };
	unless ($ok) {
		my $err = $@ // 'unknown error';
		eval { $dbh->rollback } if $own && $txn;
		&logger( 4, "schema_Additive: aborted: $err" );
		return {
			ok          => 0,
			from        => $detect->{level},
			to          => 'T',
			created     => \@created,
			added       => \%added,
			widened     => \%widened,
			key_changed => \@key_changed,
			violations  => \@violations,
			error       => $err,
		};
	}

	# 3. nothing changed at all -> no-op, and no history row.
	unless ( @created || %added || %widened || @key_changed ) {
		return {
			ok          => 1,
			noop        => 1,
			from        => $detect->{level},
			to          => 'T',
			created     => [],
			added       => {},
			widened     => {},
			key_changed => [],
			violations  => \@violations,
		};
	}

	schema_History_add(
		$dbh,
		from   => $detect->{level},
		to     => 'T',
		mode   => 'additive',
		counts => {
			created => scalar @created,
			added   => scalar( map { @$_ } values %added ),
		},
	);
	return {
		ok          => 1,
		from        => $detect->{level},
		to          => 'T',
		created     => \@created,
		added       => \%added,
		widened     => \%widened,
		key_changed => \@key_changed,
		violations  => \@violations,
	};
}

# ============================================================
# PUBLIC : probe whether the connected DB user may run the DDL that schema_Create
# and schema_Upgrade issue, so a missing right is reported early instead of failing
# later on a CREATE TABLE / INDEX / SEQUENCE or an ALTER TABLE. Best effort: it only
# reads the data dictionary and never dies.
#
# Returns { driver  => 'SQLite'|'Oracle'|'PostgreSQL'|'mysql'|'NC',
#           checked => 0|1,       # 0 when the driver has no privilege model
#           create  => 0|1,       # undef when left unknown
#           drop    => 0|1,
#           index   => 0|1,
#           alter   => 0|1,
#           sequence=> 0|1,
#           missing => [ 'CREATE', ... ],
#           error   => '...' }    # set when the probe itself failed
# Options: table => 'name' targets a specific table for the ownership checks
# (PostgreSQL); ignored by the other backends.
# ============================================================
sub db_check_privileges {
	my ( $dbh, %opt ) = @_;

	# Rights probed, in the order they are reported in 'missing'.
	my @RIGHTS = qw(CREATE DROP INDEX ALTER SEQUENCE);

	my %res = ( driver => 'NC', checked => 0, missing => [] );
	return \%res unless defined $dbh;

	my $driver = _db_check_driver_name($dbh);
	$res{driver} = $driver;

	# SQLite has no GRANT/privilege model: the file owner may do everything.
	if ( $driver eq 'SQLite' ) {
		$res{ lc $_ } = 1 for @RIGHTS;
		$res{checked} = 1;
		&logger( 7,
				  "db_check_privileges: SQLite has no privilege model, "
				. "assuming every right is allowed" );
		return \%res;
	}

	# No privilege model we can query: report nothing rather than guess.
	if ( $driver eq 'NC' ) {
		&logger( 7, "db_check_privileges: unknown driver, " . "cannot check privileges" );
		return \%res;
	}

	my %rights;
	my $ok = eval {
		%rights =
			  $driver eq 'PostgreSQL' ? _db_priv_pg( $dbh, %opt )
			: $driver eq 'mysql'      ? _db_priv_mysql( $dbh, %opt )
			: $driver eq 'Oracle'     ? _db_priv_oracle( $dbh, %opt )
			:                           ();
		1;
	};
	unless ($ok) {
		$res{error} = $@ || 'unknown error';
		&logger( 4, "db_check_privileges: privilege probe failed: $res{error}" );
		return \%res;
	}

	$res{checked} = 1;
	for my $right (@RIGHTS) {
		my $have = $rights{ lc $right };
		$res{ lc $right } = $have;
		next if !defined $have || $have;
		push @{ $res{missing} }, $right;
		&logger( 3,
				  "db_check_privileges: DB user lacks the $right privilege on the "
				. "current database/schema ; schema_Create and schema_Upgrade may fail" );
	}
	return \%res;
}

# PostgreSQL: CREATE is a database/schema privilege; owning the table grants DROP,
# INDEX and ALTER. Ownership is tested on the target table (option 'table') or on
# any table of the current schema, and a superuser always passes; an empty schema
# does not raise a false alarm. Returns a hash of rights.
sub _db_priv_pg {
	my ( $dbh, %opt ) = @_;

	my ($super) =
		$dbh->selectrow_array("SELECT rolsuper FROM pg_roles WHERE rolname = current_user");
	return map { $_ => 1 } qw(create drop index alter sequence) if $super;

	my ($create) = $dbh->selectrow_array(
			  "SELECT has_database_privilege(current_user, current_database(), 'CREATE') "
			. "AND has_schema_privilege(current_user, current_schema(), 'CREATE')" );

	my $owns;
	if ( defined $opt{table} && length $opt{table} ) {
		($owns) = $dbh->selectrow_array(
			"SELECT pg_get_userbyid(c.relowner) = current_user "
				. "FROM pg_class c JOIN pg_namespace n ON n.oid = c.relnamespace "
				. "WHERE c.relname = ? AND n.nspname = current_schema()",
			undef, $opt{table}
		);
	}
	else {
		($owns) =
			$dbh->selectrow_array( "SELECT bool_or(pg_get_userbyid(c.relowner) = current_user) "
				. "FROM pg_class c JOIN pg_namespace n ON n.oid = c.relnamespace "
				. "WHERE n.nspname = current_schema() AND c.relkind = 'r'" );
	}
	my $owning = defined $owns ? ( $owns ? 1 : 0 ) : 1;

	return (
		create   => $create ? 1 : 0,
		drop     => $owning,
		index    => $owning,            # CREATE INDEX needs table ownership
		alter    => $owning,            # ALTER TABLE needs table ownership
		sequence => $create ? 1 : 0,    # CREATE SEQUENCE needs CREATE on the schema
	);
}

# MySQL / MariaDB: SHOW GRANTS lists the effective grants. A statement that grants
# ALL PRIVILEGES, or the specific right, on '*.*' or on the current database gives
# the right. CREATE INDEX needs INDEX or ALTER; CREATE SEQUENCE (MariaDB) needs
# CREATE. Returns a hash of rights.
sub _db_priv_mysql {
	my ( $dbh, %opt ) = @_;

	my ($db) = $dbh->selectrow_array("SELECT DATABASE()");
	$db = '' unless defined $db;

	my $rows = $dbh->selectall_arrayref("SHOW GRANTS FOR CURRENT_USER()");
	my %have;
	for my $r ( @{ $rows || [] } ) {
		my $grant = $r->[0] // '';
		next unless $grant =~ /^\s*GRANT\s+(.+?)\s+ON\s+(\S.*?)\s+TO\s/i;
		my ( $privs, $scope ) = ( uc $1, $2 );
		$scope =~ s/`//g;
		my $global = ( $scope eq '*.*' );
		my $local  = ( $db ne '' && lc($scope) eq lc("$db.*") );
		next unless $global || $local;
		if ( $privs =~ /ALL PRIVILEGES/ ) {
			$have{$_} = 1 for qw(CREATE DROP INDEX ALTER);
		}
		else {
			$have{$_} = 1 for grep { $privs =~ /\b$_\b/ } qw(CREATE DROP INDEX ALTER);
		}
	}
	return (
		create   => $have{CREATE}                    ? 1 : 0,
		drop     => $have{DROP}                      ? 1 : 0,
		index    => ( $have{INDEX} || $have{ALTER} ) ? 1 : 0,
		alter    => $have{ALTER}                     ? 1 : 0,
		sequence => $have{CREATE}                    ? 1 : 0,
	);
}

# Oracle: system privileges; those held directly sit in USER_SYS_PRIVS, those held
# through an enabled role in ROLE_SYS_PRIVS. Creating the tables (CREATE TABLE) makes
# us their owner, so we may then INDEX and ALTER them. Returns a hash of rights.
sub _db_priv_oracle {
	my ( $dbh, %opt ) = @_;

	my $ref = $dbh->selectcol_arrayref(
		"SELECT PRIVILEGE FROM USER_SYS_PRIVS " . "UNION SELECT PRIVILEGE FROM ROLE_SYS_PRIVS" );
	my %priv = map { uc($_) => 1 } @{ $ref || [] };

	my $create_table = ( $priv{'CREATE TABLE'} || $priv{'CREATE ANY TABLE'} ) ? 1 : 0;
	return (
		create   => $create_table,
		drop     => $priv{'DROP ANY TABLE'} ? 1 : 0,
		index    => ( $create_table            || $priv{'CREATE ANY INDEX'} )    ? 1 : 0,
		alter    => ( $create_table            || $priv{'ALTER ANY TABLE'} )     ? 1 : 0,
		sequence => ( $priv{'CREATE SEQUENCE'} || $priv{'CREATE ANY SEQUENCE'} ) ? 1 : 0,
	);
}

sub schema_Upgrade {

	# EXAMPLE CALL:
	# schema_Upgrade (CFG => $cfg);
	my %p = @_;

	# PREREQUISITES FOR THIS OPERATION:
	#- DISK SPACE
	#- HISTORIZATION
	#- DATABASE || TABLE OPTIMIZATION

	my @tListeTables = (
		"edtk_acq",
		"edtk_admin",
		"edtk_agrege",
		"edtk_filieres",
		"edtk_id",
		"edtk_lots",
		"edtk_refiddoc",
		"edtk_supports",

		#		"edtk_datagroups",
		#		"edtk_para",
		$p{CFG}->{EDTK_DBI_DISTRIB},
		$p{CFG}->{EDTK_DBI_DISTRIB_STATS},
		$p{CFG}->{EDTK_DBI_OUTMNGR},
		$p{CFG}->{EDTK_DBI_OUTMNGR_STATS}
	);

	my $stamp = strftime "%Y%m%d_%H%M", localtime;
	$p{DBH} = db_connect( $p{CFG}, 'EDTK_DBI_DSN' );

	# Repatriate any pending backup rows before renaming / copying the schema.
	eval { _db_maybe_reconcile( $p{DBH}, $p{CFG} ); };

	# Best effort: alert (never block) when the DB user cannot CREATE/DROP.
	eval { db_check_privileges( $p{DBH} ) };

	my $sep = "";
	if ( _db_check_driver_name( $p{DBH} ) =~ m/SQLite/i ) {
		$sep = "'";
	}

	foreach my $table (@tListeTables) {
		my $sql = sprintf( "alter table %s rename to " . "$sep" . "%s_%s" . "$sep" . " ;",
			$table, $stamp, $table );
		&logger( 7, $sql );

		#$p{DBH}->do(                   $sql, undef, )  or die &logger( -1, "ERROR: can't $sql");
		_db_do_log( $p{DBH}, _sql_fixup( $p{DBH}, $sql, 'casse' ), "ERROR: can't $sql",
			fatal => 1 );

	}

	# if ok:
	schema_Create( $p{DBH} );

	#if ok:
	foreach my $table (@tListeTables) {
		my $sql = sprintf( "insert into %s select * from " . "$sep" . "%s_%s" . "$sep" . " ;",
			$table, $stamp, $table );
		&logger( 7, $sql );
		_db_do_log( $p{DBH}, _sql_fixup( $p{DBH}, $sql, undef ), "ERROR: can't $sql", fatal => 1 );
		my $drop = sprintf( "drop table " . "$sep" . "%s_%s" . "$sep" . " ;", $stamp, $table );
		&logger( 7, $drop );
		_db_do_log(
			$p{DBH},
			_sql_fixup( $p{DBH}, $drop, 'casse' ),
			"ERROR: can't $drop",
			fatal => 1
		);
	}

	db_invalidate_meta_cache();
}

sub schema_Create {

	#	my ($dbh, $table, $maxkeys) = @_;
	my $dbh = shift;
	my $cfg = config_read('EDTK_DB');

	# Best effort: alert (never block) when the DB user cannot CREATE/DROP.
	eval { db_check_privileges($dbh) };

	#if ( $cfg->{'EDTK_DBI_DSN'} =~ m/SQLite/i) {
	if ( $dbh->{'Driver'}->{'Name'} =~ m/mysql/i ) {

		# MySQL uses its own AUTO_INCREMENT emulation, nothing to create here.
		&logger( 5, "MySQL uses its own sequence emulation, ignoring." );
	}
	else {
		# Oracle/PostgreSQL create a SEQUENCE; SQLite creates a counter table.
		create_lot_sequence($dbh);
	}

	create_table_ADMIN($dbh);
	create_table_ACQUIT($dbh);
	create_table_AGREGE($dbh);
	create_table_FILIERES($dbh);
	create_table_ID($dbh);
	create_table_LOTS($dbh);
	create_table_REFIDDOC($dbh);
	create_table_SUPPORTS($dbh);

	#create_table_DATAGROUPS($dbh);
	#create_table_PARA($dbh);

	# CHECK THE PRIMARY KEY AND INDEX PROPOSALS (BE CAREFUL NOT TO DO ANYTHING DAFT)
	create_table_OUTMNGR( $dbh, $cfg->{'EDTK_DBI_OUTMNGR'} );
	create_table_OUTMNGR( $dbh, $cfg->{'EDTK_DBI_OUTMNGR_STATS'} );
	create_table_DISTRIB( $dbh, $cfg->{'EDTK_DBI_DISTRIB'} );
	create_table_DISTRIB( $dbh, $cfg->{'EDTK_DBI_DISTRIB_STATS'} );

	# Optional extension schema (oEUser::Schema, D19): absent -> nothing extra.
	_schema_create_extra($dbh);

	db_invalidate_meta_cache();
}

sub _db_maintenance {
	my (%p) = @_;    # CFG, DBH, [rotate => 1], [purge => 1]
	my $dbh = $p{DBH} // db_connect( $p{CFG}, 'EDTK_DBI_DSN' );

	_db_rotate( $dbh, $p{CFG} ) if $p{rotate};
	_db_purge( $dbh, $p{CFG} )  if $p{purge};

	$dbh->disconnect unless $p{DBH};    # do not disconnect when a $dbh was passed to us
	return 1;
}

sub _db_with_lock {
	my (%p)  = @_;                                      # CFG, CODE-REF
	my $dbh  = db_connect( $p{CFG}, 'EDTK_DBI_DSN' );
	my $date = strftime( "%Y-%m-%d", localtime );
	my $pid  = $$;

	# Try to insert the lock
	eval {
		local $dbh->{PrintError} = 0;
		$dbh->do(
'insert into edtk_admin (ed_action_date,ed_action_pid,ed_action_status,ed_oedtk_release) values (?,?,?,?)',
			undef, $date, $pid, 'START', $VERSION
		);
	};
	if ($@) {    # conflict, another process already holds it
		$dbh->disconnect;
		return 0;
	}

	# Check that it is really us
	my ($got_pid) =
		$dbh->selectrow_array( 'select ed_action_pid from edtk_admin where ed_action_date = ?',
		undef, $date );
	unless ( $got_pid == $pid ) {
		$dbh->disconnect;
		return 0;
	}

	# Run the body
	eval { $p{code}->($dbh) };
	my $err = $@;

	# Mark the end
	my $duration = time - $^T;
	$dbh->do(
'update edtk_admin set ed_action_status = ?, ed_action_duration = ? where ed_action_date = ?',
		undef, 'DONE', $duration, $date
	);
	$dbh->disconnect;

	die $err if $err;
	return 1;
}

sub _db_check_driver_name {
	my ($dbh) = shift;

	# Guard against an invalid or disconnected $dbh
	return "NC" unless defined $dbh;
	my $driver_name = eval { $dbh->{'Driver'}->{'Name'} };
	return "NC" unless defined $driver_name;

	if    ( $driver_name =~ m/SQLite/i )          { return "SQLite"; }
	elsif ( $driver_name =~ m/Oracle/i )          { return "Oracle"; }
	elsif ( $driver_name =~ m/Pg/i )              { return "PostgreSQL"; }
	elsif ( $driver_name =~ m/(?:mysql|maria)/i ) { return "mysql"; }
	else                                          { return "NC"; }
}

# Returns the MySQL storage-engine clause appended to CREATE TABLE statements.
# The engine is configurable through EDTK_DB_STORAGE_ENGINE (default: MyISAM,
# kept for its bulk-load performance). Empty string for non-MySQL drivers.
sub _db_engine_clause {
	my ($dbh) = @_;
	return '' unless _db_check_driver_name($dbh) eq 'mysql';
	unless ( defined $_DB_ENGINE_CACHE ) {
		my $cfg = eval { config_read('EDTK_DB') } || {};
		$_DB_ENGINE_CACHE = $cfg->{'EDTK_DB_STORAGE_ENGINE'} || 'MyISAM';
	}
	return ' engine=' . $_DB_ENGINE_CACHE . ' ';
}

# Does an object (table, index or sequence) already exist in the current schema?
# Queries each driver's data dictionary; returns 1/0 (0 for an unknown driver,
# so that the CREATE attempt is still allowed to run).
sub _db_object_exists {
	my ( $dbh, $kind, $name ) = @_;
	my $driver = _db_check_driver_name($dbh);
	my ( $schema, $obj ) = ( $name =~ /^(\w+)\.(\w+)$/ ) ? ( $1, $2 ) : ( undef, $name );

	if ( $driver eq 'SQLite' ) {
		my ($n) = $dbh->selectrow_array( 'select 1 from sqlite_master where type = ? and name = ?',
			undef, $kind, $obj );
		return $n ? 1 : 0;
	}
	elsif ( $driver eq 'PostgreSQL' ) {

		# PostgreSQL folds unquoted identifiers to lower case (EDTK_ACQMGENTECH is
		# stored as edtk_acqmgentech), so compare case-insensitively, as the Oracle
		# branch does with upper().
		my ($n) = $dbh->selectrow_array(
			'select 1 from pg_class c join pg_namespace n on n.oid = c.relnamespace '
				. 'where lower(c.relname) = lower(?) and n.nspname = current_schema()',
			undef, $obj
		);
		return $n ? 1 : 0;
	}
	elsif ( $driver eq 'mysql' ) {
		if ( $kind eq 'index' ) {
			my ($n) = $dbh->selectrow_array(
				'select 1 from information_schema.statistics '
					. 'where table_schema = database() and index_name = ?',
				undef, $obj
			);
			return $n ? 1 : 0;
		}
		my ($n) = $dbh->selectrow_array( 'show tables like ?', undef, $obj );
		return $n ? 1 : 0;
	}
	elsif ( $driver eq 'Oracle' ) {
		my ($n) = $dbh->selectrow_array( 'select 1 from user_objects where object_name = upper(?)',
			undef, $obj );
		return $n ? 1 : 0;
	}
	return 0;
}

# Extracts the kind ('table'|'index'|'sequence') and name from a CREATE statement.
sub _db_parse_create {
	my ($sql) = @_;
	return ( 'index', $1 )
		if $sql =~ /\bcreate\s+(?:unique\s+)?index\s+(?:if\s+not\s+exists\s+)?(\S+)/i;
	return ( 'table',    $1 ) if $sql =~ /\bcreate\s+table\s+(?:if\s+not\s+exists\s+)?(\S+)/i;
	return ( 'sequence', $1 ) if $sql =~ /\bcreate\s+sequence\s+(?:if\s+not\s+exists\s+)?(\S+)/i;
	return;
}

# Runs a DDL statement through the driver-specific fixup. On drivers that lack
# "CREATE ... IF NOT EXISTS" (Oracle, MySQL) the clause is emulated by checking
# existence first and stripping it. PostgreSQL supports the clause natively, but
# the server then emits a "relation ... already exists, skipping" NOTICE straight
# to STDERR; pre-checking it too turns that notice into a regular Information log
# line and skips the redundant DDL. Returns the underlying do() result.
sub _db_do_ddl {
	my ( $dbh, $sql ) = @_;
	my $driver = _db_check_driver_name($dbh);
	$sql = _sql_fixup( $dbh, $sql, 'casse' );

	if ( ( $driver eq 'Oracle' || $driver eq 'mysql' || $driver eq 'PostgreSQL' )
		&& $sql =~ /\bcreate\b.*\bif\s+not\s+exists\b/is )
	{
		my ( $kind, $name ) = _db_parse_create($sql);
		if ( defined $name && _db_object_exists( $dbh, $kind, $name ) ) {
			&logger( 6, "INFO: relation \"$name\" already exists, skipping\n" );
			return 1;
		}
		$sql =~ s/\s+if\s+not\s+exists\b//ig
			if $driver eq 'Oracle' || $driver eq 'mysql';
	}
	return do { local $dbh->{PrintError} = 0; $dbh->do($sql) };
}

# Per-engine table-maintenance command templates, as (repair, optimize) hash refs
# keyed by _db_check_driver_name() class. A template without %s is a portable no-op
# ("select 1"), so an engine that has no such command still runs harmlessly. Kept in
# one place so every engine's coverage is declared and unit-testable.
sub _db_maintenance_commands {
	my ($driver) = @_;
	my %repair = (
		NC         => "select 1",
		mysql      => "repair table %s",
		Oracle     => "select 1 from dual",
		PostgreSQL => "select 1",
		SQLite     => "select 1",
	);
	my %optm = (
		NC     => "select 1",
		mysql  => "optimize table %s",
		Oracle => "select 1 from dual",

		# VACUUM FULL takes an exclusive lock and rewrites the whole table: it does
		# not belong in the routine maintenance path. Plain VACUUM ANALYZE reclaims
		# space without blocking writers and refreshes the planner statistics.
		PostgreSQL => "vacuum analyze %s",

		# SQLite has no per-table VACUUM; ANALYZE %s refreshes the statistics it uses.
		SQLite => "analyze %s",
	);
	return ( \%repair, \%optm );
}

sub admin_optimize_db {

	# EXAMPLE CALL:
	# admin_optimize_db (CFG => $cfg);

	my %p = @_;

	# Single connection for the whole operation (it used to open two per table).
	$p{DBH} = db_connect( $p{CFG}, 'EDTK_DBI_DSN' );

	# Repatriate any pending backup rows before optimizing / repairing.
	eval { _db_maybe_reconcile( $p{DBH}, $p{CFG} ); };
	&logger( 3, "admin_optimize_db: reconciliation failed: $@" ) if $@;

	my @tListeTables = grep { defined $_ && $_ ne '' } (
		"edtk_acq",
		"edtk_admin",
		"edtk_agrege",
		"edtk_filieres",
		"edtk_id",
		"edtk_lots",
		"edtk_refiddoc",
		"edtk_supports",

		#       "edtk_datagroups",
		#       "edtk_para",
		$p{CFG}->{EDTK_DBI_DISTRIB},
		$p{CFG}->{EDTK_DBI_DISTRIB_STATS},
		$p{CFG}->{EDTK_DBI_OUTMNGR},
		$p{CFG}->{EDTK_DBI_OUTMNGR_STATS},
		"edtk_tracking"
	);

	# Detect the driver once, on the live handle.
	my $dbName = _db_check_driver_name( $p{DBH} );
	&logger( 7, "admin_optimize_db: driver=$dbName, " . scalar(@tListeTables) . " tables" );

	# PostgreSQL maintenance can spawn parallel workers that allocate dynamic shared
	# memory in /dev/shm; on a small /dev/shm the segment resize aborts with
	# "could not resize shared memory segment ... No space left on device". Routine
	# per-table maintenance gains nothing from parallelism, so force it serial.
	if ( $dbName eq 'PostgreSQL' ) {
		eval { local $p{DBH}->{PrintError} = 0; $p{DBH}->do($_) }
			for (
			'set max_parallel_maintenance_workers = 0',
			'set max_parallel_workers_per_gather = 0'
			);
	}

	my ( $hCdeRepair, $hCdeOptm ) = _db_maintenance_commands($dbName);

	foreach my $table (@tListeTables) {

		# Repair
		my $tpl_repair = $hCdeRepair->{$dbName} // "select 1";

		# sprintf only when the template contains %s
		my $sql_repair = ( $tpl_repair =~ /\%s/ ) ? sprintf( $tpl_repair, $table ) : $tpl_repair;
		&logger( 7, "repair: $sql_repair" );
		_db_maintenance_run( $p{DBH}, _sql_fixup( $p{DBH}, $sql_repair, 'casse' ),
			"repair $table" );

		# Optimize
		my $tpl_optm = $hCdeOptm->{$dbName} // "select 1";
		my $sql_optm = ( $tpl_optm =~ /\%s/ ) ? sprintf( $tpl_optm, $table ) : $tpl_optm;
		&logger( 7, "optimize: $sql_optm" );
		_db_maintenance_run( $p{DBH}, _sql_fixup( $p{DBH}, $sql_optm, 'casse' ),
			"optimize $table" );
	}
	$p{DBH}->disconnect;
	return 1;
}

# Run one maintenance statement. Catches driver errors so a single table cannot
# abort the whole pass, and reports them as one concise logger line instead of the
# raw DBI/PrintError dump (e.g. a PostgreSQL shared-memory exhaustion). Never dies.
sub _db_maintenance_run {
	my ( $dbh, $sql, $what ) = @_;
	my $res = do {
		local $dbh->{PrintError} = 0;
		local $dbh->{RaiseError} = 0;
		eval { $dbh->do($sql) };
	};
	return 1 if defined $res;
	&logger( 4, "can't $what: " . ( $dbh->errstr // $@ // 'unknown error' ) );
	return 0;
}

sub _sql_fixup_v1 {
	my ( $dbh, $sql ) = @_;

	# invert the logic: standard SQL => Oracle-specific
	if ( $dbh->{'Driver'}->{'Name'} ne 'Oracle' ) {
		$sql =~ s/varchar2 *(\(\d+\))/varchar$1/gi;
	}

	return $sql;
}

sub _sql_fixup {
	my ( $dbh, $sql, $mysqlCasse ) = @_;
	my $driver = $dbh->{'Driver'}->{'Name'};

	# Driver class, so that MariaDB (Driver.Name 'MariaDB') is handled like MySQL.
	my $class = _db_check_driver_name($dbh);

	# POSTGRESQL specifics
	if ( $class eq 'PostgreSQL' ) {

		# --- Empty strings '' for non-string types ---
		if ( $sql =~ /VALUES\s*\((.*)\)/si ) {
			my $values_part = $1;

			# Replace standalone '' with NULL
			$values_part =~ s/''(?=\s*,|\s*\))/NULL/g;
			$sql         =~ s/VALUES\s*\(.*\)/VALUES ($values_part)/si;
		}

		# Handle the update form "SET column = ''"
		$sql =~ s/=\s*''(\s*,|\s+WHERE|=)/ = NULL$1/gi;
	}

	# Generic logic / other drivers: Oracle keeps VARCHAR2, everyone else gets VARCHAR.
	if ( $class ne 'Oracle' ) {
		$sql =~ s/VARCHAR2 *(\(\d+\))/VARCHAR$1/gi;
	}

	# MySQL forced case (keyed on the real MySQL driver only; MariaDB is left untouched).
	if ( $driver eq 'mysql' and $mysqlCasse and $sql !~ /\b(INSERT|REPLACE)\b/i ) {
		$sql = uc($sql);
	}

	return $sql;
}

sub db_backup_agent {

	# Archives the 3 production tables (EDTK_DBI_TRACKING / OUTMNGR / ACQUIT) into a
	# date-stamped snapshot, then purges the rows older than EDTK_ENTIRE_YEARS_KEPT.
	# The snapshot copies the whole table (not just the old rows), so a re-run on the
	# same day must not overwrite it with the now-smaller source: the existing archive
	# is kept as is. Called from Outmngr::omgr_purge_fs.
	my ( $dbh, $cfg ) = @_;
	$cfg ||= config_read('EDTK_DB');
	unless ( defined( $cfg->{'EDTK_ENTIRE_YEARS_KEPT'} ) && $cfg->{'EDTK_ENTIRE_YEARS_KEPT'} > 0 ) {
		&logger( 4,
			"EDTK_ENTIRE_YEARS_KEPT not defined for optimization purge. db_backup_agent not needed."
		);
		return 1;
	}

	my $suffixe   = strftime( "%Y%m%d", localtime ) . "_BAK";
	my $cur_year  = strftime( "%Y",     localtime );
	my $kept_year = $cur_year - $cfg->{'EDTK_ENTIRE_YEARS_KEPT'};

	# (table, date column, purge threshold) of the tables to archive and purge.
	my @plan = (
		[ $cfg->{'EDTK_DBI_TRACKING'}, 'ed_tstamp',   $kept_year . "0101000000" ],
		[ $cfg->{'EDTK_DBI_OUTMNGR'},  'ed_dtedtion', $kept_year . "0101" ],
		[ $cfg->{'EDTK_DBI_ACQUIT'},   'ed_dtpost',   $kept_year . "0101" ],
	);

	foreach my $spec (@plan) {
		my ( $table, $datecol, $check ) = @$spec;
		next unless defined $table && $table ne '';

		my $sql_check = "select count($datecol) from $table where $datecol < ? ";
		my $sth       = $dbh->prepare($sql_check);
		do { local $sth->{PrintError} = 0; $sth->execute($check) }
			or &logger( 3, "SQL execute failed " . $sth->err . "-" . $sth->errstr );
		my ($result) = $sth->fetchrow_array;
		unless ($result) {
			&logger( 5, "db_backup_agent has nothing to do with $table" );
			next;
		}

		my $cible = $table . "_" . $suffixe;

		# MySQL stores the archive under its uppercase name (copy_table DDL is uppercased).
		my $exists = _db_object_exists( $dbh, 'table', $cible )
			|| _db_object_exists( $dbh, 'table', uc $cible );
		if ($exists) {
			&logger( 4, "db_backup_agent: archive $cible already exists for today, keeping it" );
		}
		else {
			copy_table( $dbh, $table, $cible, '-create' );
			&logger( 5, "db_backup_agent archived $table into $cible" );
		}

		my $sql_clean = "delete from $table where $datecol < ? ";
		_db_do_log(
			$dbh, $sql_clean, "ERROR: can't delete from $table",
			bind  => [$check],
			fatal => 1
		);

		&logger( 4, "db_backup_agent DONE with $table for data older than $check." );
	}

	return 1;
}

1;

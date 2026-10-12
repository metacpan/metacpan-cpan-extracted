package oEdtk::DBAdmin;

use DBI;
use oEdtk::Config	qw(config_read);
use oEdtk::logger	qw(logger $LOGGERLEVEL $WARN2LOGGER);
use POSIX			qw(strftime);
use Scalar::Util 	qw(looks_like_number);
use strict;
use Text::CSV;
use Encode		qw(encode find_encoding);
use warnings;
use Data::Dumper qw(Dumper);

# check sql : https://www.eversql.com
# SHOW CREATE DATABASE oEdtk;

use Exporter;
our $VERSION		= 2.1109; 
our $VERSION_TXT 	= $VERSION =~ s/\./_/gr;
our @ISA			= qw(Exporter);
our @EXPORT_OK		= qw(
				acheck_db_admin_on_connect
				acheck_db_admin
				agrege_idJob
				copy_table
				schema_Create
				schema_Upgrade
				create_lot_sequence
				create_table_TRACKING
				create_table_OUTMNGR
				create_table_DISTRIB
				create_table_ACQUIT
				create_table_ADMIN
				create_table_AGREGE
				create_table_DATAGROUPS
				create_table_FILIERES
				create_table_ID
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
				historicize_table
				insert_tData
				move_table
				admin_optimize_db
				@INDEX_COLS
				@TRACKER_COLS
				);


my $_LOCAL_EDTK_WAITRUN=0;
my $CONNECT_COUNT=0;
our %_csv_import_type_cache;
my $_DB_ENGINE_CACHE;

# PostgreSQL bulk-load tuning (used by _load_csv_pg_copy / _pg_load_tx).
use constant PG_COPY_SYNC_OFF   => 'SET LOCAL synchronous_commit = off';  # relax fsync for this transaction only
use constant PG_COPY_ANALYZE    => 'ANALYZE %s';                            # refresh planner stats after a bulk load
use constant PG_COPY_BLOCK_SIZE => 1 << 20;                                # bytes fed per pg_putcopydata call


sub move_table (@){
	&logger (4, "method oEdtk::DBAdmin::move_table is deprecated you should use oEdtk::DBAdmin::copy_table");

	copy_table (@_);
1;
}


sub copy_table ($$$;$){ 
	my ($dbh, $table_source, $table_cible, $create_option) = @_;
	$create_option ||= "";

	# check if source is empty
	my $sql_check_source = "SELECT CASE WHEN COUNT(*) > 0 THEN 1 ELSE 0 END FROM ".$table_source;
	my $sth = $dbh->prepare($sql_check_source);
	do { local $sth->{PrintError} = 0; $sth->execute() } or &logger (3, "SQL execute failed ".$sth->err."-".$sth->errstr);
	my $result = $sth->fetchrow_array;
	unless ($result){
		&logger (4, "Source $table_source is empty, copy aborted");
		return 1;
	}

	# preparing the data copy from source to target
	&logger (4, "Data from $table_source will be copyed into $table_cible");

	if ($create_option =~/-create/i) {
		my $sql_create	= "CREATE TABLE ".$table_cible." AS SELECT * FROM ".$table_source;
		# on error, DIE so no other operation runs against the databases (db_backup_agent, ...)
		_db_do_log($dbh, _sql_fixup($dbh, $sql_create, 'casse'), "ERROR: can't create $table_cible", fatal => 1);

	} else {
		my $sql_insert	= "INSERT INTO  ".$table_cible." SELECT * FROM ".$table_source;
		# on error, DIE so no other operation runs against the databases (db_backup_agent, ...)
		_db_do_log($dbh, _sql_fixup($dbh, $sql_insert, 'casse'), "ERROR: can't insert into $table_cible", fatal => 1);
	}
	
	&logger (4, "Insert DONE into $table_cible");
1;
}


sub _load_csv_mysql_infile ($$$$) {
	my ($dbh, $tablename, $fi, $params) = @_;

	# read the header line: it holds the field names and the insert order
	open(my $fh, '<', $fi) or die "ERROR: Cannot open file \"$fi\": $!\n";
	my $fields = <$fh>;
	chomp ($fields);
	$fields =~s/\"+//g;
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

	my $sep = $params->{'sep_char'};
	my $local_opt = $params->{'local_opt'} || "";
	if ($local_opt !~m/local/i) {
		$local_opt = "";
	} else {
		$local_opt = "LOCAL";
	}
	
	$local_opt = $params->{'local_opt'} || "";
	my $sql = "LOAD DATA $local_opt INFILE ? INTO TABLE $tablename CHARACTER SET latin1 "
				. " FIELDS TERMINATED BY '" . $sep . "' ENCLOSED BY '" . $params->{'quote_char'} . "' "
				. " LINES TERMINATED BY '" . '\n' . "'"
				. " IGNORE 1 LINES "
				. "($fields)";

	##  OPTIONALLY ENCLOSED BY '"'
	##  REPLACE 

	&logger (7,"_load_csv_mysql_local_infile trying : $sql");

	my $count = _db_do_log($dbh, $sql, "SQL execute failed", bind => [$fi]);

	if ($count !~m/^\d+$/) { # or $count = "0E0") {
		return (-1, &logger (3, "$count-ERROR LOAD INFILE-$@ $!".$dbh::errstr));
	}

	my $rows = _count_csv_rows($fi, $params);
	&logger(4, "bulk insert into $tablename via LOAD DATA INFILE: $rows rows");
	return ($count, " lines inserted");
}


sub _load_csv_mysql_local_infile ($$$$) {
	my ($dbh, $tablename, $fi, $params) = @_;

	# read the header line: it holds the field names and the insert order
	open(my $fh, '<', $fi) or die "ERROR: Cannot open file \"$fi\": $!\n";
	my $fields = <$fh>;
	chomp ($fields);
	$fields =~s/\"+//g;
	close($fh);

	my $sep = $params->{'sep_char'};
	my $sql = "LOAD DATA LOCAL INFILE ? INTO TABLE $tablename CHARACTER SET latin1 "
				. " FIELDS TERMINATED BY '" . $sep . "' ENCLOSED BY '" . $params->{'quote_char'} . "' "
				. " LINES TERMINATED BY '" . '\n' . "'"
				. " IGNORE 1 LINES "
				. "($fields)";
	&logger (7, $sql);

	##  OPTIONALLY ENCLOSED BY '"'
	##  REPLACE 

	&logger (7,"_load_csv_mysql_local_infile trying : $sql");

	my $count = _db_do_log($dbh, $sql, "SQL execute failed", bind => [$fi]);

	if ($count !~m/^\d+$/) { # or $count = "0E0") {
#		&logger (3, "$count-ERROR LOAD INFILE-$@ $!".$dbh::errstr);
		return (-1, &logger (3, "$count-ERROR LOAD INFILE-$@ $!".($dbh::errstr || "")));
	}

	# Refresh the planner statistics after the bulk load (parity with the PG COPY path).
	eval { local $dbh->{PrintError} = 0; $dbh->do("analyze table $tablename"); 1 }
		or &logger(7, "_load_csv_mysql_local_infile: analyze table $tablename failed: $@");

	my $rows = _count_csv_rows($fi, $params);
	&logger(4, "bulk insert into $tablename via LOAD DATA LOCAL INFILE: $rows rows");
	return ($count, " lines inserted");
}


# ============================================================
# PRIVATE : serialize one CSV field (RFC4180 style).
#   undef    => unquoted empty field => read as NULL by COPY (NULL '')
#   ''       => force-quoted ""      => read as empty string (clean_val parity)
#   otherwise=> quoted only when needed (sep, quote, CR or LF inside)
# ============================================================
sub _pg_csv_field {
	my ($val, $sep, $quo) = @_;
	return '' unless defined $val;
	return $val unless $val eq ''
		|| index($val, $sep) >= 0
		|| index($val, $quo) >= 0
		|| $val =~ /[\r\n]/;
	(my $esc = $val) =~ s/\Q$quo\E/$quo$quo/g;
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
	my ($data, $cols, $sep, $quo, $blank_to_null, $col_size) = @_;
	my @out;
	for my $i (0 .. $#{$cols}) {
		my $v = $data->[$i];
		if (defined $v) {
			if ($v eq '') {
				if ($blank_to_null->[$i]) {
					&logger(7, "clean_val: col '$cols->[$i]' numeric/date, '' => undef")
						if $LOGGERLEVEL >= 7;
					$v = undef;
				}
			} elsif ($col_size->[$i] && length($v) > $col_size->[$i]) {
				&logger(6, "clean_val: col '$cols->[$i]' truncated from "
					. length($v) . " to $col_size->[$i] chars")
					if $LOGGERLEVEL >= 6;
				$v = substr($v, 0, $col_size->[$i]);
			}
		}
		push @out, _pg_csv_field($v, $sep, $quo);
	}
	return join($sep, @out);
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
	my ($fi, $params, $cols, $blank_to_null, $col_size, $count_ref, $enc) = @_;
	my $sep = $params->{'sep_char'};
	my $quo = $params->{'quote_char'};

	open(my $fh, '<', $fi) or die "ERROR: Cannot open file \"$fi\": $!\n";
	my $csv = Text::CSV->new({ binary     => 1,
	                           sep_char   => $sep,
	                           quote_char => $quo });
	unless ($csv->getline($fh)) {     # skip the header record
		close($fh);
		die "ERROR: cannot read header of \"$fi\"\n";
	}

	my $closed = 0;
	return sub {
		return undef if $closed;
		my $eof   = 0;
		my $bytes = 0;
		my @rows;
		# Collect whole rows and join() them once per block. Appending to a scalar
		# and resetting it every block is quadratic and dominated the load ; join()
		# allocates the whole block in a single pass.
		while ($bytes < PG_COPY_BLOCK_SIZE) {
			my $data = $csv->getline($fh);
			if (!defined $data) {
				unless ($csv->eof) {
					die "CSV parse error near line " . ($$count_ref + 1)
						. " in \"$fi\": " . ($csv->error_diag // 'unknown') . "\n";
				}
				$eof = 1;
				last;
			}
			my $row = _pg_csv_row($data, $cols, $sep, $quo, $blank_to_null, $col_size);
			push @rows, $row;
			$bytes += length($row) + 1;    # +1 for the newline added by join()
			$$count_ref++;
		}
		if ($eof) { $closed = 1; close($fh); }
		return undef unless @rows;
		my $chunk = join("\n", @rows) . "\n";
		$chunk = encode($enc, $chunk) if defined $enc;
		return $chunk;
	};
}

# Map a PostgreSQL client_encoding name to an Encode name.
# Text::CSV (binary=>1) returns decoded characters, so values must be
# re-encoded to the session client_encoding before COPY reads the bytes.
sub _pg_encoding_name {
	my ($pg) = @_;
	my $n = uc($pg // '');
	$n =~ s/[^A-Z0-9]//g;
	my %map = (
		UTF8   => 'UTF-8',      UNICODE => 'UTF-8',
		LATIN1 => 'ISO-8859-1',  LATIN2 => 'ISO-8859-2',
		LATIN3 => 'ISO-8859-3',  LATIN4 => 'ISO-8859-4',
		LATIN5 => 'ISO-8859-9',  LATIN6 => 'ISO-8859-10',
		LATIN7 => 'ISO-8859-13', LATIN8 => 'ISO-8859-14',
		LATIN9 => 'ISO-8859-15', LATIN10 => 'ISO-8859-16',
	);
	return $map{$n} if exists $map{$n};
	return "CP$1" if $n =~ /^WIN(\d+)$/;
	return $n if $n ne '' && defined find_encoding($n);
	return 'UTF-8';
}

# ============================================================
# PRIVATE : count the CSV data records (header excluded) so a bulk
# load can report how many rows it is about to inject. getline (not
# parse) is used so a quoted field may span several physical lines.
# Returns the number of data records, or -1 when the file is unreadable.
# ============================================================
sub _count_csv_rows {
	my ($fi, $params) = @_;
	open(my $fh, '<', $fi) or return -1;
	my $csv = Text::CSV->new({ binary     => 1,
	                           sep_char   => $params->{'sep_char'}   // ',',
	                           quote_char => $params->{'quote_char'} // '"',
	});
	$csv->getline($fh);            # skip the header record
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
	my ($dbh, $sql, $next_block) = @_;
	my $emsg;
	my $copy_live = 0;
	eval {
		local $dbh->{PrintError} = 0;
		$dbh->do($sql);
		$copy_live = 1;
		while (defined(my $chunk = $next_block->())) {
			defined $dbh->pg_putcopydata($chunk)
				or die ($dbh->errstr || "pg_putcopydata failed");
		}
		$copy_live = 0;              # pg_putcopyend always ends the COPY
		$dbh->pg_putcopyend();
		1;
	} or $emsg = $@;
	$emsg ||= ($dbh->err ? $dbh->errstr : '');
	if ($emsg) {
		eval { $dbh->pg_putcopyend() } if $copy_live;  # abort a live COPY
		return $emsg;
	}
	return undef;
}

# ============================================================
# PRIVATE : quote a PostgreSQL identifier ("" doubling).
# ============================================================
sub _pg_quote_ident {
	my ($name) = @_;
	(my $s = $name) =~ s/"/""/g;
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
	my ($dbh, $table, $defer_pk) = @_;
	my ($oid) = $dbh->selectrow_array("SELECT to_regclass(?)::oid", undef, $table);
	return { drop => [], create => [] } unless $oid;

	my (@drop, @create);

	# Secondary indexes that back no constraint and are referenced by no FK.
	my $idx = $dbh->selectall_arrayref(
		"SELECT n.nspname, c.relname, pg_get_indexdef(i.indexrelid)"
		. " FROM pg_index i"
		. " JOIN pg_class c ON c.oid = i.indexrelid"
		. " JOIN pg_namespace n ON n.oid = c.relnamespace"
		. " WHERE i.indrelid = ? AND NOT i.indisprimary"
		. "   AND NOT EXISTS (SELECT 1 FROM pg_constraint k WHERE k.conindid = i.indexrelid)",
		undef, $oid);
	foreach my $r (@$idx) {
		my ($nsp, $name, $def) = @$r;
		push @drop,   "DROP INDEX " . _pg_quote_ident($nsp) . "." . _pg_quote_ident($name);
		push @create, $def;
	}

	# Unique and foreign-key constraints on this table -- plus the primary key
	# when $defer_pk is set -- except any whose index a foreign key depends on.
	my $cons = $dbh->selectall_arrayref(
		"SELECT c.conname, pg_get_constraintdef(c.oid) FROM pg_constraint c"
		. " WHERE c.conrelid = ? AND c.contype IN ('u','f'" . ($defer_pk ? ",'p'" : "") . ")"
		. "   AND NOT (c.contype IN ('u','p') AND EXISTS (SELECT 1 FROM pg_constraint k"
		. "                                             WHERE k.conindid = c.conindid"
		. "                                               AND k.contype = 'f'))",
		undef, $oid);
	foreach my $r (@$cons) {
		my ($cname, $cdef) = @$r;
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
	my ($dbh, $tablename, $sql, $make_supplier, $ddl) = @_;
	my $own   = $dbh->{AutoCommit} ? 1 : 0;
	my $phase = 'begin';
	my $ok = eval {
		$dbh->begin_work if $own;
		eval { local $dbh->{PrintError} = 0; $dbh->do(PG_COPY_SYNC_OFF); 1 }
			or &logger(4, "_pg_load_tx: SET LOCAL failed: $@");
		$phase = 'defer';
		foreach my $s (@{ $ddl->{drop} }) {
			$dbh->do($s) or die($dbh->errstr || "drop failed: $s");
		}
		$phase = 'copy';
		my $err = _pg_copy_stdin($dbh, $sql, $make_supplier->());
		die $err if defined $err;
		$phase = 'rebuild';
		foreach my $s (@{ $ddl->{create} }) {
			$dbh->do($s) or die($dbh->errstr || "create failed: $s");
		}
		$dbh->commit if $own;
		1;
	};
	return ('ok', '') if $ok;

	my $err = $@ // '';
	eval { $dbh->rollback } if $own && !$dbh->{AutoCommit};
	$err =~ s/\s+\z//;
	return ($phase eq 'defer' ? 'defer' : 'fail', $err);
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
sub _load_csv_pg_copy ($$$$$) {
	my ($dbh, $tablename, $fi, $params, $norm_id) = @_;

	my $sep = $params->{'sep_char'};
	my $quo = $params->{'quote_char'};

	# COPY reads the bytes in the session client_encoding; encode rows to
	# match what the row-by-row DBI path would send.
	my $enc = _pg_encoding_name(eval { $dbh->selectrow_array('SHOW client_encoding') });
	&logger(7, "_load_csv_pg_copy: client_encoding=".($enc // 'raw'));

	# Read the header record for column names and insertion order.
	# getline (not parse) so a quoted field may span several physical lines.
	open(my $fh, '<', $fi) or return (-1, &logger(3, "_load_csv_pg_copy: cannot open \"$fi\": $!"));
	my $csv = Text::CSV->new({ binary     => 1,
	                           sep_char   => $sep,
	                           quote_char => $quo });
	my $hdr = $csv->getline($fh);
	unless ($hdr) {
		close($fh);
		return (-1, &logger(3, "_load_csv_pg_copy: cannot read header of \"$fi\""));
	}
	close($fh);
	my @cols = map { $norm_id->($_) } @$hdr;

	# Same column metadata as the row-by-row path, flattened into positional
	# arrays so the per-row loop does no hash lookup.
	my $col_meta      = _get_col_meta($dbh, $tablename, $norm_id);
	my @blank_to_null = map { ($col_meta->{$_} // {})->{blank_to_null} ? 1 : 0 } @cols;
	my @col_size      = map { ($col_meta->{$_} // {})->{size} // 0 } @cols;

	# COPY ... FROM STDIN : NULL '' makes an unquoted empty field a NULL.
	my $sql = "COPY $tablename (" . join(',', @cols) . ")"
	        . " FROM STDIN WITH (FORMAT csv, DELIMITER '" . $sep . "',"
	        . " QUOTE '" . $quo . "', NULL '')";
	&logger(7, $sql);

	# $make_supplier returns a fresh byte supplier for each COPY attempt so the
	# single retry path re-reads the source ; $count is reset on every attempt.
	my $count = 0;
	my $make_supplier = sub {
		$count = 0;
		_pg_csv_supplier($fi, $params, \@cols, \@blank_to_null, \@col_size, \$count, $enc);
	};

	# Default path (pg_copy_optimize unset or true) : load inside one
	# transaction, dropping the target table's secondary indexes and unique /
	# foreign-key constraints (plus the primary key when pg_copy_defer_pk is
	# set) for the duration of the COPY, relaxing synchronous_commit for that
	# transaction only and refreshing the planner statistics at the end. If the
	# DDL cannot be dropped, the load is retried once without deferral. Passing
	# pg_copy_optimize => 0 keeps the historical plain COPY.
	my ($status, $emsg) = ('ok', '');
	if ($params->{'pg_copy_optimize'} // 1) {
		my $ddl = eval { _pg_deferrable_ddl($dbh, $tablename, $params->{'pg_copy_defer_pk'}) };
		&logger(4, "_load_csv_pg_copy: deferral lookup failed: $@") unless $ddl;
		$ddl ||= { drop => [], create => [] };
		($status, $emsg) = _pg_load_tx($dbh, $tablename, $sql, $make_supplier, $ddl);
		if ($status eq 'defer') {
			&logger(4, "_load_csv_pg_copy: deferral unavailable ($emsg), retrying without it");
			($status, $emsg) = _pg_load_tx($dbh, $tablename, $sql, $make_supplier,
			                               { drop => [], create => [] });
		}
	} else {
		my $err = _pg_copy_stdin($dbh, $sql, $make_supplier->());
		($status, $emsg) = defined $err ? ('fail', $err) : ('ok', '');
	}

	if ($status ne 'ok') {
		chomp($emsg //= '');
		return (-1, &logger(3, "_load_csv_pg_copy: COPY into $tablename failed: $emsg"));
	}

	# Refresh the planner statistics for the freshly loaded table (best effort).
	eval { local $dbh->{PrintError} = 0; $dbh->do(sprintf(PG_COPY_ANALYZE, $tablename)); 1 }
		or &logger(4, "_load_csv_pg_copy: ANALYZE $tablename failed: $@");

	&logger(4, "bulk insert into $tablename via COPY ... FROM STDIN: $count rows");
	return ($count, " lines inserted");
}



# ============================================================
# PRIVATE: normalize SQL identifiers
# according to the driver case (uc for MySQL/MariaDB, lc otherwise)
# ============================================================
sub _norm_identifiers {
    my ($dbh, $table, $cols_ref) = @_;

    my $driver   = lc( $dbh->{Driver}{Name} // '' );
    my $is_mysql = ( $driver =~ /mysql|mariadb/ ) ? 1 : 0;
    my $norm_id  = $is_mysql
        ? sub { my $s = $_[0]; $s =~ s/^\s+|\s+$//g; return uc($s) }
        : sub { my $s = $_[0]; $s =~ s/^\s+|\s+$//g; return lc($s) };

    # Normalize the table name, keeping the schema when present
    my $norm_table = join('.', map { $norm_id->($_) } split(/\./, $table, 2));

    # Normalize the columns (optional)
    my @norm_cols = map { $norm_id->($_) } @{ $cols_ref // [] };

    return ($norm_id, $norm_table, @norm_cols);
}


# ============================================================
# PRIVATE: column metadata for one table
# Returns { col_name => { numeric => 1, size => N } }
# The keys are normalized through $norm_id (supplied by _norm_identifiers)
# $table must already be normalized by the caller
# ============================================================

sub _get_col_meta {
    my ($dbh, $table, $norm_id) = @_;

    # $norm_id is mandatory - always supplied by _norm_identifiers
    die "_get_col_meta: norm_id missing" unless defined $norm_id;

    my $driver    = lc( $dbh->{Driver}{Name} // '' );
    my $cache_key = lc($table) . "\0" . $driver;
    return $_csv_import_type_cache{$cache_key}
        if exists $_csv_import_type_cache{$cache_key};

    my %meta;
    eval {
        # $table is already normalized by the caller: split without re-normalizing
        my ($schema, $table_name) = $table =~ /^(\w+)\.(\w+)$/
                                    ? ($1, $2)
                                    : (undef, $table);

        my $sth = $dbh->column_info(undef, $schema, $table_name, undef);

        # Fallback for drivers that do not support column_info (e.g. SQLite)
        # Degraded mode: column names without type or size
        unless (defined $sth) {
            &logger(5, "_get_col_meta: column_info unsupported for '$table_name', fallback SELECT");
            my $sth2 = $dbh->prepare("SELECT * FROM $table WHERE 1=0");
            $sth2->execute();
            for my $col (@{ $sth2->{NAME} }) {
                my $norm_col = $norm_id->($col);
                $meta{$norm_col} = { numeric => 0, size => 0 };
                &logger(7, "_get_col_meta (fallback): col=$norm_col");
            }
            $_csv_import_type_cache{$cache_key} = \%meta;
            return;
        }

        my %num_codes = map { $_ => 1 } (2, 3, 4, 5, 6, 7, 8, -5, -6, -7);
        my $found = 0;
        while (my $row = $sth->fetchrow_hashref) {
            $found++;
            my $col  = $norm_id->( $row->{COLUMN_NAME} // '' );
            my $type = $row->{DATA_TYPE}    // 0;
            my $name = lc($row->{TYPE_NAME} // '');
            my $size = $row->{COLUMN_SIZE}  // 0;

            my $by_name = ($name =~ m{
                ^( int[248]? | integer | smallint | bigint
                 | serial | bigserial | smallserial
                 | numeric | decimal | number
                 | float[48]? | real | double(\s+precision)?
                 | money | tinyint | mediumint )$
            }xi) ? 1 : 0;
            my $is_num = ($num_codes{$type} || $by_name) ? 1 : 0;

            # COLUMN_SIZE is a usable character length for truncation only
            # for text types. For numeric, date, time, etc. types, column_info
            # (in particular DBD::Pg) returns the internal storage size (e.g.
            # date(4), like an int4), which wrongly truncates values (e.g. a
            # date "2026-07-09" cut down to "2026" before the insert).
            my $is_text = ($name =~ m{
                ^( varchar | character(\s+varying)? | char | bpchar | text )
            }xi) ? 1 : 0;

            # Types that need the '' => NULL conversion on insert: the
            # numeric ones (already covered by is_num) plus the date/time
            # types, for which PostgreSQL rejects an empty string
            # ('ERROR: invalid input syntax for type date: ""').
            my $is_datetime = ($name =~ m{
                ^( date | time | timestamp(tz)? | datetime )
            }xi) ? 1 : 0;
            my $blank_to_null = ($is_num || $is_datetime) ? 1 : 0;

            $meta{$col} = {
                numeric       => $is_num,
                blank_to_null => $blank_to_null,
                size          => ($is_text ? $size : 0),
            };
            &logger(7, "_get_col_meta: col=$col TYPE=$name($size) is_num=$is_num is_text=$is_text blank_to_null=$blank_to_null");
        }
        &logger(5, "_get_col_meta: $found columns for '$table_name'");
    };
    if ($@) {
        &logger(3, "_get_col_meta: column_info failed for $table: $@");
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
        my ($col, $val) = @_;
        return undef unless defined $val;
        my $m = $col_meta->{ $col } // {};

        if ($val eq '') {
            if ($m->{blank_to_null}) {
                &logger(7, "clean_val: col '$col' numeric/date, '' => undef");
                return undef;
            }
            return $val;
        }

        if ($m->{size} && length($val) > $m->{size}) {
            my $truncated = substr($val, 0, $m->{size});
            &logger(6, "clean_val: col '$col' truncated from ".length($val)." to $m->{size} chars");
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

    my ($norm_id, $norm_table, @norm_cols) = _norm_identifiers(
        $p{'dbh'}, $p{'table'}, $p{'tCols'}
    );

    my $col_meta  = _get_col_meta($p{'dbh'}, $norm_table, $norm_id);
    my $clean_val = _make_clean_val($col_meta);

    &logger(7, "Table : $norm_table");
    &logger(7, "NB Data : " . scalar @{$p{'tData'}});
    &logger(7, "Data : " . Dumper($p{'tData'}));

    my $sql = "INSERT INTO " . $norm_table
            . " (" . join(',', @norm_cols) . ")"
            . " VALUES (" . join(',', ('?') x @norm_cols) . ")";
    &logger(7, $sql);

    my $sth = $p{'dbh'}->prepare_cached($sql);
    do { local $sth->{PrintError} = 0; $sth->execute(
        map { $clean_val->($norm_cols[$_], $p{'tData'}[$_]) } 0..$#norm_cols
    ) } or &logger(3, "SQL execute failed " . $sth->err . "-" . $sth->errstr);
    1;
}


# ============================================================
# PUBLIC: import a CSV file into a table
# API unchanged
# ============================================================
sub csv_import ($$$;$) {
    my ($dbh, $table, $in, $params) = @_;
    $params->{'mode'}         = $params->{'mode'}         || "insert";
    $params->{'sep_char'}     = $params->{'sep_char'}      || ',';
    $params->{'quote_char'}   = $params->{'quote_char'}    || '"';
    $params->{'local_infile'} = $params->{'local_infile'}  || "no";

    # Normalize the driver and the table name
    # $norm_id is kept to normalize the CSV columns after reading the header
    my ($norm_id, $norm_table) = _norm_identifiers($dbh, $table);

    if ( $params->{'local_infile'} =~ /try/i
      && $params->{'mode'}         !~ /merge/i
      && $dbh->{'Name'}            =~ m/mysql_local_infile\=true/i ) {
        &logger(7, "'mysql_local_infile=true' detected in DSN by csv_import, trying local infile");
        return _load_csv_mysql_local_infile($dbh, $norm_table, $in, $params);
    }

    # PostgreSQL: COPY ... FROM STDIN is the native equivalent of LOAD DATA LOCAL INFILE.
    # Enabled automatically for the Pg driver (merge mode keeps the row-by-row path).
    if ( $params->{'mode'} !~ /merge/i
      && _db_check_driver_name($dbh) eq "PostgreSQL" ) {
        &logger(7, "PostgreSQL driver detected by csv_import, trying COPY FROM STDIN");
        return _load_csv_pg_copy($dbh, $norm_table, $in, $params, $norm_id);
    }

    open(my $fh, '<', $in) or die "ERROR: Cannot open index file \"$in\": $!\n";
    my $csv = Text::CSV->new({ binary     => 1,
                               sep_char   => $params->{'sep_char'},
                               quote_char => $params->{'quote_char'} });

    my ($line, $lines_inserted, $rv);
    if (defined $params->{'header'}) {
        $line = $params->{'header'};
    } else {
        $line = <$fh>;
    }
    $csv->parse($line);

    # The CSV columns are normalized through $norm_id after reading the header,
    # since they are only known at that point (unlike insert_tData)
    my @cols = map { $norm_id->($_) } $csv->fields();

    if (defined $params->{'ignore_first_line'}) {
        $line = <$fh>;
    }

    # $norm_table and $norm_id are consistent: the %$col_meta keys
    # are in the same case as @cols
	my $col_meta  = _get_col_meta($dbh, $norm_table, $norm_id);
    my $clean_val = _make_clean_val($col_meta); 

    while (<$fh>) {
        $lines_inserted++;
        $csv->parse($_);
        my @data = $csv->fields();
        my ($sql, $sth, $seqlot);

        if ($params->{'mode'} =~ /merge/i) {
            $sql = "SELECT " . $cols[0] . " FROM " . $norm_table
                 . " WHERE "  . $cols[0] . " = ?";
            &logger(8, "Select from $norm_table : $sql");
            $sth = $dbh->prepare_cached($sql);
            do { local $sth->{PrintError} = 0; $sth->execute( $clean_val->($cols[0], $data[0]) )
                } or &logger(3, "SQL execute failed ".$sth->err."-".$sth->errstr);
            $seqlot = $sth->fetchrow_hashref();

            # fetchrow_hashref returns keys in the driver's native case:
            # normalize so the comparison with $cols[0] is reliable
            if (defined $seqlot) {
                $seqlot = { map { $norm_id->($_) => $seqlot->{$_} } keys %$seqlot };
            }
        }

        if (defined $seqlot && defined $seqlot->{ $cols[0] }) {
            $sql = "UPDATE " . $norm_table
                 . " SET "   . join('=?, ', @cols) . "=? "
                 . " WHERE " . $cols[0] . " = ?";
            &logger(8, "Update $norm_table : $sql");
            $sth = $dbh->prepare_cached($sql);
            do { local $sth->{PrintError} = 0; $sth->execute(
                (map { $clean_val->($cols[$_], $data[$_]) } 0..$#cols),
                $clean_val->($cols[0], $data[0])
            ) } or &logger(3, "SQL execute failed ".$sth->err."-".$sth->errstr);
        } else {
            $sql = "INSERT INTO " . $norm_table
                 . " (" . join(',', @cols) . ")"
                 . " VALUES (" . join(',', ('?') x @cols) . ")";
            &logger(7, "Insert into $norm_table : $sql");
            $sth = $dbh->prepare_cached($sql);
            do { local $sth->{PrintError} = 0; $sth->execute(
                map { $clean_val->($cols[$_], $data[$_]) } 0..$#cols
            ) } or &logger(3, "SQL execute failed ".$sth->err."-".$sth->errstr);
        }

        if ($sth->err && ($sth->err > 0 || $sth->err =~ m/0E/)) {
            $rv = $sth->err."-".$sth->errstr;
        }
    }

    close($fh);
    if ($rv) {
        &logger(-1, $rv);
        return (-1, " - $rv");
    } else {
        $lines_inserted //= 0;
        &logger(5, "$lines_inserted lines inserted from $in");
        return ($lines_inserted, " lines inserted");
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
	my ($cfg, $dsnvar, $dbargs) = @_;
	my $dbh;
	my $dsn = $cfg->{$dsnvar};
	$_LOCAL_EDTK_WAITRUN = $cfg->{EDTK_WAITRUN};

	&logger (5, "Connecting to DSN $dsn, $dsnvar");
	
	# TODO review attribute handling for displaying error messages:
	# https://docstore.mik.ua/orelly/linux/dbi/ch04_05.htm

	# connection handled in a timed loop: 3 attempts with an increasing pause
	for (my $i=0;$i<3;$i++){
		sleep ($_LOCAL_EDTK_WAITRUN*$i);
		eval {
			$dbh=DBI->connect($dsn, $cfg->{"${dsnvar}_USER"}, $cfg->{"${dsnvar}_PASS"}, $dbargs); ## xxxx
		};

		if ($@){
			# on a connection failure, try again
			&logger (4, "DBI connection missmatch to $dsnvar, we try 3 times");
			&logger (4, "Error message was : $@");

		} else {
			# if it looks fine, we are done

			if ($CONNECT_COUNT == 1 
					and $dsnvar ne "EDTK_DBI_PARAM" 
					#and ($cfg->{EDTK_DB_CHECK_AUTO}||"YES")!~/NO/i
					#and (defined $cfg->{EDTK_DB_CHECK_AUTO} && $cfg->{EDTK_DB_CHECK_AUTO} =~/YES/i)
					and ($cfg->{EDTK_DB_CHECK_AUTO} =~/YES/i)
					and looks_like_number($cfg->{EDTK_DB_MAX_DAYS_KEPT})
					and looks_like_number($cfg->{EDTK_DB_MAX_DAYS_KEPT_STATS})
					and	looks_like_number($cfg->{EDTK_DB_MAX_DAYS_TRACKED})
				){
				my ($level, $return) = acheck_db_admin_on_connect ($dbh, $cfg);
				&logger ($level, "$return-$dsn");
			}
			$CONNECT_COUNT++;

			$i=4;
		}
	}
	return $dbh;	
}


sub db_connect {
	my ($cfg, $dsnvar, $dbargs) = @_;
#	$dbargs->{'RaiseError'} = 1;

	# This avoids problems with PostgreSQL where in some cases, the column
	# names are lowercase instead of uppercase, defaukt set as uc.
	$dbargs->{'FetchHashKeyName'} = $cfg->{EDTK_DB_FetchHashKeyName} || 'NAME_uc';;

	#$dbh = DBI->connect($dsn, $user, $password,
	#                    { RaiseError => 1, AutoCommit => 0 });

	# Connect to the database.
	my $dbh = _db_connect1($cfg, $dsnvar, $dbargs);

    # If we could not connect to the database server, try
	# to connect to the backup database server if there is one.
	if (!defined $dbh) {
		if (defined $cfg->{"${dsnvar}_BAK"}) { # TODO the setting should be added in the backup database (procedure that creates it)
			&logger (4, "Could not connect to main database server: " . ($DBI::errstr || "not defined"));
			$dbh = _db_connect1($cfg, "${dsnvar}_BAK", $dbargs);
			
			if (!defined $dbh) {
				die "ERROR: Could not connect to backup database server : " . ($DBI::errstr || "not defined") ."\n";
			}
			# Store-and-forward: flag that we are writing on the backup buffer and
			# make sure it can hold the event tables. db_reconcile_backup will copy
			# the accumulated rows back once the main server is reachable again.
			$dbh->{'private_oEdtk_on_backup'} = 1;
			&logger (3, "Writing to the BACKUP database (main unreachable): data is buffered and will be repatriated.");
			eval { db_backup_prepare($dbh); };
		} else {
			die "ERROR: Could not connect to database server : " . ($DBI::errstr || "not defined") ."\n";
		}
	}

	if (_table_exists($dbh,  $cfg->{'EDTK_DBI_TRACKING'})) {
		# silent soft check
	} else {
		create_table_TRACKING($dbh, $cfg->{'EDTK_DBI_TRACKING'}, $cfg->{'EDTK_MAX_USER_KEY'});
	}

	return $dbh;
}

# Run a DML statement, routing any driver error through the logger (see the
# &logger calls below) rather than letting DBI's PrintError dump the raw message
# to STDERR. Returns do()'s result (truthy even for 0 rows, "0E0", as DBI does)
# or undef on failure. Never dies: pass fatal => 1 to log then re-raise (so $@
# carries the message); pass bind => [..] for placeholder arguments.
sub _db_do_log {
    my ($dbh, $sql, $msg, %opt) = @_;
    my $res = do {
        local $dbh->{PrintError} = 0;
        local $dbh->{RaiseError} = 0;
        eval { $dbh->do($sql, undef, @{ $opt{bind} // [] }) };
    };
    return $res if defined $res;
    my $full = $msg . ": " . ($dbh->errstr // $@ // 'unknown error');
    die &logger(-1, $full) if $opt{fatal};
    &logger(3, $full);
    return undef;
}

sub _table_exists {
    my ($dbh, $table_name) = @_;
	# universal soft and silent check

    # table_info takes 4 arguments: catalog, schema, table, type
    # Pass undef for the global filters and target the table name
    my $sth = $dbh->table_info(undef, undef, $table_name, 'TABLE');
    
    # If fetchrow_array returns a row, the table exists
    my @info = $sth->fetchrow_array();
    
    return @info ? 1 : 0;
}

# Job on request
sub acheck_db_admin2 {
    my (%p) = @_;
    my $date = strftime("%Y-%m-%d", localtime);

    my $dbh = db_connect($p{CFG}, 'EDTK_DBI_DSN');
    my ($last) = $dbh->selectrow_array(
        'select 1 from edtk_admin where ed_action_date = ?', undef, $date
    );
    $dbh->disconnect;
    return if $last;

    _db_with_lock(
        CFG  => $p{CFG},
        code => sub {
            my $dbh = shift;
            _db_maintenance(DBH => $dbh, CFG => $p{CFG}, rotate => 1, purge => 1);
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
	my $date =strftime "%Y-%m-%d", localtime;
	my ($sth, $sql);
	&logger (4,"ACHECK lookup");
	
	# LOOK FOR THE LAST ACTION ON THE ADMIN TABLE
	$sql = "select ed_action_date, ed_action_pid, ed_action_status, ed_action_duration, ed_oedtk_release from edtk_admin " 
			. " where ed_action_date = '"
			. $date
			. "'  "; #order by ed_action_date desc limit 1";
	&logger (7, $sql);

	$p{DBH}	= db_connect($p{CFG}, 'EDTK_DBI_DSN');
	$sth 	= $p{DBH}->prepare($sql) or return (3, $p{DBH}->errstr);
	do { local $sth->{PrintError} = 0; $sth->execute() } or &logger (3, "SQL execute failed ".$sth->err."-".$sth->errstr);

	# HAS AN ADMINISTRATION ACTION ALREADY BEEN DONE TODAY ?
	my @tValues = $p{DBH}->selectrow_array($sql, undef);# or warn ("ERROR: in acheck_db_admin_on_connect, message is " . $dbh->errstr);
	my $rc = $sth->finish;
	$p{DBH}->disconnect;

	if ($tValues[0] and $date eq $tValues[0]){
		&logger(5, ("Previously done, ACHECK Last EDTK_DB_MAX_DAYS check : ". $tValues[0] ." PID ". $tValues[1]));
		return (5, ("ACHECK Last EDTK_DB_MAX_DAYS check : ". $tValues[0] ." PID ". $tValues[1]));
	}

	return _acheck_request_for_db(CFG => $p{CFG});
}


sub _acheck_request_for_db {
	# example call
	# _acheck_request_for_db (CFG => $cfg, DBH => $dbh);
	my %p = @_;

	my $time =time;
	my $date =strftime "%Y-%m-%d", localtime;
	my $pid  =$$;
	my ($rc, $sth, $sql, $insert, $reportActions);

	# REQUEST A TICKET TO CARRY OUT THE ACTIONS
	$insert = 'insert into edtk_admin (ed_action_date, ed_action_pid, ed_action_status, ed_oedtk_release) '
			. ' values (?, ?, ?, ?) ';
	$p{DBH} = db_connect($p{CFG}, 'EDTK_DBI_DSN');
	$sth 	= $p{DBH}->prepare_cached($insert);

	eval {
		do { local $sth->{PrintError} = 0; $sth->execute($date, $pid, "START", $VERSION) } or &logger (3, "SQL execute failed ".$sth->err."-".$sth->errstr);
	};
	if ($@) {
		&logger(3, "ERROR: $@ into $insert");
	}

	# CHECK THAT WE HOLD THE LOCK FOR THE ACTION
	# LOOK FOR THE LAST ACTION ON THE ADMIN TABLE
	$sql = "select ed_action_date, ed_action_pid, ed_action_status, ed_action_duration, ed_oedtk_release from edtk_admin " 
			. " where ed_action_date = '"
			. $date
			. "'  "; #order by ed_action_date desc limit 1";
	&logger (7, $sql);

	$sth = $p{DBH}->prepare($sql);
	do { local $sth->{PrintError} = 0; $sth->execute() } or &logger (3, "SQL execute failed ".$sth->err."-".$sth->errstr);
	my @tValues = do { local $p{DBH}->{PrintError} = 0; $p{DBH}->selectrow_array($sql, undef) } or &logger(3, "ERROR: in acheck_db_admin_on_connect, message is ".$p{DBH}->errstr);
	$reportActions = "ACHECK Check 1 : ". $tValues[0] ." PID ". $tValues[1];
	$rc = $sth->finish;
	$p{DBH}->disconnect;

	if ($date eq $tValues[0] and $pid eq $tValues[1]){
		&logger (5, $reportActions);
		$reportActions .=_acheck_db_rotate(CFG => $p{CFG});
		$reportActions .=_acheck_db_purges(CFG => $p{CFG});
		
	} else {
		# another process took the action, giving up
		&logger(6, "failed, process locked");
		return (5, $reportActions);
	}

	# End of the run
	$time=time-$time;
	$sql = 'update edtk_admin set ed_action_status = ?, ed_action_duration = ? where ed_action_date = ?';
	&logger (7, $sql);

	$p{DBH} = db_connect($p{CFG}, 'EDTK_DBI_DSN');
	_db_do_log($p{DBH}, $sql, "ERROR: can't update ED_ACTION_STATUS", bind => ["DONE", $time, $date]);

	$rc = $sth->finish;
	$p{DBH}->disconnect;
	return (4, $reportActions);
}


sub _acheck_db_purges {
	my %p = @_;
	
#	my $time =time;
#	my $date =strftime "%Y-%m-%d", localtime;
#	my $day  =strftime "%d", localtime;
	my ($sql, $insert, $result, $reportActions);
#	my $DAYS_KEPT_time			= time - (86400*$p{CFG}->{EDTK_DB_MAX_DAYS_KEPT});
	my $DAYS_TRACKED_time		= time - (86400*$p{CFG}->{EDTK_DB_MAX_DAYS_TRACKED});
	my $DAYS_KEPT_STATS_time	= time - (86400*$p{CFG}->{EDTK_DB_MAX_DAYS_KEPT_STATS});
	my $DAYS_AGREGED_time		= time - (86400*($p{CFG}->{EDTK_DB_MAX_DAYS_AGREGED} || $p{CFG}->{EDTK_DB_MAX_DAYS_TRACKED}));


	### STATS PURGES ###
	# PURGE FROM OEDTK_ADMIN
	$sql = "delete from edtk_admin where ed_action_date < '" 
			. (strftime "%Y-%m-%d", localtime($DAYS_TRACKED_time))."'";
	&logger (7, $sql);

	$p{DBH} = db_connect($p{CFG}, 'EDTK_DBI_DSN');
	$result = _db_do_log($p{DBH}, $sql, "ERROR: can't update edtk_admin") or return;
	$p{DBH}->disconnect;
	&logger (6,"RESULT = " . ($result || 0) ." for $sql");
	$reportActions = "ACHECK PURGE edtk_admin=" . ($result || 0);

	# PURGE FROM EDTK_DBI_TRACKING
	$sql = "delete from " 
			. $p{CFG}->{'EDTK_DBI_TRACKING'} 
			. " where ed_tstamp < '" . (strftime "%Y%m%d", localtime($DAYS_TRACKED_time)) . "000000'";
	&logger (7, $sql);

	$p{DBH} = db_connect($p{CFG}, 'EDTK_DBI_DSN');
	$result = _db_do_log($p{DBH}, $sql, "ERROR: can't update ".$p{CFG}->{'EDTK_DBI_TRACKING'}) or return;
	$p{DBH}->disconnect;
	&logger (6,"RESULT = " . ($result || 0) ." for $sql");
	$reportActions .= "-PURGE TRACKING=" . ($result || 0);

	# PURGE FROM EDTK_DBI_DISTRIB_STATS 
	$sql = "delete from " 
			. $p{CFG}->{'EDTK_DBI_DISTRIB_STATS'}
			. " where ed_dtlot < '" . (strftime "%Y-%m-%d", localtime($DAYS_KEPT_STATS_time)) ."'"; # note: NOT REGEXP_LIKE (ED_DTLOT, '\d\d\d\d-\d\d-\d\d') does not work on MySQL...
	&logger (7, $sql);

	$p{DBH} = db_connect($p{CFG}, 'EDTK_DBI_DSN');
	$result = _db_do_log($p{DBH}, $sql, "ERROR: can't update ".$p{CFG}->{'EDTK_DBI_DISTRIB_STATS'}) or return;
	$p{DBH}->disconnect;
	&logger (6,"RESULT = " . ($result || 0) ." for $sql");
	$reportActions .= "-PURGE DISTRIB_S=" . ($result || 0);

	# PURGE FROM OUTMNGR_STATS 
	$sql = "delete from " 
			. $p{CFG}->{'EDTK_DBI_OUTMNGR_STATS'}
			. " where ed_dtlot < '" . (strftime "%Y-%m-%d", localtime($DAYS_KEPT_STATS_time)) ."'";
	&logger (7, $sql);

	$p{DBH} = db_connect($p{CFG}, 'EDTK_DBI_DSN');
	$result = _db_do_log($p{DBH}, $sql, "ERROR: can't update ".$p{CFG}->{'EDTK_DBI_OUTMNGR_STATS'}) or return;
	$p{DBH}->disconnect;
	&logger (6,"RESULT = " . ($result || 0) ." for $sql");
	$reportActions .= "-PURGE OUTMNGR_S=" . ($result || 0);

	# PURGE FROM EDTK_AGREGE
	$sql = "delete from edtk_agrege " 
			. " where ed_dtlot < '" . (strftime "%Y-%m-%d", localtime($DAYS_AGREGED_time)) ."'";
	&logger (7, $sql);

	$p{DBH} = db_connect($p{CFG}, 'EDTK_DBI_DSN');
	$result = _db_do_log($p{DBH}, $sql, "ERROR: can't update EDTK_AGREGE") or return;
	$p{DBH}->disconnect;
	&logger (6,"RESULT = " . ($result || 0) ." for $sql");
	$reportActions .= "-PURGE AGREGE=" . ($result || 0);

	
	### EDTK_ID ###
	# PURGE FROM EDTK_ID 
	$sql = "delete from edtk_id"
			. " where ed_id_date < '" . (strftime "%Y-%m-%d", localtime($DAYS_TRACKED_time)) ."'";
	&logger (7, $sql);

	$p{DBH} = db_connect($p{CFG}, 'EDTK_DBI_DSN');
	$result = _db_do_log($p{DBH}, $sql, "ERROR: can't update ".$p{CFG}->{'EDTK_DBI_OUTMNGR_STATS'});
	$p{DBH}->disconnect;
	&logger (6,"RESULT = " . ($result || 0) ." for $sql");
	$reportActions .= "-PURGE EDTK_ID=" . ($result || 0);

	return &logger(4, $reportActions);
}


sub _acheck_db_rotate {
	my %p = @_;

#	my $time =time;
#	my $date =strftime "%Y-%m-%d", localtime;
#	my $day  =strftime "%d", localtime;
#	my $pid  =$$;
	my ($sql, $insert, $result, $reportActions);
	$p{DBH} = db_connect($p{CFG}, 'EDTK_DBI_DSN');
	# Repatriate any pending backup rows before rotating / purging.
	eval { _db_maybe_reconcile($p{DBH}, $p{CFG}); };
	my $stamp =strftime "%Y%m%d%H%M%S", localtime;

	my $DAYS_KEPT_time			= time - (86400*$p{CFG}->{EDTK_DB_MAX_DAYS_KEPT});
	my $DAYS_KEPT_STATS_time	= time - (86400*$p{CFG}->{EDTK_DB_MAX_DAYS_KEPT_STATS});
	my $DAYS_TRACKED_time		= time - (86400*$p{CFG}->{EDTK_DB_MAX_DAYS_TRACKED});
	my $DAYS_AGREGED_time		= time - (86400*($p{CFG}->{EDTK_DB_MAX_DAYS_AGREGED} || $p{CFG}->{EDTK_DB_MAX_DAYS_TRACKED}));

	### ROTATIONS ###
	### EDTK_AGREGE ### 
	# MOVE DATA TO EDTK_AGREGE
		$sql = "insert into edtk_agrege "
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
			. "where d.ed_dtlot < '" . (strftime "%Y-%m-%d", localtime($DAYS_KEPT_time)) ."' "
			. "group by "
			. "i.ed_source, "
			. "d.ed_chanel_out, "
			. "i.ed_refiddoc, "
			. "i.ed_idproduct," 
			. "i.ed_dtedtion, "
			. "d.ed_dtlot, "
			. "d.ed_idlot, "
			. "d.ed_idjob ";
	&logger (7,"SQL = $sql");

	$result = _db_do_log($p{DBH}, $sql, "ERROR: can't update EDTK_AGREGE", fatal => 1);
	&logger (6,"RESULT = " . ($result || 0) ." for $sql");
	$reportActions .= "-MV AGREGE=" . ($result || 0);

	### DISTRIB ###
	# MOVE DATA FROM DISTRIB TO DISTRIB_STATS
	$sql = "insert into " 
			. $p{CFG}->{'EDTK_DBI_DISTRIB_STATS'}
			. " select * from "
			. $p{CFG}->{'EDTK_DBI_DISTRIB'}
			. " where ed_dtlot < '" . (strftime "%Y-%m-%d", localtime($DAYS_KEPT_time)) ."'";
	&logger (7, $sql);

	$result = _db_do_log($p{DBH}, $sql, "ERROR: can't update ".$p{CFG}->{'EDTK_DBI_DISTRIB_STATS'}) or return;
	&logger (6,"RESULT = " . ($result || 0) ." for $sql");
	$reportActions .= "-MV DISTRIB=" . ($result || 0);

		# CLEAN DISTRIB 
		$sql = "delete from " 
				. $p{CFG}->{'EDTK_DBI_DISTRIB'}
				. " where ed_dtlot < '" . (strftime "%Y-%m-%d", localtime($DAYS_KEPT_time)) ."'";
		&logger (7, $sql);

		$result = _db_do_log($p{DBH}, $sql, "ERROR: can't update ".$p{CFG}->{'EDTK_DBI_DISTRIB_STATS'});
		&logger (6,"RESULT = " . ($result || 0) ." for $sql");
		$reportActions .= "/" . ($result || 0);

		
	### OUTMNGR ###
	# MOVE DATA FROM OUTMNGR TO OUTMNGR_STATS
	$sql = "insert into " 
			. $p{CFG}->{'EDTK_DBI_OUTMNGR_STATS'}
			. " select * from "
			. $p{CFG}->{'EDTK_DBI_OUTMNGR'}
			. " where ed_dtlot < '" . (strftime "%Y-%m-%d", localtime($DAYS_KEPT_time)) ."'";
	&logger (7, $sql);

	$result = _db_do_log($p{DBH}, $sql, "ERROR: can't update ".$p{CFG}->{'EDTK_DBI_OUTMNGR_STATS'});
	&logger (6,"RESULT = " . ($result || 0) ." for $sql");
	$reportActions .= "-MV OUTMNGR=" . ($result || 0);

		# CLEAN OUTMNGR 
		$sql = "delete from " 
				. $p{CFG}->{'EDTK_DBI_OUTMNGR'}
				. " where ed_dtlot < '" . (strftime "%Y-%m-%d", localtime($DAYS_KEPT_time)) ."'";
		&logger (7, $sql);

		$result = _db_do_log($p{DBH}, $sql, "ERROR: can't update ".$p{CFG}->{'EDTK_DBI_OUTMNGR_STATS'});
		&logger (6,"RESULT = " . ($result || 0) ." for $sql");
		$reportActions .= "/" . ($result || 0);

	$p{DBH}->disconnect;
	return (4, $reportActions);
}	


sub agrege_idJob {
	# EXAMPLE CALL:
	# agrege_idJob (CFG => $cfg, IDJOB => 'IdJob');
	my %p = @_;
	my $stamp =strftime "%Y%m%d%H%M%S", localtime;
	&logger (6,"p{CFG} = " . $p{CFG} . " - p{IDJOB} " . $p{IDJOB} );

	my ($sql, $insert, $result, $reportActions);
	$p{DBH} = db_connect($p{CFG}, 'EDTK_DBI_DSN');
	# Repatriate any pending backup rows before aggregating.
	eval { _db_maybe_reconcile($p{DBH}, $p{CFG}); };

	### ROTATIONS JobID ###
	### EDTK_AGREGE ### 
	# MOVE DATA TO EDTK_AGREGE
	
	$sql = "insert into edtk_agrege "
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
			. "where d.ed_idjob = '" . $p{IDJOB} ."' "
			. "group by "
			. "i.ed_source, "
			. "d.ed_chanel_out, "
			. "i.ed_refiddoc, "
			. "i.ed_idproduct," 
			. "i.ed_dtedtion, "
			. "d.ed_dtlot, "
			. "d.ed_idlot, "
			. "d.ed_idjob ";
	&logger (7,"SQL = $sql");

	$result = _db_do_log($p{DBH}, $sql, "ERROR: can't update edtk_agrege", fatal => 1);
	&logger (6,"RESULT = " . ($result || 0) ." for $sql");
	$reportActions .= "-MV AGREGE=" . ($result || 0);


	### DISTRIB ###
	# MOVE DATA FROM DISTRIB TO DISTRIB_STATS
	$sql = "insert into "
			. $p{CFG}->{'EDTK_DBI_DISTRIB_STATS'}
			. " select * from "
			. $p{CFG}->{'EDTK_DBI_DISTRIB'}
			. " where ed_idjob = '" . $p{IDJOB} ."'";
	&logger (7, $sql);

	$result = _db_do_log($p{DBH}, $sql, "ERROR: can't update ".$p{CFG}->{'EDTK_DBI_DISTRIB_STATS'}) or do { $p{DBH}->disconnect; return (4, $reportActions); };
	&logger (6,"RESULT = " . ($result || 0) ." for $sql");
	$reportActions .= "-MV DISTRIB=" . ($result || 0);

		# CLEAN DISTRIB
		$sql = "delete from "
				. $p{CFG}->{'EDTK_DBI_DISTRIB'}
			. " where ed_idjob = '" . $p{IDJOB} ."'";
		&logger (7, $sql);

		$result = _db_do_log($p{DBH}, $sql, "ERROR: can't update ".$p{CFG}->{'EDTK_DBI_DISTRIB_STATS'});
		&logger (6,"RESULT = " . ($result || 0) ." for $sql");
		$reportActions .= "/" . ($result || 0);

		
	### OUTMNGR ###
	# MOVE DATA FROM OUTMNGR TO OUTMNGR_STATS
	$sql = "insert into "
			. $p{CFG}->{'EDTK_DBI_OUTMNGR_STATS'}
			. " select * from "
			. $p{CFG}->{'EDTK_DBI_OUTMNGR'}
			. " where ed_idjob = '" . $p{IDJOB} ."'";
	&logger (7, $sql);

	$result = _db_do_log($p{DBH}, $sql, "ERROR: can't update ".$p{CFG}->{'EDTK_DBI_OUTMNGR_STATS'});
	&logger (6,"RESULT = " . ($result || 0) ." for $sql");
	$reportActions .= "-MV OUTMNGR=" . ($result || 0);

		# CLEAN OUTMNGR
		$sql = "delete from "
				. $p{CFG}->{'EDTK_DBI_OUTMNGR'}
			. " where ed_idjob = '" . $p{IDJOB} ."'";
		&logger (7, $sql);

		$result = _db_do_log($p{DBH}, $sql, "ERROR: can't update ".$p{CFG}->{'EDTK_DBI_OUTMNGR_STATS'});
		&logger (6,"RESULT = " . ($result || 0) ." for $sql");
		$reportActions .= "/" . ($result || 0);

	$p{DBH}->disconnect;
	return (4, $reportActions);
}	


sub acheck_db_admin_on_connect ($ $) {
	# https://www.forknerds.com/reduce-the-size-of-mysql/
	# my ($level, $return) = acheck_db_admin_on_connect ($dbh, $cfg);
	my $dbh  =shift;
	my $cfg  =shift;

	my $time =time;
	my $date =strftime "%Y-%m-%d", localtime;
	my $day  =strftime "%d", localtime;
	my $pid  =$$;
	my ($sth, $sql, $insert, $result, $reportActions);

	my $DAYS_KEPT_time			= time - (86400*$cfg->{EDTK_DB_MAX_DAYS_KEPT});
	my $DAYS_KEPT_STATS_time	= time - (86400*$cfg->{EDTK_DB_MAX_DAYS_KEPT_STATS});
	my $DAYS_TRACKED_time		= time - (86400*$cfg->{EDTK_DB_MAX_DAYS_TRACKED});
	my $DAYS_AGREGED_time		= time - (86400*($cfg->{EDTK_DB_MAX_DAYS_AGREGED} || $cfg->{EDTK_DB_MAX_DAYS_TRACKED}));
	#my $EDTK_DB_CHECK_MONTH_DAY = $cfg->{EDTK_DB_CHECK_MONTH_DAY} || 0; # to remove

	# Repatriate any pending backup rows before the maintenance check.
	eval { _db_maybe_reconcile($dbh, $cfg); };

	&logger (4,"ACHECK Check START");
	
	#LOOK FOR THE LAST ACTION ON THE ADMIN TABLE
	$sql = "select ed_action_date, ed_action_pid, ed_action_status, ed_action_duration, ed_oedtk_release from edtk_admin " 
			. " where ed_action_date = '"
			. $date
			. "'  "; #order by ed_action_date desc limit 1";
	&logger (7, $sql);
	
	$sth = $dbh->prepare($sql) or return (3, $dbh->errstr);

	do { local $sth->{PrintError} = 0; $sth->execute() } or &logger (3, "SQL execute failed ".$sth->err."-".$sth->errstr);

	# HAS AN ADMINISTRATION ACTION ALREADY BEEN DONE TODAY ?
	my @tValues = $dbh->selectrow_array($sql, undef);# or warn ("ERROR: in acheck_db_admin_on_connect, message is " . $dbh->errstr);
	if ($tValues[0] and $date eq $tValues[0]){
		&logger(6, ("Previously done, ACHECK Last EDTK_DB_MAX_DAYS check : ". $tValues[0] ." PID ". $tValues[1]));
		return (5, ("ACHECK Last EDTK_DB_MAX_DAYS check : ". $tValues[0] ." PID ". $tValues[1]));
	}


	# OTHERWISE, REQUEST A TICKET TO CARRY OUT THE ACTION
	$insert = 'insert into edtk_admin (ed_action_date, ed_action_pid, ed_action_status, ed_oedtk_release) '
		. ' values (?, ?, ?, ?) ';
	$sth = $dbh->prepare_cached($insert);

	eval {
		do { local $sth->{PrintError} = 0; $sth->execute($date, $pid, "START", $VERSION) } or &logger (3, "SQL execute failed ".$sth->err."-".$sth->errstr);
	};
	if ($@) {
		&logger(3, "ERROR: $@ into $insert");
	}


	# CHECK THAT WE HOLD THE LOCK FOR THE ACTION
	$sth = $dbh->prepare($sql);
	do { local $sth->{PrintError} = 0; $sth->execute() } or &logger (3, "SQL execute failed ".$sth->err."-".$sth->errstr);
	@tValues = do { local $dbh->{PrintError} = 0; $dbh->selectrow_array($sql, undef) } or &logger(3, "ERROR: in acheck_db_admin_on_connect, message is ".$dbh->errstr);
	$reportActions = "ACHECK Check 2 : ". $tValues[0] ." PID ". $tValues[1];

	if ($date eq $tValues[0] and $pid eq $tValues[1]){
		&logger (5, $reportActions);
		# _db_admin_actions;
	} else {
		# another process did the action, giving up
		return (5, $reportActions);
	}

	### PURGES ###
	# PURGE FROM OEDTK_ADMIN
	$sql = "delete from edtk_admin where ed_action_date < '" 
			. (strftime "%Y-%m-%d", localtime($DAYS_TRACKED_time))."'";
	&logger (7, $sql);

	$result = _db_do_log($dbh, $sql, "ERROR: can't update EDTK_ADMIN") or return;
	&logger (6,"RESULT = " . ($result // 0) ." for $sql");
	$reportActions = "ACHECK PURGE edtk_admin=" . ($result // 0);

	# PURGE FROM EDTK_DBI_TRACKING
	$sql = "delete from " . $cfg->{'EDTK_DBI_TRACKING'} 
			. " where ed_tstamp < '" . (strftime "%Y%m%d", localtime($DAYS_TRACKED_time)) . "000000'";
	&logger (7, $sql);

	$result = _db_do_log($dbh, $sql, "ERROR: can't update ".$cfg->{'EDTK_DBI_TRACKING'}) or return;
	&logger (6,"RESULT = " . ($result // 0) ." for $sql");
	$reportActions .= "-PURGE tracking=" . ($result // 0);

	# PURGE FROM EDTK_DBI_DISTRIB_STATS 
	$sql = "delete from " 
			. $cfg->{'EDTK_DBI_DISTRIB_STATS'}
			. " where ed_dtlot < '" . (strftime "%Y-%m-%d", localtime($DAYS_KEPT_STATS_time)) ."'"; # note: NOT REGEXP_LIKE (ED_DTLOT, '\d\d\d\d-\d\d-\d\d') does not work on MySQL...
	&logger (7, $sql);

	$result = _db_do_log($dbh, $sql, "ERROR: can't update ".$cfg->{'EDTK_DBI_DISTRIB_STATS'}) or return;
	&logger (6,"RESULT = " . ($result // 0) ." for $sql");
	$reportActions .= "-PURGE distrib_s=" . ($result // 0);

	# PURGE FROM OUTMNGR_STATS 
	$sql = "delete from " 
			. $cfg->{'EDTK_DBI_OUTMNGR_STATS'}
			. " where ed_dtlot < '" . (strftime "%Y-%m-%d", localtime($DAYS_KEPT_STATS_time)) ."'";
	&logger (7, $sql);

	$result = _db_do_log($dbh, $sql, "ERROR: can't update ".$cfg->{'EDTK_DBI_OUTMNGR_STATS'}) or return;
	&logger (6,"RESULT = " . ($result // 0) ." for $sql");
	$reportActions .= "-PURGE outmngr_s=" . ($result // 0);

	# PURGE FROM EDTK_AGREGE
	$sql = "delete from edtk_agrege " 
			. " where ed_dtlot < '" . (strftime "%Y-%m-%d", localtime($DAYS_AGREGED_time)) ."'";
	&logger (7, $sql);

	$result = _db_do_log($dbh, $sql, "ERROR: can't update EDTK_AGREGE") or return;
	&logger (6,"RESULT = " . ($result // 0) ." for $sql");
	$reportActions .= "-PURGE agrege=" . ($result // 0);
	my $stamp =strftime "%Y%m%d%H%M%S", localtime;

	### MOVE / PURGE ###
		### EDTK_AGREGE ### 
		# MOVE DATA TO EDTK_AGREGE
			$sql = "insert into edtk_agrege "
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
			. " where d.ed_dtlot < '" . (strftime "%Y-%m-%d", localtime($DAYS_KEPT_time)) ."'"
			. "group by "
			. "i.ed_source, "
			. "d.ed_chanel_out, "
			. "i.ed_refiddoc, "
			. "i.ed_idproduct," 
			. "i.ed_dtedtion, "
			. "d.ed_dtlot, "
			. "d.ed_idlot, "
			. "d.ed_idjob ";
	&logger (7,"SQL = $sql");

		$result = _db_do_log($dbh, $sql, "ERROR: can't update EDTK_AGREGE", fatal => 1);
		&logger (6,"RESULT = " . ($result // 0) ." for $sql");
		$reportActions .= "-MV agrege=" . ($result // 0);


		### DISTRIB ###
		# MOVE DATA FROM DISTRIB TO DISTRIB_STATS
		$sql = "insert into " 
				. $cfg->{'EDTK_DBI_DISTRIB_STATS'}
				. " select * from "
				. $cfg->{'EDTK_DBI_DISTRIB'}
				. " where ed_dtlot < '" . (strftime "%Y-%m-%d", localtime($DAYS_KEPT_time)) ."'";
		&logger (7, $sql);

		$result = _db_do_log($dbh, $sql, "ERROR: can't update ".$cfg->{'EDTK_DBI_DISTRIB_STATS'}) or return;
		&logger (6,"RESULT = " . ($result // 0) ." for $sql");
		$reportActions .= "-MV distrib=" . ($result // 0);

		# CLEAN DISTRIB 
		$sql = "delete from " 
				. $cfg->{'EDTK_DBI_DISTRIB'}
				. " where ed_dtlot < '" . (strftime "%Y-%m-%d", localtime($DAYS_KEPT_time)) ."'";
		&logger (7, $sql);

		$result = _db_do_log($dbh, $sql, "ERROR: can't update ".$cfg->{'EDTK_DBI_DISTRIB_STATS'});
		&logger (6,"RESULT = " . ($result // 0) ." for $sql");
		$reportActions .= "/" . ($result // 0);

		
		### OUTMNGR ###
		# MOVE DATA FROM OUTMNGR TO OUTMNGR_STATS
		$sql = "insert into " 
				. $cfg->{'EDTK_DBI_OUTMNGR_STATS'}
				. " select * from "
				. $cfg->{'EDTK_DBI_OUTMNGR'}
				. " where ed_dtlot < '" . (strftime "%Y-%m-%d", localtime($DAYS_KEPT_time)) ."'";
		&logger (7, $sql);

		$result = _db_do_log($dbh, $sql, "ERROR: can't update ".$cfg->{'EDTK_DBI_OUTMNGR_STATS'});
		&logger (6,"RESULT = " . ($result // 0) ." for $sql");
		$reportActions .= "-MV outmngr=" . ($result // 0);

		# CLEAN OUTMNGR 
		$sql = "delete from " 
				. $cfg->{'EDTK_DBI_OUTMNGR'}
				. " where ed_dtlot < '" . (strftime "%Y-%m-%d", localtime($DAYS_KEPT_time)) ."'";
		&logger (7, $sql);

		$result = _db_do_log($dbh, $sql, "ERROR: can't update ".$cfg->{'EDTK_DBI_OUTMNGR_STATS'});
		&logger (6,"RESULT = " . ($result // 0) ." for $sql");
		$reportActions .= "/" . ($result // 0);


		### EDTK_ID ###
		# PURGE FROM EDTK_ID 
		$sql = "delete from edtk_id"
				. " where ed_id_date < '" . (strftime "%Y-%m-%d", localtime($DAYS_TRACKED_time)) ."'";
		&logger (7, $sql);

		$result = _db_do_log($dbh, $sql, "ERROR: can't update ".$cfg->{'EDTK_DBI_OUTMNGR_STATS'});
		&logger (6,"RESULT = " . ($result // 0) ." for $sql");
		$reportActions .= "-PURGE edtk_id=" . ($result // 0);



	# End of the run
	$time=time-$time;
	$sql = 'update edtk_admin set ed_action_status = ?, ed_action_duration = ? where ed_action_date = ?';
	_db_do_log($dbh, $sql, "ERROR: can't update ED_ACTION_STATUS", bind => ["DONE", $time, $date]);

	return (4, $reportActions);
}


our @TRACKER_COLS = (
	['ed_tstamp',	'varchar2(14) not null'],	# timestamp of event
	['ed_sngl_id',	'varchar2(25) not null'],	#xx ed_idldoc single id : format ywwwdhhmmsspppp.u (compuset se limite ? 16 digits : 15 entiers, 1 decimal)
	['ed_seq',		'integer      not null'],	# sequence
	['ed_app',		'varchar2(20) not null'],	#xx ed_refiddoc application name

	['ed_user',		'varchar2(10) not null'],	# user for the job or request 
	['ed_corp',		'varchar2(8)  not null'],	# entity related 
	['ed_account',	'varchar2(8)'],				# administrative account 
	['ed_mod_ed',	'char(1)'],					# editing mode (undef, batch, tp, web, mail, probing)
	['ed_job_evt',	'char(1)'],					# level of the event (job (default), spool, document, line, warning, error, halt (critic), reject)
	['ed_obj_typ',	'varchar2(3)'],				# to define the object concerned
	['ed_obj_count','integer'],					# number of objects attached to the event
	['ed_child_typ','varchar2(3)'],				# to define the object concerned
	['ed_child_id',	'varchar2(32)'],			#xx ed_idldoc single id : format ywwwdhhmmsspppp.u (compuset se limite ? 16 digits : 15 entiers, 1 decimal)
	['ed_parent_id','varchar2(32)'],			#xx ed_idldoc single id : format ywwwdhhmmsspppp.u (compuset se limite ? 16 digits : 15 entiers, 1 decimal)

	['ed_host',		'varchar2(32)'],			# hostname for input stream of this document (max length for smtp is 31, could be 255...)
	['ed_source',	'varchar2(128)'],			# input stream of this document
	['ed_message',	'varchar2(256)']			# treatment message

);

sub create_table_TRACKING {
	my ($dbh, $table, $maxkeys) = @_;

	my $sql = "create table if not exists $table ("
			. join(', ', map {"$$_[0] $$_[1]"} @TRACKER_COLS) . ", ";

	foreach my $i (0 .. $maxkeys) {
		$sql .= " ed_k${i}_NAME VARCHAR2(8),";	# Name of key $i
		$sql .= " ed_k${i}_VAL VARCHAR2(128)";	# Value of key $i
		$sql .= "," unless ($i == $maxkeys);
	}
	$sql .= " )";
	$sql .= _db_engine_clause($dbh);
	&logger (7, $sql);
	_db_do_ddl($dbh, $sql) or &logger (4, $dbh->errstr);
#	my $idx = "ix_".$table."_".$VERSION_TXT;
	my $idx = "ix_".$table;
	$sql = "create index if not exists $idx on $table "
			." (ed_tstamp);";
	&logger (7, $sql);
	_db_do_ddl($dbh, $sql) or &logger (4, $dbh->errstr ) if (_db_check_driver_name($dbh) ne "SQLite");
	
}


sub db_drop_table {
	my ($dbh, $table) = @_;
	my $sql = "drop table $table";

	_db_do_ddl($dbh, $sql) or &logger (4, $dbh->errstr);
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
    return 0 if $bak eq $main;      # anti-loop guard: backup == main
    return 1;
}

# Does this handle point at the backup buffer?
sub db_on_backup {
    my ($dbh) = @_;
    return (defined $dbh && $dbh->{'private_oEdtk_on_backup'}) ? 1 : 0;
}

# Open the backup buffer (never fatal, never blocking).
sub _db_backup_connect {
    my ($cfg) = @_;
    return undef unless db_backup_available($cfg);
    my %bcfg = (%$cfg, EDTK_WAITRUN => 0);   # no retry loop for a probe
    my $bak  = eval {
        _db_connect1(\%bcfg, 'EDTK_DBI_DSN_BAK',
            { FetchHashKeyName => $cfg->{'EDTK_DB_FetchHashKeyName'} || 'NAME_uc',
              AutoCommit      => 1 })
    };
    return $bak;
}

# Tables repatriated from the buffer, in dependency order, with the natural key
# used for the idempotent "insert if absent" test.
sub _backup_table_registry {
    my ($cfg) = @_;
    my @t;
    push @t, { table => $cfg->{'EDTK_DBI_TRACKING'}, keys => [qw(ed_tstamp ed_sngl_id ed_seq ed_app)] } if $cfg->{'EDTK_DBI_TRACKING'};
    push @t, { table => $cfg->{'EDTK_DBI_ACQUIT'},   keys => [qw(ed_seqlot ed_lotname ed_dtpost)] } if $cfg->{'EDTK_DBI_ACQUIT'};
    push @t, { table => 'edtk_id',                   keys => [qw(ed_id_value)] };
    push @t, { table => $cfg->{'EDTK_DBI_OUTMNGR'},  keys => [qw(ed_idldoc ed_seqdoc ed_idseqpg ed_idjob)] } if $cfg->{'EDTK_DBI_OUTMNGR'};
    push @t, { table => $cfg->{'EDTK_DBI_DISTRIB'},  keys => [qw(ed_idldoc ed_seqdoc ed_idseqpg ed_idjob)] } if $cfg->{'EDTK_DBI_DISTRIB'};
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
        unless (_table_exists($bak_dbh, $cfg->{'EDTK_DBI_TRACKING'})) {
            create_table_TRACKING($bak_dbh, $cfg->{'EDTK_DBI_TRACKING'}, $cfg->{'EDTK_MAX_USER_KEY'});
        }
        1;
    };
    &logger(3, "db_backup_prepare: could not prepare the backup schema: $@") unless $ok;
    return $ok ? 1 : 0;
}

# Count pending rows per buffer table (read-only detection).
sub db_backup_pending {
    my ($cfg) = @_;
    my %pending;
    return \%pending unless db_backup_available($cfg);
    my $bak = _db_backup_connect($cfg);
    unless ($bak) { &logger(7, "db_backup_pending: backup database unreachable"); return \%pending; }
    for my $t (_backup_table_registry($cfg)) {
        my $n = eval { my ($c) = $bak->selectrow_array("select count(*) from $t->{table}"); $c };
        $pending{ $t->{table} } = $n if defined $n && $n > 0;
    }
    eval { $bak->disconnect };
    return \%pending;
}

# Copy the pending rows of ONE buffer table into the main database, then drain
# the buffer table when the whole batch succeeded. Idempotent.
sub _reconcile_one_table {
    my ($main, $bak, $t, %p) = @_;
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
    unless (defined $n) { &logger(7, "_reconcile_one_table: '$table' absent from the backup"); return $out; }
    return $out if $n == 0;
    if ($p{dry_run}) { $out->{read} = $n; return $out; }

    my $sth_rd = $bak->prepare("select * from $table");
    unless ($sth_rd && $sth_rd->execute) {
        &logger(3, "_reconcile_one_table: cannot read '$table' from the backup: ".($bak->errstr // ''));
        $out->{ok} = 0; return $out;
    }
    my $raw_cols = $sth_rd->{NAME};      # buffer column names (raw order)

    my ($norm_id, $norm_table, @norm_cols) = _norm_identifiers($main, $table, $raw_cols);
    my $meta  = _get_col_meta($main, $norm_table, $norm_id);
    my $clean = _make_clean_val($meta);

    my @uk         = map { $norm_id->($_) } @keys;
    my $sql_exists = "select 1 from $norm_table where " . join(' and ', map {"$_ = ?"} @uk);
    my $sql_insert = "insert into $norm_table (" . join(',', @norm_cols) . ")"
                   . " values (" . join(',', ('?') x @norm_cols) . ")";
    my $sth_chk = $main->prepare($sql_exists);
    my $sth_ins = $main->prepare($sql_insert);
    &logger(7, "_reconcile_one_table: $table exists=[$sql_exists]");

    while (my $row = $sth_rd->fetchrow_arrayref) {
        $out->{read}++;
        # Map values by NAME (not position) so that a column-order divergence
        # between the buffer and the main schema cannot corrupt the data.
        my %by_name;
        for my $i (0 .. $#$raw_cols) { $by_name{ $norm_id->($raw_cols->[$i]) } = $row->[$i]; }

        my $dup = eval {
            local $sth_chk->{PrintError} = 0; $sth_chk->execute(map { $clean->($_, $by_name{$_}) } @uk);
            my ($x) = $sth_chk->fetchrow_array;
            $sth_chk->finish;
            $x;
        };
        if ($dup) { $out->{skipped}++; next; }

        my $ok = eval {
            local $sth_ins->{PrintError} = 0; $sth_ins->execute(map { $clean->($_, $by_name{$_}) } @norm_cols);
            1;
        };
        if ($ok) { $out->{written}++ }
        else {
            &logger(3, "_reconcile_one_table: insert into '$table' failed: ".($main->errstr // $@));
            $out->{ok} = 0; last;
        }
    }
    $sth_rd->finish;

    # Drain the buffer table only when the whole batch was written.
    if ($out->{ok} && !$p{keep_backup}) {
        my $d = eval { local $bak->{PrintError} = 0; $bak->do("delete from $table"); };
        unless (defined $d) { &logger(3, "_reconcile_one_table: could not drain '$table': ".($bak->errstr // '')); $out->{ok} = 0; }
    }
    return $out;
}

# PUBLIC: copy every pending row of the backup buffer back into the main DB.
# Never dies; returns a report hashref.
#   %opt: CFG => $cfg, tables => [ {table=>,keys=>[]} ], dry_run => 1, keep_backup => 1
sub db_reconcile_backup {
    my ($main_dbh, %p) = @_;
    my $cfg = $p{CFG} || config_read('EDTK_DB');
    my $res = { driver => _db_check_driver_name($main_dbh), tables => {}, written => 0, ok => 1 };

    unless (db_backup_available($cfg)) {
        &logger(7, "db_reconcile_backup: no distinct backup database configured, nothing to do");
        return $res;
    }
    if (db_on_backup($main_dbh)) {
        &logger(7, "db_reconcile_backup: current handle is the backup itself, skipping");
        return $res;
    }

    my $bak = _db_backup_connect($cfg);
    unless ($bak) {
        &logger(3, "db_reconcile_backup: backup database unreachable, no repatriation");
        $res->{ok} = 0; $res->{error} = 'backup unreachable';
        return $res;
    }

    my @tables = $p{tables} ? @{ $p{tables} } : _backup_table_registry($cfg);
	&logger(4, "checking if backup data needs reconciliation ...");

    for my $t (@tables) {
        my $r = _reconcile_one_table($main_dbh, $bak, $t, %p);
        $res->{tables}{ $t->{table} } = $r;
        $res->{written} += $r->{written};
        $res->{ok} = 0 unless $r->{ok};
    }
    eval { $bak->disconnect };
    return $res;
}

# Best-effort hook: repatriate before a maintenance operation. Never fatal.
sub _db_maybe_reconcile {
    my ($dbh, $cfg) = @_;
    return unless defined $dbh && defined $cfg && db_backup_available($cfg);
    eval {
        my $r = db_reconcile_backup($dbh, CFG => $cfg);
        &logger(3, "db_reconcile_backup: ".$r->{written}." row(s) repatriated from the backup buffer")
            if ($r->{written} || 0) > 0;
    };
    &logger(3, "db_reconcile_backup failed: $@") if $@;
    return;
}


sub historicize_table ($$$){
	my ($dbh, $table, $suffixe) = @_;
	my $table_cible =$table."_".$suffixe;
		
	copy_table ($dbh, $table, $table_cible, '-create');	

	# SQLite has no TRUNCATE statement; DELETE achieves the same move of the data.
	my $sql = (_db_check_driver_name($dbh) eq 'SQLite')
	        ? "delete from $table" : "truncate table $table";
	&logger (7, $sql);

	_db_do_log($dbh, _sql_fixup($dbh, $sql, 'casse'), "ERROR: can't $sql", fatal => 1);
}


sub create_table_ADMIN {
	my $dbh = shift;
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
	&logger (7, $sql);

	_db_do_ddl($dbh, $sql) or &logger (4, $dbh->errstr);
}


sub create_table_ID {
	my $dbh = shift;
	my $table = "edtk_id";

	my $sql = "create table if not exists $table ";
	$sql .= "( ed_id_date       date not null";					# 2021-05-19
	$sql .= ", ed_id_value      varchar2(25) unique";	  
	$sql .= ", ed_id_chanel_out varchar2(32)";	  
	$sql .= ", primary key (ed_id_value)";
	$sql .= " )";
	$sql .= _db_engine_clause($dbh);

	&logger (7, $sql);

	_db_do_ddl($dbh, $sql) or &logger (4, $dbh->errstr);
#	my $idx = "ix_".$table."_".$VERSION_TXT;
	my $idx = "ix_".$table;
	$sql = "create index if not exists $idx on $table (ed_id_date);";
	&logger (7, $sql);
	_db_do_ddl($dbh, $sql) or &logger (4, $dbh->errstr );

}

sub create_table_FILIERES {
	my $dbh = shift;
	my $table = "edtk_filieres";

	my $sql = "create table if not exists $table ";
	$sql .= "( ed_idfiliere varchar2(5) unique";	# 
	$sql .= ", ed_priorite integer unique";			# 
	$sql .= ", ed_idmanufact varchar2(16)";	  
	$sql .= ", ed_designation varchar2(64)";		# 
	$sql .= ", ed_actif char(1) not null";				# flag: whether that business line (filiere) is active 
	$sql .= ", ed_typed char(1) not null";				# 
	$sql .= ", ed_modedi char(1) not null";			# 
	$sql .= ", ed_idgplot varchar2(16) not null";	# 
	$sql .= ", ed_nbbacprn integer not null";		# 
	$sql .= ", ed_nbencmax integer";
	$sql .= ", ed_minfeuil_l integer"; 
	$sql .= ", ed_maxfeuil_l integer"; 
	$sql .= ", ed_feuilpli integer";
	$sql .= ", ed_minplis integer";
	$sql .= ", ed_maxplis integer not null";
	$sql .= ", ed_poids_pli integer";				# maximum weight of the folded item in the line
	$sql .= ", ed_ref_env varchar2(8) not null";
	$sql .= ", ed_formflux varchar2(3) not null";
	$sql .= ", ed_sort varchar2(128) not null";
	$sql .= ", ed_direction varchar2(4) not null";
	$sql .= ", ed_postcomp varchar2(8) not null";
	$sql .= ", primary key (ed_idfiliere, ed_priorite)";
	$sql .= " )";
	$sql .= _db_engine_clause($dbh);
	&logger (7, $sql);

	_db_do_ddl($dbh, $sql) or &logger (4, $dbh->errstr);
}


sub create_table_LOTS {
	my $dbh = shift;
	my $table = "edtk_lots";

	my $sql = "create table if not exists $table ";
	$sql .= "( ed_idlot varchar2(8) not null";		# rendre unique ? -> alter table edtk_lots modify ed_idlot varchar2(8) not null
	$sql .= ", ed_priorite integer   unique"; 		#
	$sql .= ", ed_idappdoc varchar2(20)";			#
	$sql .= ", ed_refiddoc varchar2(20) not null";	# 
	$sql .= ", ed_cpdest varchar2(10)"; 			# 
	$sql .= ", ed_filter varchar2(64)";				#
	$sql .= ", ed_refenc varchar2(32)";				#
	$sql .= ", ed_groupby varchar2(16)"; 
	$sql .= ", ed_lotname varchar2(64) not null";	#
	$sql .= ", ed_idgplot varchar2(16) not null";	
	$sql .= ", ed_idmanufact varchar2(16) not null";	
	$sql .= ", ed_consigne varchar2(250) ";			#
	$sql .= ", primary key (ed_idlot, ed_priorite)" ;
	$sql .= " )";
	$sql .= _db_engine_clause($dbh);
	&logger (7, $sql);

	_db_do_ddl($dbh, $sql) or &logger (4, $dbh->errstr);
}


sub create_table_REFIDDOC {
	my $dbh = shift;
	my $table = "edtk_refiddoc";

	my $sql = "create table if not exists $table ";
	$sql .= "( ed_refiddoc varchar2(20) unique"; 
	$sql .= ", ed_corp varchar2(8) not null";		# entity related to the document
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
	$sql .= ", ed_mail_referent varchar2(300)";		# referent mail for doc validation
	$sql .= ", primary key (ed_refiddoc, ed_corp, ed_catdoc)";
	$sql .= " )";
	$sql .= _db_engine_clause($dbh);
	&logger (7, $sql);

	_db_do_ddl($dbh, $sql) or &logger (4, $dbh->errstr);
}


sub create_table_SUPPORTS {
	my $dbh = shift;
	my $table = "edtk_supports";

	my $sql = "create table if not exists $table ";
	$sql .= "( ed_refimp varchar2(16) unique";	# 
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
	&logger (7, $sql);

	_db_do_ddl($dbh, $sql) or &logger (4, $dbh->errstr);
}


our @DISTRIB_COLS = (
	['ed_idldoc',	'varchar2(25) not null'],# document id within the page-layout batch ed_sngl_id widened to 25
	['ed_idseqpg',	'integer not null'],	 # page sequence number [doc] within the page-layout batch
	['ed_seqdoc',	'integer not null'],	 # document sequence number within the batch
	['ed_idjob',	'varchar2(25) not null'],# job id

	['ed_idlot',	'varchar2(8)'],			# batch id
	['ed_seqlot',	'varchar2(7)'],			# mailing batch id (sub-batch)
	['ed_dtlot',	'varchar2(10)'],		# creation date of the mailing batch
	['ed_idfiliere','varchar2(5)'],			# production line id
	['ed_seqpgdoc',	'integer'],				# page sequence number within the document
	['ed_nbpgdoc',	'integer'],				# number of pages (sides) of the document

	# add
	['ed_workflow', 'varchar2(32)'],		# workflow on which the metadata was produced	++ new ++
	['ed_chanel_out','varchar2(32)'],		# distribution/output channel						++ new ++
	
	['ed_idged', 	'varchar2(25)']

);


sub create_table_DISTRIB {
	my ($dbh, $table) = @_;

	my $sql = "create table if not exists $table ("
			. join(', ', map {"$$_[0] $$_[1]"} @DISTRIB_COLS) 
#			. ", primary key (ed_idldoc, ed_seqdoc, ed_idseqpg, ed_idjob, ed_chanel_out)" 	
			. " )";
	$sql .= _db_engine_clause($dbh);
	&logger (7, $sql);

	_db_do_ddl($dbh, $sql) or &logger (4, $dbh->errstr);
#	my $idx = "ix_".$table."_".$VERSION_TXT;
	my $idx = "ix_".$table;

	$sql = "create index if not exists $idx on $table "
			." (ed_idldoc, ed_seqdoc, ed_idseqpg, ed_idjob, ed_chanel_out, ed_dtlot);";
	&logger (7, $sql);
	_db_do_ddl($dbh, $sql) or &logger (4, $dbh->errstr );

	# Rotation / maintenance predicates. Rows are selected and deleted by job
	# (agrege_idJob, _acheck_db_rotate) and by batch date (rotation). The composite
	# index above leads with ed_idldoc, so neither predicate can use it: dedicated
	# indexes are required (verified with EXPLAIN: seq scan -> index scan).
	for my $spec ( [ 'job',   'ed_idjob' ],
	               [ 'dtlot', 'ed_dtlot' ] ) {
		my ($sfx, $col) = @$spec;
		$sql = "create index if not exists ${idx}_$sfx on $table ($col);";
		&logger (7, $sql);
		_db_do_ddl($dbh, $sql) or &logger (4, $dbh->errstr);
	}

}

our @AGREGE_COLS = (
	['ed_source',	'varchar2(128)'],				# input stream of this document
	['ed_chanel_out','varchar2(32)'],				# distribution/output channel						
	['ed_refiddoc',	'varchar2(25) not null'],		# id in the document repository
	['ed_idproduct','varchar2(8)'],					# product id							
	['ed_dtedtion',	'varchar2(8) not null'],		# edition date, the one printed on the document
	['ed_cntd_idldoc',	'integer not null'],		# distinct count of document ids
	['ed_cnt_idseqpg',	'integer not null'],	 	# count of page sequence [doc] within the page-layout batch
	['ed_dtlot',	'varchar2(10)'],				# creation date of the mailing batch
	['ed_idlot',	'varchar2(8)'],					# batch id
	['ed_idjob',	'varchar2(25) not null'],		# job id
	['ed_tstamp',	'varchar2(14) not null']		# timestamp of event # TODO see how upgrade handles differing field counts

);


sub create_table_AGREGE {
	my ($dbh) = @_;
	my $table = "edtk_agrege";

	my $sql = "create table if not exists $table ("
			. join(', ', map {"$$_[0] $$_[1]"} @AGREGE_COLS) 
			. " )";
	$sql .= _db_engine_clause($dbh);
	&logger (7, $sql);

	_db_do_ddl($dbh, $sql) or &logger (4, $dbh->errstr );
#	my $idx = "ix_".$table."_".$VERSION_TXT;
	my $idx = "ix_".$table;
	$sql = "create index if not exists $idx on $table "
			." (ed_source, ed_chanel_out, ed_refiddoc, ed_idproduct, ed_dtedtion, ed_dtlot, ed_idlot);";
	&logger (7, $sql);
	_db_do_ddl($dbh, $sql) or &logger (4, $dbh->errstr );

}


sub create_table_PARA {
	my $dbh = shift;
	my $table = "edtk_test_para";

	my $sql = "create table if not exists $table ";
	$sql .= "( ed_para_refiddoc varchar2(20) not null"; 
	$sql .= ", ed_para_corp varchar2(8) not null";		# entity related to the document
	$sql .= ", ed_id       integer unique";				#
	$sql .= ", ed_tstamp   varchar2(14) not null";		# timestamp of event
	$sql .= ", ed_textbloc varchar2(512)";
	$sql .= ", primary key (ed_para_refiddoc, ed_para_corp, ed_id)";
	$sql .= " )";
	$sql .= _db_engine_clause($dbh);
	&logger (7, $sql);

	_db_do_ddl($dbh, $sql) or &logger (4, $dbh->errstr);
}


sub create_table_DATAGROUPS {
	my $dbh = shift;
	my $table = "edtk_test_datagroups";

	my $sql = "create table if not exists $table ";
	$sql .= "( ed_dgps_refiddoc varchar2(20) not null"; 
	$sql .= ", ed_id   integer not null";
	$sql .= ", ed_data varchar2(64)";
	$sql .= " )";
	$sql .= _db_engine_clause($dbh);

	&logger (7, $sql);

	_db_do_ddl($dbh, $sql) or die &logger (-1, $dbh->errstr);
#	my $idx = "ix_".$table."_".$VERSION_TXT;
	my $idx = "ix_".$table;
	$sql = "create index if not exists $idx on $table "
			." (ed_dgps_refiddoc, ed_id);";
	&logger (7, $sql);
	_db_do_ddl($dbh, $sql) or &logger (4, $dbh->errstr );

}


sub create_table_ACQUIT {
	my $dbh = shift;
	my $table = "edtk_acq";

	my $sql = "create table if not exists $table ";
	$sql .= "( ed_seqlot  varchar2(7)  not null";	# mailing batch id (sub-batch) update edtk_acq set ed_seqlot = substr('1'|| ed_seqlot,-7);
	$sql .= ", ed_lotname varchar2(16) not null";	# 
	$sql .= ", ed_dtpost  varchar2(8)  not null";	# mailing-out date
	$sql .= ", ed_dtprint varchar2(8)";				# print date
	$sql .= ", ed_nbfaces integer   	not null";	# number of sides of the batch (accounting sides, including blank recto/verso sides)
	$sql .= ", ed_nbplis  integer 		not null";	# number of documents in the folded item
	$sql .= ", ed_dtpost2 varchar2(8)";				# mailing-out date		
	$sql .= ", ed_dtcheck varchar2(8)";				# check date
	$sql .= ", ed_status  varchar2(4)";				# check status
	$sql .= ", primary key (ed_seqlot, ed_lotname, ed_dtpost)";
	$sql .= " )";
	$sql .= _db_engine_clause($dbh);

	&logger (7, $sql);

	_db_do_ddl($dbh, $sql) or &logger (4, $dbh->errstr);
}


our @INDEX_COLS = (
#	NB : " primary key (ed_idldoc, ed_seqdoc, ed_idseqpg, ed_idjob)"

	# INDEX COMPOSITION SECTION
	['ed_refiddoc',	'varchar2(25) not null'],# id in the document repository
	['ed_idldoc',	'varchar2(25) not null'],# document id within the page-layout batch ed_sngl_id widened to 25
	['ed_idseqpg',	'integer not null'],	 # page sequence number [doc] within the page-layout batch
	['ed_seqdoc',	'integer not null'],	 # document sequence number within the batch
	['ed_idjob',	'varchar2(25) not null'],# Job id 

	# SECTION DOCUMENT
	['ed_dtedtion',	'varchar2(8) not null'],# edition date, the one printed on the document
	['ed_cpdest',	'varchar2(10)'],		# recipient postal code
	['ed_villdest',	'varchar2(38)'],		# recipient city
	['ed_iddest',	'varchar2(25)'],		# recipient id in the management system
	['ed_nomdest',	'varchar2(38)'],		# recipient name
	['ed_idemet',	'varchar2(10)'],		# sender id
	['ed_typprod',	'varchar(16)'],			# production type associated with the batch 
	['ed_portadr',	'char(1)'],				# flag: document carries an address
	['ed_adrln1',	'varchar2(38)'],		# address line 1
	['ed_cleged1',	'varchar2(32)'],		# archiving system key
	['ed_adrln2',	'varchar2(38)'],		# address line 2
	['ed_cleged2',	'varchar2(20)'],		# archiving system key
	['ed_adrln3',	'varchar2(38)'],		# address line 3
	['ed_cleged3',	'varchar2(20)'],		# archiving system key
	['ed_adrln4',	'varchar2(38)'],		# address line 4
	['ed_cleged4',	'varchar2(20)'],		# archiving system key
	['ed_adrln5',	'varchar2(38)'],		# address line 5
	['ed_corp',		'varchar2(8) not null'],# issuing entity of the page
	['ed_doclib',	'varchar2(32)'],		# compuset merge library associated with the page
	['ed_refimp',	'varchar2(16)'],		# pre-printed, printed or insert reference
	['ed_adrln6',	'varchar2(38)'],		# address line 6
	['ed_source',	'varchar2(8) not null'],# index source or ed_corp entity
	['ed_owner',	'varchar2(10)'],		# document owner (used in document management / archiving)
	['ed_host',		'varchar2(32)'],		# hostname of the machine this entry came from
	['ed_ididx',	'varchar2(8) '],		# index id
	['ed_catdoc',	'char(1)'],				# document category
	['ed_codrupt',	'varchar2(8)'],			# burst forcing code

	# INDEX BATCHING SECTION 
	['ed_idlot',	'varchar2(8)'],			# batch id
	['ed_seqlot',	'varchar2(7)'],			# mailing batch id (sub-batch)
	['ed_dtlot',	'varchar2(10)'],		# creation date of the mailing batch
	['ed_idfiliere','varchar2(5)'],			# production line id
	['ed_seqpgdoc',	'integer'],				# page sequence number within the document
	['ed_nbpgdoc',	'integer'],				# number of pages (sides) of the document
	['ed_poidsunit','integer'],				# weight of the print or insert in mg
	['ed_nbenc',	'integer'],				# number of inserts in the doc
	['ed_encpds',	'integer'],				# weight of the inserts in the doc
	['ed_bac_insert','integer'],			# Tray or insert call

	# INDEX EDITION SECTION
	['ed_typed',	'char(1)'],				# edition type (black / full color)
	['ed_modedi',	'char(1)'],				# edition mode (simplex / duplex) => recto / verso 
	['ed_formatp',	'varchar2(2)'],			# paper format (a4 / a3 ...)
	['ed_pgorien',	'varchar2(2)'],			# edition orientation (portrait / reverseportrait / landscape / reverse landscape)
	['ed_formflux',	'varchar2(3)'],			# edition stream format (afp / pdf / ...)
#	['ed_formdef',	'varchar2(8)'],			# formdef afp
#	['ed_pagedef',	'varchar2(8)'],			# pagedef afp
#	['ed_forms',	'varchar2(8)'],			# Forms 

	# INDEX FOLDING SECTION
	['ed_idpli',	'integer'],				# folded-item id
	['ed_nbdocpli',	'integer'],				# number of documents in the folded item
	['ed_numpgpli',	'integer'],				# page (side) number in the folded item
	['ed_nbpgpli',	'integer'],				# number of pages (sides) of the folded item
	['ed_nbfpli',	'integer'],				# number of sheets of the folded item
	['ed_listerefenc','varchar2(64)'],		# list of inserts in the folded item
	['ed_pdspli',	'integer'],				# weight of the folded item in mg
	['ed_typobj',	'char(1)'],				# object type in the folded item	xxxxxx  conserver ?
	['ed_status',	'varchar2(8)'],			# batching status (mailing-out date or status depending on the version)
	['ed_dtposte',	'varchar2(8)'],			# to remove : batching status (mailing-out date or status depending on the version)

	# ADD
	['ed_workflow', 'varchar2(32)'],	    # workflow on which the metadata was produced	++ new ++
	['ed_chanel_out', 'varchar2(32)'],		# distribution/output channel						++ new ++
	['ed_country',	'varchar2(5)'],			# recipient country code							++ new ++
	['ed_idcontract','varchar2(16)'],		# contract id							++ new ++
	['ed_idproduct','varchar2(8)']			# Product id							++ NEW ++

);



sub create_table_OUTMNGR {
	my ($dbh, $table) = @_;

	my $sql = "create table if not exists $table ("
			. join(', ', map {"$$_[0] $$_[1]"} @INDEX_COLS) . ", "
			. " primary key (ed_idldoc, ed_seqdoc, ed_idseqpg, ed_idjob)"
			. " )";
	$sql .= _db_engine_clause($dbh);
	&logger (7, $sql);

	_db_do_ddl($dbh, $sql) or &logger (4, $dbh->errstr );
#	my $idx = "ix_".$table."_".$VERSION_TXT;
	my $idx = "ix_".$table;
	$sql = "create index if not exists $idx on $table "
			." (ed_dtedtion, ed_seqlot, ed_typprod);";
	&logger (7, $sql);
	_db_do_ddl($dbh, $sql) or &logger (4, $dbh->errstr );
}


sub create_lot_sequence {
	# USED FOR BATCH CREATION IN Outmngr.pm
	my $dbh = shift;

	if (_db_check_driver_name($dbh) eq "SQLite") {
		# SQLite has no SEQUENCE object: emulate EDTK_IDLOT with a one-row counter
		# table cycling 0..999 (read back by _get_seqlot in Outmngr.pm). MySQL uses
		# its own AUTO_INCREMENT emulation and is skipped by the caller.
		_db_do_ddl($dbh, "create table if not exists edtk_idlot_seq (id_val integer not null)")
			or &logger (4, $dbh->errstr);
		do { local $dbh->{PrintError} = 0; $dbh->do("insert into edtk_idlot_seq (id_val) select 0 where not exists (select 1 from edtk_idlot_seq)") }
			or &logger (4, $dbh->errstr);
		return 1;
	}

	# method valid for most DBMS except MySQL
	my $sql = "create sequence if not exists edtk_idlot minvalue 0 maxvalue 999 cycle";
	_db_do_ddl($dbh, $sql) or &logger (4, $dbh->errstr);
	return 1;
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
    my ($dbh, %opt) = @_;

    # Rights probed, in the order they are reported in 'missing'.
    my @RIGHTS = qw(CREATE DROP INDEX ALTER SEQUENCE);

    my %res = (driver => 'NC', checked => 0, missing => []);
    return \%res unless defined $dbh;

    my $driver = _db_check_driver_name($dbh);
    $res{driver} = $driver;

    # SQLite has no GRANT/privilege model: the file owner may do everything.
    if ($driver eq 'SQLite') {
        $res{lc $_} = 1 for @RIGHTS;
        $res{checked} = 1;
        &logger(7, "db_check_privileges: SQLite has no privilege model, "
                 . "assuming every right is allowed");
        return \%res;
    }

    # No privilege model we can query: report nothing rather than guess.
    if ($driver eq 'NC') {
        &logger(7, "db_check_privileges: unknown driver, "
                 . "cannot check privileges");
        return \%res;
    }

    my %rights;
    my $ok = eval {
        %rights = $driver eq 'PostgreSQL' ? _db_priv_pg($dbh, %opt)
                : $driver eq 'mysql'      ? _db_priv_mysql($dbh, %opt)
                : $driver eq 'Oracle'     ? _db_priv_oracle($dbh, %opt)
                : ();
        1;
    };
    unless ($ok) {
        $res{error} = $@ || 'unknown error';
        &logger(4, "db_check_privileges: privilege probe failed: $res{error}");
        return \%res;
    }

    $res{checked} = 1;
    for my $right (@RIGHTS) {
        my $have = $rights{lc $right};
        $res{lc $right} = $have;
        next if !defined $have || $have;
        push @{ $res{missing} }, $right;
        &logger(3, "db_check_privileges: DB user lacks the $right privilege on the "
                 . "current database/schema ; schema_Create and schema_Upgrade may fail");
    }
    return \%res;
}


# PostgreSQL: CREATE is a database/schema privilege; owning the table grants DROP,
# INDEX and ALTER. Ownership is tested on the target table (option 'table') or on
# any table of the current schema, and a superuser always passes; an empty schema
# does not raise a false alarm. Returns a hash of rights.
sub _db_priv_pg {
    my ($dbh, %opt) = @_;

    my ($super) = $dbh->selectrow_array(
        "SELECT rolsuper FROM pg_roles WHERE rolname = current_user");
    return map { $_ => 1 } qw(create drop index alter sequence) if $super;

    my ($create) = $dbh->selectrow_array(
        "SELECT has_database_privilege(current_user, current_database(), 'CREATE') "
      . "AND has_schema_privilege(current_user, current_schema(), 'CREATE')");

    my $owns;
    if (defined $opt{table} && length $opt{table}) {
        ($owns) = $dbh->selectrow_array(
            "SELECT pg_get_userbyid(c.relowner) = current_user "
          . "FROM pg_class c JOIN pg_namespace n ON n.oid = c.relnamespace "
          . "WHERE c.relname = ? AND n.nspname = current_schema()",
            undef, $opt{table});
    } else {
        ($owns) = $dbh->selectrow_array(
            "SELECT bool_or(pg_get_userbyid(c.relowner) = current_user) "
          . "FROM pg_class c JOIN pg_namespace n ON n.oid = c.relnamespace "
          . "WHERE n.nspname = current_schema() AND c.relkind = 'r'");
    }
    my $owning = defined $owns ? ($owns ? 1 : 0) : 1;

    return (
        create   => $create ? 1 : 0,
        drop     => $owning,
        index    => $owning,   # CREATE INDEX needs table ownership
        alter    => $owning,   # ALTER TABLE needs table ownership
        sequence => $create ? 1 : 0,   # CREATE SEQUENCE needs CREATE on the schema
    );
}


# MySQL / MariaDB: SHOW GRANTS lists the effective grants. A statement that grants
# ALL PRIVILEGES, or the specific right, on '*.*' or on the current database gives
# the right. CREATE INDEX needs INDEX or ALTER; CREATE SEQUENCE (MariaDB) needs
# CREATE. Returns a hash of rights.
sub _db_priv_mysql {
    my ($dbh, %opt) = @_;

    my ($db) = $dbh->selectrow_array("SELECT DATABASE()");
    $db = '' unless defined $db;

    my $rows = $dbh->selectall_arrayref("SHOW GRANTS FOR CURRENT_USER()");
    my %have;
    for my $r (@{ $rows || [] }) {
        my $grant = $r->[0] // '';
        next unless $grant =~ /^\s*GRANT\s+(.+?)\s+ON\s+(\S.*?)\s+TO\s/i;
        my ($privs, $scope) = (uc $1, $2);
        $scope =~ s/`//g;
        my $global = ($scope eq '*.*');
        my $local  = ($db ne '' && lc($scope) eq lc("$db.*"));
        next unless $global || $local;
        if ($privs =~ /ALL PRIVILEGES/) {
            $have{$_} = 1 for qw(CREATE DROP INDEX ALTER);
        } else {
            $have{$_} = 1 for grep { $privs =~ /\b$_\b/ } qw(CREATE DROP INDEX ALTER);
        }
    }
    return (
        create   => $have{CREATE} ? 1 : 0,
        drop     => $have{DROP}   ? 1 : 0,
        index    => ($have{INDEX} || $have{ALTER}) ? 1 : 0,
        alter    => $have{ALTER}  ? 1 : 0,
        sequence => $have{CREATE} ? 1 : 0,
    );
}


# Oracle: system privileges; those held directly sit in USER_SYS_PRIVS, those held
# through an enabled role in ROLE_SYS_PRIVS. Creating the tables (CREATE TABLE) makes
# us their owner, so we may then INDEX and ALTER them. Returns a hash of rights.
sub _db_priv_oracle {
    my ($dbh, %opt) = @_;

    my $ref = $dbh->selectcol_arrayref(
        "SELECT PRIVILEGE FROM USER_SYS_PRIVS "
      . "UNION SELECT PRIVILEGE FROM ROLE_SYS_PRIVS");
    my %priv = map { uc($_) => 1 } @{ $ref || [] };

    my $create_table = ($priv{'CREATE TABLE'} || $priv{'CREATE ANY TABLE'}) ? 1 : 0;
    return (
        create   => $create_table,
        drop     => $priv{'DROP ANY TABLE'} ? 1 : 0,
        index    => ($create_table || $priv{'CREATE ANY INDEX'}) ? 1 : 0,
        alter    => ($create_table || $priv{'ALTER ANY TABLE'}) ? 1 : 0,
        sequence => ($priv{'CREATE SEQUENCE'} || $priv{'CREATE ANY SEQUENCE'}) ? 1 : 0,
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

	my $stamp =strftime "%Y%m%d_%H%M", localtime;
	$p{DBH}	= db_connect($p{CFG}, 'EDTK_DBI_DSN');
	# Repatriate any pending backup rows before renaming / copying the schema.
	eval { _db_maybe_reconcile($p{DBH}, $p{CFG}); };

	# Best effort: alert (never block) when the DB user cannot CREATE/DROP.
	eval { db_check_privileges($p{DBH}) };

	my $sep ="";
	if (_db_check_driver_name($p{DBH}) =~ m/SQLite/i) {
		$sep = "'";
	}

	foreach my $table (@tListeTables) {
		my $sql = sprintf ("alter table %s rename to "."$sep"."%s_%s"."$sep"." ;", $table, $stamp, $table);
		&logger (7, $sql);
		#$p{DBH}->do(                   $sql, undef, )  or die &logger( -1, "ERROR: can't $sql");	
		_db_do_log($p{DBH}, _sql_fixup($p{DBH}, $sql, 'casse'), "ERROR: can't $sql", fatal => 1);

	}

	# if ok:
	schema_Create($p{DBH});
	
	#if ok:
	foreach my $table (@tListeTables) {
		my $sql = sprintf ("insert into %s select * from "."$sep"."%s_%s"."$sep"." ;", $table, $stamp, $table);
		&logger (7, $sql);
		_db_do_log($p{DBH}, _sql_fixup($p{DBH}, $sql, undef), "ERROR: can't $sql", fatal => 1);
		my $drop = sprintf ("drop table "."$sep"."%s_%s"."$sep"." ;", $stamp, $table);
		&logger (7, $drop);
		_db_do_log($p{DBH}, _sql_fixup($p{DBH}, $drop, 'casse'), "ERROR: can't $drop", fatal => 1);
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
	if ( $dbh->{'Driver'}->{'Name'} =~ m/mysql/i) {
		# MySQL uses its own AUTO_INCREMENT emulation, nothing to create here.
		&logger (5, "MySQL uses its own sequence emulation, ignoring.");
	} else {
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
	create_table_OUTMNGR($dbh, $cfg->{'EDTK_DBI_OUTMNGR'});
	create_table_OUTMNGR($dbh, $cfg->{'EDTK_DBI_OUTMNGR_STATS'});
	create_table_DISTRIB($dbh, $cfg->{'EDTK_DBI_DISTRIB'});
	create_table_DISTRIB($dbh, $cfg->{'EDTK_DBI_DISTRIB_STATS'});

	db_invalidate_meta_cache();
}


sub _db_maintenance {
    my (%p) = @_;   # CFG, DBH, [rotate => 1], [purge => 1]
    my $dbh = $p{DBH} // db_connect($p{CFG}, 'EDTK_DBI_DSN');

    _db_rotate($dbh, $p{CFG})  if $p{rotate};
    _db_purge ($dbh, $p{CFG})  if $p{purge};

    $dbh->disconnect unless $p{DBH};   # do not disconnect when a $dbh was passed to us
    return 1;
}

sub _db_with_lock {
    my (%p) = @_;   # CFG, CODE-REF
    my $dbh = db_connect($p{CFG}, 'EDTK_DBI_DSN');
    my $date = strftime("%Y-%m-%d", localtime);
    my $pid  = $$;

    # Try to insert the lock
    eval {
        local $dbh->{PrintError} = 0; $dbh->do(
            'insert into edtk_admin (ed_action_date,ed_action_pid,ed_action_status,ed_oedtk_release) values (?,?,?,?)',
            undef, $date, $pid, 'START', $VERSION
        );
    };
    if ($@) {                 # conflict, another process already holds it
        $dbh->disconnect;
        return 0;
    }

    # Check that it is really us
    my ($got_pid) = $dbh->selectrow_array(
        'select ed_action_pid from edtk_admin where ed_action_date = ?', undef, $date
    );
    unless ($got_pid == $pid) {
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

sub _db_check_driver_name($){
    my ($dbh) = shift;
    
    # Guard against an invalid or disconnected $dbh
    return "NC" unless defined $dbh;
    my $driver_name = eval { $dbh->{'Driver'}->{'Name'} };
    return "NC" unless defined $driver_name;

    if    ($driver_name =~ m/SQLite/i)          { return "SQLite";     }
    elsif ($driver_name =~ m/Oracle/i)          { return "Oracle";     }
    elsif ($driver_name =~ m/Pg/i)              { return "PostgreSQL"; }
    elsif ($driver_name =~ m/(?:mysql|maria)/i) { return "mysql";      }
    else                                        { return "NC";          }
}

# Returns the MySQL storage-engine clause appended to CREATE TABLE statements.
# The engine is configurable through EDTK_DB_STORAGE_ENGINE (default: MyISAM,
# kept for its bulk-load performance). Empty string for non-MySQL drivers.
sub _db_engine_clause {
    my ($dbh) = @_;
    return '' unless _db_check_driver_name($dbh) eq 'mysql';
    unless (defined $_DB_ENGINE_CACHE) {
        my $cfg = eval { config_read('EDTK_DB') } || {};
        $_DB_ENGINE_CACHE = $cfg->{'EDTK_DB_STORAGE_ENGINE'} || 'MyISAM';
    }
    return ' engine=' . $_DB_ENGINE_CACHE . ' ';
}


# Does an object (table, index or sequence) already exist in the current schema?
# Queries each driver's data dictionary; returns 1/0 (0 for an unknown driver,
# so that the CREATE attempt is still allowed to run).
sub _db_object_exists {
    my ($dbh, $kind, $name) = @_;
    my $driver = _db_check_driver_name($dbh);
    my ($schema, $obj) = ($name =~ /^(\w+)\.(\w+)$/) ? ($1, $2) : (undef, $name);

    if ($driver eq 'SQLite') {
        my ($n) = $dbh->selectrow_array(
            'select 1 from sqlite_master where type = ? and name = ?', undef, $kind, $obj);
        return $n ? 1 : 0;
    }
    elsif ($driver eq 'PostgreSQL') {
        my ($n) = $dbh->selectrow_array(
            'select 1 from pg_class c join pg_namespace n on n.oid = c.relnamespace '
          . 'where c.relname = ? and n.nspname = current_schema()', undef, $obj);
        return $n ? 1 : 0;
    }
    elsif ($driver eq 'mysql') {
        if ($kind eq 'index') {
            my ($n) = $dbh->selectrow_array(
                'select 1 from information_schema.statistics '
              . 'where table_schema = database() and index_name = ?', undef, $obj);
            return $n ? 1 : 0;
        }
        my ($n) = $dbh->selectrow_array('show tables like ?', undef, $obj);
        return $n ? 1 : 0;
    }
    elsif ($driver eq 'Oracle') {
        my ($n) = $dbh->selectrow_array(
            'select 1 from user_objects where object_name = upper(?)', undef, $obj);
        return $n ? 1 : 0;
    }
    return 0;
}


# Extracts the kind ('table'|'index'|'sequence') and name from a CREATE statement.
sub _db_parse_create {
    my ($sql) = @_;
    return ('index',    $1) if $sql =~ /\bcreate\s+(?:unique\s+)?index\s+(?:if\s+not\s+exists\s+)?(\S+)/i;
    return ('table',    $1) if $sql =~ /\bcreate\s+table\s+(?:if\s+not\s+exists\s+)?(\S+)/i;
    return ('sequence', $1) if $sql =~ /\bcreate\s+sequence\s+(?:if\s+not\s+exists\s+)?(\S+)/i;
    return;
}


# Runs a DDL statement through the driver-specific fixup. On drivers that lack
# "CREATE ... IF NOT EXISTS" (Oracle, MySQL) the clause is emulated by checking
# existence first and stripping it. Returns the underlying do() result.
sub _db_do_ddl {
    my ($dbh, $sql) = @_;
    my $driver = _db_check_driver_name($dbh);
    $sql = _sql_fixup($dbh, $sql, 'casse');

    if (   ($driver eq 'Oracle' || $driver eq 'mysql')
        && $sql =~ /\bcreate\b.*\bif\s+not\s+exists\b/is) {
        my ($kind, $name) = _db_parse_create($sql);
        return 1 if defined $name && _db_object_exists($dbh, $kind, $name);
        $sql =~ s/\s+if\s+not\s+exists\b//ig;
    }
    return do { local $dbh->{PrintError} = 0; $dbh->do($sql) };
}


# Per-engine table-maintenance command templates, as (repair, optimize) hash refs
# keyed by _db_check_driver_name() class. A template without %s is a portable no-op
# ("select 1"), so an engine that has no such command still runs harmlessly. Kept in
# one place so every engine's coverage is declared and unit-testable.
sub _db_maintenance_commands ($) {
    my ($driver) = @_;
    my %repair = (
        NC         => "select 1",
        mysql      => "repair table %s",
        Oracle     => "select 1 from dual",
        PostgreSQL => "select 1",
        SQLite     => "select 1",
    );
    my %optm = (
        NC         => "select 1",
        mysql      => "optimize table %s",
        Oracle     => "select 1 from dual",
        # VACUUM FULL takes an exclusive lock and rewrites the whole table: it does
        # not belong in the routine maintenance path. Plain VACUUM ANALYZE reclaims
        # space without blocking writers and refreshes the planner statistics.
        PostgreSQL => "vacuum analyze %s",
        # SQLite has no per-table VACUUM; ANALYZE %s refreshes the statistics it uses.
        SQLite     => "analyze %s",
    );
    return (\%repair, \%optm);
}

sub admin_optimize_db {
	# EXAMPLE CALL:
	# admin_optimize_db (CFG => $cfg);

    my %p = @_;

    # Single connection for the whole operation (it used to open two per table).
    $p{DBH} = db_connect($p{CFG}, 'EDTK_DBI_DSN');

    # Repatriate any pending backup rows before optimizing / repairing.
    eval { _db_maybe_reconcile($p{DBH}, $p{CFG}); };
    &logger(3, "admin_optimize_db: reconciliation failed: $@") if $@;

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
    my $dbName = _db_check_driver_name($p{DBH});
    &logger(7, "admin_optimize_db: driver=$dbName, ".scalar(@tListeTables)." tables");

    # PostgreSQL maintenance can spawn parallel workers that allocate dynamic shared
    # memory in /dev/shm; on a small /dev/shm the segment resize aborts with
    # "could not resize shared memory segment ... No space left on device". Routine
    # per-table maintenance gains nothing from parallelism, so force it serial.
    if ($dbName eq 'PostgreSQL') {
        eval { local $p{DBH}->{PrintError} = 0; $p{DBH}->do($_) }
            for ('set max_parallel_maintenance_workers = 0',
                 'set max_parallel_workers_per_gather = 0');
    }

    my ($hCdeRepair, $hCdeOptm) = _db_maintenance_commands($dbName);

    foreach my $table (@tListeTables) {
        # Repair
        my $tpl_repair = $hCdeRepair->{$dbName} // "select 1";
        # sprintf only when the template contains %s
        my $sql_repair = ($tpl_repair =~ /\%s/) ? sprintf($tpl_repair, $table) : $tpl_repair;
        &logger(7, "repair: $sql_repair");
        _db_maintenance_run($p{DBH}, _sql_fixup($p{DBH}, $sql_repair, 'casse'), "repair $table");

        # Optimize
        my $tpl_optm = $hCdeOptm->{$dbName} // "select 1";
        my $sql_optm = ($tpl_optm =~ /\%s/) ? sprintf($tpl_optm, $table) : $tpl_optm;
        &logger(7, "optimize: $sql_optm");
        _db_maintenance_run($p{DBH}, _sql_fixup($p{DBH}, $sql_optm, 'casse'), "optimize $table");
    }
    $p{DBH}->disconnect;
    return 1;
}

# Run one maintenance statement. Catches driver errors so a single table cannot
# abort the whole pass, and reports them as one concise logger line instead of the
# raw DBI/PrintError dump (e.g. a PostgreSQL shared-memory exhaustion). Never dies.
sub _db_maintenance_run {
    my ($dbh, $sql, $what) = @_;
    my $res = do {
        local $dbh->{PrintError} = 0;
        local $dbh->{RaiseError} = 0;
        eval { $dbh->do($sql) };
    };
    return 1 if defined $res;
    &logger(4, "can't $what: ".($dbh->errstr // $@ // 'unknown error'));
    return 0;
}

sub _sql_fixup_v1 {
	my ($dbh, $sql) = @_;

	# invert the logic: standard SQL => Oracle-specific
	if ($dbh->{'Driver'}->{'Name'} ne 'Oracle') {
		$sql =~ s/varchar2 *(\(\d+\))/varchar$1/gi;
	}

	return $sql;
}

sub _sql_fixup {
    my ($dbh, $sql, $mysqlCasse) = @_;
    my $driver = $dbh->{'Driver'}->{'Name'};
    # Driver class, so that MariaDB (Driver.Name 'MariaDB') is handled like MySQL.
    my $class  = _db_check_driver_name($dbh);

    # POSTGRESQL specifics
    if ($class eq 'PostgreSQL') {
        # --- Empty strings '' for non-string types ---
        if ($sql =~ /VALUES\s*\((.*)\)/si) {
            my $values_part = $1;
            # Replace standalone '' with NULL
            $values_part =~ s/''(?=\s*,|\s*\))/NULL/g;
            $sql =~ s/VALUES\s*\(.*\)/VALUES ($values_part)/si;
        }

        # Handle the update form "SET column = ''"
        $sql =~ s/=\s*''(\s*,|\s+WHERE|=)/ = NULL$1/gi;
    }
    
    # Generic logic / other drivers: Oracle keeps VARCHAR2, everyone else gets VARCHAR.
    if ($class ne 'Oracle') {
        $sql =~ s/VARCHAR2 *(\(\d+\))/VARCHAR$1/gi;
    }

    # MySQL forced case (keyed on the real MySQL driver only; MariaDB is left untouched).
    if ($driver eq 'mysql' and $mysqlCasse and $sql !~ /\b(INSERT|REPLACE)\b/i) {
        $sql = uc($sql);
    }


    return $sql;
}

sub db_backup_agent($;$){
	# Archives the 3 production tables (EDTK_DBI_TRACKING / OUTMNGR / ACQUIT) into a
	# date-stamped snapshot, then purges the rows older than EDTK_ENTIRE_YEARS_KEPT.
	# The snapshot copies the whole table (not just the old rows), so a re-run on the
	# same day must not overwrite it with the now-smaller source: the existing archive
	# is kept as is. Called from Outmngr::omgr_purge_fs.
	my ($dbh, $cfg) = @_;
	$cfg ||= config_read('EDTK_DB');
	unless (defined ($cfg->{'EDTK_ENTIRE_YEARS_KEPT'}) && $cfg->{'EDTK_ENTIRE_YEARS_KEPT'} > 0){
		&logger (4, "EDTK_ENTIRE_YEARS_KEPT not defined for optimization purge. db_backup_agent not needed.");
		return 1;
	}

	my $suffixe		= strftime ("%Y%m%d", localtime) . "_BAK";
	my $cur_year	= strftime ("%Y", localtime);
	my $kept_year	= $cur_year - $cfg->{'EDTK_ENTIRE_YEARS_KEPT'};

	# (table, date column, purge threshold) of the tables to archive and purge.
	my @plan = (
		[ $cfg->{'EDTK_DBI_TRACKING'}, 'ed_tstamp',   $kept_year . "0101000000" ],
		[ $cfg->{'EDTK_DBI_OUTMNGR'},  'ed_dtedtion', $kept_year . "0101"     ],
		[ $cfg->{'EDTK_DBI_ACQUIT'},   'ed_dtpost',   $kept_year . "0101"     ],
	);

	foreach my $spec (@plan) {
		my ($table, $datecol, $check) = @$spec;
		next unless defined $table && $table ne '';

		my $sql_check = "select count($datecol) from $table where $datecol < ? ";
		my $sth		= $dbh->prepare($sql_check);
		do { local $sth->{PrintError} = 0; $sth->execute($check) } or &logger (3, "SQL execute failed ".$sth->err."-".$sth->errstr);
		my ($result) = $sth->fetchrow_array;
		unless ($result){
			&logger (5, "db_backup_agent has nothing to do with $table");
			next;
		}

		my $cible = $table . "_" . $suffixe;
		# MySQL stores the archive under its uppercase name (copy_table DDL is uppercased).
		my $exists = _db_object_exists($dbh, 'table', $cible)
			|| _db_object_exists($dbh, 'table', uc $cible);
		if ($exists) {
			&logger (4, "db_backup_agent: archive $cible already exists for today, keeping it");
		} else {
			copy_table ($dbh, $table, $cible, '-create');
			&logger (5, "db_backup_agent archived $table into $cible");
		}

		my $sql_clean = "delete from $table where $datecol < ? ";
		_db_do_log($dbh, $sql_clean, "ERROR: can't delete from $table", bind => [$check], fatal => 1);

		&logger (4, "db_backup_agent DONE with $table for data older than $check.");
	}

	return 1;
}


1;

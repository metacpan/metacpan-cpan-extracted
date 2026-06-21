package oEdtk::DBAdmin;

use DBI;
use oEdtk::Config	qw(config_read);
use oEdtk::logger	qw(logger $LOGGERLEVEL $WARN2LOGGER);
use POSIX			qw(strftime);
use Scalar::Util 	qw(looks_like_number);
use strict;
use Text::CSV;
use warnings;
use Data::Dumper qw(Dumper);

# TODO   : check db status et retourner alerte si besoin -sortir de db_admin_check si il y a le moindre problème sur les tables de tracking + dans les log en cas d'incident, préciser de quelle table il s'agit
# Fait   : ajout ED_IDGED, ordre des purges - drapeau table admin rechercher la valeur contrôlée 
# Fait   : Simplification de l'historisation en se basant sur ED_DTLOT, protection des ED_DTLOT (ED_DLOT non numérique ou non date) à l'insertion faite au niveau de la demande d'insertion
# 220725 : correction erreur silencieuse dans historisation lorsqu'il n'y a pas de valeur assignée $result
# 230818 : préparation évolution check à la demande (base stats AGREGE à valider)
# check sql : https://www.eversql.com
# SHOW CREATE DATABASE oEdtk;

use Exporter;
our $VERSION		= 2.1063; #version lc Mysql / PG / Oracle / SQLite
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


sub move_table (@){
	&logger (4, "method oEdtk::DBAdmin::move_table is deprecated you should use oEdtk::DBAdmin::copy_table");

	copy_table (@_);
1;
}


sub copy_table ($$$;$){ 
	my ($dbh, $table_source, $table_cible, $create_option) = @_;
	$create_option ||= "";

	# check if source is empty
	my $sql_check_source = "SELECT SIGN(COUNT(*)) FROM ".$table_source;
	my $sth = $dbh->prepare($sql_check_source);
	$sth->execute() or &logger (3, "SQL execute failed ".$sth->err."-".$sth->errstr);
	my $result = $sth->fetchrow_array;
	unless ($result){
		&logger (4, "Source $table_source is empty, copy aborted");
		return 1;
	}

	# preparing data copy from source to cible
	&logger (4, "Data from $table_source will be copyed into $table_cible");

	if ($create_option =~/-create/i) {
		my $sql_create	= "CREATE TABLE ".$table_cible." AS SELECT * FROM ".$table_source;
		# en cas d'erreur, DIE pour protéger toute autre opération sur les bases (db_backup_agent, ...)
		$dbh->do(_sql_fixup($dbh, $sql_create, 'casse'), undef, ) or die $dbh->errstr;	

	} else {
		my $sql_insert	= "INSERT INTO  ".$table_cible." SELECT * FROM ".$table_source;
		# en cas d'erreur, DIE pour protéger toute autre opération sur les bases (db_backup_agent, ...)
		$dbh->do(_sql_fixup($dbh, $sql_insert, 'casse'), undef, ) or die $dbh->errstr;	
	}
	
	&logger (4, "Insert DONE into $table_cible");
1;
}


sub insert_tData_deprecated_1 {
# Exemple d'appel
#		my $ret = insert_tData(
#			dbh => $dbh, 
#			table => $cfg->{'EDTK_DBI_TRACKING'}, 
#			tCols => \@cols,
#			tData => \@tData
#		);
	
	my (%p) = @_;
	&logger (7, "Table : ". Dumper($p{'table'}));
	&logger (7, "NB Data : " . @{$p{'tData'}});
	&logger (7, "Data : " . Dumper($p{'tData'}));

	my $sql = "insert into " . ${p{'table'}} . " (" . join(',', @{$p{'tCols'}})
			. ") values (" . join(',', ('?') x @{$p{'tCols'}}) . ")";
	&logger (7, $sql);

	my $sth = ${p{'dbh'}}->prepare_cached($sql);
	$sth->execute(@{$p{'tData'}}) or &logger (3, "SQL execute failed ".$sth->err."-".$sth->errstr);

	1;
}


sub _load_csv_mysql_infile ($$$$) {
	my ($dbh, $tablename, $fi, $params) = @_;

	# on récupère la ligne d'en-tete qui contient les champs et l'ordre d'insertion des champs
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
	# => mysql> set global local_infile=true; + dans la config DSN ";mysql_local_infile=true"
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

	my $count = $dbh->do($sql,undef,$fi) or &logger (3, "SQL execute failed $@-".$dbh->err."-".$dbh->errstr);  

	if ($count !~m/^\d+$/) { # or $count = "0E0") {
		return (-1, &logger (3, "$count-ERROR LOAD INFILE-$@ $!".$dbh::errstr));
	}

	&logger(4, $count." lines inserted into $tablename");
	return ($count, " lines inserted");
}


sub _load_csv_mysql_local_infile ($$$$) {
	my ($dbh, $tablename, $fi, $params) = @_;

	# on récupère la ligne d'en-tete qui contient les champs et l'ordre d'insertion des champs
	open(my $fh, '<', $fi) or die "ERROR: Cannot open file \"$fi\": $!\n";
	my $fields = <$fh>;
	chomp ($fields);
	$fields =~s/\"+//g;
	close($fh);

	# https://www.perlmonks.org/?node_id=1058110  => insert data inline

	# https://metacpan.org/pod/DBD::mysql
	# https://tecfa.unige.ch/guides/mysql/man/manuel_LOAD_DATA.html
	# https://dev.mysql.com/doc/refman/8.0/en/load-data.html
	# https://stackoverflow.com/questions/59993844/error-loading-local-data-is-disabled-this-must-be-enabled-on-both-the-client
	# https://dzone.com/articles/mysql-57-utf8mb4-and-the-load-data-infile
	# => mysql> set global local_infile=true; + dans la config DSN ";mysql_local_infile=true"

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

	my $count = $dbh->do($sql,undef,$fi) or &logger (3, "SQL execute failed $@-".($dbh->err || "")."-".($dbh->errstr || ""));  

	if ($count !~m/^\d+$/) { # or $count = "0E0") {
#		&logger (3, "$count-ERROR LOAD INFILE-$@ $!".$dbh::errstr);
		return (-1, &logger (3, "$count-ERROR LOAD INFILE-$@ $!".($dbh::errstr || "")));
	}

	&logger(4, $count." lines inserted into $tablename");
	return ($count, " lines inserted");
}

# Cache global des types numériques par table
# Structure : { "SCHEMA.TABLE" => { col_name => 1_si_numerique } }

sub _get_col_meta_deprecated_2 {
    # Retourne { COL_NAME => { numeric => 1, size => N } }
    my ($dbh, $table) = @_;
    my $key = lc($table);
    return $_csv_import_type_cache{$key} if exists $_csv_import_type_cache{$key};

    my %meta;
    eval {
        my ($schema, $table_name) = $table =~ /^(\w+)\.(\w+)$/
                                    ? ($1, lc($2))
                                    : (undef, lc($table));
        my $sth = $dbh->column_info(undef, $schema, $table_name, undef);
        my $found = 0;
        while (my $row = $sth->fetchrow_hashref) {
            $found++;
            my $col  = uc($row->{COLUMN_NAME} // '');
            $col =~ s/^\s+|\s+$//g;
            my $type = $row->{DATA_TYPE}    // 0;
            my $name = lc($row->{TYPE_NAME} // '');
            my $size = $row->{COLUMN_SIZE}  // 0;   # longueur max pour VARCHAR

            my %num_codes = map { $_ => 1 } (2, 3, 4, 5, 6, 7, 8, -5, -6, -7);
            my $by_name = ($name =~ m{
                ^( int[248]? | integer | smallint | bigint
                 | serial | bigserial | smallserial
                 | numeric | decimal | number
                 | float[48]? | real | double(\s+precision)?
                 | money | tinyint | mediumint )$
            }xi) ? 1 : 0;
            my $is_num = ($num_codes{$type} || $by_name) ? 1 : 0;

            $meta{$col} = { numeric => $is_num, size => $size };
            &logger(7, "_get_col_meta: col=$col TYPE=$name($size) is_num=$is_num");
        }
        &logger(5, "_get_col_meta: $found colonnes pour '$table_name'");
    };
    if ($@) {
        &logger(3, "_get_col_meta: column_info failed for $table: $@");
    }
    $_csv_import_type_cache{$key} = \%meta;
    return \%meta;
}

sub _get_col_meta_deprecated_1 {
    # Retourne { col_name => { numeric => 1, size => N } }
    # Les clés sont normalisées selon la casse du driver (uc pour MySQL, lc sinon)
    my ($dbh, $table, $norm_id) = @_;

    # Clé de cache : table en minuscules + driver, pour éviter les collisions
    # entre deux bases de casse différente sur le même process
    my $driver   = lc( $dbh->{Driver}{Name} // '' );
    my $is_mysql = ( $driver =~ /mysql|mariadb/ ) ? 1 : 0;
    my $cache_key = lc($table) . "\0" . $driver;
    return $_csv_import_type_cache{$cache_key}
        if exists $_csv_import_type_cache{$cache_key};

    # Fallback si $norm_id n'est pas fourni (appel autonome)
    $norm_id //= $is_mysql
        ? sub { my $s = $_[0]; $s =~ s/^\s+|\s+$//g; return uc($s) }
        : sub { my $s = $_[0]; $s =~ s/^\s+|\s+$//g; return lc($s) };

    my %meta;
    eval {
		my ($schema, $table_name) = $table =~ /^(\w+)\.(\w+)$/
                                ? ($1, $2)
                                : (undef, $table);
                                # plus de $norm_id->() ici : normalisé en amont

        my $sth = $dbh->column_info(undef, $schema, $table_name, undef);

        # Certains drivers (SQLite notamment) ne supportent pas column_info :
        # on tente un fallback par SELECT vide pour récupérer les noms de colonnes
        # sans les types (mode dégradé : pas de contrôle numérique ni de taille)
        unless (defined $sth) {
            &logger(5, "_get_col_meta: column_info non supporté pour '$table_name', fallback SELECT");
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

            $meta{$col} = { numeric => $is_num, size => $size };
            &logger(7, "_get_col_meta: col=$col TYPE=$name($size) is_num=$is_num");
        }
        &logger(5, "_get_col_meta: $found colonnes pour '$table_name'");
    };
    if ($@) {
        &logger(3, "_get_col_meta: column_info failed for $table: $@");
    }

    $_csv_import_type_cache{$cache_key} = \%meta;
    return \%meta;
}

sub csv_import_deprecated_3 ($$$;$){
    my ($dbh, $table, $in, $params) = @_;
    $params->{'mode'}         = $params->{'mode'}         || "insert";
    $params->{'sep_char'}     = $params->{'sep_char'}      || ',';
    $params->{'quote_char'}   = $params->{'quote_char'}    || '"';
    $params->{'local_infile'} = $params->{'local_infile'}  || "no";

    # --- Détection du driver pour la normalisation de casse ---
    # MySQL/MariaDB : identifiants en majuscules dans le catalogue
    # PostgreSQL, Oracle, SQLite : identifiants en minuscules
    my $driver = lc( $dbh->{Driver}{Name} // '' );
    my $is_mysql = ( $driver =~ /mysql|mariadb/ ) ? 1 : 0;
    my $norm_id  = $is_mysql
        ? sub { my $s = $_[0]; $s =~ s/^\s+|\s+$//g; return uc($s)  }
        : sub { my $s = $_[0]; $s =~ s/^\s+|\s+$//g; return lc($s)  };

    # Normalisation du nom de table selon la casse du driver
    # Préserve le schéma si présent (schema.table)
    $table = join('.', map { $norm_id->($_) } split(/\./, $table, 2));

    if ( $params->{'local_infile'} =~ /try/i
      && $params->{'mode'}         !~ /merge/i
      && $dbh->{'Name'}            =~ m/mysql_local_infile\=true/i ) {
        &logger(7, "'mysql_local_infile=true' detected in DSN by csv_import, trying local infile");
        return _load_csv_mysql_local_infile($dbh, $table, $in, $params);
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

    # Normalisation des colonnes CSV selon la casse du driver cible
    my @cols = map { $norm_id->($_) } $csv->fields();

    if (defined $params->{'ignore_first_line'}) {
        $line = <$fh>;
    }

    # Récupération des métadonnées (types + tailles) via le catalogue
    # Les clés de %$col_meta sont normalisées par _get_col_meta selon le driver
    my $col_meta = _get_col_meta($dbh, $table);

    my $clean_val = sub {
        my ($col, $val) = @_;
        return undef unless defined $val;

        # La clé de lookup est déjà normalisée ($col vient de @cols)
        my $m = $col_meta->{ $col } // {};

        if ($val eq '') {
            if ($m->{numeric}) {
                &logger(7, "clean_val: col '$col' numerique, '' => undef");
                return undef;
            }
            return $val;
        }

        # Troncature si la valeur dépasse la taille max déclarée
        if ($m->{size} && length($val) > $m->{size}) {
            my $truncated = substr($val, 0, $m->{size});
            &logger(5, "clean_val: col '$col' tronquee de ".length($val)." a $m->{size} cars");
            return $truncated;
        }

        return $val;
    };

    while (<$fh>) {
        $lines_inserted++;
        $csv->parse($_);
        my @data = $csv->fields();

        my ($sql, $sth, $seqlot);

        if ($params->{'mode'} =~ /merge/i) {
            $sql = "SELECT " . $cols[0] . " FROM " . $table
                 . " WHERE "  . $cols[0] . " = ?";
            &logger(8, "Select into $table : $sql");
            $sth = $dbh->prepare_cached($sql);
            $sth->execute( $clean_val->($cols[0], $data[0]) )
                or &logger(3, "SQL execute failed ".$sth->err."-".$sth->errstr);
            $seqlot = $sth->fetchrow_hashref();

            # fetchrow_hashref retourne des clés dans la casse du driver :
            # on normalise pour comparer de façon fiable
            if (defined $seqlot) {
                $seqlot = { map { $norm_id->($_) => $seqlot->{$_} } keys %$seqlot };
            }
        }

        if (defined $seqlot && defined $seqlot->{ $cols[0] }) {
            $sql = "UPDATE " . $table . " SET " . join('=?, ', @cols) . "=? "
                 . " WHERE " . $cols[0] . " = ?";
            &logger(8, "Update into $table : $sql");
            $sth = $dbh->prepare_cached($sql);
            $sth->execute(
                (map { $clean_val->($cols[$_], $data[$_]) } 0..$#cols),
                $clean_val->($cols[0], $data[0])
            ) or &logger(3, "SQL execute failed ".$sth->err."-".$sth->errstr);
        } else {
            $sql = "INSERT INTO " . $table . " (" . join(',', @cols)
                 . ") VALUES (" . join(',', ('?') x @cols) . ")";
            &logger(7, "Insert into $table : $sql");
            $sth = $dbh->prepare_cached($sql);
            $sth->execute(
                map { $clean_val->($cols[$_], $data[$_]) } 0..$#cols
            ) or &logger(3, "SQL execute failed ".$sth->err."-".$sth->errstr);
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

sub csv_import_deprecated_2 ($$$;$){
	# xxxxxx insert mysql / autres
    my ($dbh, $table, $in, $params) = @_;
    $params->{'mode'}        = $params->{'mode'}        || "insert";
    $params->{'sep_char'}    = $params->{'sep_char'}    || ',';
    $params->{'quote_char'}  = $params->{'quote_char'}  || '"';
    $params->{'local_infile'}= $params->{'local_infile'}|| "no";

    if ( $params->{'local_infile'}=~/try/i
      && $params->{'mode'}!~/merge/i
      && $dbh->{'Name'} =~m/mysql_local_infile\=true/i) {
        &logger(7, "'mysql_local_infile=true' detected in DSN by csv_import, trying local infile");
        return _load_csv_mysql_local_infile($dbh, $table, $in, $params);
    }

    open(my $fh, '<', $in) or die "ERROR: Cannot open index file \"$in\": $!\n";
    my $csv = Text::CSV->new({ binary    => 1,
                               sep_char  => $params->{'sep_char'},
                               quote_char=> $params->{'quote_char'} });

    my ($line, $lines_inserted, $rv);
    if (defined $params->{'header'}) {
        $line = $params->{'header'};
    } else {
        $line = <$fh>;
    }
    $csv->parse($line);
    my @cols = map { my $c = $_; $c =~ s/^\s+|\s+$//g; $c } $csv->fields();

    if (defined $params->{'ignore_first_line'}) {
        $line = <$fh>;
    }

    # Récupération des métadonnées (types + tailles) via le catalogue
    my $col_meta = _get_col_meta($dbh, $table);

    my $clean_val = sub {
        my ($col, $val) = @_;
        return undef unless defined $val;
        (my $col_uc = uc($col)) =~ s/^\s+|\s+$//g;
        my $m = $col_meta->{$col_uc} // {};

        if ($val eq '') {
            if ($m->{numeric}) {
                &logger(7, "clean_val: col '$col_uc' numerique, '' => undef");
                return undef;
            }
            return $val;
        }

        # Troncature si la valeur dépasse la taille max déclarée (Postgres strict)
        if ($m->{size} && length($val) > $m->{size}) {
            my $truncated = substr($val, 0, $m->{size});
            &logger(5, "clean_val: col '$col_uc' tronquee de ".length($val)." a $m->{size} cars");
            return $truncated;
        }

        return $val;
    };

    while (<$fh>) {
        $lines_inserted++;
        $csv->parse($_);
        my @data = $csv->fields();

        my ($sql, $sth, $seqlot);

        if ($params->{'mode'}=~/merge/i) {
            $sql = "SELECT " . $cols[0] . " FROM " . $table
                 . " WHERE "  . $cols[0] . " = ?";
            &logger(8, "Select into $table : $sql");
            $sth = $dbh->prepare_cached($sql);
            $sth->execute( $clean_val->($cols[0], $data[0]) )
                or &logger(3, "SQL execute failed ".$sth->err."-".$sth->errstr);
            $seqlot = $sth->fetchrow_hashref();
        }

        if (defined $seqlot && defined $seqlot->{ $cols[0] }) {
            $sql = "UPDATE " . $table . " SET " . join('=?, ', @cols) . "=? "
                 . " WHERE " . $cols[0] . " = ?";
            &logger(8, "Update into $table : $sql");
            $sth = $dbh->prepare_cached($sql);
            $sth->execute(
                (map { $clean_val->($cols[$_], $data[$_]) } 0..$#cols),
                $clean_val->($cols[0], $data[0])
            ) or &logger(3, "SQL execute failed ".$sth->err."-".$sth->errstr);
        } else {
            $sql = "INSERT INTO " . $table . " (" . join(',', @cols)
                 . ") VALUES (" . join(',', ('?') x @cols) . ")";
            &logger(8, "Insert into $table : $sql");
            $sth = $dbh->prepare_cached($sql);
            $sth->execute(
                map { $clean_val->($cols[$_], $data[$_]) } 0..$#cols
            ) or &logger(3, "SQL execute failed ".$sth->err."-".$sth->errstr);
        }

        if ($sth->err && ($sth->err > 0 || $sth->err =~m/0E/)) {
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

# ============================================================
# FONCTION PRIVÉE : normalisation des identifiants SQL
# selon la casse du driver (uc pour MySQL/MariaDB, lc sinon)
# ============================================================
sub _norm_identifiers {
    my ($dbh, $table, $cols_ref) = @_;

    my $driver   = lc( $dbh->{Driver}{Name} // '' );
    my $is_mysql = ( $driver =~ /mysql|mariadb/ ) ? 1 : 0;
    my $norm_id  = $is_mysql
        ? sub { my $s = $_[0]; $s =~ s/^\s+|\s+$//g; return uc($s) }
        : sub { my $s = $_[0]; $s =~ s/^\s+|\s+$//g; return lc($s) };

    # Normalisation du nom de table en préservant le schéma si présent
    my $norm_table = join('.', map { $norm_id->($_) } split(/\./, $table, 2));

    # Normalisation des colonnes (optionnel)
    my @norm_cols = map { $norm_id->($_) } @{ $cols_ref // [] };

    return ($norm_id, $norm_table, @norm_cols);
}


# ============================================================
# FONCTION PRIVÉE : métadonnées des colonnes d'une table
# Retourne { col_name => { numeric => 1, size => N } }
# Les clés sont normalisées via $norm_id (fourni par _norm_identifiers)
# $table doit être déjà normalisé en amont
# ============================================================

sub _get_col_meta {
    my ($dbh, $table, $norm_id) = @_;

    # $norm_id est obligatoire - toujours fourni via _norm_identifiers
    die "_get_col_meta: norm_id manquant" unless defined $norm_id;

    my $driver    = lc( $dbh->{Driver}{Name} // '' );
    my $cache_key = lc($table) . "\0" . $driver;
    return $_csv_import_type_cache{$cache_key}
        if exists $_csv_import_type_cache{$cache_key};

    my %meta;
    eval {
        # $table est déjà normalisé en amont : split sans re-normalisation
        my ($schema, $table_name) = $table =~ /^(\w+)\.(\w+)$/
                                    ? ($1, $2)
                                    : (undef, $table);

        my $sth = $dbh->column_info(undef, $schema, $table_name, undef);

        # Fallback pour les drivers ne supportant pas column_info (ex: SQLite)
        # Mode dégradé : noms de colonnes sans type ni taille
        unless (defined $sth) {
            &logger(5, "_get_col_meta: column_info non supporté pour '$table_name', fallback SELECT");
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

            $meta{$col} = { numeric => $is_num, size => $size };
            &logger(7, "_get_col_meta: col=$col TYPE=$name($size) is_num=$is_num");
        }
        &logger(5, "_get_col_meta: $found colonnes pour '$table_name'");
    };
    if ($@) {
        &logger(3, "_get_col_meta: column_info failed for $table: $@");
    }

    $_csv_import_type_cache{$cache_key} = \%meta;
    return \%meta;
}

# ============================================================
# FONCTION PRIVÉE : nettoyage d'une valeur selon les métadonnées
# de la colonne (type numérique, taille max)
# ============================================================
sub _make_clean_val {
    my ($col_meta) = @_;
    return sub {
        my ($col, $val) = @_;
        return undef unless defined $val;
        my $m = $col_meta->{ $col } // {};

        if ($val eq '') {
            if ($m->{numeric}) {
                &logger(7, "clean_val: col '$col' numerique, '' => undef");
                return undef;
            }
            return $val;
        }

        if ($m->{size} && length($val) > $m->{size}) {
            my $truncated = substr($val, 0, $m->{size});
            &logger(5, "clean_val: col '$col' tronquee de ".length($val)." a $m->{size} cars");
            return $truncated;
        }

        return $val;
    };
}

sub insert_tData {
# Exemple d'appel :
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
    $sth->execute(
        map { $clean_val->($norm_cols[$_], $p{'tData'}[$_]) } 0..$#norm_cols
    ) or &logger(3, "SQL execute failed " . $sth->err . "-" . $sth->errstr);
    1;
}

# ============================================================
# FONCTION PUBLIQUE : insertion d'un enregistrement
# Interface (API) inchangée
# ============================================================
sub insert_tData_deprecated_2 {
# Exemple d'appel :
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

    &logger(7, "Table : $norm_table");
    &logger(7, "NB Data : " . scalar @{$p{'tData'}});
    &logger(7, "Data : " . Dumper($p{'tData'}));

    my $sql = "INSERT INTO " . $norm_table
            . " (" . join(',', @norm_cols) . ")"
            . " VALUES (" . join(',', ('?') x @norm_cols) . ")";
    &logger(7, $sql);

    my $sth = $p{'dbh'}->prepare_cached($sql);
    $sth->execute(@{$p{'tData'}})
        or &logger(3, "SQL execute failed " . $sth->err . "-" . $sth->errstr);
    1;
}


# ============================================================
# FONCTION PUBLIQUE : import d'un fichier CSV dans une table
# Interface (API) inchangée
# ============================================================
sub csv_import ($$$;$) {
    my ($dbh, $table, $in, $params) = @_;
    $params->{'mode'}         = $params->{'mode'}         || "insert";
    $params->{'sep_char'}     = $params->{'sep_char'}      || ',';
    $params->{'quote_char'}   = $params->{'quote_char'}    || '"';
    $params->{'local_infile'} = $params->{'local_infile'}  || "no";

    # Normalisation du driver et du nom de table
    # $norm_id est gardé pour normaliser les colonnes CSV après lecture du header
    my ($norm_id, $norm_table) = _norm_identifiers($dbh, $table);

    if ( $params->{'local_infile'} =~ /try/i
      && $params->{'mode'}         !~ /merge/i
      && $dbh->{'Name'}            =~ m/mysql_local_infile\=true/i ) {
        &logger(7, "'mysql_local_infile=true' detected in DSN by csv_import, trying local infile");
        return _load_csv_mysql_local_infile($dbh, $norm_table, $in, $params);
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

    # Les colonnes CSV sont normalisées via $norm_id après lecture du header,
    # car elles ne sont connues qu'à ce stade (contrairement à insert_tData)
    my @cols = map { $norm_id->($_) } $csv->fields();

    if (defined $params->{'ignore_first_line'}) {
        $line = <$fh>;
    }

    # $norm_table et $norm_id sont cohérents : les clés de %$col_meta
    # sont dans la même casse que @cols
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
            $sth->execute( $clean_val->($cols[0], $data[0]) )
                or &logger(3, "SQL execute failed ".$sth->err."-".$sth->errstr);
            $seqlot = $sth->fetchrow_hashref();

            # fetchrow_hashref retourne des clés dans la casse native du driver :
            # on normalise pour que la comparaison avec $cols[0] soit fiable
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
            $sth->execute(
                (map { $clean_val->($cols[$_], $data[$_]) } 0..$#cols),
                $clean_val->($cols[0], $data[0])
            ) or &logger(3, "SQL execute failed ".$sth->err."-".$sth->errstr);
        } else {
            $sql = "INSERT INTO " . $norm_table
                 . " (" . join(',', @cols) . ")"
                 . " VALUES (" . join(',', ('?') x @cols) . ")";
            &logger(7, "Insert into $norm_table : $sql");
            $sth = $dbh->prepare_cached($sql);
            $sth->execute(
                map { $clean_val->($cols[$_], $data[$_]) } 0..$#cols
            ) or &logger(3, "SQL execute failed ".$sth->err."-".$sth->errstr);
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


sub csv_import_deprecated_1 ($$$;$){
	# insertion d'un fichier csv dans une table
	# csv_import($dbh, "EDTK_ACQ", $ARGV[0], 
	#		{sep_char => ',' ,						# ',' is default value
	#		quote_char => '"',						# '"' is default value
	#		header => 'ED_SEQLOT,ED_LOTNAME,...',	# default value is "no header", read header from csv file
	#		ignore_first_line => 1,					# ignore first line : option, could be used in conjonction with header du change it
	# 		mode => 'merge';						# 'insert' is default value ('merge' imply no local_infile)
	#		local_infile => 'try'					# by default do not try local_infile, if set to 'try' try it for MySQL (see MySQL Configuration)
	#		});	
	

	my ($dbh, $table, $in, $params) = @_;
	$params->{'mode'}		= $params->{'mode'} || "insert";
	$params->{'sep_char'} 	= $params->{'sep_char'}  ||',';
	$params->{'quote_char'}	= $params->{'quote_char'}||'"' ;
	$params->{'local_infile'}=$params->{'local_infile'} || "no";


	if ( $params->{'local_infile'}=~/try/i && $params->{'mode'}!~/merge/i && $dbh->{'Name'} =~m/mysql_local_infile\=true/i) {
		&logger (7, "'mysql_local_infile=true' detected in DSN by csv_import, trying local infile if SHOW GLOBAL VARIABLES LIKE 'local_infile' apply");
		#SET GLOBAL local_infile = 'ON';
		#If setting this in my.cnf
		#[mysqld]
		#local_infile=ON
		return _load_csv_mysql_local_infile($dbh, $table, $in, $params);
		#return _load_csv_mysql_infile($dbh, $table, $in, $params);
	}


	open(my $fh, '<', $in) or die "ERROR: Cannot open index file \"$in\": $!\n";
	my $csv = Text::CSV->new({ binary => 1, sep_char => $params->{'sep_char'}, 
							quote_char => $params->{'quote_char'}});

	my ($line, $lines_inserted, $rv);
	if (defined $params->{'header'}){
		$line = $params->{'header'};
	} else {
		$line = <$fh>;
	}
	$csv->parse($line);
	my @cols = $csv->fields();

	if (defined $params->{'ignore_first_line'}){
		$line = <$fh>;
	}

	while (<$fh>) {
		$lines_inserted++;
		$csv->parse($_);
		my @data = $csv->fields();

		# s'assurer qu'on insère pas des valeurs null (contraintes ???) ou pas ?
		for (my $i=0 ; $i<=$#data ; $i++ ){
			$data[$i]=$data[$i] || "";
		}

		my ($sql, $sth, $seqlot);

		if 	($params->{'mode'}=~/merge/i) {
			$sql = "SELECT " . $cols[0] . " FROM " . $table 
				. " WHERE " . $cols[0] . " =?  ";
			&logger (8, "Select into $table : $sql");

			my $sth = $dbh->prepare_cached($sql);
			$sth->execute($data[0]) or &logger (3, "SQL execute failed ".$sth->err."-".$sth->errstr);

			$seqlot = $sth->fetchrow_hashref();
		}
		
		if (defined $seqlot->{' '}) {
			$sql = "UPDATE " . $table . " SET " . join ('=? , ', @cols) . "=? "
				. " WHERE " . $cols[0] . " =?  ";
			&logger (8, "Update into $table : $sql");

			$sth = $dbh->prepare_cached($sql);
			$sth->execute(@data, $data[0]) or &logger (3, "SQL execute failed ".$sth->err."-".$sth->errstr);
		
		} else {
			$sql = "INSERT INTO " . $table . " (" . join(',', @cols)
				. ") VALUES (" . join(',', ('?') x @cols) . ")";
			&logger (8, "Insert into $table : $sql");

			$sth = $dbh->prepare_cached($sql);
			$sth->execute(@data) or &logger (3, "SQL execute failed ".$sth->err."-".$sth->errstr);
			# GERER EN CAS D'ERREUR DANS LE FLUX A INJECTER : DBD::SQLite::db prepare_cached failed: table EDTK_DISTRIB has no column named ED_ID_VALUE at oEdtk/DBAdmin.pm line 275, <$fh> line 2
		}

		if ($sth->err && ($sth->err >0 or $sth->err =~m/0E/)) { 
			$rv = $sth->err."-".$sth->errstr;
		}
	}
	close($fh);

	if ($rv){
		&logger (-1, $rv);
		return  (-1, " - $rv");
	} else {
		$lines_inserted //=0 ;
		&logger (5, "$lines_inserted lines inserted from $in");
		return ($lines_inserted, " lines inserted");
	}
}

###### VERSION ORACLE DU MERGE, DIFFÉRENTE DE CELLE DE POSTGRESQL
	#MERGE INTO table_name USING table_reference ON (condition)
	#  WHEN MATCHED THEN
	#  UPDATE SET column1 = value1 [, column2 = value2 ...]
	#  WHEN NOT MATCHED THEN
	#  INSERT (column1 [, column2 ...]) VALUES (value1 [, value2 ...

	#MERGE INTO Table1 T1
	#  USING (SELECT Id, Meschamps FROM Table2) T2
	#    ON ( T1.Id = T2.Id ) -- Condition de correspondance
	#WHEN MATCHED THEN -- Si Vraie
	#  UPDATE SET T1.Meschamps = T2.Meschamps
	#WHEN NOT MATCHED THEN -- Si faux
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
	
	# revoir gestion ds attributs pour traiter l'affichage des messages d'erreur:
	# https://docstore.mik.ua/orelly/linux/dbi/ch04_05.htm

	# gestion de la connexion dans une boucle temporisée, pour effectuer 3 tentatives de connexion avec incrément de pause
	for (my $i=0;$i<3;$i++){
		sleep ($_LOCAL_EDTK_WAITRUN*$i);
		eval {
			$dbh=DBI->connect($dsn, $cfg->{"${dsnvar}_USER"}, $cfg->{"${dsnvar}_PASS"}, $dbargs); ## xxxx
		};

		if ($@){
			# en cas d'incident de connexion, on essaie encore
			&logger (4, "DBI connection missmatch to $dsnvar, we try 3 times");
			&logger (4, "Error message was : $@");

		} else {
			# si ça semble bon on sort

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
		if (defined $cfg->{"${dsnvar}_BAK"}) { # il faudrait ajouter le paramétrage dans la base de backup (procédure de création de cette base)
			&logger (4, "Could not connect to main database server: " . ($DBI::errstr || "not defined"));
			$dbh = _db_connect1($cfg, "${dsnvar}_BAK", $dbargs);
			
			if (!defined $dbh) {
				die "ERROR: Could not connect to backup database server : " . ($DBI::errstr || "not defined") ."\n";
			}
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

sub _table_exists {
    my ($dbh, $table_name) = @_;
	# universal soft and silent check

    # table_info prend 4 arguments : catalog, schema, table, type
    # On passe undef pour les filtres globaux et on cible le nom de la table
    my $sth = $dbh->table_info(undef, undef, $table_name, 'TABLE');
    
    # Si fetchrow_array renvoie quelque chose, c'est que la table existe
    my @info = $sth->fetchrow_array();
    
    return @info ? 1 : 0;
}

# Job à la demande
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

## Appel inline (à chaque connexion)
#sub acheck_db_admin_on_connect2 {
#	#my ($level, $return) = acheck_db_admin_on_connect ($dbh, $cfg);
#    my ($dbh, $cfg) = @_;
#    _db_maintenance(DBH => $dbh, CFG => $cfg, rotate => 1, purge => 1);
#
#    _db_with_lock(
#        CFG  => $cfg,
#        code => sub {
#            #my $dbh = $dbh;
#            _db_maintenance(DBH => $dbh, CFG => $p{CFG}, rotate => 1, purge => 1);
#        }
#    );
#
#
#}

sub acheck_db_admin {
	# EXEMPLE D'APPEL :
	# acheck_db_admin (CFG => $cfg);
	# en mode Auto, un seul traitement quotidien est effectué
	my %p = @_;
	
#	print $p{TEST} . " pour TEST\n";
#	print $p{maxTime} . " pour maxTime\n";
#	print $p{tableau} . " pour tableau\n";
#	print $p{tableau}[2] . " pour tableau[2]\n";

#	my $time =time;
	my $date =strftime "%Y-%m-%d", localtime;
	my ($sth, $sql);
	&logger (4,"ACHECK lookup");
	
	# RECHERCHE DE LA DERNIÈRE ACTION SUR LA TABLE ADMIN
	$sql = "select ed_action_date, ed_action_pid, ed_action_status, ed_action_duration, ed_oedtk_release from edtk_admin " 
			. " where ed_action_date = '"
			. $date
			. "'  "; #order by ed_action_date desc limit 1";
	&logger (7, $sql);

	$p{DBH}	= db_connect($p{CFG}, 'EDTK_DBI_DSN');
	$sth 	= $p{DBH}->prepare($sql) or return (3, $p{DBH}->errstr);
	$sth->execute() or &logger (3, "SQL execute failed ".$sth->err."-".$sth->errstr);

	# EST-CE QU'UNE ACTION D'ADMINISTRATION A ETE EFFECTUEE A DATE ?
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
	# exemple d'appel
	# _acheck_request_for_db (CFG => $cfg, DBH => $dbh);
	my %p = @_;

	my $time =time;
	my $date =strftime "%Y-%m-%d", localtime;
	my $pid  =$$;
	my ($rc, $sth, $sql, $insert, $reportActions);

	# SOLLICITE UN TICKET POUR REALISER LES ACTIONS
	$insert = 'insert into edtk_admin (ed_action_date, ed_action_pid, ed_action_status, ed_oedtk_release) '
			. ' values (?, ?, ?, ?) ';
	$p{DBH} = db_connect($p{CFG}, 'EDTK_DBI_DSN');
	$sth 	= $p{DBH}->prepare_cached($insert);

	eval {
		$sth->execute($date, $pid, "START", $VERSION) or &logger (3, "SQL execute failed ".$sth->err."-".$sth->errstr);
	};
	if ($@) {
		warn "ERROR: $@ into $insert\n";
	}

	# CONTROLE QU'ON A BIEN LA MAIN POUR L'ACTION
	# RECHERCHE DE LA DERNIÈRE ACTION SUR LA TABLE ADMIN
	$sql = "select ed_action_date, ed_action_pid, ed_action_status, ed_action_duration, ed_oedtk_release from edtk_admin " 
			. " where ed_action_date = '"
			. $date
			. "'  "; #order by ed_action_date desc limit 1";
	&logger (7, $sql);

	$sth = $p{DBH}->prepare($sql);
	$sth->execute() or &logger (3, "SQL execute failed ".$sth->err."-".$sth->errstr);
	my @tValues = $p{DBH}->selectrow_array($sql, undef) or warn ("ERROR: in acheck_db_admin_on_connect, message is " . $p{DBH}->errstr);
	$reportActions = "ACHECK Check 1 : ". $tValues[0] ." PID ". $tValues[1];
	$rc = $sth->finish;
	$p{DBH}->disconnect;

	if ($date eq $tValues[0] and $pid eq $tValues[1]){
		&logger (5, $reportActions);
		$reportActions .=_acheck_db_rotate(CFG => $p{CFG});
		$reportActions .=_acheck_db_purges(CFG => $p{CFG});
		
#			use Parallel::Async;
#			# create new task
#			my $task = async {
#				_acheck_db_purges(CFG => $p{CFG}); # fork en tâche de fond
#			};
#			my $pid = $task->run();

#			my $can_use_threads = eval 'use threads; 1';
#			if ($can_use_threads) {
#				# Do processing using threads
#				$|=1; # forces a flush after every write or print
#				my $thr = threads->create(\&_acheck_db_purges, CFG => $p{CFG});
#				$thr->detach();
#
#			} else {
#				# Do it without using threads
#				# _acheck_db_purges(CFG => $p{CFG});
#			}



	} else {
		# un autre process a pris l'action, abandon
		&logger(6, "failed, process locked");
		return (5, $reportActions);
	}


	# Fin du traitement
	$time=time-$time;
	$sql = 'update edtk_admin set ed_action_status = ?, ed_action_duration = ? where ed_action_date = ?';
	&logger (7, $sql);

	$p{DBH} = db_connect($p{CFG}, 'EDTK_DBI_DSN');
	$p{DBH}->do($sql, undef, "DONE", $time, $date) or warn "ERROR: can't update ED_ACTION_STATUS";	

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


	### PURGES STATS ###
	# PURGE FROM OEDTK_ADMIN
	$sql = "delete from edtk_admin where ed_action_date < '" 
			. (strftime "%Y-%m-%d", localtime($DAYS_TRACKED_time))."'";
	&logger (7, $sql);

	$p{DBH} = db_connect($p{CFG}, 'EDTK_DBI_DSN');
	$result = $p{DBH}->do($sql, undef ) or return warn "ERROR: can't update edtk_admin";	
	$p{DBH}->disconnect;
	&logger (6,"RESULT = " . ($result || 0) ." for $sql");
	$reportActions = "ACHECK PURGE edtk_admin=" . ($result || 0);

	# PURGE FROM EDTK_DBI_TRACKING
	$sql = "delete from " 
			. $p{CFG}->{'EDTK_DBI_TRACKING'} 
			. " where ed_tstamp < '" . (strftime "%Y%m%d", localtime($DAYS_TRACKED_time)) . "000000'";
	&logger (7, $sql);

	$p{DBH} = db_connect($p{CFG}, 'EDTK_DBI_DSN');
	$result = $p{DBH}->do($sql, undef ) or return print STDERR "ERROR: can't update ". $p{CFG}->{'EDTK_DBI_TRACKING'};	
	$p{DBH}->disconnect;
	&logger (6,"RESULT = " . ($result || 0) ." for $sql");
	$reportActions .= "-PURGE TRACKING=" . ($result || 0);

	# PURGE FROM EDTK_DBI_DISTRIB_STATS 
	$sql = "delete from " 
			. $p{CFG}->{'EDTK_DBI_DISTRIB_STATS'}
			. " where ed_dtlot < '" . (strftime "%Y-%m-%d", localtime($DAYS_KEPT_STATS_time)) ."'"; # or not REGEXP_LIKE (ED_DTLOT, '\d\d\d\d-\d\d-\d\d') ne fonctionne pas sur MySQL...
	&logger (7, $sql);

	$p{DBH} = db_connect($p{CFG}, 'EDTK_DBI_DSN');
	$result = $p{DBH}->do($sql, undef ) or return warn "ERROR: can't update ". $p{CFG}->{'EDTK_DBI_DISTRIB_STATS'};	
	$p{DBH}->disconnect;
	&logger (6,"RESULT = " . ($result || 0) ." for $sql");
	$reportActions .= "-PURGE DISTRIB_S=" . ($result || 0);

	# PURGE FROM OUTMNGR_STATS 
	$sql = "delete from " 
			. $p{CFG}->{'EDTK_DBI_OUTMNGR_STATS'}
			. " where ed_dtlot < '" . (strftime "%Y-%m-%d", localtime($DAYS_KEPT_STATS_time)) ."'";
	&logger (7, $sql);

	$p{DBH} = db_connect($p{CFG}, 'EDTK_DBI_DSN');
	$result = $p{DBH}->do($sql, undef ) or return warn "ERROR: can't update ". $p{CFG}->{'EDTK_DBI_OUTMNGR_STATS'};	
	$p{DBH}->disconnect;
	&logger (6,"RESULT = " . ($result || 0) ." for $sql");
	$reportActions .= "-PURGE OUTMNGR_S=" . ($result || 0);

	# PURGE FROM EDTK_AGREGE
	$sql = "delete from edtk_agrege " 
			. " where ed_dtlot < '" . (strftime "%Y-%m-%d", localtime($DAYS_AGREGED_time)) ."'";
	&logger (7, $sql);

	$p{DBH} = db_connect($p{CFG}, 'EDTK_DBI_DSN');
	$result = $p{DBH}->do($sql, undef ) or return warn "ERROR: can't update EDTK_AGREGE";	
	$p{DBH}->disconnect;
	&logger (6,"RESULT = " . ($result || 0) ." for $sql");
	$reportActions .= "-PURGE AGREGE=" . ($result || 0);

	
	### EDTK_ID ###
	# PURGE FROM EDTK_ID 
	$sql = "delete from edtk_id"
			. " where ed_id_date < '" . (strftime "%Y-%m-%d", localtime($DAYS_TRACKED_time)) ."'";
	&logger (7, $sql);

	$p{DBH} = db_connect($p{CFG}, 'EDTK_DBI_DSN');
	$result = $p{DBH}->do($sql, undef ) or warn "ERROR: can't update ". $p{CFG}->{'EDTK_DBI_OUTMNGR_STATS'};	
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
	my $stamp =strftime "%Y%m%d%H%M%S", localtime;

	my $DAYS_KEPT_time			= time - (86400*$p{CFG}->{EDTK_DB_MAX_DAYS_KEPT});
	my $DAYS_KEPT_STATS_time	= time - (86400*$p{CFG}->{EDTK_DB_MAX_DAYS_KEPT_STATS});
	my $DAYS_TRACKED_time		= time - (86400*$p{CFG}->{EDTK_DB_MAX_DAYS_TRACKED});
	my $DAYS_AGREGED_time		= time - (86400*($p{CFG}->{EDTK_DB_MAX_DAYS_AGREGED} || $p{CFG}->{EDTK_DB_MAX_DAYS_TRACKED}));

	### ROTATIONS ###
	### EDTK_AGREGE ### 
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

	$result = $p{DBH}->do($sql, undef ) or die "ERROR: can't update EDTK_AGREGE";	
	&logger (6,"RESULT = " . ($result || 0) ." for $sql");
	$reportActions .= "-MV AGREGE=" . ($result || 0);

#INSERT INTO [table_destination](https://www.google.com/search?q=table_destination) (colonne1, colonne2, colonne_supplementaire)
#SELECT colonne1, colonne2, valeur_par_defaut
#FROM [table_source](https://www.google.com/search?q=table_source);

	### DISTRIB ###
	# MOVE DATA FROM DISTRIB TO DISTRIB_STATS
	$sql = "insert into " 
			. $p{CFG}->{'EDTK_DBI_DISTRIB_STATS'}
			. " select * from "
			. $p{CFG}->{'EDTK_DBI_DISTRIB'}
			. " where ed_dtlot < '" . (strftime "%Y-%m-%d", localtime($DAYS_KEPT_time)) ."'";
	&logger (7, $sql);

	$result = $p{DBH}->do($sql, undef ) or return warn "ERROR: can't update ". $p{CFG}->{'EDTK_DBI_DISTRIB_STATS'};	
	&logger (6,"RESULT = " . ($result || 0) ." for $sql");
	$reportActions .= "-MV DISTRIB=" . ($result || 0);

		# CLEAN DISTRIB 
		$sql = "delete from " 
				. $p{CFG}->{'EDTK_DBI_DISTRIB'}
				. " where ed_dtlot < '" . (strftime "%Y-%m-%d", localtime($DAYS_KEPT_time)) ."'";
		&logger (7, $sql);

		$result = $p{DBH}->do($sql, undef ) or warn "ERROR: can't update ". $p{CFG}->{'EDTK_DBI_DISTRIB_STATS'};	
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

	$result = $p{DBH}->do($sql, undef ) or warn "ERROR: can't update ". $p{CFG}->{'EDTK_DBI_OUTMNGR_STATS'};	
	&logger (6,"RESULT = " . ($result || 0) ." for $sql");
	$reportActions .= "-MV OUTMNGR=" . ($result || 0);

		# CLEAN OUTMNGR 
		$sql = "delete from " 
				. $p{CFG}->{'EDTK_DBI_OUTMNGR'}
				. " where ed_dtlot < '" . (strftime "%Y-%m-%d", localtime($DAYS_KEPT_time)) ."'";
		&logger (7, $sql);

		$result = $p{DBH}->do($sql, undef ) or warn "ERROR: can't update ". $p{CFG}->{'EDTK_DBI_OUTMNGR_STATS'};	
		&logger (6,"RESULT = " . ($result || 0) ." for $sql");
		$reportActions .= "/" . ($result || 0);

	$p{DBH}->disconnect;
	return (4, $reportActions);
}	



sub agrege_idJob {
	# EXEMPLE D'APPEL :
	# agrege_idJob (CFG => $cfg, IDJOB => 'IdJob');
	my %p = @_;
	my $stamp =strftime "%Y%m%d%H%M%S", localtime;
	&logger (6,"p{CFG} = " . $p{CFG} . " - p{IDJOB} " . $p{IDJOB} );

	my ($sql, $insert, $result, $reportActions);
	$p{DBH} = db_connect($p{CFG}, 'EDTK_DBI_DSN');

	### ROTATIONS JobID ###
	### EDTK_AGREGE ### 
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

	$result = $p{DBH}->do($sql, undef ) or die "ERROR: can't update edtk_agrege";	
	&logger (6,"RESULT = " . ($result || 0) ." for $sql");
	$reportActions .= "-MV AGREGE=" . ($result || 0);


	### DISTRIB ###
	# MOVE DATA FROM DISTRIB TO DISTRIB_STATS
	$sql = "insert into " 
			. $p{CFG}->{'EDTK_DBI_DISTRIB_STATS'}
			. " select * from "
			. $p{CFG}->{'EDTK_DBI_DISTRIB'}
			. " where ed_idjob = '" . $p{IDJOB} ."'";
	&logger (7, $sql);

	$result = $p{DBH}->do($sql, undef ) or return warn "ERROR: can't update ". $p{CFG}->{'EDTK_DBI_DISTRIB_STATS'};	
	&logger (6,"RESULT = " . ($result || 0) ." for $sql");
	$reportActions .= "-MV DISTRIB=" . ($result || 0);

		# CLEAN DISTRIB 
		$sql = "delete from " 
				. $p{CFG}->{'EDTK_DBI_DISTRIB'}
			. " where ed_idjob = '" . $p{IDJOB} ."'";
		&logger (7, $sql);

		$result = $p{DBH}->do($sql, undef ) or warn "ERROR: can't update ". $p{CFG}->{'EDTK_DBI_DISTRIB_STATS'};	
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

	$result = $p{DBH}->do($sql, undef ) or warn "ERROR: can't update ". $p{CFG}->{'EDTK_DBI_OUTMNGR_STATS'};	
	&logger (6,"RESULT = " . ($result || 0) ." for $sql");
	$reportActions .= "-MV OUTMNGR=" . ($result || 0);

		# CLEAN OUTMNGR 
		$sql = "delete from " 
				. $p{CFG}->{'EDTK_DBI_OUTMNGR'}
			. " where ed_idjob = '" . $p{IDJOB} ."'";
		&logger (7, $sql);

		$result = $p{DBH}->do($sql, undef ) or warn "ERROR: can't update ". $p{CFG}->{'EDTK_DBI_OUTMNGR_STATS'};	
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
	#my $EDTK_DB_CHECK_MONTH_DAY = $cfg->{EDTK_DB_CHECK_MONTH_DAY} || 0; # à supprimer

	&logger (4,"ACHECK Check START");
	
	#RECHERCHE DE LA DERNIÈRE ACTION SUR LA TABLE ADMIN
	$sql = "select ed_action_date, ed_action_pid, ed_action_status, ed_action_duration, ed_oedtk_release from edtk_admin " 
			. " where ed_action_date = '"
			. $date
			. "'  "; #order by ed_action_date desc limit 1";
	&logger (7, $sql);
	
	#eval {

		$sth = $dbh->prepare($sql) or return (3, $dbh->errstr);
	#};
	#if ($@) {
	#	warn "ERROR: $@ into $sql\n";
	#	return 0;
	#}
	$sth->execute() or &logger (3, "SQL execute failed ".$sth->err."-".$sth->errstr);

	# EST-CE QU'UNE ACTION D'ADMINISTRATION A ETE EFFECTUEE AUJOURD'HUI ?
	my @tValues = $dbh->selectrow_array($sql, undef);# or warn ("ERROR: in acheck_db_admin_on_connect, message is " . $dbh->errstr);
	if ($tValues[0] and $date eq $tValues[0]){
		&logger(6, ("Previously done, ACHECK Last EDTK_DB_MAX_DAYS check : ". $tValues[0] ." PID ". $tValues[1]));
		return (5, ("ACHECK Last EDTK_DB_MAX_DAYS check : ". $tValues[0] ." PID ". $tValues[1]));
	}


	# SINON, SOLLICITE UN TICKET POUR REALISER L'ACTION
	$insert = 'insert into edtk_admin (ed_action_date, ed_action_pid, ed_action_status, ed_oedtk_release) '
		. ' values (?, ?, ?, ?) ';
	$sth = $dbh->prepare_cached($insert);

	eval {
		$sth->execute($date, $pid, "START", $VERSION) or &logger (3, "SQL execute failed ".$sth->err."-".$sth->errstr);
	};
	if ($@) {
		warn "ERROR: $@ into $insert\n";
	}


	# CONTROLE QU'ON A BIEN LA MAIN POUR L'ACTION
	$sth = $dbh->prepare($sql);
	$sth->execute() or &logger (3, "SQL execute failed ".$sth->err."-".$sth->errstr);
	@tValues = $dbh->selectrow_array($sql, undef) or warn ("ERROR: in acheck_db_admin_on_connect, message is " . $dbh->errstr);
	$reportActions = "ACHECK Check 2 : ". $tValues[0] ." PID ". $tValues[1];

	if ($date eq $tValues[0] and $pid eq $tValues[1]){
		&logger (5, $reportActions);
		# _db_admin_actions;
	} else {
		# un autre process a fait l'action, abandon
		return (5, $reportActions);
	}


	### PURGES ###
	# PURGE FROM OEDTK_ADMIN
	$sql = "delete from edtk_admin where ed_action_date < '" 
			. (strftime "%Y-%m-%d", localtime($DAYS_TRACKED_time))."'";
	&logger (7, $sql);

	$result = $dbh->do($sql, undef ) or return warn "ERROR: can't update EDTK_ADMIN";	
	&logger (6,"RESULT = " . ($result // 0) ." for $sql");
	$reportActions = "ACHECK PURGE edtk_admin=" . ($result // 0);

	# PURGE FROM EDTK_DBI_TRACKING
	$sql = "delete from " . $cfg->{'EDTK_DBI_TRACKING'} 
			. " where ed_tstamp < '" . (strftime "%Y%m%d", localtime($DAYS_TRACKED_time)) . "000000'";
	&logger (7, $sql);

	$result = $dbh->do($sql, undef ) or return print STDERR "ERROR: can't update ". $cfg->{'EDTK_DBI_TRACKING'};	
	&logger (6,"RESULT = " . ($result // 0) ." for $sql");
	$reportActions .= "-PURGE tracking=" . ($result // 0);

	# PURGE FROM EDTK_DBI_DISTRIB_STATS 
	$sql = "delete from " 
			. $cfg->{'EDTK_DBI_DISTRIB_STATS'}
			. " where ed_dtlot < '" . (strftime "%Y-%m-%d", localtime($DAYS_KEPT_STATS_time)) ."'"; # or not REGEXP_LIKE (ED_DTLOT, '\d\d\d\d-\d\d-\d\d') ne fonctionne pas sur MySQL...
	&logger (7, $sql);

	$result = $dbh->do($sql, undef ) or return warn "ERROR: can't update ". $cfg->{'EDTK_DBI_DISTRIB_STATS'};	
	&logger (6,"RESULT = " . ($result // 0) ." for $sql");
	$reportActions .= "-PURGE distrib_s=" . ($result // 0);

	# PURGE FROM OUTMNGR_STATS 
	$sql = "delete from " 
			. $cfg->{'EDTK_DBI_OUTMNGR_STATS'}
			. " where ed_dtlot < '" . (strftime "%Y-%m-%d", localtime($DAYS_KEPT_STATS_time)) ."'";
	&logger (7, $sql);

	$result = $dbh->do($sql, undef ) or return warn "ERROR: can't update ". $cfg->{'EDTK_DBI_OUTMNGR_STATS'};	
	&logger (6,"RESULT = " . ($result // 0) ." for $sql");
	$reportActions .= "-PURGE outmngr_s=" . ($result // 0);

	# PURGE FROM EDTK_AGREGE
	$sql = "delete from edtk_agrege " 
			. " where ed_dtlot < '" . (strftime "%Y-%m-%d", localtime($DAYS_AGREGED_time)) ."'";
	&logger (7, $sql);

	$result = $dbh->do($sql, undef ) or return warn "ERROR: can't update EDTK_AGREGE";	
	&logger (6,"RESULT = " . ($result // 0) ." for $sql");
	$reportActions .= "-PURGE agrege=" . ($result // 0);
	my $stamp =strftime "%Y%m%d%H%M%S", localtime;

	### MOVE / PURGE ###
		### EDTK_AGREGE ### 
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

		$result = $dbh->do($sql, undef ) or die "ERROR: can't update EDTK_AGREGE";	
		&logger (6,"RESULT = " . ($result // 0) ." for $sql");
		$reportActions .= "-MV agrege=" . ($result // 0);


		### DISTRIB ###
		# MOVE DATA FROM DISTRIB TO DISTRIB_STATS
		$sql = "insert into " 
				. $cfg->{'EDTK_DBI_DISTRIB_STATS'}
				. " select * from "
				. $cfg->{'EDTK_DBI_DISTRIB'}
				. " where ed_dtlot < '" . (strftime "%Y-%m-%d", localtime($DAYS_KEPT_time)) ."'";
		&logger (7, $sql);

		$result = $dbh->do($sql, undef ) or return warn "ERROR: can't update ". $cfg->{'EDTK_DBI_DISTRIB_STATS'};	
		&logger (6,"RESULT = " . ($result // 0) ." for $sql");
		$reportActions .= "-MV distrib=" . ($result // 0);

		# CLEAN DISTRIB 
		$sql = "delete from " 
				. $cfg->{'EDTK_DBI_DISTRIB'}
				. " where ed_dtlot < '" . (strftime "%Y-%m-%d", localtime($DAYS_KEPT_time)) ."'";
		&logger (7, $sql);

		$result = $dbh->do($sql, undef ) or warn "ERROR: can't update ". $cfg->{'EDTK_DBI_DISTRIB_STATS'};	
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

		$result = $dbh->do($sql, undef ) or warn "ERROR: can't update ". $cfg->{'EDTK_DBI_OUTMNGR_STATS'};	
		&logger (6,"RESULT = " . ($result // 0) ." for $sql");
		$reportActions .= "-MV outmngr=" . ($result // 0);

		# CLEAN OUTMNGR 
		$sql = "delete from " 
				. $cfg->{'EDTK_DBI_OUTMNGR'}
				. " where ed_dtlot < '" . (strftime "%Y-%m-%d", localtime($DAYS_KEPT_time)) ."'";
		&logger (7, $sql);

		$result = $dbh->do($sql, undef ) or warn "ERROR: can't update ". $cfg->{'EDTK_DBI_OUTMNGR_STATS'};	
		&logger (6,"RESULT = " . ($result // 0) ." for $sql");
		$reportActions .= "/" . ($result // 0);


		### EDTK_ID ###
		# PURGE FROM EDTK_ID 
		$sql = "delete from edtk_id"
				. " where ed_id_date < '" . (strftime "%Y-%m-%d", localtime($DAYS_TRACKED_time)) ."'";
		&logger (7, $sql);

		$result = $dbh->do($sql, undef ) or warn "ERROR: can't update ". $cfg->{'EDTK_DBI_OUTMNGR_STATS'};	
		&logger (6,"RESULT = " . ($result // 0) ." for $sql");
		$reportActions .= "-PURGE edtk_id=" . ($result // 0);



	# Fin du traitement
	$time=time-$time;
	$sql = 'update edtk_admin set ed_action_status = ?, ed_action_duration = ? where ed_action_date = ?';
	$dbh->do($sql, undef, "DONE", $time, $date) or warn "ERROR: can't update ED_ACTION_STATUS";	

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
	['ed_mod_ed',	'char'],					# editing mode (undef, batch, tp, web, mail, probing)
	['ed_job_evt',	'char'],					# level of the event (job (default), spool, document, line, warning, error, halt (critic), reject)
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
	$sql .= " ENGINE=MyISAM " if (_db_check_driver_name($dbh) eq "mysql");
	&logger (7, $sql);
	$dbh->do(_sql_fixup($dbh, $sql, 'casse')) or &logger (4, $dbh->errstr);
	my $idx = "ix_".$table."_".$VERSION_TXT;
	$sql = "create index if not exists $idx on $table "
			." (ed_tstamp);";
	&logger (7, $sql);
	$dbh->do(_sql_fixup($dbh, $sql, 'casse')) or &logger (4, $dbh->errstr ) if (_db_check_driver_name($dbh) ne "SQLite");
	
}


sub db_drop_table {
	my ($dbh, $table) = @_;
	my $sql = "drop table $table";

	$dbh->do(_sql_fixup($dbh, $sql, 'casse')) or &logger (4, $dbh->errstr);
}


sub historicize_table ($$$){
	my ($dbh, $table, $suffixe) = @_;
	my $table_cible =$table."_".$suffixe;
		
	copy_table ($dbh, $table, $table_cible, '-create');	

	my $sql = "truncate table $table"; # DEVIENT UN 'MOVE'
	&logger (7, $sql);

	$dbh->do(_sql_fixup($dbh, $sql, 'casse'), undef) or die &logger (-1, $dbh->errstr);	
}


## TODO ADMIN
# => creer les tables qui n'existent pas ou les completer si besoin
# => attention les optimize peuvent etre tres longs
# Les variables  a ajouter :


# OPERATIONS ADMIN POSSIBLES ?
# - Historiser
# - Verifier que la structure de la base est conforme à la version / avertir => prposer une fonction de reconstruction ?
# - reversement des données de filedb backup dans base centrale
# - Clean base / Optimize ?????
# - Innodb / MyIsam ???


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
	$sql .= " engine=MyISAM " if (_db_check_driver_name($dbh) eq "mysql");
	&logger (7, $sql);

	$dbh->do(_sql_fixup($dbh, $sql, 'casse')) or &logger (4, $dbh->errstr);
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
	$sql .= " engine=MyISAM " if (_db_check_driver_name($dbh) eq "mysql");

	&logger (7, $sql);

	$dbh->do(_sql_fixup($dbh, $sql, 'casse')) or &logger (4, $dbh->errstr);
	my $idx = "ix_".$table."_".$VERSION_TXT;
	$sql = "create index if not exists $idx on $table (ed_id_date);";
	&logger (7, $sql);
	$dbh->do(_sql_fixup($dbh, $sql, 'casse')) or &logger (4, $dbh->errstr );

}



sub create_table_FILIERES {
	my $dbh = shift;
	my $table = "edtk_filieres";

	my $sql = "create table if not exists $table ";
	$sql .= "( ed_idfiliere varchar2(5) unique";	# 
	$sql .= ", ed_priorite integer unique";			# 
	$sql .= ", ed_idmanufact varchar2(16)";	  
	$sql .= ", ed_designation varchar2(64)";		# 
	$sql .= ", ed_actif char not null";				# flag indiquant si la filiere est active ou pas 
	$sql .= ", ed_typed char not null";				# 
	$sql .= ", ed_modedi char not null";			# 
	$sql .= ", ed_idgplot varchar2(16) not null";	# 
	$sql .= ", ed_nbbacprn integer not null";		# 
	$sql .= ", ed_nbencmax integer";
	$sql .= ", ed_minfeuil_l integer"; 
	$sql .= ", ed_maxfeuil_l integer"; 
	$sql .= ", ed_feuilpli integer";
	$sql .= ", ed_minplis integer";
	$sql .= ", ed_maxplis integer not null";
	$sql .= ", ed_poids_pli integer";				# poids maximum du pli dans la filiere
	$sql .= ", ed_ref_env varchar2(8) not null";
	$sql .= ", ed_formflux varchar2(3) not null";
	$sql .= ", ed_sort varchar2(128) not null";
	$sql .= ", ed_direction varchar2(4) not null";
	$sql .= ", ed_postcomp varchar2(8) not null";
	$sql .= ", primary key (ed_idfiliere, ed_priorite)";
	$sql .= " )";
	$sql .= " engine=MyISAM " if (_db_check_driver_name($dbh) eq "mysql");
	&logger (7, $sql);

	$dbh->do(_sql_fixup($dbh, $sql, 'casse')) or &logger (4, $dbh->errstr);
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
	$sql .= " engine=MyISAM " if (_db_check_driver_name($dbh) eq "mysql");
	&logger (7, $sql);

	$dbh->do(_sql_fixup($dbh, $sql, 'casse')) or &logger (4, $dbh->errstr);
}


sub create_table_REFIDDOC {
	my $dbh = shift;
	my $table = "edtk_refiddoc";

	my $sql = "create table if not exists $table ";
	$sql .= "( ed_refiddoc varchar2(20) unique"; 
	$sql .= ", ed_corp varchar2(8) not null";		# entity related to the document
	$sql .= ", ed_catdoc char not null";  
	$sql .= ", ed_portadr char not null";  
	$sql .= ", ed_massmail char not null";
	$sql .= ", ed_edocshare char not null";  
	$sql .= ", ed_typed char not null";  
	$sql .= ", ed_modedi char not null";  
	$sql .= ", ed_pgorien varchar2(2)";
	$sql .= ", ed_formatp varchar2(2)"; 
	$sql .= ", ed_refimp_p1 varchar2(16)"; 
	$sql .= ", ed_refimp_ps varchar2(16)"; 
	$sql .= ", ed_refimp_refiddoc varchar2(64)"; 
	$sql .= ", ed_mail_referent varchar2(300)";		# referent mail for doc validation
	$sql .= ", primary key (ed_refiddoc, ed_corp, ed_catdoc)";
	$sql .= " )";
	$sql .= " engine=MyISAM " if (_db_check_driver_name($dbh) eq "mysql");
	&logger (7, $sql);

	$dbh->do(_sql_fixup($dbh, $sql, 'casse')) or &logger (4, $dbh->errstr);
}


sub create_table_SUPPORTS {
	my $dbh = shift;
	my $table = "edtk_supports";

	my $sql = "create table if not exists $table ";
	$sql .= "( ed_refimp varchar2(16) unique";	# 
	$sql .= ", ed_typimp char not null";  
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
	$sql .= " engine=MyISAM " if (_db_check_driver_name($dbh) eq "mysql");
	&logger (7, $sql);

	$dbh->do(_sql_fixup($dbh, $sql, 'casse')) or &logger (4, $dbh->errstr);
}


our @DISTRIB_COLS = (
	['ed_idldoc',	'varchar2(25) not null'],# identifiant du document dans le lot de mise en page ed_sngl_id porté à 25
	['ed_idseqpg',	'integer not null'],	 # numéro de séquence de page [doc] dans le lot de mise en page
	['ed_seqdoc',	'integer not null'],	 # numéro de séquence du document dans le lot
	['ed_idjob',	'varchar2(25) not null'],# identifiant du job

	['ed_idlot',	'varchar2(8)'],			# identifiant du lot
	['ed_seqlot',	'varchar2(7)'],			# identifiant du lot de mise sous plis (sous-lot)
	['ed_dtlot',	'varchar2(10)'],		# date de la création du lot de mise sous plis
	['ed_idfiliere','varchar2(5)'],			# identifiant de la filière de production
	['ed_seqpgdoc',	'integer'],				# numéro de séquence de page dans le document
	['ed_nbpgdoc',	'integer'],				# nombre de page (faces) du document

	# add
	['ed_workflow', 'varchar2(32)'],		# workflow sur lequel on a produit les metadonnées	++ new ++
	['ed_chanel_out','varchar2(32)'],		# canal de distribution/output						++ new ++
	
	['ed_idged', 	'varchar2(25)']

);


sub create_table_DISTRIB {
	my ($dbh, $table) = @_;

	my $sql = "create table if not exists $table ("
			. join(', ', map {"$$_[0] $$_[1]"} @DISTRIB_COLS) 
#			. ", primary key (ed_idldoc, ed_seqdoc, ed_idseqpg, ed_idjob, ed_chanel_out)" 	
			. " )";
	$sql .= " engine=MyISAM " if (_db_check_driver_name($dbh) eq "mysql");
	&logger (7, $sql);

	$dbh->do(_sql_fixup($dbh, $sql, 'casse')) or &logger (4, $dbh->errstr);
	my $idx = "ix_".$table."_".$VERSION_TXT;
	$sql = "create index if not exists $idx on $table "
			." (ed_idldoc, ed_seqdoc, ed_idseqpg, ed_idjob, ed_chanel_out, ed_dtlot);";
	&logger (7, $sql);
	$dbh->do(_sql_fixup($dbh, $sql, 'casse')) or &logger (4, $dbh->errstr );

}
# SHOW CREATE TABLE tablename


our @AGREGE_COLS = (
	['ed_source',	'varchar2(128)'],				# input stream of this document
	['ed_chanel_out','varchar2(32)'],				# canal de distribution/output						
	['ed_refiddoc',	'varchar2(25) not null'],		# identifiant dans le référentiel de document
	['ed_idproduct','varchar2(8)'],					# identifiant de produit							
	['ed_dtedtion',	'varchar2(8) not null'],		# date d'édition, celle qui figure sur le document
	['ed_cntd_idldoc',	'integer not null'],		# count distinct des identifiants de documents
	['ed_cnt_idseqpg',	'integer not null'],	 	# count séquence de page [doc] dans le lot de mise en page
	['ed_dtlot',	'varchar2(10)'],				# date de la création du lot de mise sous plis
	['ed_idlot',	'varchar2(8)'],					# identifiant de lot
	['ed_idjob',	'varchar2(25) not null'],		# identifiant du job
	['ed_tstamp',	'varchar2(14) not null']		# timestamp of event # voir comment upgrade va gerer les diferences de nb de champs

);


sub create_table_AGREGE {
	my ($dbh) = @_;
	my $table = "edtk_agrege";

	my $sql = "create table if not exists $table ("
			. join(', ', map {"$$_[0] $$_[1]"} @AGREGE_COLS) 
#			. ", primary key (ed_source, ed_chanel_out, ed_refiddoc, ed_idproduct, ed_dtedtion, ed_dtlot, ed_idlot, ed_idjob)"
			. " )";
	$sql .= " engine=MyISAM " if (_db_check_driver_name($dbh) eq "mysql");
	&logger (7, $sql);

	$dbh->do(_sql_fixup($dbh, $sql, 'casse')) or &logger (4, $dbh->errstr );
	my $idx = "ix_".$table."_".$VERSION_TXT;
	$sql = "create index if not exists $idx on $table "
			." (ed_source, ed_chanel_out, ed_refiddoc, ed_idproduct, ed_dtedtion, ed_dtlot, ed_idlot);";
#	$sql = "create index `ix_ed_agrege` on $table (ed_source, ed_chanel_out, ed_refiddoc, ed_idproduct, ed_dtedtion, ed_dtlot);";
	&logger (7, $sql);
	$dbh->do(_sql_fixup($dbh, $sql, 'casse')) or &logger (4, $dbh->errstr );

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
	$sql .= " engine=MyISAM " if (_db_check_driver_name($dbh) eq "mysql");
	&logger (7, $sql);

	$dbh->do(_sql_fixup($dbh, $sql, 'casse')) or &logger (4, $dbh->errstr);
}


sub create_table_DATAGROUPS {
	my $dbh = shift;
	my $table = "edtk_test_datagroups";

	my $sql = "create table if not exists $table ";
	$sql .= "( ed_dgps_refiddoc varchar2(20) not null"; 
	$sql .= ", ed_id   integer not null";
	$sql .= ", ed_data varchar2(64)";
	$sql .= " )";
	$sql .= " engine=MyISAM " if (_db_check_driver_name($dbh) eq "mysql");

	&logger (7, $sql);

	$dbh->do(_sql_fixup($dbh, $sql, 'casse')) or die &logger (-1, $dbh->errstr);
	my $idx = "ix_".$table."_".$VERSION_TXT;
	$sql = "create index if not exists $idx on $table "
			." (ed_dgps_refiddoc, ed_id);";
	&logger (7, $sql);
	$dbh->do(_sql_fixup($dbh, $sql, 'casse')) or &logger (4, $dbh->errstr );

}


sub create_table_ACQUIT {
	my $dbh = shift;
	my $table = "edtk_acq";

	my $sql = "create table if not exists $table ";
	$sql .= "( ed_seqlot  varchar2(7)  not null";	# identifiant du lot de mise sous plis (sous-lot) update edtk_acq set ed_seqlot = substr('1'|| ed_seqlot,-7);
	$sql .= ", ed_lotname varchar2(16) not null";	# 
	$sql .= ", ed_dtpost  varchar2(8)  not null";	# date de remise en poste
	$sql .= ", ed_dtprint varchar2(8)";				# date de d'impression
	$sql .= ", ed_nbfaces integer   	not null";	# nombre de faces du lot (faces comptables, comprenant les faces blanches de r°/v°)
	$sql .= ", ed_nbplis  integer 		not null";	# nombre de documents du pli
	$sql .= ", ed_dtpost2 varchar2(8)";				# date de remise en poste		
	$sql .= ", ed_dtcheck varchar2(8)";				# date de check
	$sql .= ", ed_status  varchar2(4)";				# check status
	$sql .= ", primary key (ed_seqlot, ed_lotname, ed_dtpost)";
	$sql .= " )";
	$sql .= " engine=MyISAM " if (_db_check_driver_name($dbh) eq "mysql");

	&logger (7, $sql);

	$dbh->do(_sql_fixup($dbh, $sql, 'casse')) or &logger (4, $dbh->errstr);
}


our @INDEX_COLS = (
#	NB : " primary key (ed_idldoc, ed_seqdoc, ed_idseqpg, ed_idjob)"

	# SECTION COMPOSITION DE L'INDEX
	['ed_refiddoc',	'varchar2(25) not null'],# identifiant dans le référentiel de document
	['ed_idldoc',	'varchar2(25) not null'],# identifiant du document dans le lot de mise en page ed_sngl_id porté à 25
	['ed_idseqpg',	'integer not null'],	 # numéro de séquence de page [doc] dans le lot de mise en page
	['ed_seqdoc',	'integer not null'],	 # numéro de séquence du document dans le lot
	['ed_idjob',	'varchar2(25) not null'],# Identifiant du Job 

	# SECTION DOCUMENT
	['ed_dtedtion',	'varchar2(8) not null'],# date d'édition, celle qui figure sur le document
	['ed_cpdest',	'varchar2(10)'],		# code postal destinataire
	['ed_villdest',	'varchar2(38)'],		# ville destinataire
	['ed_iddest',	'varchar2(25)'],		# identifiant du destinataire dans le système de gestion
	['ed_nomdest',	'varchar2(38)'],		# nom destinataire
	['ed_idemet',	'varchar2(10)'],		# identifiant de l'émetteur
	['ed_typprod',	'varchar(16)'],			# type de production associée au lot 
	['ed_portadr',	'char'],				# indicateur de document porte adresse
	['ed_adrln1',	'varchar2(38)'],		# ligne d'adresse 1
	['ed_cleged1',	'varchar2(32)'],		# clef pour système d'archivage
	['ed_adrln2',	'varchar2(38)'],		# ligne d'adresse 2
	['ed_cleged2',	'varchar2(20)'],		# clef pour système d'archivage
	['ed_adrln3',	'varchar2(38)'],		# ligne d'adresse 3
	['ed_cleged3',	'varchar2(20)'],		# clef pour système d'archivage
	['ed_adrln4',	'varchar2(38)'],		# ligne d'adresse 4
	['ed_cleged4',	'varchar2(20)'],		# clef pour système d'archivage
	['ed_adrln5',	'varchar2(38)'],		# ligne d'adresse 5
	['ed_corp',		'varchar2(8) not null'],# entité émettrice de la page
	['ed_doclib',	'varchar2(32)'],		# merge library compuset associée ? la page
	['ed_refimp',	'varchar2(16)'],		# référence de pré-imprimé ou d'imprimé ou d'encart
	['ed_adrln6',	'varchar2(38)'],		# ligne d'adresse 6
	['ed_source',	'varchar2(8) not null'],# source de l'index ou entité de ed_corp
	['ed_owner',	'varchar2(10)'],		# propriétaire du document (utilisation en gestion / archivage de documents)
	['ed_host',		'varchar2(32)'],		# hostname de la machine d'origine de cette entrée
	['ed_ididx',	'varchar2(8) '],		# identifiant de l'index
	['ed_catdoc',	'char'],				# catégorie de document
	['ed_codrupt',	'varchar2(8)'],			# code forçage de rupture

	# SECTION LOTISSEMENT DE L'INDEX 
	['ed_idlot',	'varchar2(8)'],			# identifiant du lot
	['ed_seqlot',	'varchar2(7)'],			# identifiant du lot de mise sous plis (sous-lot)
	['ed_dtlot',	'varchar2(10)'],		# date de la création du lot de mise sous plis
	['ed_idfiliere','varchar2(5)'],			# identifiant de la filière de production
	['ed_seqpgdoc',	'integer'],				# numéro de séquence de page dans le document
	['ed_nbpgdoc',	'integer'],				# nombre de page (faces) du document
	['ed_poidsunit','integer'],				# poids de l'imprim? ou de l'encart en mg
	['ed_nbenc',	'integer'],				# nombre d'encarts du doc
	['ed_encpds',	'integer'],				# poids des encarts du doc
	['ed_bac_insert','integer'],			# Appel de bac ou d'insert

	# SECTION EDITION DE L'INDEX
	['ed_typed',	'char'],				# type d'édition (noir / black / full color)
	['ed_modedi',	'char'],				# mode d'édition (simplex / duplex) => recto / verso 
	['ed_formatp',	'varchar2(2)'],			# format papier  (a4 / a3 ...)
	['ed_pgorien',	'varchar2(2)'],			# orientation de l'édition (portrait / reverseportrait  / landscape / reverse landscape)
	['ed_formflux',	'varchar2(3)'],			# format du flux d'édition (afp / pdf / ...)
#	['ed_formdef',	'varchar2(8)'],			# formdef afp
#	['ed_pagedef',	'varchar2(8)'],			# pagedef afp
#	['ed_forms',	'varchar2(8)'],			# Forms 

	# SECTION PLI DE L'INDEX
	['ed_idpli',	'integer'],				# identifiant du pli
	['ed_nbdocpli',	'integer'],				# nombre de documents du pli
	['ed_numpgpli',	'integer'],				# numéro de la page (face) dans le pli
	['ed_nbpgpli',	'integer'],				# nombre de pages (faces) du pli
	['ed_nbfpli',	'integer'],				# nombre de feuillets du pli
	['ed_listerefenc','varchar2(64)'],		# liste des encarts du pli
	['ed_pdspli',	'integer'],				# poids du pli en mg
	['ed_typobj',	'char'],				# type d'objet dans le pli	xxxxxx  conserver ?
	['ed_status',	'varchar2(8)'],			# status de lotissement (date de remise en poste ou status en fonction des versions)
	['ed_dtposte',	'varchar2(8)'],			# à supprimer : status de lotissement (date de remise en poste ou status en fonction des versions)

	# ADD
	['ed_workflow', 'varchar2(32)'],	    # workflow sur lequel on a produit les metadonnées	++ new ++
	['ed_chanel_out', 'varchar2(32)'],		# canal de distribution/output						++ new ++
	['ed_country',	'varchar2(5)'],			# code pays du destinataire							++ new ++
	['ed_idcontract','varchar2(16)'],		# identifiant de contrat							++ new ++
	['ed_idproduct','varchar2(8)']			# Identifiant de Produit							++ NEW ++

);



sub create_table_OUTMNGR {
	my ($dbh, $table) = @_;

	my $sql = "create table if not exists $table ("
			. join(', ', map {"$$_[0] $$_[1]"} @INDEX_COLS) . ", "
			. " primary key (ed_idldoc, ed_seqdoc, ed_idseqpg, ed_idjob)"
			. " )";
	$sql .= " engine=MyISAM " if (_db_check_driver_name($dbh) eq "mysql");
	&logger (7, $sql);

	$dbh->do(_sql_fixup($dbh, $sql, 'casse')) or &logger (4, $dbh->errstr );
	my $idx = "ix_".$table."_".$VERSION_TXT;
	$sql = "create index if not exists $idx on $table "
			." (ed_dtedtion, ed_seqlot, ed_typprod);";
	&logger (7, $sql);
	$dbh->do(_sql_fixup($dbh, $sql, 'casse')) or &logger (4, $dbh->errstr );

#	$sql = "create index `ix_ed_dtedtion_$table` on $table (`ed_dtedtion`);";
#	$dbh->do(_sql_fixup($dbh, $sql, 'casse')) or &logger (4, $dbh->errstr );
#
#	$sql = "create index `ix_ed_seqlot_$table` on $table (`ed_seqlot`);";
#	$dbh->do(_sql_fixup($dbh, $sql, 'casse')) or &logger (4, $dbh->errstr );
#
#	$sql = "create index `ix_ed_typprod_$table` on $table (`ed_typprod`);";
#	$dbh->do(_sql_fixup($dbh, $sql, 'casse')) or &logger (4, $dbh->errstr );
	
}


sub create_lot_sequence {
	# UTILISER POUR LA CREATION DE LOT DANS Outmngr.pm
	# méthode valable pour la plupart des SGBD sauf MySql
	my $dbh = shift;
	my $sql = "create sequence if not exists edtk_idlot minvalue 0 maxvalue 999 cycle";

	$dbh->do(_sql_fixup ($dbh, $sql, 'casse')) or &logger (4, $dbh->errstr);

# Tester si cette évolution est plus universelle :	
#create sequence edtk_idlot
#start with 0
#increment by 1
#maxvalue 999
#cycle;

# create table edtk_idlot_seq (
#    id_val int not null
#);
#insert into edtk_idlot_seq (id_val) values (0);
# On incrémente et on applique un modulo 1000 pour boucler de 0 à 999
# update edtk_idlot_seq set id_val = mod(id_val + 1, 1000);
# select id_val from edtk_idlot_seq;

}


sub schema_Upgrade {
	# EXEMPLE D'APPEL :
	# schema_Upgrade (CFG => $cfg);
	my %p = @_;

	# PRE REQUIS A CETTE OPERATION :
	#- ESPACE DISQUE
	#- HISTORIZATION
	#- OPTIMISATION DE LA BASE || DES TABLES

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
	my $sep ="";
	if (_db_check_driver_name($p{DBH}) =~ m/SQLite/i) {
		$sep = "'";
	}

	foreach my $table (@tListeTables) {
		my $sql = sprintf ("alter table %s rename to "."$sep"."%s_%s"."$sep"." ;", $table, $stamp, $table);
		&logger (7, $sql);
		#$p{DBH}->do(                   $sql, undef, )  or die &logger( -1, "ERROR: can't $sql");	
		$p{DBH}->do(_sql_fixup($p{DBH}, $sql, 'casse' )) or die &logger( -1, "ERROR: can't $sql");

	}

	# si ok :
	schema_Create($p{DBH});
	
	#si ok :
	foreach my $table (@tListeTables) {
		my $sql = sprintf ("insert into %s select * from "."$sep"."%s_%s"."$sep"." ;", $table, $stamp, $table);
		&logger (7, $sql);
		$p{DBH}->do(_sql_fixup($p{DBH}, $sql, undef )) or die &logger ( -1, "ERROR: can't $sql");
		my $drop = sprintf ("drop table "."$sep"."%s_%s"."$sep"." ;", $stamp, $table);
		&logger (7, $drop);
		$p{DBH}->do(_sql_fixup($p{DBH}, $drop, 'casse')) or die &logger ( -1, "ERROR: can't $drop");
	}


#insert into table_destination (colonne1, colonne2, colonne_supplementaire)
#select colonne1, colonne2, 'valeur_par_defaut'
#from table_source;

#declare @colonne_supplementaire_presente bit;
#set @colonne_supplementaire_presente = (select count(*) from information_schema.columns where table_name = 'table_destination' and column_name = 'colonne_supplementaire');
#
#if @colonne_supplementaire_presente = 1
#begin
#    insert into [table_destination](https://www.google.com/search?q=table_destination) (colonne1, colonne2, colonne_supplementaire)
#    select colonne1, colonne2, 'valeur_par_defaut'
#    from [table_source](https://www.google.com/search?q=table_source);
#end
#else
#begin
#    insert into [table_destination](https://www.google.com/search?q=table_destination) (colonne1, colonne2)
#    select colonne1, colonne2
#    from [table_source](https://www.google.com/search?q=table_source);
#end

}

sub schema_Create {
#	my ($dbh, $table, $maxkeys) = @_;
	my $dbh = shift;
	my $cfg = config_read('EDTK_DB');

	#if ( $cfg->{'EDTK_DBI_DSN'} =~ m/SQLite/i) {
	if ( $dbh->{'Driver'}->{'Name'} =~ m/SQLite/i) {
		&logger (5, "SQLite doesn't support SEQUENCE value, ignoring.");
	} elsif ( $dbh->{'Driver'}->{'Name'} =~ m/mysql/i) {
		&logger (5, "MySQL support specific SEQUENCE value, ignoring.");

	} else {
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

	# VÉRIFIER LES PROPOSITIONS DE CLÉS PRIMAIRES ET LES INDEX (ATTENTION À NE PAS FAIRE N'IMPORTE QUOI)
	create_table_OUTMNGR($dbh, $cfg->{'EDTK_DBI_OUTMNGR'});
	create_table_OUTMNGR($dbh, $cfg->{'EDTK_DBI_OUTMNGR_STATS'});
	create_table_DISTRIB($dbh, $cfg->{'EDTK_DBI_DISTRIB'});
	create_table_DISTRIB($dbh, $cfg->{'EDTK_DBI_DISTRIB_STATS'});

}


sub _db_maintenance {
    my (%p) = @_;   # CFG, DBH, [rotate => 1], [purge => 1]
    my $dbh = $p{DBH} // db_connect($p{CFG}, 'EDTK_DBI_DSN');

    _db_rotate($dbh, $p{CFG})  if $p{rotate};
    _db_purge ($dbh, $p{CFG})  if $p{purge};

    $dbh->disconnect unless $p{DBH};   # ne déconnecte pas si on nous a passé $dbh
    return 1;
}

sub _db_with_lock {
    my (%p) = @_;   # CFG, CODE-REF
    my $dbh = db_connect($p{CFG}, 'EDTK_DBI_DSN');
    my $date = strftime("%Y-%m-%d", localtime);
    my $pid  = $$;

    # Tente d insérer le verrou
    eval {
        $dbh->do(
            'insert into edtk_admin (ed_action_date,ed_action_pid,ed_action_status,ed_oedtk_release) values (?,?,?,?)',
            undef, $date, $pid, 'START', $VERSION
        );
    };
    if ($@) {                 # conflit, un autre process a déjà la main
        $dbh->disconnect;
        return 0;
    }

    # Vérifie que c est bien nous
    my ($got_pid) = $dbh->selectrow_array(
        'select ed_action_pid from edtk_admin where ed_action_date = ?', undef, $date
    );
    unless ($got_pid == $pid) {
        $dbh->disconnect;
        return 0;
    }

    # Exécute le corps
    eval { $p{code}->($dbh) };
    my $err = $@;

    # Marque la fin
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
    
    # Protection contre un $dbh invalide ou non connecté
    return "NC" unless defined $dbh;
    my $driver_name = eval { $dbh->{'Driver'}->{'Name'} };
    return "NC" unless defined $driver_name;

    if    ($driver_name =~ m/SQLite/i) { return "SQLite";     }
    elsif ($driver_name =~ m/Oracle/i) { return "Oracle";     }
    elsif ($driver_name =~ m/Pg/i)     { return "PostgreSQL"; }
    elsif ($driver_name =~ m/mysql/i)  { return "mysql";      }
    else                               { return "NC";          }
}

sub admin_optimize_db {
	# EXEMPLE D'APPEL :
	# admin_optimize_db (CFG => $cfg);

    my %p = @_;
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

    my %hCdeRepair = (
        NC         => "select 1",           # pas de %s : no-op portable
        mysql      => "repair table %s",
        Oracle     => "select 1 from dual",
        PostgreSQL => "select 1",
    );
    my %hCdeOptm = (
        NC         => "select 1",
        mysql      => "optimize table %s",
        Oracle     => "select 1 from dual",
        PostgreSQL => "vacuum full %s",
    );

    # Détection du driver une seule fois, sur la connexion initiale
    my $dbName = _db_check_driver_name($p{DBH});
    &logger(7, "admin_optimize_db: driver=$dbName, ".scalar(@tListeTables)." tables");

    foreach my $table (@tListeTables) {
        $p{DBH} = db_connect($p{CFG}, 'EDTK_DBI_DSN');
        my $dbName_cur = _db_check_driver_name($p{DBH});

        # Repair
        my $tpl_repair = $hCdeRepair{$dbName_cur} // "select 1";
        # sprintf seulement si le template contient %s
        my $sql_repair = ($tpl_repair =~ /\%s/) ? sprintf($tpl_repair, $table) : $tpl_repair;
        &logger(7, "repair: $sql_repair");
        $p{DBH}->do(_sql_fixup($p{DBH}, $sql_repair, 'casse'))
            or &logger(4, "can't repair $table");
        $p{DBH}->disconnect;

        $p{DBH} = db_connect($p{CFG}, 'EDTK_DBI_DSN');
        $dbName_cur = _db_check_driver_name($p{DBH});

        # Optimize
        my $tpl_optm = $hCdeOptm{$dbName_cur} // "select 1";
        my $sql_optm = ($tpl_optm =~ /\%s/) ? sprintf($tpl_optm, $table) : $tpl_optm;
        &logger(7, "optimize: $sql_optm");
        $p{DBH}->do(_sql_fixup($p{DBH}, $sql_optm, 'casse'))
            or &logger(4, "can't optimize $table");
        $p{DBH}->disconnect;
    }
    return 1;
}

sub _db_check_driver_name_deprecated($){
	my ($dbh) = shift;
	
	if ( $dbh->{'Driver'}->{'Name'} =~ m/SQLite/i) {
		return "SQLite";	# Standard
	} elsif ( $dbh->{'Driver'}->{'Name'} =~ m/Oracle/i) {
		return "Oracle";	# Standard
	} elsif ( $dbh->{'Driver'}->{'Name'} =~ m/Pg/i) {
		return "PostgreSQL";# Standard
	} elsif ( $dbh->{'Driver'}->{'Name'} =~ m/mysql/i) {
		return "mysql";		# non Standard

	} else {
		return "NC"; #$dbh->{'Driver'}->{'Name'};
	}
}

sub admin_optimize_db_deprecated{
	# EXEMPLE D'APPEL :
	# admin_optimize_db (CFG => $cfg);
	my %p = @_;

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
		$p{CFG}->{EDTK_DBI_OUTMNGR_STATS},
		"edtk_tracking"
	);

	my %hCdeRepair =(
		NC		=> "select * from %s limit 1",
		mysql	=> "repair table %s",
		Oracle	=> "select * from %s limit 1",	# à tester
		PostgreSQL => "select * from %s limit 1"		# à tester
		
		#check table edtk_tracking quick fast;
	);


	my %hCdeOptm =(
		NC		=> "select * from %s limit 1",
		mysql	=> "optimize table %s",
		#Oracle	=> "alter table %s move",	# à tester
		Oracle	=> "select * from %s limit 1",	# à tester
		PostgreSQL => "vacuum full %s"		# à tester
	);

	my $dbName = _db_check_driver_name($p{DBH});
	my $sql;

	foreach my $table (@tListeTables) {
		# connexion et deconnexion avant et après chaque opération pour ne pas mobiliser la base
		$p{DBH}	= db_connect($p{CFG}, 'EDTK_DBI_DSN');
		$sql = sprintf (($hCdeRepair{$dbName} || "-- %s"), $table);
		&logger (7, $sql);
		$p{DBH}->do(_sql_fixup($p{DBH}, $sql, 'casse' )) or &logger( 4, "can't repair $table");	
		$p{DBH}->disconnect;

		$p{DBH}	= db_connect($p{CFG}, 'EDTK_DBI_DSN');
		$sql = sprintf (($hCdeOptm{$dbName} || "-- %s"), $table);
		&logger (7, $sql);
		$p{DBH}->do(_sql_fixup($p{DBH}, $sql, 'casse' )) or &logger( 4, "can't optimize $table");	
		$p{DBH}->disconnect;
	}

1;
}

sub _sql_fixup_v1 {
	my ($dbh, $sql) = @_;

	# inverser la logique : standard SQL => spécifique Oracle
	if ($dbh->{'Driver'}->{'Name'} ne 'Oracle') {
		$sql =~ s/varchar2 *(\(\d+\))/varchar$1/gi;
	}

	return $sql;
}

sub _sql_fixup {
    my ($dbh, $sql, $mysqlCasse) = @_;
    my $driver = $dbh->{'Driver'}->{'Name'};

    # Spécificités pour POSTGRESQL (Driver 'Pg')
    if ($driver eq 'Pg') {
        # --- Gestion des chaînes vides '' pour les types non-string ---
        if ($sql =~ /VALUES\s*\((.*)\)/si) {
            my $values_part = $1;
            # Remplace les '' isolés par NULL
            $values_part =~ s/''(?=\s*,|\s*\))/NULL/g;
            $sql =~ s/VALUES\s*\(.*\)/VALUES ($values_part)/si;
        }

        # Gestion du format de mise à jour "SET colonne = ''"
        $sql =~ s/=\s*''(\s*,|\s+WHERE|=)/ = NULL$1/gi;
    }
    
    # Logique générique / autres drivers (MySQL, etc.)
    if ($driver ne 'Oracle') {
        $sql =~ s/VARCHAR2 *(\(\d+\))/VARCHAR$1/gi;
    }

    if ($driver eq 'mysql' and $mysqlCasse and $sql !~ /\b(INSERT|REPLACE)\b/i) {
        $sql = uc($sql);
    }


    return $sql;
}

sub db_backup_agent($){
	&logger (4, "method oEdtk::DBAdmin::db_backup_agent is deprecated you should use oEdtk::DBAdmin::copy_table");
	# deprecated method
	# purge sauvegardée des 3 tables de productions : EDTK_DBI_TRACKING EDTK_DBI_OUTMNGR EDTK_DBI_ACQUIT
	# en fonction du paramétrage EDTK_ENTIRE_YEARS_KEPT
	my ($dbh)	= shift;
	my $cfg		= config_read('EDTK_DB');
	unless (defined ($cfg->{'EDTK_ENTIRE_YEARS_KEPT'}) && $cfg->{'EDTK_ENTIRE_YEARS_KEPT'} > 0){
		&logger (4, "EDTK_ENTIRE_YEARS_KEPT not defined for optimization purge. db_backup_agent not needed.");
		return 1;
	}

	my $suffixe		= strftime ("%Y%m%d", localtime);
	$suffixe 		.="_BAK";
	my $cur_year	= strftime ("%Y", localtime);

	{ # isole le block pour les variables locales
		# CHECK IF EDTK_DBI_TRACKING HAS OLD STATS
		my $sql_check="select count(ed_tstamp) from ".$cfg->{'EDTK_DBI_TRACKING'}." where ed_tstamp < ? ";
		my $check	= ($cur_year - $cfg->{'EDTK_ENTIRE_YEARS_KEPT'}) . "0101000000";
		my $sth		= $dbh->prepare($sql_check);

		$sth->execute($check) or &logger (3, "SQL execute failed ".$sth->err."-".$sth->errstr);
		my $result = $sth->fetchrow_array;
		unless ($result){
			&logger (5, "db_backup_agent has nothing to do with ".$cfg->{'EDTK_DBI_TRACKING'});
		} else {
			my $cible = $cfg->{'EDTK_DBI_TRACKING'}."_".$suffixe;
			copy_table ($dbh, $cfg->{'EDTK_DBI_TRACKING'}, $cible, '-create'); 
			&logger (5, "db_backup_agent DONE with ".$cfg->{'EDTK_DBI_TRACKING'}." for data older than $check.");

			my $sql_clean = "delete from ".$cfg->{'EDTK_DBI_TRACKING'}." where ed_tstamp < ? ";
			$dbh->do($sql_clean, undef, $check) or die $dbh->errstr;	
		}
	}

	{ # isole le block pour les variables locales
		# CHECK IF EDTK_DBI_OUTMNGR HAS OLD STATS
		my $sql_check="select count(ed_dtedtion) from ".$cfg->{'EDTK_DBI_OUTMNGR'}." where ed_dtedtion < ? ";
		my $check	= ($cur_year - $cfg->{'EDTK_ENTIRE_YEARS_KEPT'}) . "0101";
		my $sth		= $dbh->prepare($sql_check);

		$sth->execute($check) or &logger (3, "SQL execute failed ".$sth->err."-".$sth->errstr);
		my $result = $sth->fetchrow_array;
		unless ($result){
			&logger (5, "db_backup_agent has nothing to do with ".$cfg->{'EDTK_DBI_OUTMNGR'});
		} else {
			my $cible = $cfg->{'EDTK_DBI_OUTMNGR'}."_".$suffixe;
			copy_table ($dbh, $cfg->{'EDTK_DBI_OUTMNGR'}, $cible, '-create'); 

			my $sql_clean = "delete from ".$cfg->{'EDTK_DBI_OUTMNGR'}." where ed_dtedtion < ? ";
			$dbh->do($sql_clean, undef, $check) or die $dbh->errstr;	

			&logger (4, "db_backup_agent DONE with ".$cfg->{'EDTK_DBI_OUTMNGR'}." for data older than $check.");
		}
	}

	{ # isole le block pour les variables locales
		# CHECK IF EDTK_DBI_ACQUIT HAS OLD STATS
		my $sql_check="select count (ed_dtpost) from ".$cfg->{'EDTK_DBI_ACQUIT'}." where ed_dtpost < ? ";
		my $check	= ($cur_year - $cfg->{'EDTK_ENTIRE_YEARS_KEPT'}) . "0101";
		my $sth		= $dbh->prepare($sql_check);

		$sth->execute($check) or &logger (3, "SQL execute failed ".$sth->err."-".$sth->errstr);
		my $result = $sth->fetchrow_array;
		unless ($result){
			&logger (5, "db_backup_agent has nothing to do with ".$cfg->{'EDTK_DBI_ACQUIT'});
		} else {
			my $cible = $cfg->{'EDTK_DBI_ACQUIT'}."_".$suffixe;
			copy_table ($dbh, $cfg->{'EDTK_DBI_ACQUIT'}, $cible, '-create'); 
	
			my $sql_clean = "delete from ".$cfg->{'EDTK_DBI_ACQUIT'}." where ed_dtpost < ? ";
			$dbh->do($sql_clean, undef, $check) or die $dbh->errstr;	

			&logger (4, "db_backup_agent DONE with ".$cfg->{'EDTK_DBI_ACQUIT'}." for data older than $check.");
		}
	}

1;
}


1;

package oEdtk::DBAdmin;

use DBI;
use oEdtk::Config	qw(config_read);
use oEdtk::logger	qw(logger $LOGGERLEVEL $WARN2LOGGER);
use POSIX			qw(strftime);
use Scalar::Util 	qw(looks_like_number);
use strict;
use Text::CSV;
use warnings;
#use Data::Dumper qw(Dumper);

# TODO   : check db status et retourner alerte si besoin -sortir de db_admin_check si il y a le moindre problème sur les tables de tracking + dans les log en cas d'incident, préciser de quelle table il s'agit
# Fait   : ajout ED_IDGED, ordre des purges - drapeau table admin rechercher la valeur contrôlée 
# Fait   : Simplification de l'historisation en se basant sur ED_DTLOT, protection des ED_DTLOT (ED_DLOT non numérique ou non date) à l'insertion faite au niveau de la demande d'insertion
# 220725 : correction erreur silencieuse dans historisation lorsqu'il n'y a pas de valeur assignée $result
# 230818 : préparation évolution check à la demande (base stats AGREGE à valider)
# check sql : https://www.eversql.com
use Exporter;
our $VERSION		= 1.8123; #bug test $cfg->{EDTK_DB_CHECK_AUTO} défini par défaut à YES
our @ISA			= qw(Exporter);
our @EXPORT_OK		= qw(
				admin_check_db
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
				historicize_table
				insert_tData
				move_table
				admin_optimize_db
				@INDEX_COLS
				@TRACKER_COLS
				);


my $_LOCAL_EDTK_WAITRUN=0;
my $CONNECT_COUNT=0;



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
		$dbh->do($sql_create, undef, ) or die $dbh->errstr;	

	} else {
		my $sql_insert	= "INSERT INTO  ".$table_cible." SELECT * FROM ".$table_source;
		# en cas d'erreur, DIE pour protéger toute autre opération sur les bases (db_backup_agent, ...)
		$dbh->do($sql_insert, undef, ) or die $dbh->errstr;	
	}
	
	&logger (4, "Insert done into $table_cible");
1;
}


sub insert_tData {
# Exemple d'appel
#		my $ret = insert_tData(
#			dbh => $dbh, 
#			table => $cfg->{'EDTK_DBI_TRACKING'}, 
#			tCols => \@cols,
#			tData => \@tData
#		);
	
	my (%p) = @_;
#	print @{$p{'tData'}} ."\n";
#	print Dumper($p{'table'});
#	print Dumper($p{'tData'});

	my $sql = "INSERT INTO " . ${p{'table'}} . " (" . join(',', @{$p{'tCols'}})
			. ") VALUES (" . join(',', ('?') x @{$p{'tCols'}}) . ")";
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


sub csv_import ($$$;$){
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
	$params->{'sep_char'} 	= $params->{'sep_char'} || ",";
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
		
		if (defined $seqlot->{'	'}) {
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
					and (defined $cfg->{EDTK_DB_CHECK_AUTO} && $cfg->{EDTK_DB_CHECK_AUTO} !~ /NO/i)
					and looks_like_number($cfg->{EDTK_DB_MAX_DAYS_KEPT})
					and looks_like_number($cfg->{EDTK_DB_MAX_DAYS_KEPT_STATS})
					and	looks_like_number($cfg->{EDTK_DB_MAX_DAYS_TRACKED})
				){
				my ($level, $return) = admin_check_db ($dbh, $cfg);
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
	# names are lowercase instead of uppercase as we assume everywhere.
	$dbargs->{'FetchHashKeyName'} = 'NAME_uc';

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

	return $dbh;
}



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
	$sql = "SELECT ED_ACTION_DATE, ED_ACTION_PID, ED_ACTION_STATUS, ED_ACTION_DURATION, ED_OEDTK_RELEASE FROM EDTK_ADMIN " 
			. " WHERE ED_ACTION_DATE = '"
			. $date
			. "'  "; #ORDER BY ED_ACTION_DATE DESC LIMIT 1";
	&logger (7, $sql);

	$p{DBH}	= db_connect($p{CFG}, 'EDTK_DBI_DSN');
	$sth 	= $p{DBH}->prepare($sql) or return (3, $p{DBH}->errstr);
	$sth->execute() or &logger (3, "SQL execute failed ".$sth->err."-".$sth->errstr);

	# EST-CE QU'UNE ACTION D'ADMINISTRATION A ETE EFFECTUEE A DATE ?
	my @tValues = $p{DBH}->selectrow_array($sql, undef);# or warn ("ERROR: in admin_check_db, message is " . $dbh->errstr);
	my $rc = $sth->finish;
	$p{DBH}->disconnect;

	if ($tValues[0] and $date eq $tValues[0]){
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
	$insert = 'INSERT INTO EDTK_ADMIN (ED_ACTION_DATE, ED_ACTION_PID, ED_ACTION_STATUS, ED_OEDTK_RELEASE) '
			. ' VALUES (?, ?, ?, ?) ';
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
	$sql = "SELECT ED_ACTION_DATE, ED_ACTION_PID, ED_ACTION_STATUS, ED_ACTION_DURATION, ED_OEDTK_RELEASE FROM EDTK_ADMIN " 
			. " WHERE ED_ACTION_DATE = '"
			. $date
			. "'  "; #ORDER BY ED_ACTION_DATE DESC LIMIT 1";
	&logger (7, $sql);

	$sth = $p{DBH}->prepare($sql);
	$sth->execute() or &logger (3, "SQL execute failed ".$sth->err."-".$sth->errstr);
	my @tValues = $p{DBH}->selectrow_array($sql, undef) or warn ("ERROR: in admin_check_db, message is " . $p{DBH}->errstr);
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
		return (5, $reportActions);
	}


	# Fin du traitement
	$time=time-$time;
	$sql = 'UPDATE EDTK_ADMIN SET ED_ACTION_STATUS = ?, ED_ACTION_DURATION = ? WHERE ED_ACTION_DATE = ?';
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
	$sql = "DELETE FROM EDTK_ADMIN WHERE ED_ACTION_DATE < '" 
			. (strftime "%Y-%m-%d", localtime($DAYS_TRACKED_time))."'";
	&logger (7, $sql);

	$p{DBH} = db_connect($p{CFG}, 'EDTK_DBI_DSN');
	$result = $p{DBH}->do($sql, undef ) or return warn "ERROR: can't update EDTK_ADMIN";	
	$p{DBH}->disconnect;
	&logger (6,"RESULT = " . ($result || 0) ." for $sql");
	$reportActions = "ACHECK PURGE EDTK_ADMIN=" . ($result || 0);

	# PURGE FROM EDTK_DBI_TRACKING
	$sql = "DELETE FROM " 
			. $p{CFG}->{'EDTK_DBI_TRACKING'} 
			. " WHERE ED_TSTAMP < '" . (strftime "%Y%m%d", localtime($DAYS_TRACKED_time)) . "000000'";
	&logger (7, $sql);

	$p{DBH} = db_connect($p{CFG}, 'EDTK_DBI_DSN');
	$result = $p{DBH}->do($sql, undef ) or return print STDERR "ERROR: can't update ". $p{CFG}->{'EDTK_DBI_TRACKING'};	
	$p{DBH}->disconnect;
	&logger (6,"RESULT = " . ($result || 0) ." for $sql");
	$reportActions .= "-PURGE TRACKING=" . ($result || 0);

	# PURGE FROM EDTK_DBI_DISTRIB_STATS 
	$sql = "DELETE FROM " 
			. $p{CFG}->{'EDTK_DBI_DISTRIB_STATS'}
			. " WHERE ED_DTLOT < '" . (strftime "%Y-%m-%d", localtime($DAYS_KEPT_STATS_time)) ."'"; # or not REGEXP_LIKE (ED_DTLOT, '\d\d\d\d-\d\d-\d\d') ne fonctionne pas sur MySQL...
	&logger (7, $sql);

	$p{DBH} = db_connect($p{CFG}, 'EDTK_DBI_DSN');
	$result = $p{DBH}->do($sql, undef ) or return warn "ERROR: can't update ". $p{CFG}->{'EDTK_DBI_DISTRIB_STATS'};	
	$p{DBH}->disconnect;
	&logger (6,"RESULT = " . ($result || 0) ." for $sql");
	$reportActions .= "-PURGE DISTRIB_S=" . ($result || 0);

	# PURGE FROM OUTMNGR_STATS 
	$sql = "DELETE FROM " 
			. $p{CFG}->{'EDTK_DBI_OUTMNGR_STATS'}
			. " WHERE ED_DTLOT < '" . (strftime "%Y-%m-%d", localtime($DAYS_KEPT_STATS_time)) ."'";
	&logger (7, $sql);

	$p{DBH} = db_connect($p{CFG}, 'EDTK_DBI_DSN');
	$result = $p{DBH}->do($sql, undef ) or return warn "ERROR: can't update ". $p{CFG}->{'EDTK_DBI_OUTMNGR_STATS'};	
	$p{DBH}->disconnect;
	&logger (6,"RESULT = " . ($result || 0) ." for $sql");
	$reportActions .= "-PURGE OUTMNGR_S=" . ($result || 0);

	# PURGE FROM EDTK_AGREGE
	$sql = "DELETE FROM EDTK_AGREGE " 
			. " WHERE ED_DTLOT < '" . (strftime "%Y-%m-%d", localtime($DAYS_AGREGED_time)) ."'";
	&logger (7, $sql);

	$p{DBH} = db_connect($p{CFG}, 'EDTK_DBI_DSN');
	$result = $p{DBH}->do($sql, undef ) or return warn "ERROR: can't update EDTK_AGREGE";	
	$p{DBH}->disconnect;
	&logger (6,"RESULT = " . ($result || 0) ." for $sql");
	$reportActions .= "-PURGE AGREGE=" . ($result || 0);

	
	### EDTK_ID ###
	# PURGE FROM EDTK_ID 
	$sql = "DELETE FROM EDTK_ID"
			. " WHERE ED_ID_DATE < '" . (strftime "%Y-%m-%d", localtime($DAYS_TRACKED_time)) ."'";
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
		$sql = "INSERT INTO EDTK_AGREGE "
			. "SELECT "
			. "I.ED_SOURCE, "
			. "D.ED_CHANEL_OUT, "
			. "I.ED_REFIDDOC, "
			. "I.ED_IDPRODUCT, "
			. "I.ED_DTEDTION, "
			. "COUNT(DISTINCT D.ED_IDLDOC) AS 'ED_CNTD_IDLDOC', "
			. "COUNT(D.ED_IDSEQPG) AS 'ED_CNT_IDSEQPG', "
			. "D.ED_DTLOT, "
			. "D.ED_IDLOT, "
			. "D.ED_IDJOB, "
			. "'$stamp' "
			. "FROM "
			. $p{CFG}->{'EDTK_DBI_OUTMNGR'}
			. " AS I "
			. "INNER JOIN "
			. $p{CFG}->{'EDTK_DBI_DISTRIB'}
			. " AS D ON D.ED_IDLDOC = I.ED_IDLDOC "
			. "AND D.ED_IDSEQPG = I.ED_IDSEQPG "
			. "AND D.ED_SEQDOC = I.ED_SEQDOC "
			. "AND D.ED_IDJOB = I.ED_IDJOB "
			. "WHERE D.ED_DTLOT < '" . (strftime "%Y-%m-%d", localtime($DAYS_KEPT_time)) ."' "
			. "GROUP BY "
			. "I.ED_SOURCE, "
			. "D.ED_CHANEL_OUT, "
			. "I.ED_REFIDDOC, "
			. "I.ED_IDPRODUCT," 
			. "I.ED_DTEDTION, "
			. "D.ED_DTLOT, "
			. "D.ED_IDLOT, "
			. "D.ED_IDJOB ";
	&logger (7,"SQL = $sql");

	$result = $p{DBH}->do($sql, undef ) or die "ERROR: can't update EDTK_AGREGE";	
	&logger (6,"RESULT = " . ($result || 0) ." for $sql");
	$reportActions .= "-MV AGREGE=" . ($result || 0);

#INSERT INTO [table_destination](https://www.google.com/search?q=table_destination) (colonne1, colonne2, colonne_supplementaire)
#SELECT colonne1, colonne2, 'valeur_par_defaut'
#FROM [table_source](https://www.google.com/search?q=table_source);

	### DISTRIB ###
	# MOVE DATA FROM DISTRIB TO DISTRIB_STATS
	$sql = "INSERT INTO " 
			. $p{CFG}->{'EDTK_DBI_DISTRIB_STATS'}
			. " SELECT * FROM "
			. $p{CFG}->{'EDTK_DBI_DISTRIB'}
			. " WHERE ED_DTLOT < '" . (strftime "%Y-%m-%d", localtime($DAYS_KEPT_time)) ."'";
	&logger (7, $sql);

	$result = $p{DBH}->do($sql, undef ) or return warn "ERROR: can't update ". $p{CFG}->{'EDTK_DBI_DISTRIB_STATS'};	
	&logger (6,"RESULT = " . ($result || 0) ." for $sql");
	$reportActions .= "-MV DISTRIB=" . ($result || 0);

		# CLEAN DISTRIB 
		$sql = "DELETE FROM " 
				. $p{CFG}->{'EDTK_DBI_DISTRIB'}
				. " WHERE ED_DTLOT < '" . (strftime "%Y-%m-%d", localtime($DAYS_KEPT_time)) ."'";
		&logger (7, $sql);

		$result = $p{DBH}->do($sql, undef ) or warn "ERROR: can't update ". $p{CFG}->{'EDTK_DBI_DISTRIB_STATS'};	
		&logger (6,"RESULT = " . ($result || 0) ." for $sql");
		$reportActions .= "/" . ($result || 0);

		
	### OUTMNGR ###
	# MOVE DATA FROM OUTMNGR TO OUTMNGR_STATS
	$sql = "INSERT INTO " 
			. $p{CFG}->{'EDTK_DBI_OUTMNGR_STATS'}
			. " SELECT * FROM "
			. $p{CFG}->{'EDTK_DBI_OUTMNGR'}
			. " WHERE ED_DTLOT < '" . (strftime "%Y-%m-%d", localtime($DAYS_KEPT_time)) ."'";
	&logger (7, $sql);

	$result = $p{DBH}->do($sql, undef ) or warn "ERROR: can't update ". $p{CFG}->{'EDTK_DBI_OUTMNGR_STATS'};	
	&logger (6,"RESULT = " . ($result || 0) ." for $sql");
	$reportActions .= "-MV OUTMNGR=" . ($result || 0);

		# CLEAN OUTMNGR 
		$sql = "DELETE FROM " 
				. $p{CFG}->{'EDTK_DBI_OUTMNGR'}
				. " WHERE ED_DTLOT < '" . (strftime "%Y-%m-%d", localtime($DAYS_KEPT_time)) ."'";
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
	
	$sql = "INSERT INTO EDTK_AGREGE "
			. "SELECT "
			. "I.ED_SOURCE, "
			. "D.ED_CHANEL_OUT, "
			. "I.ED_REFIDDOC, "
			. "I.ED_IDPRODUCT, "
			. "I.ED_DTEDTION, "
			. "COUNT(DISTINCT D.ED_IDLDOC) AS 'ED_CNTD_IDLDOC', "
			. "COUNT(D.ED_IDSEQPG) AS 'ED_CNT_IDSEQPG', "
			. "D.ED_DTLOT, "
			. "D.ED_IDLOT, "
			. "D.ED_IDJOB, "
			. "'$stamp' "
			. "FROM "
			. $p{CFG}->{'EDTK_DBI_OUTMNGR'}
			. " AS I "
			. "INNER JOIN "
			. $p{CFG}->{'EDTK_DBI_DISTRIB'}
			. " AS D ON D.ED_IDLDOC = I.ED_IDLDOC "
			. "AND D.ED_IDSEQPG = I.ED_IDSEQPG "
			. "AND D.ED_SEQDOC = I.ED_SEQDOC "
			. "AND D.ED_IDJOB = I.ED_IDJOB "
			. "WHERE D.ED_IDJOB = '" . $p{IDJOB} ."' "
			. "GROUP BY "
			. "I.ED_SOURCE, "
			. "D.ED_CHANEL_OUT, "
			. "I.ED_REFIDDOC, "
			. "I.ED_IDPRODUCT," 
			. "I.ED_DTEDTION, "
			. "D.ED_DTLOT, "
			. "D.ED_IDLOT, "
			. "D.ED_IDJOB ";
	&logger (7,"SQL = $sql");

	$result = $p{DBH}->do($sql, undef ) or die "ERROR: can't update EDTK_AGREGE";	
	&logger (6,"RESULT = " . ($result || 0) ." for $sql");
	$reportActions .= "-MV AGREGE=" . ($result || 0);


	### DISTRIB ###
	# MOVE DATA FROM DISTRIB TO DISTRIB_STATS
	$sql = "INSERT INTO " 
			. $p{CFG}->{'EDTK_DBI_DISTRIB_STATS'}
			. " SELECT * FROM "
			. $p{CFG}->{'EDTK_DBI_DISTRIB'}
			. " WHERE ED_IDJOB = '" . $p{IDJOB} ."'";
	&logger (7, $sql);

	$result = $p{DBH}->do($sql, undef ) or return warn "ERROR: can't update ". $p{CFG}->{'EDTK_DBI_DISTRIB_STATS'};	
	&logger (6,"RESULT = " . ($result || 0) ." for $sql");
	$reportActions .= "-MV DISTRIB=" . ($result || 0);

		# CLEAN DISTRIB 
		$sql = "DELETE FROM " 
				. $p{CFG}->{'EDTK_DBI_DISTRIB'}
			. " WHERE ED_IDJOB = '" . $p{IDJOB} ."'";
		&logger (7, $sql);

		$result = $p{DBH}->do($sql, undef ) or warn "ERROR: can't update ". $p{CFG}->{'EDTK_DBI_DISTRIB_STATS'};	
		&logger (6,"RESULT = " . ($result || 0) ." for $sql");
		$reportActions .= "/" . ($result || 0);

		
	### OUTMNGR ###
	# MOVE DATA FROM OUTMNGR TO OUTMNGR_STATS
	$sql = "INSERT INTO " 
			. $p{CFG}->{'EDTK_DBI_OUTMNGR_STATS'}
			. " SELECT * FROM "
			. $p{CFG}->{'EDTK_DBI_OUTMNGR'}
			. " WHERE ED_IDJOB = '" . $p{IDJOB} ."'";
	&logger (7, $sql);

	$result = $p{DBH}->do($sql, undef ) or warn "ERROR: can't update ". $p{CFG}->{'EDTK_DBI_OUTMNGR_STATS'};	
	&logger (6,"RESULT = " . ($result || 0) ." for $sql");
	$reportActions .= "-MV OUTMNGR=" . ($result || 0);

		# CLEAN OUTMNGR 
		$sql = "DELETE FROM " 
				. $p{CFG}->{'EDTK_DBI_OUTMNGR'}
			. " WHERE ED_IDJOB = '" . $p{IDJOB} ."'";
		&logger (7, $sql);

		$result = $p{DBH}->do($sql, undef ) or warn "ERROR: can't update ". $p{CFG}->{'EDTK_DBI_OUTMNGR_STATS'};	
		&logger (6,"RESULT = " . ($result || 0) ." for $sql");
		$reportActions .= "/" . ($result || 0);

	$p{DBH}->disconnect;
	return (4, $reportActions);
}	


sub admin_check_db ($ $) {
	# https://www.forknerds.com/reduce-the-size-of-mysql/
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

	&logger (4,"ACHECK Check start");
	
	#RECHERCHE DE LA DERNIÈRE ACTION SUR LA TABLE ADMIN
	$sql = "SELECT ED_ACTION_DATE, ED_ACTION_PID, ED_ACTION_STATUS, ED_ACTION_DURATION, ED_OEDTK_RELEASE FROM EDTK_ADMIN " 
			. " WHERE ED_ACTION_DATE = '"
			. $date
			. "'  "; #ORDER BY ED_ACTION_DATE DESC LIMIT 1";
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
	my @tValues = $dbh->selectrow_array($sql, undef);# or warn ("ERROR: in admin_check_db, message is " . $dbh->errstr);
	if ($tValues[0] and $date eq $tValues[0]){
		return (5, ("ACHECK Last EDTK_DB_MAX_DAYS check : ". $tValues[0] ." PID ". $tValues[1]));
	}


	# SINON, SOLLICITE UN TICKET POUR REALISER L'ACTION
	$insert = 'INSERT INTO EDTK_ADMIN (ED_ACTION_DATE, ED_ACTION_PID, ED_ACTION_STATUS, ED_OEDTK_RELEASE) '
		. ' VALUES (?, ?, ?, ?) ';
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
	@tValues = $dbh->selectrow_array($sql, undef) or warn ("ERROR: in admin_check_db, message is " . $dbh->errstr);
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
	$sql = "DELETE FROM EDTK_ADMIN WHERE ED_ACTION_DATE < '" 
			. (strftime "%Y-%m-%d", localtime($DAYS_TRACKED_time))."'";
	&logger (7, $sql);

	$result = $dbh->do($sql, undef ) or return warn "ERROR: can't update EDTK_ADMIN";	
	&logger (6,"RESULT = " . ($result // 0) ." for $sql");
	$reportActions = "ACHECK PURGE EDTK_ADMIN=" . ($result // 0);

	# PURGE FROM EDTK_DBI_TRACKING
	$sql = "DELETE FROM " . $cfg->{'EDTK_DBI_TRACKING'} 
			. " WHERE ED_TSTAMP < '" . (strftime "%Y%m%d", localtime($DAYS_TRACKED_time)) . "000000'";
	&logger (7, $sql);

	$result = $dbh->do($sql, undef ) or return print STDERR "ERROR: can't update ". $cfg->{'EDTK_DBI_TRACKING'};	
	&logger (6,"RESULT = " . ($result // 0) ." for $sql");
	$reportActions .= "-PURGE TRACKING=" . ($result // 0);

	# PURGE FROM EDTK_DBI_DISTRIB_STATS 
	$sql = "DELETE FROM " 
			. $cfg->{'EDTK_DBI_DISTRIB_STATS'}
			. " WHERE ED_DTLOT < '" . (strftime "%Y-%m-%d", localtime($DAYS_KEPT_STATS_time)) ."'"; # or not REGEXP_LIKE (ED_DTLOT, '\d\d\d\d-\d\d-\d\d') ne fonctionne pas sur MySQL...
	&logger (7, $sql);

	$result = $dbh->do($sql, undef ) or return warn "ERROR: can't update ". $cfg->{'EDTK_DBI_DISTRIB_STATS'};	
	&logger (6,"RESULT = " . ($result // 0) ." for $sql");
	$reportActions .= "-PURGE DISTRIB_S=" . ($result // 0);

	# PURGE FROM OUTMNGR_STATS 
	$sql = "DELETE FROM " 
			. $cfg->{'EDTK_DBI_OUTMNGR_STATS'}
			. " WHERE ED_DTLOT < '" . (strftime "%Y-%m-%d", localtime($DAYS_KEPT_STATS_time)) ."'";
	&logger (7, $sql);

	$result = $dbh->do($sql, undef ) or return warn "ERROR: can't update ". $cfg->{'EDTK_DBI_OUTMNGR_STATS'};	
	&logger (6,"RESULT = " . ($result // 0) ." for $sql");
	$reportActions .= "-PURGE OUTMNGR_S=" . ($result // 0);

	# PURGE FROM EDTK_AGREGE
	$sql = "DELETE FROM EDTK_AGREGE " 
			. " WHERE ED_DTLOT < '" . (strftime "%Y-%m-%d", localtime($DAYS_AGREGED_time)) ."'";
	&logger (7, $sql);

	$result = $dbh->do($sql, undef ) or return warn "ERROR: can't update EDTK_AGREGE";	
	&logger (6,"RESULT = " . ($result // 0) ." for $sql");
	$reportActions .= "-PURGE AGREGE=" . ($result // 0);
	my $stamp =strftime "%Y%m%d%H%M%S", localtime;

	### MOVE / PURGE ###
		### EDTK_AGREGE ### 
		# MOVE DATA TO EDTK_AGREGE
			$sql = "INSERT INTO EDTK_AGREGE "
			. "SELECT "
			. "I.ED_SOURCE, "
			. "D.ED_CHANEL_OUT, "
			. "I.ED_REFIDDOC, "
			. "I.ED_IDPRODUCT, "
			. "I.ED_DTEDTION, "
			. "COUNT(DISTINCT D.ED_IDLDOC) AS 'ED_CNTD_IDLDOC', "
			. "COUNT(D.ED_IDSEQPG) AS 'ED_CNT_IDSEQPG', "
			. "D.ED_DTLOT, "
			. "D.ED_IDLOT, "
			. "D.ED_IDJOB, "
			. "'$stamp' "
			. "FROM "
			. $cfg->{'EDTK_DBI_OUTMNGR'}
			. " AS I "
			. "INNER JOIN "
			. $cfg->{'EDTK_DBI_DISTRIB'}
			. " AS D ON D.ED_IDLDOC = I.ED_IDLDOC "
			. "AND D.ED_IDSEQPG = I.ED_IDSEQPG "
			. "AND D.ED_SEQDOC = I.ED_SEQDOC "
			. "AND D.ED_IDJOB = I.ED_IDJOB "
			. " WHERE D.ED_DTLOT < '" . (strftime "%Y-%m-%d", localtime($DAYS_KEPT_time)) ."'"
			. "GROUP BY "
			. "I.ED_SOURCE, "
			. "D.ED_CHANEL_OUT, "
			. "I.ED_REFIDDOC, "
			. "I.ED_IDPRODUCT," 
			. "I.ED_DTEDTION, "
			. "D.ED_DTLOT, "
			. "D.ED_IDLOT, "
			. "D.ED_IDJOB ";
	&logger (7,"SQL = $sql");

		$result = $dbh->do($sql, undef ) or die "ERROR: can't update EDTK_AGREGE";	
		&logger (6,"RESULT = " . ($result // 0) ." for $sql");
		$reportActions .= "-MV AGREGE=" . ($result // 0);


		### DISTRIB ###
		# MOVE DATA FROM DISTRIB TO DISTRIB_STATS
		$sql = "INSERT INTO " 
				. $cfg->{'EDTK_DBI_DISTRIB_STATS'}
				. " SELECT * FROM "
				. $cfg->{'EDTK_DBI_DISTRIB'}
				. " WHERE ED_DTLOT < '" . (strftime "%Y-%m-%d", localtime($DAYS_KEPT_time)) ."'";
		&logger (7, $sql);

		$result = $dbh->do($sql, undef ) or return warn "ERROR: can't update ". $cfg->{'EDTK_DBI_DISTRIB_STATS'};	
		&logger (6,"RESULT = " . ($result // 0) ." for $sql");
		$reportActions .= "-MV DISTRIB=" . ($result // 0);

		# CLEAN DISTRIB 
		$sql = "DELETE FROM " 
				. $cfg->{'EDTK_DBI_DISTRIB'}
				. " WHERE ED_DTLOT < '" . (strftime "%Y-%m-%d", localtime($DAYS_KEPT_time)) ."'";
		&logger (7, $sql);

		$result = $dbh->do($sql, undef ) or warn "ERROR: can't update ". $cfg->{'EDTK_DBI_DISTRIB_STATS'};	
		&logger (6,"RESULT = " . ($result // 0) ." for $sql");
		$reportActions .= "/" . ($result // 0);

		
		### OUTMNGR ###
		# MOVE DATA FROM OUTMNGR TO OUTMNGR_STATS
		$sql = "INSERT INTO " 
				. $cfg->{'EDTK_DBI_OUTMNGR_STATS'}
				. " SELECT * FROM "
				. $cfg->{'EDTK_DBI_OUTMNGR'}
				. " WHERE ED_DTLOT < '" . (strftime "%Y-%m-%d", localtime($DAYS_KEPT_time)) ."'";
		&logger (7, $sql);

		$result = $dbh->do($sql, undef ) or warn "ERROR: can't update ". $cfg->{'EDTK_DBI_OUTMNGR_STATS'};	
		&logger (6,"RESULT = " . ($result // 0) ." for $sql");
		$reportActions .= "-MV OUTMNGR=" . ($result // 0);

		# CLEAN OUTMNGR 
		$sql = "DELETE FROM " 
				. $cfg->{'EDTK_DBI_OUTMNGR'}
				. " WHERE ED_DTLOT < '" . (strftime "%Y-%m-%d", localtime($DAYS_KEPT_time)) ."'";
		&logger (7, $sql);

		$result = $dbh->do($sql, undef ) or warn "ERROR: can't update ". $cfg->{'EDTK_DBI_OUTMNGR_STATS'};	
		&logger (6,"RESULT = " . ($result // 0) ." for $sql");
		$reportActions .= "/" . ($result // 0);


		### EDTK_ID ###
		# PURGE FROM EDTK_ID 
		$sql = "DELETE FROM EDTK_ID"
				. " WHERE ED_ID_DATE < '" . (strftime "%Y-%m-%d", localtime($DAYS_TRACKED_time)) ."'";
		&logger (7, $sql);

		$result = $dbh->do($sql, undef ) or warn "ERROR: can't update ". $cfg->{'EDTK_DBI_OUTMNGR_STATS'};	
		&logger (6,"RESULT = " . ($result // 0) ." for $sql");
		$reportActions .= "-PURGE EDTK_ID=" . ($result // 0);



	# Fin du traitement
	$time=time-$time;
	$sql = 'UPDATE EDTK_ADMIN SET ED_ACTION_STATUS = ?, ED_ACTION_DURATION = ? WHERE ED_ACTION_DATE = ?';
	$dbh->do($sql, undef, "DONE", $time, $date) or warn "ERROR: can't update ED_ACTION_STATUS";	

	return (4, $reportActions);
}


our @TRACKER_COLS = (
	['ED_TSTAMP',	'VARCHAR2(14) NOT NULL'],	# Timestamp of event
	['ED_SNGL_ID',	'VARCHAR2(25) NOT NULL'],	#xx ED_IDLDOC Single ID : format YWWWDHHMMSSPPPP.U (compuset se limite ? 16 digits : 15 entiers, 1 decimal)
	['ED_SEQ',		'INTEGER      NOT NULL'],	# Sequence
	['ED_APP',		'VARCHAR2(20) NOT NULL'],	#xx ED_REFIDDOC Application name

	['ED_USER',		'VARCHAR2(10) NOT NULL'],	# user for the Job or request 
	['ED_CORP',		'VARCHAR2(8)  NOT NULL'],	# Entity related 
	['ED_ACCOUNT',	'VARCHAR2(8)'],				# Administrative account 
	['ED_MOD_ED',	'CHAR'],					# Editing mode (Undef, Batch, Tp, Web, Mail, probinG)
	['ED_JOB_EVT',	'CHAR'],					# Level of the event (Job (default), Spool, Document, Line, Warning, Error, Halt (critic), Reject)
	['ED_OBJ_TYP',	'VARCHAR2(3)'],				# To define the object concerned
	['ED_OBJ_COUNT','INTEGER'],					# Number of objects attached to the event
	['ED_CHILD_TYP','VARCHAR2(3)'],				# To define the object concerned
	['ED_CHILD_ID',	'VARCHAR2(32)'],			#xx ED_IDLDOC Single ID : format YWWWDHHMMSSPPPP.U (compuset se limite ? 16 digits : 15 entiers, 1 decimal)
	['ED_PARENT_ID','VARCHAR2(32)'],			#xx ED_IDLDOC Single ID : format YWWWDHHMMSSPPPP.U (compuset se limite ? 16 digits : 15 entiers, 1 decimal)

	['ED_HOST',		'VARCHAR2(32)'],			# Hostname for input stream of this document (max length for smtp is 31, could be 255...)
	['ED_SOURCE',	'VARCHAR2(128)'],			# Input stream of this document
	['ED_MESSAGE',	'VARCHAR2(256)']			# Treatment message

);

sub create_table_TRACKING {
	my ($dbh, $table, $maxkeys) = @_;

	my $sql = "CREATE TABLE if not exists $table ("
			. join(', ', map {"$$_[0] $$_[1]"} @TRACKER_COLS) . ", ";

	foreach my $i (0 .. $maxkeys) {
		$sql .= " ED_K${i}_NAME VARCHAR2(8),";	# Name of key $i
		$sql .= "ED_K${i}_VAL VARCHAR2(128)";	# Value of key $i
		$sql .= "," unless ($i == $maxkeys);
	}
	$sql .= " ENGINE=MyISAM " if (_db_check_driver_name($dbh) eq "mysql");
	$sql .= " )";
	&logger (7, $sql);
	$dbh->do(_sql_fixup($dbh, $sql)) or &logger (4, $dbh->errstr);
	
	$sql = "CREATE INDEX `ix.$VERSION.$table` ON $table "
			." (ED_TSTAMP);";
	&logger (7, $sql);
	$dbh->do(_sql_fixup($dbh, $sql)) or &logger (4, $dbh->errstr ) if (_db_check_driver_name($dbh) ne "SQLite");
	
}


sub _drop_table {
	my ($dbh, $table) = @_;

	$dbh->do("DROP TABLE $table") or &logger (4, $dbh->errstr);
}


sub historicize_table ($$$){
	my ($dbh, $table, $suffixe) = @_;
	my $table_cible =$table."_".$suffixe;
		
	copy_table ($dbh, $table, $table_cible, '-create');	

	my $sql = "TRUNCATE TABLE $table"; # LA CA DEVIENT UN 'MOVE'
	&logger (7, $sql);

	$dbh->do($sql, undef) or die &logger (-1, $dbh->errstr);	
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
	my $table = "EDTK_ADMIN";

	my $sql = "CREATE TABLE if not exists $table ";
	$sql .= "( ED_ACTION_DATE     DATE NOT NULL";
	$sql .= ", ED_ACTION_PID      INTEGER NOT NULL";	  
	$sql .= ", ED_ACTION_STATUS   VARCHAR2(16)";	  
	$sql .= ", ED_ACTION_DURATION INTEGER";	  
	$sql .= ", ED_OEDTK_RELEASE   VARCHAR2(8) NOT NULL";	  
	$sql .= ", PRIMARY KEY (ED_ACTION_DATE)";
	$sql .= " )";
	&logger (7, $sql);

	$dbh->do(_sql_fixup($dbh, $sql)) or &logger (4, $dbh->errstr);
}


sub create_table_ID {
	my $dbh = shift;
	my $table = "EDTK_ID";

	my $sql = "CREATE TABLE if not exists $table ";
	$sql .= "( ED_ID_DATE       DATE NOT NULL";					# 2021-05-19
	$sql .= ", ED_ID_VALUE      VARCHAR2(25) UNIQUE";	  
	$sql .= ", ED_ID_CHANEL_OUT VARCHAR2(32)";	  
	$sql .= ", PRIMARY KEY (ED_ID_VALUE)";
	$sql .= " )";
	$sql .= " ENGINE=MyISAM " if (_db_check_driver_name($dbh) eq "mysql");

	&logger (7, $sql);

	$dbh->do(_sql_fixup($dbh, $sql)) or &logger (4, $dbh->errstr);
	
	$sql = "CREATE INDEX `ix.$VERSION.ED_ID_DATE` ON $table (`ED_ID_DATE`);";
	&logger (7, $sql);
	$dbh->do(_sql_fixup($dbh, $sql)) or &logger (4, $dbh->errstr );

}



sub create_table_FILIERES {
	my $dbh = shift;
	my $table = "EDTK_FILIERES";

	my $sql = "CREATE TABLE if not exists $table ";
	$sql .= "( ED_IDFILIERE VARCHAR2(5) UNIQUE";	# 
	$sql .= ", ED_PRIORITE INTEGER UNIQUE";			# 
	$sql .= ", ED_IDMANUFACT VARCHAR2(16)";	  
	$sql .= ", ED_DESIGNATION VARCHAR2(64)";		# 
	$sql .= ", ED_ACTIF CHAR NOT NULL";				# Flag indiquant si la filiere est active ou pas 
	$sql .= ", ED_TYPED CHAR NOT NULL";				# 
	$sql .= ", ED_MODEDI CHAR NOT NULL";			# 
	$sql .= ", ED_IDGPLOT VARCHAR2(16) NOT NULL";	# 
	$sql .= ", ED_NBBACPRN INTEGER NOT NULL";		# 
	$sql .= ", ED_NBENCMAX INTEGER";
	$sql .= ", ED_MINFEUIL_L INTEGER"; 
	$sql .= ", ED_MAXFEUIL_L INTEGER"; 
	$sql .= ", ED_FEUILPLI INTEGER";
	$sql .= ", ED_MINPLIS INTEGER";
	$sql .= ", ED_MAXPLIS INTEGER NOT NULL";
	$sql .= ", ED_POIDS_PLI INTEGER";				# poids maximum du pli dans la filiere
	$sql .= ", ED_REF_ENV VARCHAR2(8) NOT NULL";
	$sql .= ", ED_FORMFLUX VARCHAR2(3) NOT NULL";
	$sql .= ", ED_SORT VARCHAR2(128) NOT NULL";
	$sql .= ", ED_DIRECTION VARCHAR2(4) NOT NULL";
	$sql .= ", ED_POSTCOMP VARCHAR2(8) NOT NULL";
	$sql .= ", PRIMARY KEY (ED_IDFILIERE, ED_PRIORITE)";
	$sql .= " )";
	&logger (7, $sql);

	$dbh->do(_sql_fixup($dbh, $sql)) or &logger (4, $dbh->errstr);
}


sub create_table_LOTS {
	my $dbh = shift;
	my $table = "EDTK_LOTS";

	my $sql = "CREATE TABLE if not exists $table ";
	$sql .= "( ED_IDLOT VARCHAR2(8) NOT NULL";		# rendre UNIQUE ? -> ALTER table EDTK_LOTS modify ED_IDLOT VARCHAR2(8) NOT NULL
	$sql .= ", ED_PRIORITE INTEGER   UNIQUE"; 		#
	$sql .= ", ED_IDAPPDOC VARCHAR2(20)";			#
	$sql .= ", ED_REFIDDOC VARCHAR2(20) NOT NULL";	# 
	$sql .= ", ED_CPDEST VARCHAR2(10)"; 			# 
	$sql .= ", ED_FILTER VARCHAR2(64)";				#
	$sql .= ", ED_REFENC VARCHAR2(32)";				#
	$sql .= ", ED_GROUPBY VARCHAR2(16)"; 
	$sql .= ", ED_LOTNAME VARCHAR2(64) NOT NULL";	#
	$sql .= ", ED_IDGPLOT VARCHAR2(16) NOT NULL";	
	$sql .= ", ED_IDMANUFACT VARCHAR2(16) NOT NULL";	
	$sql .= ", ED_CONSIGNE VARCHAR2(250) ";			#
	$sql .= ", PRIMARY KEY (ED_IDLOT, ED_PRIORITE)" ;
	$sql .= " )";
	&logger (7, $sql);

	$dbh->do(_sql_fixup($dbh, $sql)) or &logger (4, $dbh->errstr);
}


sub create_table_REFIDDOC {
	my $dbh = shift;
	my $table = "EDTK_REFIDDOC";

	my $sql = "CREATE TABLE if not exists $table ";
	$sql .= "( ED_REFIDDOC VARCHAR2(20) UNIQUE"; 
	$sql .= ", ED_CORP VARCHAR2(8) NOT NULL";		# Entity related to the document
	$sql .= ", ED_CATDOC CHAR NOT NULL";  
	$sql .= ", ED_PORTADR CHAR NOT NULL";  
	$sql .= ", ED_MASSMAIL CHAR NOT NULL";
	$sql .= ", ED_EDOCSHARE CHAR NOT NULL";  
	$sql .= ", ED_TYPED CHAR NOT NULL";  
	$sql .= ", ED_MODEDI CHAR NOT NULL";  
	$sql .= ", ED_PGORIEN VARCHAR2(2)";
	$sql .= ", ED_FORMATP VARCHAR2(2)"; 
	$sql .= ", ED_REFIMP_P1 VARCHAR2(16)"; 
	$sql .= ", ED_REFIMP_PS VARCHAR2(16)"; 
	$sql .= ", ED_REFIMP_REFIDDOC VARCHAR2(64)"; 
	$sql .= ", ED_MAIL_REFERENT VARCHAR2(300)";		# referent mail for doc validation
	$sql .= ", PRIMARY KEY (ED_REFIDDOC, ED_CORP, ED_CATDOC)";
	$sql .= " )";
	&logger (7, $sql);

	$dbh->do(_sql_fixup($dbh, $sql)) or &logger (4, $dbh->errstr);
}


sub create_table_SUPPORTS {
	my $dbh = shift;
	my $table = "EDTK_SUPPORTS";

	my $sql = "CREATE TABLE if not exists $table ";
	$sql .= "( ED_REFIMP VARCHAR2(16) UNIQUE";	# 
	$sql .= ", ED_TYPIMP CHAR NOT NULL";  
	$sql .= ", ED_FORMATP VARCHAR2(2) NOT NULL";
	$sql .= ", ED_POIDSUNIT INTEGER NOT NULL";  
	$sql .= ", ED_FEUIMAX INTEGER";  
	$sql .= ", ED_POIDSMAX INTEGER";  
	$sql .= ", ED_BAC_INSERT INTEGER";  
	$sql .= ", ED_COPYGROUP VARCHAR2(16)";
	$sql .= ", ED_OPTCTRL VARCHAR2(8)"; 
	$sql .= ", ED_DEBVALID VARCHAR2(8)"; 
	$sql .= ", ED_FINVALID VARCHAR2(8)"; 
	$sql .= ", PRIMARY KEY (ED_REFIMP)";
	$sql .= " )";
	&logger (7, $sql);

	$dbh->do(_sql_fixup($dbh, $sql)) or &logger (4, $dbh->errstr);
}


our @DISTRIB_COLS = (
	['ED_IDLDOC',	'VARCHAR2(25) NOT NULL'],# Identifiant du document dans le lot de mise en page ED_SNGL_ID porté à 25
	['ED_IDSEQPG',	'INTEGER NOT NULL'],	 # Numéro de séquence de page [doc] dans le lot de mise en page
	['ED_SEQDOC',	'INTEGER NOT NULL'],	 # Numéro de séquence du document dans le lot
	['ED_IDJOB',	'VARCHAR2(25) NOT NULL'],# Identifiant du Job

	['ED_IDLOT',	'VARCHAR2(8)'],			# identifiant du lot
	['ED_SEQLOT',	'VARCHAR2(7)'],			# identifiant du lot de mise sous plis (sous-lot)
	['ED_DTLOT',	'VARCHAR2(10)'],		# date de la création du lot de mise sous plis
	['ED_IDFILIERE','VARCHAR2(5)'],			# identifiant de la filière de production
	['ED_SEQPGDOC',	'INTEGER'],				# numéro de séquence de page dans le document
	['ED_NBPGDOC',	'INTEGER'],				# nombre de page (faces) du document

	# ADD
	['ED_WORKFLOW', 'VARCHAR2(32)'],		# Workflow sur lequel on a produit les metadonnées	++ NEW ++
	['ED_CHANEL_OUT','VARCHAR2(32)'],		# Canal de distribution/Output						++ NEW ++
	
	['ED_IDGED', 	'VARCHAR2(25)']

);


sub create_table_DISTRIB {
	my ($dbh, $table) = @_;

	my $sql = "CREATE TABLE if not exists $table ("
			. join(', ', map {"$$_[0] $$_[1]"} @DISTRIB_COLS) 
#			. ", PRIMARY KEY (ED_IDLDOC, ED_SEQDOC, ED_IDSEQPG, ED_IDJOB, ED_CHANEL_OUT)" 	
			. " )";
	$sql .= " ENGINE=MyISAM " if (_db_check_driver_name($dbh) eq "mysql");
	&logger (7, $sql);

	$dbh->do(_sql_fixup($dbh, $sql)) or &logger (4, $dbh->errstr);
	
#	$sql = "CREATE INDEX `ix_ED_DTLOT_$table` ON $table (ED_DTLOT);";
	$sql = "CREATE INDEX `ix.$VERSION.$table` ON $table "
			." (ED_IDLDOC, ED_SEQDOC, ED_IDSEQPG, ED_IDJOB, ED_CHANEL_OUT, ED_DTLOT);";
	&logger (7, $sql);
	$dbh->do(_sql_fixup($dbh, $sql)) or &logger (4, $dbh->errstr );

}
# SHOW CREATE TABLE tablename


our @AGREGE_COLS = (
	['ED_SOURCE',	'VARCHAR2(128)'],				# Input stream of this document
	['ED_CHANEL_OUT','VARCHAR2(32)'],				# Canal de distribution/Output						
	['ED_REFIDDOC',	'VARCHAR2(25) NOT NULL'],		# identifiant dans le référentiel de document
	['ED_IDPRODUCT','VARCHAR2(8)'],					# Identifiant de Produit							
	['ED_DTEDTION',	'VARCHAR2(8) NOT NULL'],		# date d'édition, celle qui figure sur le document
	['ED_CNTD_IDLDOC',	'INTEGER NOT NULL'],		# count distinct des Identifiants de documents
	['ED_CNT_IDSEQPG',	'INTEGER NOT NULL'],	 	# count séquence de page [doc] dans le lot de mise en page
	['ED_DTLOT',	'VARCHAR2(10)'],				# date de la création du lot de mise sous plis
	['ED_IDLOT',	'VARCHAR2(8)'],					# identifiant de lot
	['ED_IDJOB',	'VARCHAR2(25) NOT NULL'],		# Identifiant du Job
	['ED_TSTAMP',	'VARCHAR2(14) NOT NULL']		# Timestamp of event # VOIR COMMENT UPGRADE VA GERER LES DIFERENCES DE NB DE CHAMPS

);


sub create_table_AGREGE {
	my ($dbh) = @_;
	my $table = "EDTK_AGREGE";

	my $sql = "CREATE TABLE if not exists $table ("
			. join(', ', map {"$$_[0] $$_[1]"} @AGREGE_COLS) 
#			. ", PRIMARY KEY (ED_SOURCE, ED_CHANEL_OUT, ED_REFIDDOC, ED_IDPRODUCT, ED_DTEDTION, ED_DTLOT, ED_IDLOT, ED_IDJOB)"
			. " )";
	$sql .= " ENGINE=MyISAM " if (_db_check_driver_name($dbh) eq "mysql");
	&logger (7, $sql);

	$dbh->do(_sql_fixup($dbh, $sql)) or &logger (4, $dbh->errstr );
	
	$sql = "CREATE INDEX `ix.$VERSION.$table` ON $table "
			." (ED_SOURCE, ED_CHANEL_OUT, ED_REFIDDOC, ED_IDPRODUCT, ED_DTEDTION, ED_DTLOT, ED_IDLOT);";
#	$sql = "CREATE INDEX `ix_ED_AGREGE` ON $table (ED_SOURCE, ED_CHANEL_OUT, ED_REFIDDOC, ED_IDPRODUCT, ED_DTEDTION, ED_DTLOT);";
	&logger (7, $sql);
	$dbh->do(_sql_fixup($dbh, $sql)) or &logger (4, $dbh->errstr );

}


sub create_table_PARA {
	my $dbh = shift;
	my $table = "EDTK_TEST_PARA";

	my $sql = "CREATE TABLE if not exists $table ";
	$sql .= "( ED_PARA_REFIDDOC VARCHAR2(20) NOT NULL"; 
	$sql .= ", ED_PARA_CORP VARCHAR2(8) NOT NULL";		# Entity related to the document
	$sql .= ", ED_ID       INTEGER UNIQUE";				#
	$sql .= ", ED_TSTAMP   VARCHAR2(14) NOT NULL";		# Timestamp of event
	$sql .= ", ED_TEXTBLOC VARCHAR2(512)";
	$sql .= ", PRIMARY KEY (ED_PARA_REFIDDOC, ED_PARA_CORP, ED_ID)";
	$sql .= " )";
	&logger (7, $sql);

	$dbh->do(_sql_fixup($dbh, $sql)) or &logger (4, $dbh->errstr);
}


sub create_table_DATAGROUPS {
	my $dbh = shift;
	my $table = "EDTK_TEST_DATAGROUPS";

	my $sql = "CREATE TABLE if not exists $table ";
	$sql .= "( ED_DGPS_REFIDDOC VARCHAR2(20) NOT NULL"; 
	$sql .= ", ED_ID   INTEGER NOT NULL";
	$sql .= ", ED_DATA VARCHAR2(64)";
	$sql .= " )";
	&logger (7, $sql);

	$dbh->do(_sql_fixup($dbh, $sql)) or die &logger (-1, $dbh->errstr);
	
	$sql = "CREATE INDEX `ix.$VERSION.$table` ON $table "
			." (ED_DGPS_REFIDDOC, ED_ID);";
	&logger (7, $sql);
	$dbh->do(_sql_fixup($dbh, $sql)) or &logger (4, $dbh->errstr );

}


sub create_table_ACQUIT {
	my $dbh = shift;
	my $table = "EDTK_ACQ";

	my $sql = "CREATE TABLE if not exists $table ";
	$sql .= "( ED_SEQLOT  VARCHAR2(7)  NOT NULL";	# identifiant du lot de mise sous plis (sous-lot) update edtk_acq set ed_seqlot = substr('1'|| ed_seqlot,-7);
	$sql .= ", ED_LOTNAME VARCHAR2(16) NOT NULL";	# 
	$sql .= ", ED_DTPOST  VARCHAR2(8)  NOT NULL";	# date de remise en poste
	$sql .= ", ED_DTPRINT VARCHAR2(8)";				# date de d'impression
	$sql .= ", ED_NBFACES INTEGER   	NOT NULL";	# nombre de faces du lot (faces comptables, comprenant les faces blanches de R°/V°)
	$sql .= ", ED_NBPLIS  INTEGER 		NOT NULL";	# nombre de documents du pli
	$sql .= ", ED_DTPOST2 VARCHAR2(8)";				# date de remise en poste		
	$sql .= ", ED_DTCHECK VARCHAR2(8)";				# date de check
	$sql .= ", ED_STATUS  VARCHAR2(4)";				# check status
	$sql .= ", PRIMARY KEY (ED_SEQLOT, ED_LOTNAME, ED_DTPOST)";
	$sql .= " )";
	$sql .= " ENGINE=MyISAM " if (_db_check_driver_name($dbh) eq "mysql");

	&logger (7, $sql);

	$dbh->do(_sql_fixup($dbh, $sql)) or &logger (4, $dbh->errstr);
}


our @INDEX_COLS = (
#	NB : " PRIMARY KEY (ED_IDLDOC, ED_SEQDOC, ED_IDSEQPG, ED_IDJOB)"

	# SECTION COMPOSITION DE LENGINE=[MyISAM]'INDEX
	['ED_REFIDDOC',	'VARCHAR2(25) NOT NULL'],# identifiant dans le référentiel de document
	['ED_IDLDOC',	'VARCHAR2(25) NOT NULL'],# Identifiant du document dans le lot de mise en page ED_SNGL_ID porté à 25
	['ED_IDSEQPG',	'INTEGER NOT NULL'],	 # Numéro de séquence de page [doc] dans le lot de mise en page
	['ED_SEQDOC',	'INTEGER NOT NULL'],	 # Numéro de séquence du document dans le lot
	['ED_IDJOB',	'VARCHAR2(25) NOT NULL'],# Identifiant du Job 

	# SECTION DOCUMENT
	['ED_DTEDTION',	'VARCHAR2(8) NOT NULL'],# date d'édition, celle qui figure sur le document
	['ED_CPDEST',	'VARCHAR2(10)'],		# Code postal Destinataire
	['ED_VILLDEST',	'VARCHAR2(38)'],		# Ville destinataire
	['ED_IDDEST',	'VARCHAR2(25)'],		# Identifiant du destinataire dans le système de gestion
	['ED_NOMDEST',	'VARCHAR2(38)'],		# Nom destinataire
	['ED_IDEMET',	'VARCHAR2(10)'],		# identifiant de l'émetteur
	['ED_TYPPROD',	'VARCHAR(16)'],			# type de production associée au lot 
	['ED_PORTADR',	'CHAR'],				# indicateur de document porte adresse
	['ED_ADRLN1',	'VARCHAR2(38)'],		# ligne d'adresse 1
	['ED_CLEGED1',	'VARCHAR2(32)'],		# clef pour système d'archivage
	['ED_ADRLN2',	'VARCHAR2(38)'],		# ligne d'adresse 2
	['ED_CLEGED2',	'VARCHAR2(20)'],		# clef pour système d'archivage
	['ED_ADRLN3',	'VARCHAR2(38)'],		# ligne d'adresse 3
	['ED_CLEGED3',	'VARCHAR2(20)'],		# clef pour système d'archivage
	['ED_ADRLN4',	'VARCHAR2(38)'],		# ligne d'adresse 4
	['ED_CLEGED4',	'VARCHAR2(20)'],		# clef pour système d'archivage
	['ED_ADRLN5',	'VARCHAR2(38)'],		# ligne d'adresse 5
	['ED_CORP',		'VARCHAR2(8) NOT NULL'],# entité émettrice de la page
	['ED_DOCLIB',	'VARCHAR2(32)'],		# merge library compuset associée ? la page
	['ED_REFIMP',	'VARCHAR2(16)'],		# référence de pré-imprimé ou d'imprimé ou d'encart
	['ED_ADRLN6',	'VARCHAR2(38)'],		# ligne d'adresse 6
	['ED_SOURCE',	'VARCHAR2(8) NOT NULL'],# Source de l'index ou entité de ED_CORP
	['ED_OWNER',	'VARCHAR2(10)'],		# propriétaire du document (utilisation en gestion / archivage de documents)
	['ED_HOST',		'VARCHAR2(32)'],		# Hostname de la machine d'origine de cette entrée
	['ED_IDIDX',	'VARCHAR2(8) NOT NULL'],# identifiant de l'index
	['ED_CATDOC',	'CHAR'],				# catégorie de document
	['ED_CODRUPT',	'VARCHAR2(8)'],			# code forçage de rupture

	# SECTION LOTISSEMENT DE L'INDEX 
	['ED_IDLOT',	'VARCHAR2(8)'],			# identifiant du lot
	['ED_SEQLOT',	'VARCHAR2(7)'],			# identifiant du lot de mise sous plis (sous-lot)
	['ED_DTLOT',	'VARCHAR2(10)'],		# date de la création du lot de mise sous plis
	['ED_IDFILIERE','VARCHAR2(5)'],			# identifiant de la filière de production
	['ED_SEQPGDOC',	'INTEGER'],				# numéro de séquence de page dans le document
	['ED_NBPGDOC',	'INTEGER'],				# nombre de page (faces) du document
	['ED_POIDSUNIT','INTEGER'],				# poids de l'imprim? ou de l'encart en mg
	['ED_NBENC',	'INTEGER'],				# nombre d'encarts du doc
	['ED_ENCPDS',	'INTEGER'],				# poids des encarts du doc
	['ED_BAC_INSERT','INTEGER'],			# Appel de bac ou d'insert

	# SECTION EDITION DE L'INDEX
	['ED_TYPED',	'CHAR'],				# type d'édition (Noir / Black / Full Color)
	['ED_MODEDI',	'CHAR'],				# mode d'édition (Simplex / Duplex) => Recto / Verso 
	['ED_FORMATP',	'VARCHAR2(2)'],			# format papier  (A4 / A3 ...)
	['ED_PGORIEN',	'VARCHAR2(2)'],			# orientation de l'édition (POrtrait / ReversePortrait  / LAndscape / Reverse Landscape)
	['ED_FORMFLUX',	'VARCHAR2(3)'],			# format du flux d'édition (AFP / PDF / ...)
#	['ED_FORMDEF',	'VARCHAR2(8)'],			# Formdef AFP
#	['ED_PAGEDEF',	'VARCHAR2(8)'],			# Pagedef AFP
#	['ED_FORMS',	'VARCHAR2(8)'],			# Forms 

	# SECTION PLI DE L'INDEX
	['ED_IDPLI',	'INTEGER'],				# identifiant du pli
	['ED_NBDOCPLI',	'INTEGER NOT NULL'],	# nombre de documents du pli
	['ED_NUMPGPLI',	'INTEGER NOT NULL'],	# numéro de la page (face) dans le pli
	['ED_NBPGPLI',	'INTEGER'],				# nombre de pages (faces) du pli
	['ED_NBFPLI',	'INTEGER'],				# nombre de feuillets du pli
	['ED_LISTEREFENC','VARCHAR2(64)'],		# liste des encarts du pli
	['ED_PDSPLI',	'INTEGER'],				# poids du pli en mg
	['ED_TYPOBJ',	'CHAR'],				# type d'objet dans le pli	xxxxxx  conserver ?
	['ED_STATUS',	'VARCHAR2(8)'],			# status de lotissement (date de remise en poste ou status en fonction des versions)
	['ED_DTPOSTE',	'VARCHAR2(8)'],			# à supprimer : status de lotissement (date de remise en poste ou status en fonction des versions)

	# ADD
	['ED_WORKFLOW', 'VARCHAR2(32)'],	    # Workflow sur lequel on a produit les metadonnées	++ NEW ++
	['ED_CHANEL_OUT', 'VARCHAR2(32)'],		# Canal de distribution/Output						++ NEW ++
	['ED_COUNTRY',	'VARCHAR2(5)'],			# Code pays du Destinataire							++ NEW ++
	['ED_IDCONTRACT','VARCHAR2(16)'],		# Identifiant de Contrat							++ NEW ++
	['ED_IDPRODUCT','VARCHAR2(8)']			# Identifiant de Produit							++ NEW ++

);



sub create_table_OUTMNGR {
	my ($dbh, $table) = @_;

	my $sql = "CREATE TABLE if not exists $table ("
			. join(', ', map {"$$_[0] $$_[1]"} @INDEX_COLS) . ", "
			. " PRIMARY KEY (ED_IDLDOC, ED_SEQDOC, ED_IDSEQPG, ED_IDJOB)"
			. " )";
	$sql .= " ENGINE=MyISAM " if (_db_check_driver_name($dbh) eq "mysql");
	&logger (7, $sql);

	$dbh->do(_sql_fixup($dbh, $sql)) or &logger (4, $dbh->errstr );

	$sql = "CREATE INDEX `ix.$VERSION.$table` ON $table "
			." (ED_DTEDTION, ED_SEQLOT, ED_TYPPROD);";
	&logger (7, $sql);
	$dbh->do(_sql_fixup($dbh, $sql)) or &logger (4, $dbh->errstr );

#	$sql = "CREATE INDEX `ix_ED_DTEDTION_$table` ON $table (`ED_DTEDTION`);";
#	$dbh->do(_sql_fixup($dbh, $sql)) or &logger (4, $dbh->errstr );
#
#	$sql = "CREATE INDEX `ix_ED_SEQLOT_$table` ON $table (`ED_SEQLOT`);";
#	$dbh->do(_sql_fixup($dbh, $sql)) or &logger (4, $dbh->errstr );
#
#	$sql = "CREATE INDEX `ix_ED_TYPPROD_$table` ON $table (`ED_TYPPROD`);";
#	$dbh->do(_sql_fixup($dbh, $sql)) or &logger (4, $dbh->errstr );
	
}


sub create_lot_sequence {
	# UTILISER POUR LA CREATION DE LOT DANS Outmngr.pm
	my $dbh = shift;

	$dbh->do('CREATE SEQUENCE EDTK_IDLOT MINVALUE 0 MAXVALUE 999 CYCLE') or &logger (4, $dbh->errstr);

# Tester si cette évolution est plus universelle :	
#CREATE SEQUENCE EDTK_IDLOT
#START WITH 0
#INCREMENT BY 1
#MAXVALUE 999
#CYCLE;
	
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
		"EDTK_ACQ",
		"EDTK_ADMIN",
		"EDTK_AGREGE",
		"EDTK_FILIERES",
		"EDTK_ID",
		"EDTK_LOTS",
		"EDTK_REFIDDOC",
		"EDTK_SUPPORTS",
#		"EDTK_DATAGROUPS",
#		"EDTK_PARA",
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
		my $sql = sprintf ("ALTER TABLE %s RENAME TO "."$sep"."%s_%s"."$sep"." ;", $table, $stamp, $table);
		&logger (7, $sql);
		#$p{DBH}->do(                   $sql, undef, )  or die &logger( -1, "ERROR: can't $sql");	
		$p{DBH}->do(_sql_fixup($p{DBH}, $sql, undef, )) or die &logger( -1, "ERROR: can't $sql");

	}

	# si ok :
	schema_Create($p{DBH});
	
	#si ok :
	foreach my $table (@tListeTables) {
		my $sql = sprintf ("INSERT INTO %s SELECT * FROM "."$sep"."%s_%s"."$sep"." ;", $table, $stamp, $table);
		&logger (7, $sql);
		$p{DBH}->do(_sql_fixup($p{DBH}, $sql, undef, )) or die &logger ( -1, "ERROR: can't $sql");
		my $drop = sprintf ("DROP TABLE "."$sep"."%s_%s"."$sep"." ;", $stamp, $table);
		&logger (7, $drop);
		$p{DBH}->do(_sql_fixup($p{DBH}, $drop, undef, )) or die &logger ( -1, "ERROR: can't $drop");
	}


#INSERT INTO table_destination (colonne1, colonne2, colonne_supplementaire)
#SELECT colonne1, colonne2, 'valeur_par_defaut'
#FROM table_source;

#DECLARE @colonne_supplementaire_presente BIT;
#SET @colonne_supplementaire_presente = (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'table_destination' AND COLUMN_NAME = 'colonne_supplementaire');
#
#IF @colonne_supplementaire_presente = 1
#BEGIN
#    INSERT INTO [table_destination](https://www.google.com/search?q=table_destination) (colonne1, colonne2, colonne_supplementaire)
#    SELECT colonne1, colonne2, 'valeur_par_defaut'
#    FROM [table_source](https://www.google.com/search?q=table_source);
#END
#ELSE
#BEGIN
#    INSERT INTO [table_destination](https://www.google.com/search?q=table_destination) (colonne1, colonne2)
#    SELECT colonne1, colonne2
#    FROM [table_source](https://www.google.com/search?q=table_source);
#END

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
	#$dbh->do('CREATE INDEX ed_seqlot_idx ON ' . $cfg->{'EDTK_DBI_OUTMNGR'} . ' (ED_SEQLOT)');
	create_table_DISTRIB($dbh, $cfg->{'EDTK_DBI_DISTRIB'});
	create_table_DISTRIB($dbh, $cfg->{'EDTK_DBI_DISTRIB_STATS'});

}

sub _db_check_driver_name($){
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

sub admin_optimize_db{
	# EXEMPLE D'APPEL :
	# admin_optimize_db (CFG => $cfg);
	my %p = @_;

	my @tListeTables = (
		"EDTK_ACQ",
		"EDTK_ADMIN",
		"EDTK_AGREGE",
		"EDTK_FILIERES",
		"EDTK_ID",
		"EDTK_LOTS",
		"EDTK_REFIDDOC",
		"EDTK_SUPPORTS",
#		"EDTK_DATAGROUPS",
#		"EDTK_PARA",
		$p{CFG}->{EDTK_DBI_DISTRIB},
		$p{CFG}->{EDTK_DBI_DISTRIB_STATS},
		$p{CFG}->{EDTK_DBI_OUTMNGR},
		$p{CFG}->{EDTK_DBI_OUTMNGR_STATS},
		"EDTK_TRACKING"
	);

	my %hCdeRepair =(
		NC		=> "SELECT * from %s LIMIT 1",
		mysql	=> "REPAIR TABLE %s",
		Oracle	=> "SELECT * from %s LIMIT 1",	# à tester
		PostgreSQL => "SELECT * from %s LIMIT 1"		# à tester
		
		#check table edtk_tracking quick fast;
	);


	my %hCdeOptm =(
		NC		=> "SELECT * from %s LIMIT 1",
		mysql	=> "OPTIMIZE TABLE %s",
		#Oracle	=> "ALTER TABLE %s MOVE",	# à tester
		Oracle	=> "SELECT * from %s LIMIT 1",	# à tester
		PostgreSQL => "VACUUM FULL %s"		# à tester
	);

	my $dbName = _db_check_driver_name($p{DBH});
	my $sql;

	foreach my $table (@tListeTables) {
		# connexion et deconnexion avant et après chaque opération pour ne pas mobiliser la base
		$p{DBH}	= db_connect($p{CFG}, 'EDTK_DBI_DSN');
		$sql = sprintf (($hCdeRepair{$dbName} || "-- %s"), $table);
		&logger (7, $sql);
		$p{DBH}->do(_sql_fixup($p{DBH}, $sql, undef, )) or &logger( 4, "can't repair $table");	
		$p{DBH}->disconnect;

		$p{DBH}	= db_connect($p{CFG}, 'EDTK_DBI_DSN');
		$sql = sprintf (($hCdeOptm{$dbName} || "-- %s"), $table);
		&logger (7, $sql);
		$p{DBH}->do(_sql_fixup($p{DBH}, $sql, undef, )) or &logger( 4, "can't optimize $table");	
		$p{DBH}->disconnect;
	}

1;
}

sub _sql_fixup {
	my ($dbh, $sql) = @_;

	# inverser la logique : standard SQL => spécifique Oracle
	if ($dbh->{'Driver'}->{'Name'} ne 'Oracle') {
		$sql =~ s/VARCHAR2 *(\(\d+\))/VARCHAR$1/g;
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
		my $sql_check="SELECT COUNT(ED_TSTAMP) FROM ".$cfg->{'EDTK_DBI_TRACKING'}." WHERE ED_TSTAMP < ? ";
		my $check	= ($cur_year - $cfg->{'EDTK_ENTIRE_YEARS_KEPT'}) . "0101000000";
		my $sth		= $dbh->prepare($sql_check);

		$sth->execute($check) or &logger (3, "SQL execute failed ".$sth->err."-".$sth->errstr);
		my $result = $sth->fetchrow_array;
		unless ($result){
			&logger (5, "db_backup_agent has nothing to do with ".$cfg->{'EDTK_DBI_TRACKING'});
		} else {
			my $cible = $cfg->{'EDTK_DBI_TRACKING'}."_".$suffixe;
			copy_table ($dbh, $cfg->{'EDTK_DBI_TRACKING'}, $cible, '-create'); 
			&logger (5, "db_backup_agent done with ".$cfg->{'EDTK_DBI_TRACKING'}." for data older than $check.");

			my $sql_clean = "DELETE FROM ".$cfg->{'EDTK_DBI_TRACKING'}." WHERE ED_TSTAMP < ? ";
			$dbh->do($sql_clean, undef, $check) or die $dbh->errstr;	
		}
	}

	{ # isole le block pour les variables locales
		# CHECK IF EDTK_DBI_OUTMNGR HAS OLD STATS
		my $sql_check="SELECT COUNT(ED_DTEDTION) FROM ".$cfg->{'EDTK_DBI_OUTMNGR'}." WHERE ED_DTEDTION < ? ";
		my $check	= ($cur_year - $cfg->{'EDTK_ENTIRE_YEARS_KEPT'}) . "0101";
		my $sth		= $dbh->prepare($sql_check);

		$sth->execute($check) or &logger (3, "SQL execute failed ".$sth->err."-".$sth->errstr);
		my $result = $sth->fetchrow_array;
		unless ($result){
			&logger (5, "db_backup_agent has nothing to do with ".$cfg->{'EDTK_DBI_OUTMNGR'});
		} else {
			my $cible = $cfg->{'EDTK_DBI_OUTMNGR'}."_".$suffixe;
			copy_table ($dbh, $cfg->{'EDTK_DBI_OUTMNGR'}, $cible, '-create'); 

			my $sql_clean = "DELETE FROM ".$cfg->{'EDTK_DBI_OUTMNGR'}." WHERE ED_DTEDTION < ? ";
			$dbh->do($sql_clean, undef, $check) or die $dbh->errstr;	

			&logger (4, "db_backup_agent done with ".$cfg->{'EDTK_DBI_OUTMNGR'}." for data older than $check.");
		}
	}

	{ # isole le block pour les variables locales
		# CHECK IF EDTK_DBI_ACQUIT HAS OLD STATS
		my $sql_check="SELECT COUNT (ED_DTPOST) FROM ".$cfg->{'EDTK_DBI_ACQUIT'}." WHERE ED_DTPOST < ? ";
		my $check	= ($cur_year - $cfg->{'EDTK_ENTIRE_YEARS_KEPT'}) . "0101";
		my $sth		= $dbh->prepare($sql_check);

		$sth->execute($check) or &logger (3, "SQL execute failed ".$sth->err."-".$sth->errstr);
		my $result = $sth->fetchrow_array;
		unless ($result){
			&logger (5, "db_backup_agent has nothing to do with ".$cfg->{'EDTK_DBI_ACQUIT'});
		} else {
			my $cible = $cfg->{'EDTK_DBI_ACQUIT'}."_".$suffixe;
			copy_table ($dbh, $cfg->{'EDTK_DBI_ACQUIT'}, $cible, '-create'); 
	
			my $sql_clean = "DELETE FROM ".$cfg->{'EDTK_DBI_ACQUIT'}." WHERE ED_DTPOST < ? ";
			$dbh->do($sql_clean, undef, $check) or die $dbh->errstr;	

			&logger (4, "db_backup_agent done with ".$cfg->{'EDTK_DBI_ACQUIT'}." for data older than $check.");
		}
	}

1;
}


1;

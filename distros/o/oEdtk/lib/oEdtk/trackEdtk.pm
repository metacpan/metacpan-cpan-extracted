package oEdtk::trackEdtk;

BEGIN {
		use oEdtk::Main; 
		use Config::IniFiles;
		use Sys::Hostname;
		use Digest::MD5 	qw(md5_base64);
		use DBI;
		use Cwd			qw(abs_path);
		use strict;

		use Exporter;
		use vars 		qw($VERSION @ISA  @EXPORT_OK); # @EXPORT %EXPORT_TAGS);
	
		$VERSION		= 0.8051; # à terme cette librairie devrait être reprise par oEdtk::Tracking
		@ISA			= qw(Exporter);
#		@EXPORT		= qw(
#						);

		@EXPORT_OK	= qw(
						ini_Edtk_Conf 		conf_To_Env 
						env_Var_Completion

						init_Tracking 		track_Obj
						define_Mod_Ed		define_Job_Evt
						define_Track_Key 

						edit_Track_Table
						create_Track_Table	prepare_Tracking_Env
						drop_Track_Table
						)

	}

	# 3 méthodes possibles d'alimentation (config edtk.ini -> EDTK_TRACK_MODE) :
	# -1- DB  : suivi directement dans un SGBD (DB)-> ralentissement du traitement de prod (insérer les info de suivi en fin de traitement pour limiter l'impact => END du module ?)
	# -2- FDB : suivi via SQLite -> pas de gestion de plusieurs accès en temps réel => créer 1 fichier db par process (procDB)-> organiser une consolidation des données 
	# -3- LOG : fichiers de suivi à plat -> organiser une consolidation des données
	#
	# ? A VOIR : bug dans la création dynamique du fichier SQLite, on utilise pas le TSTAMP/PROCESS_ID ???

	my $DBI_DNS		="";
	my $DBI_USER	="";
	my $DBI_PASS	="";
	my $TABLENAME	="tracking_oEdtk";

	my $ED_HOST		="";
	my $ED_TSTAMP	="";
	my $ED_PROC		="";
	my $ED_SNGL_ID	="";
	my $ED_USER		="";
	my $ED_SEQ		="";
	my $ED_APP		="";
	my $ED_MOD_ED	="";
	my $ED_JOB_EVT	="";
	my $ED_OBJS		="";
	my @ED_K_NAME;
	my @ED_K_VAL;

	my @TRACKED_OBJ;
	my @DB_USER_COL;

	my $NOK=-1;


sub ini_Edtk_Conf {
	# recherche du fichier de configuration
	# renvoi le chemin au fichier de configuration valide
	my $iniEdtk 	=$INC{'oEdtk/trackEdtk.pm'};
	$iniEdtk		=~s/(trackEdtk\.pm)//;
	$iniEdtk 		.="iniEdtk/edtk.ini";
	my $hostname	=uc ( hostname());

	# OUVERTURE DU FICHIER DE CONFIGURATION
	my $tmpIniEdtk	=$iniEdtk;
	my $confIni;
	while ($tmpIniEdtk ne 'local'){
		if (! (-e $tmpIniEdtk)){die "ERR. config file not found : $tmpIniEdtk\n";}
			$confIni	= Config::IniFiles->new( -file => $tmpIniEdtk, -default => 'DEFAULT');

			$iniEdtk	=$tmpIniEdtk;
			# recherche de la variable iniEdtk dans la section '$hostname' ou par défaut
			#  dans la section 'DEFAULT' (cf méthode new)
			$tmpIniEdtk=$confIni->val( $hostname, 'iniEdtk' );

		# si iniEdtk == fichier courant alors mettre la valeur à local (éviter les boucle infinies)
		if ($tmpIniEdtk eq $iniEdtk) { last; }
	}

	$ENV{EDTK_INIEDTK}	=$iniEdtk;		
return $iniEdtk;
}


sub conf_To_Env ($;$) {
	# charge les sections demandées du fic de config dans la configuration d'environnement
	# en param, passer le chemin d'accès au fichier ini + la section à charger
	# si la section HOSTNAME existe elle surcharge les valeurs de la section
	my $confIni=shift;
	my $section=shift;
	$section ||='DEFAULT';
	
	if (-e $confIni){
	} else {
		die "ERR. config file not found : $confIni\n";
	}

	my $hostname	=uc ( hostname());

	# OUVERTURE DU FICHIER DE CONFIGURATION
	my %hConfIni;
	tie %hConfIni, 'Config::IniFiles',( -file => $confIni );

	# CHARGEMENT DES VALEURS DE LA SECTION
	my %hSection;
 	if (exists $hConfIni{$section}) {
		%hSection =%{$hConfIni{$section}};
	}

	# CHARGEMENT EN SURCHARGE DES VALEURS PROPRES AU HOSTNAME
	my %hHostname;
	if (exists $hConfIni{$hostname}) {
		undef %hSpecific;
		%hHostname =%{$hConfIni{$hostname}};
	} else {
		warn "INFO machine '$hostname' inconnue dans la configuration";
	}
 	%hConfig=(%hSection,%hHostname);
 
	my $self = abs_path($0);
 	$self =~ /([\w\.\-]+)[\/\\]\w+\.\w+$/;
	# DÉFINITION POUR L'ENVIRONNEMENT DE DÉV DE L'APPLICATION/PROGRAMME COURANT
	$hConfig{'EDTK_PRGNAME'} =$1;
	#$hConfig{'EDTK_OPTJOB'}	=$EDTK_OPTJOB;

	# mise en place des variables d'environnement
	while ((my $cle, my $valeur) = each (%hConfig)){
		$valeur ||="";
		$ENV{$cle}=$valeur;
	}
1;
}


sub env_Var_Completion (\$){
	# développe les chemins en remplaçant les variables d'environnement par les valeurs réelles
	# tous les niveaux d'imbrication définis dans les variables d'environnement sont développés
	# nécessite au préalable que les variables d'environnements soient définies
	my $rScript =shift;
	# il peut y avoir des variables dans les variables d'environnement elles mêmes
	while (${$rScript}=~/\$/g) {
		${$rScript}=~s/\$(\w+)/${ENV{$1}}/g;
	}
	${$rScript}=~s/(\/)/\\/g;
1;
}


################################################################################
# PARTIE DEFINITION SUIVI DE PRODUCTION
#
#
	my $DBH;
	my %h_subInsert;
	
	# definition de la méthode d'insertion
	$h_subInsert{'LOG'}=\&subInsert_Log;
	$h_subInsert{'DB'} =\&subInsert_DB;
	$h_subInsert{'FDB'}=\&subInsert_DB;
	$h_subInsert{'none'}=\&noSub;

	my %h_subClose;
	$h_subClose{'DB'} =\&subClose_DB;
	$h_subClose{'FDB'}=\&subClose_DB;


sub prepare_Tracking_Env() {
	my $iniEdtk	=ini_Edtk_Conf();
	conf_To_Env($iniEdtk, 'ENVDESC');
	conf_To_Env($iniEdtk, 'EDTK_DB');
	oe_uc_sans_accents($ENV{EDTK_TRACK_MODE});

1;
}

sub open_Tracking_Env(){
	if ($ENV{EDTK_TRACK_MODE} =~/FDB/i){
		# DB FILE oe_now_time/PROCESS
		$ENV{EDTK_DBI_DNS}=~s/(.+)\.(\w+)$/$1\.$ED_TSTAMP\.$ED_PROC\.$2/;
		warn "INFO tracking to $ENV{EDTK_DBI_DSN}\n";
		create_Track_Table($ENV{EDTK_DBI_DSN});
		open_DBI();
			
	} elsif ($ENV{EDTK_TRACK_MODE} =~/LOG/i){
		# log

	} elsif ($ENV{EDTK_TRACK_MODE} =~/DB/i){
		# DB connexion tracking
		open_DBI();

	} else {
		$ENV{EDTK_TRACK_MODE} = "none";
		
	}

	if (!($h_subInsert{$ENV{EDTK_TRACK_MODE}}) && !($h_subCreate{$ENV{EDTK_TRACK_MODE}})){
		warn "INFO $ENV{EDTK_TRACK_MODE} undefined - tracking halted\n";
		$ENV{EDTK_TRACK_MODE} ="none";
	}

1;
}

sub open_DBI(){
	my $dbargs = {	AutoCommit => 	$ENV{EDTK_DBI_AutoCommit},
			RaiseError => 	$ENV{EDTK_DBI_RaiseError},
			PrintError => 	$ENV{EDTK_DBI_PrintError}};

	$DBH = DBI->connect(		$ENV{EDTK_DBI_DSN},
					$ENV{EDTK_DBI_DSN_USER},
					$ENV{EDTK_DBI_DSN_PASS}
			#		,$dbargs
				)
			or die "ERR no connexion to $ENV{EDTK_DBI_DSN} " . DBI->errstr;

1;
}


sub init_Tracking(;@){
	my $Mod_Ed	=shift;
	my $Typ_Job	=shift;
	my $Job_User	=shift;
	my @Track_Key	=@_;
	define_Mod_Ed	($Mod_Ed);	# U(ndef) by default 
	define_Job_Evt ($Typ_Job);	# S(pool) by default
	define_Job_User($Job_User);	# user job request, by default 'None'
	$ED_HOST	=hostname();
	$ED_TSTAMP	=oe_now_time();
	$ED_PROC	=$$;
	$ED_SEQ		=0;			# (dynamic, private)
	$ED_SNGL_ID	= md5_base64($ED_HOST.$ED_TSTAMP.$ED_PROC);

	&prepare_Tracking_Env();
	&open_Tracking_Env();
	
	my $indice =0;
	foreach my $element (@Track_Key) {
		define_Track_Key($element, $indice++);	# default key for indiced col_name
	}

	$0 =~/([\w-]+)[\.plmex]*$/;
	$1 ? $ED_APP ="application" : $ED_APP =$1;

	$ED_OBJS		=1;		## default insert unit count (dynamic)

	warn "INFO tracking init ( track mode : $ENV{EDTK_TRACK_MODE}, edition mode : $ED_MOD_ED, job type : $ED_JOB_EVT, user : $ED_USER, optional Keys : @ED_K_NAME )\n";

return $ED_SNGL_ID;
}


sub track_Obj (;@){
	# track_Obj ([$ED_OBJS, $ED_JOB_EVT, @ED_K_VAL])
	#  $ED_OBJS (optionel) : nombre d'unité de l'objet (1 par defaut)
	#  $ED_JOB_EVT (optio) : evenement en question (cf define_Job_Evt)
	#  @ED_K_VAL(optionel) : valeurs des clefs optionnels définies avec init_Tracking (même ordre)

	$ED_SEQ++;
	$ED_OBJS 		=shift;
	$ED_OBJS		||=1;
	define_Job_Evt (shift);
	@ED_K_VAL =@_;

	undef @TRACKED_OBJ;
	push (@TRACKED_OBJ, oe_now_time());
	push (@TRACKED_OBJ, $ED_USER);
	push (@TRACKED_OBJ, $ED_SEQ);
	push (@TRACKED_OBJ, $ED_SNGL_ID);
	push (@TRACKED_OBJ, $ED_APP);
	push (@TRACKED_OBJ, $ED_MOD_ED);

	push (@TRACKED_OBJ, $ED_JOB_EVT);
	push (@TRACKED_OBJ, $ED_OBJS);
	undef @DB_USER_COL;
	for (my $i=0 ; $i <= $#ED_K_VAL ; $i++) {
		push (@TRACKED_OBJ, $ED_K_NAME[$i]	|| "");
		push (@TRACKED_OBJ, $ED_K_VAL[$i]	|| "");
		push (@DB_USER_COL, "ED_K${i}_NAME");
		push (@DB_USER_COL, "ED_K${i}_VAL");
	}
	
	&{$h_subInsert{$ENV{EDTK_TRACK_MODE}}}
		or die "ERR. undefined EDTK_TRACK_MODE -> $ENV{EDTK_TRACK_MODE}\n";
1;
}


sub define_Mod_Ed ($) {
	# Printing Mode : looking for one of the following :
	#	 Undef (default), Batch, Tp, Web, Mail
	my $value	 =shift;

	if ($value) { $ED_MOD_ED =$value }; 
	$ED_MOD_ED	=~ /([NBTWM])/;
	$ED_MOD_ED	=$1;
	$ED_MOD_ED	||="U"; 	# Undef by default

return $ED_MOD_ED;
}


sub define_Job_Evt ($) {
	# Job Event : looking for one of the following : 
	#	 Job (default), Spool, Document, Line, Warning, Error, Halt (critic), Reject
	my $value	 =shift;

	if ($value) { $ED_JOB_EVT =$value };
	$ED_JOB_EVT	=~ /([JSDLWEHR])/;
	$ED_JOB_EVT	=$1;
	$ED_JOB_EVT	||="J"; 	# Job by default

return $ED_JOB_EVT;
}


sub define_Job_User ($) {
	# USER JOB REQUEST : LOOKING FOR ONE OF THE FOLLOWING :
	#	 None (default), user Id (max 10 alphanumerics)
	my $value	 =shift;

	if ($value=~/(\w{1,10})/) {
		$ED_USER	=$1;	
	} else {
		$ED_USER	="None";
	}

return $ED_USER;
}


sub define_Track_Key ($;$) {
	# TO DEFINE THE COL_NAME OF THE N INDICED TRACKING KEY
	my $value	 =shift;
	my $indice =shift;
	$indice 	||=0;

	if (!defined $ENV{EDTK_MAX_USER_KEY}) {	
		warn "INFO : tracking key undefined\n";
		return 0;

	} elsif ($indice gt ($ENV{EDTK_MAX_USER_KEY}-1)) { 
		warn "INFO : tracking key not allowed (limit is $ENV{EDTK_MAX_USER_KEY})\n";
		return 0;

	} elsif (length ($value) > 5) {
		$value=~s/^(\w{5})(.*)/$1/;
		warn "INFO : redefined col as '$value'";
	}
	if ($value) { $ED_K_NAME[$indice] =$value; }

	$ED_K_NAME[$indice] =~ s/\s/\_/g;
	oe_uc_sans_accents($ED_K_NAME[$indice]);

return $ED_K_NAME[$indice];
}


sub subInsert_Log(){
	# DANS LE CAS D'UN SUIVI SOUS FORME DE FICHIERS LOG
	# à compléter avec l'utisation du remplaçant du Logger

	my $request	=join (", ", @TRACKED_OBJ);
	warn "$request\n";

1;
}


sub subInsert_DB() {
	# constructuction de la commande SQL pour insertion dans une base DBI (file/DB)

	my $request="insert into $ENV{EDTK_DBI_TRACKING}"; 
	$request	.=" (";
	$request	.="ED_TSTAMP, ED_USER, ED_SEQ, ED_SNGL_ID, ED_APP, ED_MOD_ED, ED_JOB_EVT, ED_OBJ_COUNT";
	if (@DB_USER_COL) {
		$request	.=", ";
		$request	.=join (", ", @DB_USER_COL);	
	}
	$request	.=" ) values ('";
#	FORMATAGE DE LA DATE POUR LES SGBD 
#	$request	.=sprintf ("to_date('%014.f', 'YYYYMMDDHH24MISS'), '", shift @TRACKED_OBJ);
	$request	.=join ("', '", @TRACKED_OBJ);
	$request	.="')";

	$DBH->do($request);
	if ($DBH->err()) {
		warn "INFO ".$DBI::errstr."\n";
	}	

#	$DBH->commit();	# nécessaire si AutoCommit  vaut 0
#	$DBH->disconnect();
#	if ($DBH->err()) { warn "$DBI::errstr\n"; }
1;
}

sub noSub(){
	# FONCTION A VIDE POUR LES POINTEURS DE FONCTION %H_SUBINSERT
	# pour éviter d'utiliser des tests dans des fonctions répétitives
	# (faux switch/case)
return 1;
}


sub test_exist_table(){
	my $dbargs = {	AutoCommit => $ENV{EDTK_DBI_AutoCommit},
				RaiseError => $ENV{EDTK_DBI_RaiseError},
				PrintError => $ENV{EDTK_DBI_PrintError}};
	$DBH = DBI->connect($ENV{EDTK_DBI_DSN},
					$ENV{EDTK_DBI_DSN_USER},
					$ENV{EDTK_DBI_DSN_PASS}
					,$dbargs
				)
			or die "ERR no connexion to $ENV{EDTK_DBI_DSN} " . DBI->errstr;

	my $request="select * from $ENV{EDTK_DBI_TABLENAME}";

	$DBH->do($request);
	if ($DBI::errstr) {
		if ( $DBI::errstr =~/no such table/ ) { 
			$DBH->disconnect();
			return 0;
		}
		warn "INFO ".$DBI::errstr."\n";
		$DBH->disconnect();
		return $NOK; 
	}	
	$DBH->disconnect();

1;
}


sub edit_Track_Table(;$){
	my $request=shift;

	&open_DBI();
	
	my $ref_Tab =&fetchall_DBI($request);
	&edit_All_rTab($ref_Tab);
1;
}


sub create_Track_Table(){
	#my $dbi_dns=shift;

	# CREATE TABLE tablename [IF NOT EXISTS][TEMPORARY] (column1data_type, column2data_type, column3data_type);
	#&prepare_Tracking_Env();
	#$dbi_dns ||=$ENV{EDTK_DBI_DNS};
	
	my $dbargs = {	AutoCommit => 0,
				RaiseError => 0,
				PrintError => 0 };
	$DBH = DBI->connect($ENV{EDTK_DBI_DSN},
					$ENV{EDTK_DBI_DSN_USER},
					$ENV{EDTK_DBI_DSN_PASS},
					$dbargs)
			or die "ERR no connexion to $ENV{EDTK_DBI_DSN} " . DBI->errstr;

	my $struct="CREATE TABLE $ENV{EDTK_DBI_TABLENAME} ";
	$struct .="( ED_TSTAMP NUMBER(14)  NOT NULL";	# interesting for formated date and interval search
#	$struct .="( ED_TSTAMP VARCHAR2(14)  NOT NULL";	# most used
#	$struct .="( ED_TSTAMP DATE  NOT NULL";			# Not compatible
#	$struct .=", ED_HOST VARCHAR2(15) NOT NULL";	# hostname
#	$struct .=", ED_PROC VARCHAR2(6) NOT NULL";		# processus
	$struct .=", ED_USER VARCHAR2(10) NOT NULL";	# job request user 
	$struct .=", ED_SEQ NUMBER(9) NOT NULL";		# sequence
	$struct .=", ED_SNGL_ID VARCHAR2(22) NOT NULL";	# Single ID
	$struct .=", ED_APP VARCHAR2(15) NOT NULL";		# application name
	$struct .=", ED_MOD_ED CHAR";					# mode d'edition (Batch, Tp, Web, Mail)
	$struct .=", ED_JOB_EVT CHAR";					# niveau de l'événement dans le job(Spool, Document, Line, Warning, Error)
	$struct .=", ED_OBJ_COUNT NUMBER(15)";			# nombre d'éléments/objets attachés à l'événement

	for (my $i=0 ; $i lt $ENV{EDTK_MAX_USER_KEY} ; $i++) {
		$struct .=", ED_K${i}_NAME VARCHAR2(5)";	# nom de clef $i
		$struct .=", ED_K${i}_VAL VARCHAR2(30)";	# valeur clef $i
	}
	$struct .=")"; #, CONSTRAINT pk_$ENV{EDTK_DBI_TABLENAME} PRIMARY KEY (ED_TSTAMP, ED_PROC, ED_SEQ)";

	$DBH->do($struct);
	if ($DBI::errstr) {
		warn "INFO ".$DBI::errstr."\n";
	}	

	# my $seq ="CREATE SEQUENCE sq_$TABLENAME 
	#			MINVALUE 1
	#			MAXVALUE 999999999
	#			START WITH 1
	#			INCREMENT BY 1;";
	#$dbh->do("$seq");

	$DBH->commit();	# nécessaire si AutoCommit  vaut 0
	$DBH->disconnect();
1;
}


sub drop_Track_Table(){
	&prepare_Tracking_Env();
	&open_DBI();
	
	warn "=> Drop table $ENV{EDTK_DBI_TABLENAME} from $ENV{EDTK_DBI_DSN}, if exist\n\n";
	$DBH->do("DROP TABLE $ENV{EDTK_DBI_TABLENAME}");
	$DBH->disconnect;

1;
}


sub fetchall_DBI(;$) {
	# CONNEXION À UNE TABLE DBI POUR SELECT VERS UNE RÉFÉRENCE DE TABLEAU
	# sélection de toutes les données correspondant à un critère
	# option : requete à passer, exemple "SELECT * FROM TRACKING_OEDTK WHERE ED_MOD_ED = 'T'"
	#		par defaut vaut 'SELECT * from $ENV{EDTK_DBI_TABLENAME}' 
	my $request =shift;
	$request ||="SELECT * from $ENV{EDTK_DBI_TABLENAME}";
	
	my $sql = qq($request); 
	my $sth = $DBH->prepare( $sql );
	$sth->execute () 
			|| warn "ERR. DBI exec " . $DBH->errstr ; 
	
	my $rTab = $sth->fetchall_arrayref;
	
	$sth->{Active} = 1;	# resolution du bug SQLite "closing dbh with active statement" http://rt.cpan.org/Public/Bug/Display.html?id=9643
	$sth->finish();
	#$DBH->commit();	# nécessaire si AutoCommit  vaut 0 ???
	if ($DBI::errstr) {
		warn $DBI::errstr."\n";
	}	

return $rTab;
}


sub edit_All_rTab($){
	# EDITION DE L'ENSEMBLE DES DONNÉES D'UN TABLEAU PASSÉ EN REFÉRENCE
	#  affichage du tableau en colonnes 
	my $rTab=shift;

	for (my $i=0 ; $i<=$#{$rTab} ; $i++) {
		my $cols = $#{$$rTab[$i]};
		print "\n$i:\t";
			
		for (my $j=0 ;$j<=$cols ; $j++){
			print "$$rTab[$i][$j]" if (defined $$rTab[$i][$j]);
		}
	}
	print "\n";

1;
}


sub subClose_DB(){
	$DBH->commit() if ($ENV{EDTK_DBI_AutoCommit} eq 0 );	# nécessaire si AutoCommit  vaut 0
#	$DBH->disconnect();
1;
}

END {
	if (exists $h_subClose{EDTK_TRACK_MODE}) {
		&{$h_subClose{$ENV{EDTK_TRACK_MODE}}} ;
	}
}
1;




# NOTES 
#
# LISTE DES TABLES
# select table_name from tabs;
#
# Lister les tables du schéma de l'utilisateur courant :
# SELECT table_name FROM user_tables;
#
# Lister les tables accessibles par l'utilisateur :
# SELECT table_name FROM all_tables;
#
# Lister toutes les tables (il faut être ADMIN) :
# SELECT table_name FROM dba_tables; 
#
# DESCRIPTION DE LA TABLE :
# desc matable; 	# retourne les champs et leurs types 



# EXEMPLES REQUETES - http://fadace.developpez.com/sgbdcmp/fonctions/
#
# SELECT * FROM TRACKING_OEDTK WHERE ED_JOB_EVT='S';
# SELECT * FROM TRACKING_OEDTK WHERE ED_MOD_ED='T';
# SELECT SUM(ED_OBJ_COUNT) AS "OBJETS" FROM TRACKING_OEDTK WHERE ED_JOB_EVT='D';
# SELECT COUNT(ED_OBJ_COUNT) AS "OBJETS" FROM TRACKING_OEDTK WHERE ED_JOB_EVT='D';
# SELECT DISTINCT ED_SNGL_ID FROM TRACKING_OEDTK;
# SELECT COUNT (DISTINCT ED_SNGL_ID) FROM TRACKING_OEDTK ;
# SELECT COUNT (DISTINCT ED_SNGL_ID) FROM TRACKING_OEDTK WHERE ED_JOB_EVT='D';
# SELECT COUNT (DISTINCT ED_SNGL_ID) AS "TOTAL" FROM TRACKING_OEDTK  WHERE ED_JOB_EVT='D' AND ED_MOD_ED='T';
# SELECT ED_TSTAMP, ED_APP, ED_SNGL_ID FROM TRACKING_OEDTK WHERE ED_MOD_ED='T' AND ED_JOB_EVT='S';
# SELECT  to_char(ED_TSTAMP, 'DD/MM/YYYY HH24:MM:SS'), ED_APP, ED_SNGL_ID FROM TRACKING_OEDTK WHERE ED_MOD_ED='T' AND ED_JOB_EVT='S';
# SELECT  to_char(ED_TSTAMP, 'DD/MM/YYYY HH24:MM:SS') AS TIME , ED_APP, ED_SNGL_ID FROM TRACKING_OEDTK WHERE ED_MOD_ED='B' AND ED_JOB_EVT='S';

# update EDTK_FILIERES SET ed_postcomp =2020  where ed_postcomp<>'FilR100';

#
# END

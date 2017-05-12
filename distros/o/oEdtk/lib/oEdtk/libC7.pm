package oEdtk::libC7 ;
# use strict; 
use warnings;

use Exporter;
our $VERSION		=0.0056;
our @ISA		=qw(Exporter);
our @EXPORT		=qw(
				c7EdtkComp
				c7_compo
				c7_emit
				c7EdtkEmit
				c7_Control_Bal
			);

use oEdtk::Main 	0.42;
use oEdtk::trackEdtk 	qw (env_Var_Completion);
use oEdtk::Config 	qw (config_read);

my $C7_EVENT_DEPTH	=7;
my $NOK			=-1;

sub c7EdtkComp () { 	# remplacé par c7_compo - PLUS UTILISÉ ? dépendance libedtkDev
	# A FAIRE : documenter et full pramétrage (compusetEdtk.ini)
	my $output_Format	=shift;

#	my $prim_style_file	="$ENV{EDTK_DIR_APP}/$ENV{EDTK_PRGNAME}/$ENV{EDTK_PRGNAME}$ENV{EDTK_FTYP_DFLT}.$ENV{EDTK_EXT_COMSET}";	
	my $prim_style_file	="$ENV{EDTK_DIR_SCRIPT}/$ENV{EDTK_PRGNAME}.$ENV{EDTK_EXT_COMSET}";	
	my $secd_input_file	="$ENV{EDTK_FDATWORK}.$ENV{EDTK_EXT_WORK}";
	my $intermedte_file	="$ENV{EDTK_DIR_APPTMP}/$ENV{EDTK_PRGNAME}.cif";
	my $null_conf_file	="$ENV{EDTK_DIR_COMSET}/System/null.cnf";
	my $hyphen_diction	=$ENV{C7_CNF_PDF};
	my $widths_file		=$ENV{C7_WID_PDF};
	my $merge_lib_1		=$ENV{C7_DCLIB_1};
	my $merge_lib_2		=$ENV{C7_DCLIB_2};
	my $merge_lib_RW	="$ENV{C7_DCLIB_RW}/libEdtkC7";
	my $scratch_file	="$ENV{EDTK_DIR_APPTMP}/$ENV{EDTK_PRGNAME}";
	my $index_file_1	="$ENV{EDTK_DIR_LOG}/$ENV{EDTK_PRGNAME}.idx1";
	my $index_file_2	="$ENV{EDTK_DIR_LOG}/$ENV{EDTK_PRGNAME}.idx2";
	my $c7_message_db	="$ENV{EDTK_DIR_COMSET}/system/$ENV{WORDTYP}/xicsmsg.mdb";
	my $comp_log_file	="$ENV{EDTK_DIR_LOG}/$ENV{EDTK_PRGNAME}.comp.log";

	my $comp_file_def	 ="*\n";
	$comp_file_def 	.="*	FILE DEFINITIONS FOR COMPUSET \n";
	$comp_file_def 	.="*\n";
	# ATTENTION COMPUSET NE SUPPORTE PAS LES TABULATIONS DANS SES FICHIERS DE COMMANDES
	$comp_file_def 	.=sprintf ("FILE  1, %s      ,primary input file\n",		$prim_style_file);
	$comp_file_def 	.=sprintf ("FILE 18, %s      ,secondary input file\n",		$secd_input_file);
	$comp_file_def 	.=sprintf ("FILE  2, %s      ,intermediate file output\n", 	$intermedte_file);
	$comp_file_def 	.=sprintf ("FILE  3, %s      ,null config file\n", 		$null_conf_file);
	$comp_file_def 	.=sprintf ("FILE  4, %s      ,hyphenation dictionary\n",	$hyphen_diction);
	$comp_file_def 	.=sprintf ("FILE  7, %s      ,POST widths file\n",		$widths_file);
	$comp_file_def 	.=sprintf ("FILE 30, %s      ,merge library 1\n",		$merge_lib_1);
	$comp_file_def 	.=sprintf ("FILE 31, %s      ,merge library 2\n",		$merge_lib_2);
	$comp_file_def 	.=sprintf ("FILE 32, %s/      ,merge library 3\n",		$merge_lib_RW);
	$comp_file_def 	.=sprintf ("FILE  8, %s1.tmp ,scratch file 1\n",		$scratch_file);
	$comp_file_def 	.=sprintf ("FILE  9, %s2.tmp ,scratch file 2\n",		$scratch_file);
	$comp_file_def 	.=sprintf ("FILE 10, %s3.tmp ,scratch file 3\n",		$scratch_file);
	$comp_file_def 	.=sprintf ("FILE 34, %s4.tmp ,scratch file 4\n",		$scratch_file);
	$comp_file_def 	.=sprintf ("FILE 11, %s      ,index file 1\n",			$index_file_1);
	$comp_file_def 	.=sprintf ("FILE 12, %s      ,index file 1\n",			$index_file_2);
	$comp_file_def 	.=sprintf ("FILE 25, %s      ,CompuSet message database\n",	$c7_message_db);

	env_Var_Completion($comp_file_def);
	$comp_file_def 	.="//                                           END OF FILE DEFINITIONS\n";

	my $comp_file=$ENV{EDTK_DIR_APPTMP}."/".$ENV{EDTK_PRGNAME}.".comp";
	env_Var_Completion($comp_file);

	oe_open_fo_OUT ("$comp_file");
	print OUT $comp_file_def;
	oe_close_fo("$comp_file");

	my $commande ="$ENV{EDTK_DIR_COMSET}/system/$ENV{OSYS}/$ENV{COMPUSET} < $comp_file > $comp_log_file";
	warn "\n$commande \n";
	env_Var_Completion($commande);
	
	eval {
		system($commande);
	};
#	if ($@){
	if ($?){
		warn " ERROR $ENV{COMPUSET} return $? ";
		warn " ERROR see $comp_log_file log";
		env_Var_Completion($comp_log_file);
		&show_C7_event ($comp_log_file);

		return $NOK;
	}
1;
}

sub c7_compo ($$$;$$) {			# PLUS UTILISÉ ? dépendance Main.pm
	my $cfg =config_read('COMSET');

	# A FAIRE : documenter et full pramétrage (compusetEdtk.ini)
	my $output_format	=shift || "PDF";
	my $prim_style_file	=shift;
	my $secd_input_file	=shift;

	my $outmngr_option	=shift || "";
	my $doc_lib		=shift || "libEdtkC7";
	# warn "INFO : doclib = $doc_lib\n";
	my $conf_pde_key	="C7_PDE_".$outmngr_option.$output_format;
	my $conf_cnf_key	="C7_CNF_".$output_format;
	my $conf_wid_key	="C7_WID_".$output_format;

	my $intermedte_file	=$cfg->{'EDTK_DIR_APPTMP'} . "/" . $cfg->{'EDTK_PRGNAME'} . ".cif";
	my $null_conf_file	=$cfg->{'C7_NULL_CNF'};
	my $hyphen_diction	=$cfg->{$conf_cnf_key};
	my $widths_file		=$cfg->{$conf_wid_key};
	my $merge_lib_1		=$cfg->{'C7_DCLIB_1'};
	my $merge_lib_2		=$cfg->{'C7_DCLIB_2'};
	my $merge_lib_RW	=$cfg->{'C7_DCLIB_RW'}. "/" . $doc_lib;
	my $scratch_file	=$cfg->{'EDTK_DIR_APPTMP'} . "/" . $cfg->{'EDTK_PRGNAME'};
	my $index_file_1	=$cfg->{'EDTK_DIR_OUTMNGR'} . "/" . $cfg->{'EDTK_PRGNAME'} . ".idx1";
	my $index_file_2	=$cfg->{'EDTK_DIR_OUTMNGR'} . "/" . $cfg->{'EDTK_PRGNAME'} . ".idx2";
	my $c7_message_db	=$cfg->{'EDTK_DIR_COMSET'} . "/system/" . $cfg->{'WORDTYP'} . "/xicsmsg.mdb";
	my $comp_log_file	=$cfg->{'EDTK_DIR_LOG'} . "/" . $cfg->{'EDTK_PRGNAME'} . ".comp.log";

	my $comp_file_def	 ="*\n";
	$comp_file_def 	.="*	FILE DEFINITIONS FOR COMPUSET \n";
	$comp_file_def 	.="*\n";
	# ATTENTION COMPUSET NE SUPPORTE PAS LES TABULATIONS DANS SES FICHIERS DE COMMANDES
	$comp_file_def 	.=sprintf ("FILE  1, %s      ,primary input file\n",		$prim_style_file);
	$comp_file_def 	.=sprintf ("FILE 18, %s      ,secondary input file\n",		$secd_input_file);
	$comp_file_def 	.=sprintf ("FILE  2, %s      ,intermediate file output\n", 	$intermedte_file);
	$comp_file_def 	.=sprintf ("FILE  3, %s      ,null config file\n", 		$null_conf_file);
	$comp_file_def 	.=sprintf ("FILE  4, %s      ,hyphenation dictionary\n",	$hyphen_diction);
	$comp_file_def 	.=sprintf ("FILE  7, %s      ,POST widths file\n",		$widths_file);
	$comp_file_def 	.=sprintf ("FILE 30, %s      ,merge library 1\n",		$merge_lib_1);
	$comp_file_def 	.=sprintf ("FILE 31, %s      ,merge library 2\n",		$merge_lib_2);
	$comp_file_def 	.=sprintf ("FILE 32, %s      ,merge library 3\n",		$merge_lib_RW);
	$comp_file_def 	.=sprintf ("FILE  8, %s1.tmp ,scratch file 1\n",		$scratch_file);
	$comp_file_def 	.=sprintf ("FILE  9, %s2.tmp ,scratch file 2\n",		$scratch_file);
	$comp_file_def 	.=sprintf ("FILE 10, %s3.tmp ,scratch file 3\n",		$scratch_file);
	$comp_file_def 	.=sprintf ("FILE 34, %s4.tmp ,scratch file 4\n",		$scratch_file);
	$comp_file_def 	.=sprintf ("FILE 11, %s      ,index file 1\n",			$index_file_1);
	$comp_file_def 	.=sprintf ("FILE 12, %s      ,index file 1\n",			$index_file_2);
	$comp_file_def 	.=sprintf ("FILE 25, %s      ,CompuSet message database\n",	$c7_message_db);

	# en environnement Windows les slash doivent être remplacés par des backslash
	# sinon plantage (message "compuset ne trouve plus la clef hardware")
	env_Var_Completion($comp_file_def); 
	# remplacer par 
	# $comp_file_def=~ms/\//\\/g;
	
	# par contre les slash suivants sont importants pour fermer le fichier de définition
	$comp_file_def 	.="//                                           END OF FILE DEFINITIONS\n";

	my $comp_file=$cfg->{'EDTK_DIR_APPTMP'}."/".$cfg->{'EDTK_PRGNAME'}.".comp";
	#env_Var_Completion($comp_file);

	oe_open_fo_OUT ("$comp_file");
	print OUT $comp_file_def;
	oe_close_fo("$comp_file");

	my $commande =$cfg->{'EDTK_DIR_COMSET'} . "/system/" . $cfg->{'OSYS'} . "/" . $cfg->{'COMPUSET'} . " < $comp_file > $comp_log_file";
	warn "INFO : $commande \n";
	#env_Var_Completion($commande);
	
	eval {
		system($commande);
	};

	if ($?){
		warn "ERROR: " . $cfg->{'COMPUSET'} . " return $? ";
		warn "ERROR: see $comp_log_file log";
		#env_Var_Completion($comp_log_file);
		&show_C7_event ($comp_log_file);

		return $NOK;
	}
1;
}

sub c7_emit ($$$$;$$) { 		# PLUS UTILISÉ ? dépendance Main.pm 
	my $cfg =config_read('COMSET');

	# A FAIRE : documenter et full pramétrage (compusetEdtk.ini)
	my $output_format	=uc (shift) || "PDF";
	my $prim_style_file	=shift;
	my $secd_input_file	=shift;


#EDTK_DIR_BASE		=C:/edtk_APP
#EDTK_DIR_APP 	=$EDTK_DIR_BASE/app
#EDTK_DIR_SCRIPT	=$EDTK_DIR_APP/$EDTK_PRGNAME
#EDTK_DIR_APPTMP 	=$EDTK_DIR_SCRIPT/tmp.nocvs
#EDTK_FDATWORK		=$EDTK_DIR_APPTMP/$EDTK_PRGNAME
#EDTK_DIR_DATA_IN	=$EDTK_DIR_SCRIPT/flux.nocvs
#EDTK_FDATAOUT		=$EDTK_DIR_DATA_IN/$EDTK_PRGNAME
#EDTK_EXT_WORK		=txt
#EDTK_EXT_PDF		=pdf
#	c7_emit  ($output_format, $script_compo, $input_fdatwork, "$input_fdatwork.pdf", "OMGR", ) ;

#	my $output_doc_file 	=$ENV{EDTK_DOC_OUTPUT};	#"$ENV{EDTK_FDATAOUT}.$ENV{EDTK_EXT_PDF}";

	my $output_doc_file	=shift;
	my $outmngr_option	=shift || "";
	my $doc_lib		=shift || "libEdtkC7";
	# warn "INFO : doclib = $doc_lib\n";
	my $conf_pde_key	="C7_PDE_" .$outmngr_option.$output_format;
	my $conf_cnf_key	="C7_CNF_" .$output_format;
	my $conf_wid_key	="C7_WID_" .$output_format;
	my $emitter		="C7_INTX_".$output_format;
	my $edtk_ext		="EDTK_EXT_".$output_format;
	$output_doc_file	="$output_doc_file.".$cfg->{$edtk_ext};

	my $intermedte_file	=$cfg->{'EDTK_DIR_APPTMP'} . "/" . $cfg->{'EDTK_PRGNAME'} . ".cif";
	my $null_conf_file	=$cfg->{'C7_NULL_CNF'};
	my $hyphen_diction	=$cfg->{$conf_cnf_key};
	my $widths_file		=$cfg->{$conf_wid_key};
	my $merge_lib_1		=$cfg->{'C7_DCLIB_1'};
	my $merge_lib_2		=$cfg->{'C7_DCLIB_2'};
	my $merge_lib_RW	=$cfg->{'C7_DCLIB_RW'}. "/" . $doc_lib;
	my $scratch_file	=$cfg->{'EDTK_DIR_APPTMP'} . "/" . $cfg->{'EDTK_PRGNAME'};
	my $index_file_1	=$cfg->{'EDTK_DIR_OUTMNGR'} . "/" . $cfg->{'EDTK_PRGNAME'} . ".idx1";
	my $index_file_2	=$cfg->{'EDTK_DIR_OUTMNGR'} . "/" . $cfg->{'EDTK_PRGNAME'} . ".idx2";
	my $c7_message_db	=$cfg->{'EDTK_DIR_COMSET'} . "/system/" . $cfg->{'WORDTYP'} . "/xicsmsg.mdb";
	my $comp_log_file	=$cfg->{'EDTK_DIR_LOG'} . "/" . $cfg->{'EDTK_PRGNAME'} . ".comp.log";
	my $output_pdef_file	=$cfg->{$conf_pde_key};

	my $emitter_file_def 	="*\n";
	$emitter_file_def 	.="*	FILE DEFINITIONS FOR PSTINT\n";
	$emitter_file_def 	.="*\n";
	# ATTENTION COMPUSET NE SUPPORTE PAS PLUSIEURS TABULATIONS DANS SES FICHIERS DE COMMANDES
	$emitter_file_def 	.=sprintf ("FILE  1, %s      ,intermediate file input\n",	$intermedte_file);
	$emitter_file_def 	.=sprintf ("FILE  3, %s      ,null config file\n",		$null_conf_file);
	$emitter_file_def 	.=sprintf ("FILE 14, %s      ,POST widths file\n",		$widths_file);
	$emitter_file_def 	.=sprintf ("FILE  8, %s      ,PostScript pdef file\n",		$output_pdef_file);
	$emitter_file_def 	.=sprintf ("FILE  4, %s      ,PostScript output file\n", 	$output_doc_file);
	$emitter_file_def 	.=sprintf ("FILE  9, %s      ,merge library 1\n",		$merge_lib_1);
	$emitter_file_def 	.=sprintf ("FILE 10, %s      ,merge library 2\n",		$merge_lib_2);
	$emitter_file_def 	.=sprintf ("FILE 11, %s      ,merge library 3\n",		$merge_lib_RW);
	$emitter_file_def 	.=sprintf ("FILE 25, %s      ,CompuSet message database\n",	$c7_message_db);

	# en environnement Windows les slash doivent être remplacés par des backslash
	# sinon plantage (message "compuset ne trouve plus la clef hardware")
	env_Var_Completion($emitter_file_def);
	# remplacer par 
	# $comp_file_def=~ms/\//\\/g;
	
	# par contre les slash suivants sont importants pour fermer le fichier de définition
	$emitter_file_def 	.="//     END OF FILE DEFINITIONS \n";
	$emitter_file_def 	.="*\n";		
	$emitter_file_def 	.="*               INSERT OPTIONS HERE OR IN PDEF FILE\n";
	$emitter_file_def 	.="*\n";
	$emitter_file_def 	.="//                         END OF OPTIONS\n";

	my $emitter_file	=$cfg->{'EDTK_DIR_APPTMP'} . "/" . $cfg->{'EDTK_PRGNAME'} . ".emit";
	#env_Var_Completion($emitter_file);
	oe_open_fo_OUT ($emitter_file);
	print OUT $emitter_file_def;
	oe_close_fo($emitter_file);

	my $emit_log_file	=$cfg->{'EDTK_DIR_LOG'} . "/" . $cfg->{'EDTK_PRGNAME'} . ".emit.log";
	my $commande 		=$cfg->{'EDTK_DIR_COMSET'} . "/system/" . $cfg->{'OSYS'} . "/" . $cfg->{$emitter} . " < $emitter_file > $emit_log_file";
	warn "INFO : $commande \n";
	#env_Var_Completion($commande);

	eval {
		system($commande);
	};
#	if ($@){
	if ($?){
		warn "ERROR: ". $cfg->{'COMPUSET'} . " emitter return $? ";
		warn "ERROR: see $emit_log_file log";
		#env_Var_Completion($emit_log_file);
		&show_C7_event ($emit_log_file);

		return $NOK;
	}
1;
}


sub c7EdtkEmit {	# remplacé par c7_emit - # PLUS UTILISÉ ? dépendance libEdtkDev
	# A FAIRE : documenter et full pramétrage (compusetEdtk.ini)
	my $output_Format =shift;

	my $prim_style_file	="$ENV{EDTK_DIR_SCRIPT}/$ENV{EDTK_PRGNAME}.$ENV{EDTK_EXT_COMSET}";	
	my $secd_input_file	="$ENV{EDTK_FDATWORK}.$ENV{EDTK_EXT_WORK}";
	my $intermedte_file	="$ENV{EDTK_DIR_APPTMP}/$ENV{EDTK_PRGNAME}.cif";
	my $null_conf_file	="$ENV{EDTK_DIR_COMSET}/System/null.cnf";
	my $hyphen_diction	=$ENV{C7_CNF_PDF};
	my $output_pdef_file	=$ENV{C7_PDE_PDF};
	my $widths_file		=$ENV{C7_WID_PDF};
	my $merge_lib_1		=$ENV{C7_DCLIB_1};
	my $merge_lib_2		=$ENV{C7_DCLIB_2};
	my $merge_lib_RW	="$ENV{C7_DCLIB_RW}/libEdtkC7";
	my $scratch_file	="$ENV{EDTK_DIR_APPTMP}/$ENV{EDTK_PRGNAME}";
	my $index_file_1	="$ENV{EDTK_DIR_LOG}/$ENV{EDTK_PRGNAME}.idx1";
	my $index_file_2	="$ENV{EDTK_DIR_LOG}/$ENV{EDTK_PRGNAME}.idx2";
	my $c7_message_db	="$ENV{EDTK_DIR_COMSET}/system/$ENV{WORDTYP}/xicsmsg.mdb";
	my $output_doc_file 	=$ENV{EDTK_DOC_OUTPUT};	#"$ENV{EDTK_FDATAOUT}.$ENV{EDTK_EXT_PDF}";

	my $emitter_file_def 	="*\n";
	$emitter_file_def 	.="*	FILE DEFINITIONS FOR PSTINT\n";
	$emitter_file_def 	.="*\n";
	# ATTENTION COMPUSET NE SUPPORTE PAS PLUSIEURS TABULATIONS DANS SES FICHIERS DE COMMANDES
	$emitter_file_def 	.=sprintf ("FILE  1, %s      ,intermediate file input\n",	$intermedte_file);
	$emitter_file_def 	.=sprintf ("FILE  3, %s      ,null config file\n",		$null_conf_file);
	$emitter_file_def 	.=sprintf ("FILE 14, %s      ,POST widths file\n",		$widths_file);
	$emitter_file_def 	.=sprintf ("FILE  8, %s      ,PostScript pdef file\n",		$output_pdef_file);
	$emitter_file_def 	.=sprintf ("FILE  4, %s      ,PostScript output file\n", 	$output_doc_file);
	$emitter_file_def 	.=sprintf ("FILE  9, %s      ,merge library 1\n",		$merge_lib_1);
	$emitter_file_def 	.=sprintf ("FILE 10, %s      ,merge library 2\n",		$merge_lib_2);
	$emitter_file_def 	.=sprintf ("FILE 11, %s      ,merge library 3\n",		$merge_lib_RW);
	$emitter_file_def 	.=sprintf ("FILE 25, %s      ,CompuSet message database\n",	$c7_message_db);

	env_Var_Completion($emitter_file_def);
	$emitter_file_def 	.="//     END OF FILE DEFINITIONS \n";
	$emitter_file_def 	.="*\n";		
	$emitter_file_def 	.="*               INSERT OPTIONS HERE OR IN PDEF FILE\n";
	$emitter_file_def 	.="*\n";
	$emitter_file_def 	.="//                         END OF OPTIONS\n";

	my $emitter_file="$ENV{EDTK_DIR_APPTMP}/$ENV{EDTK_PRGNAME}.emit";
	env_Var_Completion($emitter_file);
	my $emit_log_file="$ENV{EDTK_DIR_LOG}/$ENV{EDTK_PRGNAME}.emit.log";
	oe_open_fo_OUT ("$emitter_file");
	print OUT $emitter_file_def;
	oe_close_fo("$emitter_file");

	my $commande ="$ENV{EDTK_DIR_COMSET}/system/$ENV{OSYS}/$ENV{PSTINTX} < $emitter_file > $emit_log_file";
	warn "\n$commande \n";
	env_Var_Completion($commande);


	eval {
		system($commande);
	};
#	if ($@){
	if ($?){
		warn " ERROR $ENV{COMPUSET} emitter return $? ";
		warn " ERROR see $emit_log_file log";
		env_Var_Completion($emit_log_file);
		&show_C7_event ($emit_log_file);

		return $NOK;
	}
1;
}

sub show_C7_event ($) {		# PLUS UTILISÉ ? dépendance interne libEdtkC7
	my $log =shift;
	my $ligne_count =0;
	
	oe_open_fi_IN ($log);
	
	warn "\n INFO extracted from log :\n";

	# introduction de 'defined (IN)' dans le test pour élilminer le warning 'Value of <HANDLE> construct can be "0"; test with defined()'
	while (defined (IN) && (my $ligne = <IN>) && ($ligne_count lt $C7_EVENT_DEPTH)) { 
		if ($ligne =~/-[EW]:/ or $ligne_count gt 1) {
			warn $ligne;
			$ligne_count++;
		}
	}
1;
}

sub c7_Control_Bal ($){		# PLUS UTILISÉ ? dépendance libEdtkDev et interne libEdtkC7
	my $file =shift;
	my $ctrl_depth_tags=$ENV{C7_DEPTH_TAGS};
	$ctrl_depth_tags ||=1;
	my $nbOpen=0;
	my $nbClose=0;
	my $nbSomOpen=0;
	my $nbSomClose=0;
	my $nbEcart=0;
	my @lineNumbers;
	my $buffMessage="";
 
	# CONTROLE D'APPARIEMENT DU FICHIER DE DONNEES BALISEES
	warn "INFO : Analyse de l'appariement des balises dans le fichier $file.\n";
	oe_open_fi_IN ($file);

	while ($ligne=<IN>){
		while ($ligne=~m/</g){$nbOpen++;}
		while ($ligne=~m/>/g){$nbClose++;}
		$nbSomOpen +=$nbOpen;
		$nbSomClose+=$nbClose;        

		if (abs($nbSomOpen - $nbSomClose) gt $ctrl_depth_tags){
			push (@lineNumbers, $.);
			warn "ERR. multiplication imbrications $nbSomOpen ouvertures / $nbSomClose fermetures";
			warn "ERR. voir $file,";
			warn "ERR. voir lignes @lineNumbers";
			return $NOK;			
		} elsif (abs($nbSomOpen - $nbSomClose) ge 1) {
			push (@lineNumbers, $.);		
		} else {
			undef (@lineNumbers);
		}
		
		if ($nbOpen ne $nbClose){
			$nbEcart++;
		}
		$nbOpen	=0;
		$nbClose	=0;
	}

	if ($nbSomOpen ne $nbSomClose){
		warn "ERROR : Le fichier balise n'est pas correctement apparie \n";
		warn $buffMessage;   
		return $NOK;
	} elsif ($nbEcart ne 0) {
		warn "INFO : Presence de super balises appariees sur plusieurs lignes \n";     
	} else {
		warn "GOOD : Le fichier balise semble bien apparie ($nbSomOpen ouverture(s)/$nbSomClose fermeture(s)).\n";
	}
1;
}

1;

package oEdtk::libXls;

use strict;

use Cwd;
use oEdtk::Main;
use File::Basename;
use Spreadsheet::WriteExcel;
use oEdtk::Config	qw(config_read);

use Exporter;

our $VERSION 	= 0.463;
our @ISA 	= qw(Exporter);
our @EXPORT 	= qw(prod_Xls_Init
		     prod_Xls_New		prod_Xls_Insert_Val
		     prod_Xls_Col_Init	prod_Xls_Edit_Ligne
		     prod_Xls_Row_Height	prod_Xls_Add_Sheet
		     prod_Xls_Close		prod_Xls_Liste_Output
		     %XLS_FORMAT);


my $LOCAL_REF_WORKBOOK;
my $CFG = config_read();

 # METHODES ASSOCIEES A LA GESTION DU FORMAT EXCEL
 my $MAX_ROW_BY_FIC =$CFG->{'EDTK_XLS_MAX_ROW'};
 my $XLSCOL = 0;
 my $XLSROW = 0;
 my $XLSHEIG= undef;
 my $MAXCOL =32;
 my $FNTSZ1 =12;
 my $FNTSZ2 =10;
 my $FNTSZ3 = 8;
 my $SHEET  = 0;
 our %XLS_FORMAT;

 my @TAB_VALUE;
 my @TAB_HEAD;
 my @TAB_COL_SIZE;
 my @TAB_LISTE_XLS;
 my ($FILENAME_REF, $XLS_NAME, $HEADER_LEFT,$HEADER_CENTER,$HEADER_RIGHT);

sub prod_Xls_Init(;$$$){
	# INITIALISATION DE LA FEUILLE EXCEL
	# ARGUMENTS : [TEXTE EN-TÊTE GAUCHE], [TEXTE EN-TÊTE CENTRE], [TEXTE EN-TÊTE DROIT]
    	($HEADER_LEFT,$HEADER_CENTER,$HEADER_RIGHT) =@_;
	$HEADER_RIGHT		||="Édition du &D";

	# EN FONCTION DU NOMBRE D'ÉLÉMENTS ON FABRIQUE L'INDICE DU PROCHAIN FICHIER
	my $item = sprintf ("%03s", $#TAB_LISTE_XLS+2);

	eval {
		$XLS_NAME = $CFG->{'EDTK_PRGNAME'}.".".$item.".".$CFG->{'EDTK_EXT_EXCEL'};
	};
	if ($@) {
		$XLS_NAME = $ARGV[0].$item.".xls";
	}

#	$XLS_NAME = basename($TXT_NAME);
#	$XLS_NAME =~ s/\.[^.]+/.xls/;
#	$XLS_NAME =~ s/(.+)\.\D{2,}$/$1.xls/;
	push (@TAB_LISTE_XLS, $XLS_NAME);
#	if ($#TAB_LISTE_XLS==0) {$FILENAME_REF=$XLS_NAME;}

	# CREATION D'UN FICHIER EXCEL
	my $workbook = Spreadsheet::WriteExcel->new($XLS_NAME)
		or die "echec a l'ouverture de $XLS_NAME, code retour $!\n";
	$LOCAL_REF_WORKBOOK=\$workbook;

	# AJOUT D'UNE FEUILLE EXCEL
	my $worksheet =$workbook->add_worksheet($0=~/([\w-]+)\.pl$/); # CREATION D'UNE FEUILLE DANS LE CLASSEUR, CETTE FEUILLE POPRTE LE NOM DE L'APPLI PERL SANS L'EXTENSION .PL
	&prod_Xls_Set_Format();
	&prod_Xls_Set_Sheet($worksheet);

	return \$workbook;
}

sub prod_Xls_New (;$$){
	# deux paramètres optionnels
	# 	- "HEAD" pour répéter la tête de tableau
#	#	- une racine de nom de fichier (s'intègre à la gestion des ruptures automatiques de fichiers)
	if ($TAB_LISTE_XLS[0]){
		my $option1=shift;
		$option1 ||="";
		if ($option1 eq "HEAD") {
			&prod_Xls_Head;
		}

		# CRÉATION D'UN NOUVEAU FICHIER XLS
		# ON RÉCUPÈRE LE NOM DU FICHIER DANS LE TABLEAU S'IL N'EST PAS PASSE EN PARAMETRE
#		my $xls_name;
#		if ($xls_name=shift) {$FILENAME_REF=$xls_name;}
#		$xls_name ||=$FILENAME_REF;

		# EN FONCTION DU NOMBRE D'ÉLÉMENTS ON FABRIQUE L'INDICE DU PROCHAIN FICHIER
#		my $item= sprintf ("%03s", $#TAB_LISTE_XLS+2);

		# ON CRÉE LE NOM DU FICHIER
#		$xls_name=~s/(.+\.).*$/$1$item.xls/;

		# CRÉATION DU NOUVEAU FICHIER AVEC SES PROPRIÉTÉS PAR DÉFAUT
		$SHEET  =0;
		$XLSROW =0;

		#return prod_Xls_Init($xls_name,$HEADER_LEFT,$HEADER_CENTER,$HEADER_RIGHT);
		return prod_Xls_Init($HEADER_LEFT,$HEADER_CENTER,$HEADER_RIGHT);
	} else {
		die "No init found for prodEdtkXls\n";
	}
}


sub prod_Xls_Col_Init{
	# INITIALISATION ET DÉFINITION DES PROPRIÉTÉS STYLES ET LARGEUR DES COLONNES
	my $paire	="";
	my $cpt	=0;
	while (my $paire =shift){
		if ($paire=~/^(\D*)/)	{$TAB_COL_SIZE[$cpt][0]=$1;} 	else {$TAB_COL_SIZE[$cpt][0]='AC';}
		if ($paire=~/([\d\.]*)$/){$TAB_COL_SIZE[$cpt][1]=$1;} 	else {$TAB_COL_SIZE[$cpt][1]=10;}
		$cpt++;
	}
	1;
}

sub prod_Xls_Row_Height($){
	$XLSHEIG=shift;

	my $worksheet	=${$LOCAL_REF_WORKBOOK}->sheets($SHEET);
	$worksheet->set_row($XLSROW, $XLSHEIG);
	$XLSHEIG=undef;
	1;
}

sub prod_Xls_Add_Sheet($){
	my $sheetName=shift;
	my $worksheet =${$LOCAL_REF_WORKBOOK}->add_worksheet($sheetName);
	&prod_Xls_Set_Sheet($worksheet);
	$SHEET++;
	$XLSROW=0;

	if (@TAB_HEAD) {
		&prod_Xls_Head;
	}

	return $worksheet;
}

sub prod_Xls_Set_Sheet($) {
	my $worksheet=shift;
	my $doc_HEADER_LEFT		='&L&10&"Arial,Bold"'.$HEADER_LEFT;
	my $doc_HEADER_CENTER	='&C&10&"Arial,Bold"'.$HEADER_CENTER;
	my $doc_HEADER_RIGHT 	='&R&10&"Arial,Bold"'.$HEADER_RIGHT;
	my $ref		 		='&L&6Réf/doc : &A - Edité le &D - &P - &F'.'&R&10Page &P/&N';

	$worksheet ->set_paper(0);		# FORMAT D'IMPRESSION (PRINTER DEFAULT))
	$worksheet ->set_landscape();		# SET_PORTRAIT() # A METTRE EN VARIABLE
	$worksheet ->set_margins_LR(0.4);	# EN INCH
	$worksheet ->set_margins_TB(0.65);	# EN INCH
	$worksheet ->fit_to_pages(1, 0);	# ADAPTE L'IMPRESSION À LA LARGEUR DE LA PAGE
	$worksheet ->set_header("$doc_HEADER_LEFT$doc_HEADER_CENTER$doc_HEADER_RIGHT", 0.4);
	$worksheet ->set_footer($ref, 0.4);
	$worksheet ->center_horizontally();
	$worksheet ->hide_gridlines();
	$worksheet ->freeze_panes(1, 0); 	# FRACTIONNE LA PREMIÈRE LIGNE POUR VISUALISATION
	$worksheet ->repeat_rows(0);		# RANG À RÉPÉTER EN TÊTE DE PAGE POUR L'IMPRESSION # A METTRE EN VARIABLE

	# DEFINITION DES FORMATS DE CHACUNE DES COLONNES
	$worksheet ->set_column(0, $MAXCOL, 10, $XLS_FORMAT{'AL'});	# FORMAT PAR DEFAUT

	my $i=0;
	# SI LES COLONNES SONT DÉFINIES EN STYLES ET EN LARGEUR, ON PREND EN COMPTE LES PROPRIÉTÉS
	while ( $TAB_COL_SIZE[$i][0] ){
		$worksheet ->set_column($i, $i, $TAB_COL_SIZE[$i][1],  $XLS_FORMAT{$TAB_COL_SIZE[$i][0]});
		$i++;
	}
	1;
}

sub prod_Xls_Insert_Val{
	# AJOUT DE LA OU LES VALEURS TRANSMISES AU TABLEAU DE VALEURS LOCAL

	@TAB_VALUE=(@TAB_VALUE, @_);
	1;
}

sub prod_Xls_Edit_Ligne (;$$){
	# LA FONCTION PEUT RECEVOIR EN PARAMÈTRE
	#	$format = UNE INSTRUCTUCTION DE FORMATTAGE UNIQUE POUR LA LIGNE COURANTE
	#	$f_tete_col = "HEAD" DESIGNE UNE TETE DE COLONNE A REPETER SUR CHAQUE PAGE
	my $oldFormat	=0;
	my $format	=shift; 				# OPTION
	my $f_tete_Col	=shift; 				# OPTION
	$f_tete_Col 	||="";

	# ON ÉDITE PAS LES LIGNES SANS VALORISATIONS (COMPLÈTEMENT VIDES)
	if ($#TAB_VALUE == -1) {
		return "OK", $XLSROW; 	# Sortie
	}

	my $worksheet	=${$LOCAL_REF_WORKBOOK}->sheets($SHEET);
	my $statut	="OK";
	my $col 		=0; 					# CETTE VARIABLE PERMET DE REPARTIR DE LA PREMIÈRE COLONNE DANS LALIGNE
	my $format_unique =0;
	if ($format) {
		 $format_unique = 1;
	}

	if ($f_tete_Col eq "HEAD"){
		undef @TAB_HEAD;
		@TAB_HEAD=("START_HEAD_$format", @TAB_VALUE, "STOP_HEAD");
	}

	# TRAITEMENT DES VALEURS DU TABLEAU, UNE PAR UNE
	#  CELLULE PAR CELLULE, Y COMPRIS LES VALEURS UNDEF
	while ($#TAB_VALUE > -1) {
		my $valeur=shift(@TAB_VALUE);
		if ($format_unique) {			# l'ensemble de la ligne est formattée avec le format transmis en paramètre
		} elsif ($TAB_COL_SIZE[$col][0]) {	# format pré défini
			$format=$TAB_COL_SIZE[$col][0];

		} else {
			$format = "AC";			# format par défaut
		}

		if ($valeur =~/NEW_PAGE/) {
			$worksheet ->set_h_pagebreaks($XLSROW+1);
			$col++;
		} elsif ($valeur =~/NEW_LINE/) {
			$col=0;
			$XLSROW++;
		} elsif ($valeur =~/STOP_HEAD/) {
			$format_unique=$oldFormat;
		} elsif ($valeur =~/START_HEAD/) {
			$oldFormat=$format_unique;
			if ($valeur =~/START_HEAD_(\w{2})/) {
				$format=$1;
				$format_unique=1;
			} else {
				$format_unique=0;
        		}
			# OUVERTURE D'UN NOUVEAU FICHIER EXCEL
			if ($XLSROW != 0) {
				&prod_Xls_New();
			}
		} elsif (ref $format eq 'HASH') {
			# enrichissement du format de mise en forme de la cellule
			# attention les valeurs modifiées ne sont pas sauvegardées
			my $xlsfmt = ${$LOCAL_REF_WORKBOOK}->add_format();
			if ($TAB_COL_SIZE[$col][0]) {
				$xlsfmt->copy($XLS_FORMAT{$TAB_COL_SIZE[$col][0]});
			}
			$xlsfmt->set_format_properties(%$format);
			$worksheet->write($XLSROW, $col, $valeur, $xlsfmt);
			$col++;
		} elsif ($format =~ /^N/) {
			$valeur=~s/\s//g;
			$worksheet->write_number($XLSROW, $col, $valeur, $XLS_FORMAT{$format});
			$col++;
		} else {
			$valeur=~s/\ +/ /g;	# on ne substitue que les blancs par les caractères tq cr lf
			$worksheet->write_string($XLSROW, $col, $valeur, $XLS_FORMAT{$format});
			$col++;
		}
	}
	if ($col > 0) { $XLSROW++ ; }

	if ($XLSROW < ($MAX_ROW_BY_FIC-1)) {
		$statut="OK";
	} elsif ($XLSROW == ($MAX_ROW_BY_FIC-1)) {
		$statut="WARN_EOF";
	} elsif ($XLSROW > $MAX_ROW_BY_FIC-1) {
		$statut="NEW";

		&prod_Xls_New('HEAD');
		&prod_Xls_Insert_Val ("NEW_LINE");
		#print "XLSROW=$XLSROW  - \$#TAB_VALUE=$#TAB_VALUE /insert head @TAB_VALUE \n" ;
	}

	return $statut, $XLSROW;
}

sub prod_Xls_Head(){
	if (!(@TAB_HEAD)) {
		@TAB_HEAD =("START_HEAD", "Suite...", "STOP_HEAD");
	}
	&prod_Xls_Insert_Val (@TAB_HEAD);
	1;
}

sub prod_Xls_Set_Format(){
	#  DEFINITION DES FORMATS PAR DEFAUT
	$XLS_FORMAT{'T1'} =${$LOCAL_REF_WORKBOOK}->add_format();
	$XLS_FORMAT{'T1'} ->set_bold(1);
	$XLS_FORMAT{'T1'} ->set_align('center');
	$XLS_FORMAT{'T1'} ->set_align('vcenter');
	$XLS_FORMAT{'T1'} ->set_size($FNTSZ1);
	$XLS_FORMAT{'T1'} ->set_border(0);

	$XLS_FORMAT{'T2'}=${$LOCAL_REF_WORKBOOK}->add_format();
	$XLS_FORMAT{'T2'}->set_bold(1);
	$XLS_FORMAT{'T2'}->set_align('center');
	$XLS_FORMAT{'T2'}->set_align('vcenter');
	$XLS_FORMAT{'T2'}->set_color('white');
	$XLS_FORMAT{'T2'}->set_size($FNTSZ2);
	$XLS_FORMAT{'T2'}->set_bg_color('black');
	$XLS_FORMAT{'T2'}->set_border(1);
	$XLS_FORMAT{'T2'}->set_text_wrap();

	$XLS_FORMAT{'T3'}=${$LOCAL_REF_WORKBOOK}->add_format();
	$XLS_FORMAT{'T3'}->set_bold(1);
	$XLS_FORMAT{'T3'}->set_align('left');
	$XLS_FORMAT{'T3'}->set_color('white');
	$XLS_FORMAT{'T3'}->set_size($FNTSZ3);
	$XLS_FORMAT{'T3'}->set_bg_color('black');
	$XLS_FORMAT{'T3'}->set_border(1);
	$XLS_FORMAT{'T3'}->set_text_wrap();

	$XLS_FORMAT{'T4'}=${$LOCAL_REF_WORKBOOK}->add_format();
	$XLS_FORMAT{'T4'}->set_bold(1);
	$XLS_FORMAT{'T4'}->set_align('left');
	$XLS_FORMAT{'T4'}->set_size($FNTSZ3);
	$XLS_FORMAT{'T4'}->set_border(1);
	$XLS_FORMAT{'T4'}->set_text_wrap();

	$XLS_FORMAT{'BD'} =${$LOCAL_REF_WORKBOOK}->add_format();
	$XLS_FORMAT{'BD'} ->set_bold(1);
	$XLS_FORMAT{'BD'} ->set_align('center');
	$XLS_FORMAT{'BD'} ->set_border(1);
	$XLS_FORMAT{'BD'} ->set_size($FNTSZ3);
	$XLS_FORMAT{'BD'}->set_text_wrap();

	$XLS_FORMAT{'AL'} =${$LOCAL_REF_WORKBOOK}->add_format();
	$XLS_FORMAT{'AL'} ->set_align('left');
	$XLS_FORMAT{'AL'} ->set_border(1);
	$XLS_FORMAT{'AL'} ->set_size($FNTSZ3);
	$XLS_FORMAT{'AL'} ->set_num_format('@'); # POUR EMPECHER EXCEL DE RECONVERTIR LES VALEURS NUMÉRIQUES EN NUMÉRIQUES
	$XLS_FORMAT{'AL'}->set_text_wrap();

	$XLS_FORMAT{'AR'} =${$LOCAL_REF_WORKBOOK}->add_format();
	$XLS_FORMAT{'AR'} ->set_align('right');
	$XLS_FORMAT{'AR'} ->set_border(1);
	$XLS_FORMAT{'AR'} ->set_size($FNTSZ3);
	$XLS_FORMAT{'AR'} ->set_num_format('@'); # POUR EMPECHER EXCEL DE RECONVERTIR LES VALEURS NUMÉRIQUES EN NUMÉRIQUES
	$XLS_FORMAT{'AR'}->set_text_wrap();

	$XLS_FORMAT{'AC'} =${$LOCAL_REF_WORKBOOK}->add_format();
	$XLS_FORMAT{'AC'} ->set_align('center');
	$XLS_FORMAT{'AC'} ->set_border(1);
	$XLS_FORMAT{'AC'} ->set_size($FNTSZ3);
	$XLS_FORMAT{'AC'} ->set_num_format('@'); # POUR EMPECHER EXCEL DE RECONVERTIR LES VALEURS NUMÉRIQUES EN NUMÉRIQUES

	$XLS_FORMAT{'Ac'} =${$LOCAL_REF_WORKBOOK}->add_format();
	$XLS_FORMAT{'Ac'} ->set_align('center');
	$XLS_FORMAT{'Ac'} ->set_border(1);
	$XLS_FORMAT{'Ac'} ->set_size($FNTSZ3);
	$XLS_FORMAT{'Ac'} ->set_num_format('@'); # POUR EMPECHER EXCEL DE RECONVERTIR LES VALEURS NUMÉRIQUES EN NUMÉRIQUES
	$XLS_FORMAT{'Ac'}->set_text_wrap();

	$XLS_FORMAT{'NR'} =${$LOCAL_REF_WORKBOOK}->add_format();
	$XLS_FORMAT{'NR'} ->set_size($FNTSZ3);
	$XLS_FORMAT{'NR'} ->set_num_format('# ### ##0.00'); # UN MONTANT DOIT ÊTRE PASSÉ AU FORMAT US
	$XLS_FORMAT{'NR'} ->set_align('right');
	$XLS_FORMAT{'NR'} ->set_border(1);

	$XLS_FORMAT{'NC'} =${$LOCAL_REF_WORKBOOK}->add_format();
	$XLS_FORMAT{'NC'} ->set_size($FNTSZ3);
	$XLS_FORMAT{'NC'} ->set_num_format('# ### ##0.00'); # UN MONTANT DOIT ÊTRE PASSÉ AU FORMAT US
	$XLS_FORMAT{'NC'} ->set_align('center');
	$XLS_FORMAT{'NC'} ->set_border(1);

	$XLS_FORMAT{'NL'} =${$LOCAL_REF_WORKBOOK}->add_format();
	$XLS_FORMAT{'NL'} ->set_size($FNTSZ3);
	$XLS_FORMAT{'NL'} ->set_num_format('# ### ##0.00'); # UN MONTANT DOIT ÊTRE PASSÉ AU FORMAT US
	$XLS_FORMAT{'NL'} ->set_align('left');
	$XLS_FORMAT{'NL'} ->set_border(1);

	1;
}

sub prod_Xls_Liste_Output (){
	return @TAB_LISTE_XLS;
}

sub  prod_Xls_Close(;$$) {
	my $fi =shift;
	# EDITION EVENTUELLE DE LA DERNIERE LIGNE ET PURGE DU TAMPON
	prod_Xls_Edit_Ligne();

	my $cwd = getcwd();
	# ON INDIQUE LA LISTE DES FICHIERS EXCEL PRODUITS
	foreach (prod_Xls_Liste_Output()) {
		print "$cwd/$_\n";
	}

	${$LOCAL_REF_WORKBOOK}->close() or die "ERR. closing file, return code $!\nDIE";

	if ($fi) {
		close (IN)  or die "ERR. fermeture $fi, return code $!\nDIE";
	}

	undef $LOCAL_REF_WORKBOOK;
	1;
}


END {
	prod_Xls_Close() if ($LOCAL_REF_WORKBOOK);
}

1;

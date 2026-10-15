package oEdtk::libXls;

use strict;
use utf8;

use Cwd;
use oEdtk::Main;
use File::Basename;
use Spreadsheet::WriteExcel;
use oEdtk::Config qw(config_read);

use Exporter;

our $VERSION = 2.1109;
our @ISA     = qw(Exporter);
our @EXPORT  = qw(prod_Xls_Init
	prod_Xls_New		prod_Xls_Insert_Val
	prod_Xls_Col_Init	prod_Xls_Edit_Ligne
	prod_Xls_Row_Height	prod_Xls_Add_Sheet
	prod_Xls_Close		prod_Xls_Liste_Output
	%XLS_FORMAT);

my $LOCAL_REF_WORKBOOK;
my $CFG = config_read();

# METHODS ASSOCIATED WITH EXCEL FORMAT HANDLING
my $MAX_ROW_BY_FIC = $CFG->{'EDTK_XLS_MAX_ROW'};
my $XLSCOL         = 0;
my $XLSROW         = 0;
my $XLSHEIG        = undef;
my $MAXCOL         = 32;
my $FNTSZ1         = 12;
my $FNTSZ2         = 10;
my $FNTSZ3         = 8;
my $SHEET          = 0;
our %XLS_FORMAT;

my @TAB_VALUE;
my @TAB_HEAD;
my @TAB_COL_SIZE;
my @TAB_LISTE_XLS;
my ( $FILENAME_REF, $XLS_NAME, $HEADER_LEFT, $HEADER_CENTER, $HEADER_RIGHT );

sub prod_Xls_Init {

	# EXCEL SHEET INITIALIZATION
	# ARGUMENTS: [LEFT HEADER TEXT], [CENTER HEADER TEXT], [RIGHT HEADER TEXT]
	( $HEADER_LEFT, $HEADER_CENTER, $HEADER_RIGHT ) = @_;
	$HEADER_RIGHT ||= "Édition du &D";

	# BASED ON THE NUMBER OF ELEMENTS, BUILD THE NEXT FILE INDEX
	my $item = sprintf( "%03s", $#TAB_LISTE_XLS + 2 );

	eval { $XLS_NAME = $CFG->{'EDTK_PRGNAME'} . "." . $item . "." . $CFG->{'EDTK_EXT_EXCEL'}; };
	if ($@) {
		$XLS_NAME = $ARGV[0] . $item . ".xls";
	}

	#	$XLS_NAME = basename($TXT_NAME);
	#	$XLS_NAME =~ s/\.[^.]+/.xls/;
	#	$XLS_NAME =~ s/(.+)\.\D{2,}$/$1.xls/;
	push( @TAB_LISTE_XLS, $XLS_NAME );

	#	if ($#TAB_LISTE_XLS==0) {$FILENAME_REF=$XLS_NAME;}

	# CREATE AN EXCEL FILE
	my $workbook = Spreadsheet::WriteExcel->new($XLS_NAME)
		or die "failed to open $XLS_NAME, return code $!\n";
	$LOCAL_REF_WORKBOOK = \$workbook;

	# ADD AN EXCEL SHEET
	my $worksheet = $workbook->add_worksheet( $0 =~ /([\w-]+)\.pl$/ )
		; # CREATE A SHEET IN THE WORKBOOK; THIS SHEET CARRIES THE PERL APP NAME WITHOUT THE .PL EXTENSION
	&prod_Xls_Set_Format();
	&prod_Xls_Set_Sheet($worksheet);

	return \$workbook;
}

sub prod_Xls_New {

	# two optional parameters
	# 	- "HEAD" to repeat the table head
	#	#	- a file name root (integrates with automatic file breaking)
	if ( $TAB_LISTE_XLS[0] ) {
		my $option1 = shift;
		$option1 ||= "";
		if ( $option1 eq "HEAD" ) {
			&prod_Xls_Head;
		}

		# CREATE A NEW XLS FILE
		# GET THE FILE NAME FROM THE ARRAY IF NOT PASSED AS A PARAMETER
		#		my $xls_name;
		#		if ($xls_name=shift) {$FILENAME_REF=$xls_name;}
		#		$xls_name ||=$FILENAME_REF;

		# BASED ON THE NUMBER OF ELEMENTS, BUILD THE NEXT FILE INDEX
		#		my $item= sprintf ("%03s", $#TAB_LISTE_XLS+2);

		# BUILD THE FILE NAME
		#		$xls_name=~s/(.+\.).*$/$1$item.xls/;

		# CREATE THE NEW FILE WITH ITS DEFAULT PROPERTIES
		$SHEET  = 0;
		$XLSROW = 0;

		#return prod_Xls_Init($xls_name,$HEADER_LEFT,$HEADER_CENTER,$HEADER_RIGHT);
		return prod_Xls_Init( $HEADER_LEFT, $HEADER_CENTER, $HEADER_RIGHT );
	}
	else {
		die "No init found for prodEdtkXls\n";
	}
}

sub prod_Xls_Col_Init {

	# INITIALIZE AND DEFINE THE STYLE AND WIDTH PROPERTIES OF THE COLUMNS
	my $paire = "";
	my $cpt   = 0;
	while ( my $paire = shift ) {
		if   ( $paire =~ /^(\D*)/ ) { $TAB_COL_SIZE[$cpt][0] = $1; }
		else                        { $TAB_COL_SIZE[$cpt][0] = 'AC'; }
		if   ( $paire =~ /([\d\.]*)$/ ) { $TAB_COL_SIZE[$cpt][1] = $1; }
		else                            { $TAB_COL_SIZE[$cpt][1] = 10; }
		$cpt++;
	}
	1;
}

sub prod_Xls_Row_Height {
	$XLSHEIG = shift;

	my $worksheet = ${$LOCAL_REF_WORKBOOK}->sheets($SHEET);
	$worksheet->set_row( $XLSROW, $XLSHEIG );
	$XLSHEIG = undef;
	1;
}

sub prod_Xls_Add_Sheet {
	my $sheetName = shift;
	my $worksheet = ${$LOCAL_REF_WORKBOOK}->add_worksheet($sheetName);
	&prod_Xls_Set_Sheet($worksheet);
	$SHEET++;
	$XLSROW = 0;

	if (@TAB_HEAD) {
		&prod_Xls_Head;
	}

	return $worksheet;
}

sub prod_Xls_Set_Sheet {
	my $worksheet         = shift;
	my $doc_HEADER_LEFT   = '&L&10&"Arial,Bold"' . $HEADER_LEFT;
	my $doc_HEADER_CENTER = '&C&10&"Arial,Bold"' . $HEADER_CENTER;
	my $doc_HEADER_RIGHT  = '&R&10&"Arial,Bold"' . $HEADER_RIGHT;
	my $ref               = '&L&6Réf/doc : &A - Edité le &D - &P - &F' . '&R&10Page &P/&N';

	$worksheet->set_paper(0);            # PRINT FORMAT (PRINTER DEFAULT))
	$worksheet->set_landscape();         # SET_PORTRAIT() # TO BE PUT IN A VARIABLE
	$worksheet->set_margins_LR(0.4);     # IN INCHES
	$worksheet->set_margins_TB(0.65);    # IN INCHES
	$worksheet->fit_to_pages( 1, 0 );    # FIT THE PRINT TO THE PAGE WIDTH
	$worksheet->set_header( "$doc_HEADER_LEFT$doc_HEADER_CENTER$doc_HEADER_RIGHT", 0.4 );
	$worksheet->set_footer( $ref, 0.4 );
	$worksheet->center_horizontally();
	$worksheet->hide_gridlines();
	$worksheet->freeze_panes( 1, 0 );    # FREEZE THE FIRST ROW FOR VIEWING
	$worksheet->repeat_rows(0)
		;    # ROW TO REPEAT AT THE TOP OF EACH PAGE FOR PRINTING # TO BE PUT IN A VARIABLE

	# DEFINE THE FORMAT OF EACH COLUMN
	$worksheet->set_column( 0, $MAXCOL, 10, $XLS_FORMAT{'AL'} );    # DEFAULT FORMAT

	my $i = 0;

	# IF THE COLUMNS ARE DEFINED WITH STYLES AND WIDTH, TAKE THE PROPERTIES INTO ACCOUNT
	while ( $TAB_COL_SIZE[$i][0] ) {
		$worksheet->set_column( $i, $i, $TAB_COL_SIZE[$i][1], $XLS_FORMAT{ $TAB_COL_SIZE[$i][0] } );
		$i++;
	}
	1;
}

sub prod_Xls_Insert_Val {

	# ADD THE PASSED VALUE(S) TO THE LOCAL VALUE ARRAY

	@TAB_VALUE = ( @TAB_VALUE, @_ );
	1;
}

sub prod_Xls_Edit_Ligne {

	# THE FUNCTION CAN RECEIVE AS PARAMETERS
	#	$format = A SINGLE FORMATTING INSTRUCTION FOR THE CURRENT ROW
	#	$f_tete_col = "HEAD" DESIGNATES A COLUMN HEAD TO REPEAT ON EACH PAGE
	my $oldFormat  = 0;
	my $format     = shift;    # OPTION
	my $f_tete_Col = shift;    # OPTION
	$f_tete_Col ||= "";

	# DO NOT OUTPUT ROWS WITHOUT VALUES (COMPLETELY EMPTY)
	if ( $#TAB_VALUE == -1 ) {
		return "OK", $XLSROW;    # Exit
	}

	my $worksheet     = ${$LOCAL_REF_WORKBOOK}->sheets($SHEET);
	my $statut        = "OK";
	my $col           = 0;       # THIS VARIABLE ALLOWS RESTARTING FROM THE FIRST COLUMN IN THE ROW
	my $format_unique = 0;
	if ($format) {
		$format_unique = 1;
	}

	if ( $f_tete_Col eq "HEAD" ) {
		undef @TAB_HEAD;
		@TAB_HEAD = ( "START_HEAD_$format", @TAB_VALUE, "STOP_HEAD" );
	}

	# PROCESS THE ARRAY VALUES ONE BY ONE
	#  CELL BY CELL, INCLUDING UNDEF VALUES
	while ( $#TAB_VALUE > -1 ) {
		my $valeur = shift(@TAB_VALUE);
		if ($format_unique) {    # the whole row is formatted with the format passed as a parameter
		}
		elsif ( $TAB_COL_SIZE[$col][0] ) {    # predefined format
			$format = $TAB_COL_SIZE[$col][0];

		}
		else {
			$format = "AC";                   # default format
		}

		if ( $valeur =~ /NEW_PAGE/ ) {
			$worksheet->set_h_pagebreaks( $XLSROW + 1 );
			$col++;
		}
		elsif ( $valeur =~ /NEW_LINE/ ) {
			$col = 0;
			$XLSROW++;
		}
		elsif ( $valeur =~ /STOP_HEAD/ ) {
			$format_unique = $oldFormat;
		}
		elsif ( $valeur =~ /START_HEAD/ ) {
			$oldFormat = $format_unique;
			if ( $valeur =~ /START_HEAD_(\w{2})/ ) {
				$format        = $1;
				$format_unique = 1;
			}
			else {
				$format_unique = 0;
			}

			# OPEN A NEW EXCEL FILE
			if ( $XLSROW != 0 ) {
				&prod_Xls_New();
			}
		}
		elsif ( ref $format eq 'HASH' ) {

			# enrich the cell formatting format
			# note: modified values are not saved
			my $xlsfmt = ${$LOCAL_REF_WORKBOOK}->add_format();
			if ( $TAB_COL_SIZE[$col][0] ) {
				$xlsfmt->copy( $XLS_FORMAT{ $TAB_COL_SIZE[$col][0] } );
			}
			$xlsfmt->set_format_properties(%$format);
			$worksheet->write( $XLSROW, $col, $valeur, $xlsfmt );
			$col++;
		}
		elsif ( $format =~ /^N/ ) {
			$valeur =~ s/\s//g;
			$worksheet->write_number( $XLSROW, $col, $valeur, $XLS_FORMAT{$format} );
			$col++;
		}
		else {
			$valeur =~ s/\ +/ /g;    # only spaces are replaced by characters such as cr lf
			$worksheet->write_string( $XLSROW, $col, $valeur, $XLS_FORMAT{$format} );
			$col++;
		}
	}
	if ( $col > 0 ) { $XLSROW++; }

	if ( $XLSROW < ( $MAX_ROW_BY_FIC - 1 ) ) {
		$statut = "OK";
	}
	elsif ( $XLSROW == ( $MAX_ROW_BY_FIC - 1 ) ) {
		$statut = "WARN_EOF";
	}
	elsif ( $XLSROW > $MAX_ROW_BY_FIC - 1 ) {
		$statut = "NEW";

		&prod_Xls_New('HEAD');
		&prod_Xls_Insert_Val("NEW_LINE");

		#print "XLSROW=$XLSROW  - \$#TAB_VALUE=$#TAB_VALUE /insert head @TAB_VALUE \n" ;
	}

	return $statut, $XLSROW;
}

sub prod_Xls_Head() {
	if ( !(@TAB_HEAD) ) {
		@TAB_HEAD = ( "START_HEAD", "Continued...", "STOP_HEAD" );
	}
	&prod_Xls_Insert_Val(@TAB_HEAD);
	1;
}

sub prod_Xls_Set_Format() {

	#  DEFINE THE DEFAULT FORMATS
	$XLS_FORMAT{'T1'} = ${$LOCAL_REF_WORKBOOK}->add_format();
	$XLS_FORMAT{'T1'}->set_bold(1);
	$XLS_FORMAT{'T1'}->set_align('center');
	$XLS_FORMAT{'T1'}->set_align('vcenter');
	$XLS_FORMAT{'T1'}->set_size($FNTSZ1);
	$XLS_FORMAT{'T1'}->set_border(0);

	$XLS_FORMAT{'T2'} = ${$LOCAL_REF_WORKBOOK}->add_format();
	$XLS_FORMAT{'T2'}->set_bold(1);
	$XLS_FORMAT{'T2'}->set_align('center');
	$XLS_FORMAT{'T2'}->set_align('vcenter');
	$XLS_FORMAT{'T2'}->set_color('white');
	$XLS_FORMAT{'T2'}->set_size($FNTSZ2);
	$XLS_FORMAT{'T2'}->set_bg_color('black');
	$XLS_FORMAT{'T2'}->set_border(1);
	$XLS_FORMAT{'T2'}->set_text_wrap();

	$XLS_FORMAT{'T3'} = ${$LOCAL_REF_WORKBOOK}->add_format();
	$XLS_FORMAT{'T3'}->set_bold(1);
	$XLS_FORMAT{'T3'}->set_align('left');
	$XLS_FORMAT{'T3'}->set_color('white');
	$XLS_FORMAT{'T3'}->set_size($FNTSZ3);
	$XLS_FORMAT{'T3'}->set_bg_color('black');
	$XLS_FORMAT{'T3'}->set_border(1);
	$XLS_FORMAT{'T3'}->set_text_wrap();

	$XLS_FORMAT{'T4'} = ${$LOCAL_REF_WORKBOOK}->add_format();
	$XLS_FORMAT{'T4'}->set_bold(1);
	$XLS_FORMAT{'T4'}->set_align('left');
	$XLS_FORMAT{'T4'}->set_size($FNTSZ3);
	$XLS_FORMAT{'T4'}->set_border(1);
	$XLS_FORMAT{'T4'}->set_text_wrap();

	$XLS_FORMAT{'BD'} = ${$LOCAL_REF_WORKBOOK}->add_format();
	$XLS_FORMAT{'BD'}->set_bold(1);
	$XLS_FORMAT{'BD'}->set_align('center');
	$XLS_FORMAT{'BD'}->set_border(1);
	$XLS_FORMAT{'BD'}->set_size($FNTSZ3);
	$XLS_FORMAT{'BD'}->set_text_wrap();

	$XLS_FORMAT{'AL'} = ${$LOCAL_REF_WORKBOOK}->add_format();
	$XLS_FORMAT{'AL'}->set_align('left');
	$XLS_FORMAT{'AL'}->set_border(1);
	$XLS_FORMAT{'AL'}->set_size($FNTSZ3);
	$XLS_FORMAT{'AL'}->set_num_format('@')
		;    # TO PREVENT EXCEL FROM CONVERTING NUMERIC VALUES BACK TO NUMBERS
	$XLS_FORMAT{'AL'}->set_text_wrap();

	$XLS_FORMAT{'AR'} = ${$LOCAL_REF_WORKBOOK}->add_format();
	$XLS_FORMAT{'AR'}->set_align('right');
	$XLS_FORMAT{'AR'}->set_border(1);
	$XLS_FORMAT{'AR'}->set_size($FNTSZ3);
	$XLS_FORMAT{'AR'}->set_num_format('@')
		;    # TO PREVENT EXCEL FROM CONVERTING NUMERIC VALUES BACK TO NUMBERS
	$XLS_FORMAT{'AR'}->set_text_wrap();

	$XLS_FORMAT{'AC'} = ${$LOCAL_REF_WORKBOOK}->add_format();
	$XLS_FORMAT{'AC'}->set_align('center');
	$XLS_FORMAT{'AC'}->set_border(1);
	$XLS_FORMAT{'AC'}->set_size($FNTSZ3);
	$XLS_FORMAT{'AC'}->set_num_format('@')
		;    # TO PREVENT EXCEL FROM CONVERTING NUMERIC VALUES BACK TO NUMBERS

	$XLS_FORMAT{'Ac'} = ${$LOCAL_REF_WORKBOOK}->add_format();
	$XLS_FORMAT{'Ac'}->set_align('center');
	$XLS_FORMAT{'Ac'}->set_border(1);
	$XLS_FORMAT{'Ac'}->set_size($FNTSZ3);
	$XLS_FORMAT{'Ac'}->set_num_format('@')
		;    # TO PREVENT EXCEL FROM CONVERTING NUMERIC VALUES BACK TO NUMBERS
	$XLS_FORMAT{'Ac'}->set_text_wrap();

	$XLS_FORMAT{'NR'} = ${$LOCAL_REF_WORKBOOK}->add_format();
	$XLS_FORMAT{'NR'}->set_size($FNTSZ3);
	$XLS_FORMAT{'NR'}->set_num_format('# ### ##0.00')
		;    # A MONETARY AMOUNT MUST BE PASSED IN US FORMAT
	$XLS_FORMAT{'NR'}->set_align('right');
	$XLS_FORMAT{'NR'}->set_border(1);

	$XLS_FORMAT{'NC'} = ${$LOCAL_REF_WORKBOOK}->add_format();
	$XLS_FORMAT{'NC'}->set_size($FNTSZ3);
	$XLS_FORMAT{'NC'}->set_num_format('# ### ##0.00')
		;    # A MONETARY AMOUNT MUST BE PASSED IN US FORMAT
	$XLS_FORMAT{'NC'}->set_align('center');
	$XLS_FORMAT{'NC'}->set_border(1);

	$XLS_FORMAT{'NL'} = ${$LOCAL_REF_WORKBOOK}->add_format();
	$XLS_FORMAT{'NL'}->set_size($FNTSZ3);
	$XLS_FORMAT{'NL'}->set_num_format('# ### ##0.00')
		;    # A MONETARY AMOUNT MUST BE PASSED IN US FORMAT
	$XLS_FORMAT{'NL'}->set_align('left');
	$XLS_FORMAT{'NL'}->set_border(1);

	1;
}

sub prod_Xls_Liste_Output () {
	return @TAB_LISTE_XLS;
}

sub prod_Xls_Close {
	my $fi = shift;

	# POSSIBLE OUTPUT OF THE LAST ROW AND FLUSH OF THE BUFFER
	prod_Xls_Edit_Ligne();

	my $cwd = getcwd();

	# PRINT THE LIST OF EXCEL FILES PRODUCED
	foreach ( prod_Xls_Liste_Output() ) {
		print "$cwd/$_\n";
	}

	${$LOCAL_REF_WORKBOOK}->close() or die "ERR. closing file, return code $!\nDIE";

	if ($fi) {
		close(IN) or die "ERR. closing $fi, return code $!\nDIE";
	}

	undef $LOCAL_REF_WORKBOOK;
	1;
}

END {
	prod_Xls_Close() if ($LOCAL_REF_WORKBOOK);
}

1;

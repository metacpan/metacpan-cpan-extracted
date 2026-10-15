#!/usr/bin/perl
use oEdtk::Main;
use oEdtk::RecordParser;
use oEdtk::Tracking;
use oEdtk::DBAdmin qw (@INDEX_COLS);
use oEdtk::libXls;
use oEdtk::EDMS qw (EDMS_prepare);
use oEUser::Lib;
use Text::CSV;
use strict;
use warnings;

my ( %hPARM, %hRECORDS, $VALS, $DOC, $TRK, %hVARS_DOC, %hIDX );

sub main() {
	if ( $#ARGV == -1 ) { oe_app_usage(); }

	# TRACKING INITIALIZATION
	$TRK = oEdtk::Tracking->new(
		$ARGV[1],
		user   => "Test",
		entity => oe_corporation_set(),
		keys   => [ 'NUMADH', 'SECTION' ]
	);

	# oe_new_job(); # is replaced by:
	init_CSV();
	init_XLS();
	open( my $fi, "<" . $hPARM{encode}, $hPARM{input} )
		or die "ERROR: Cannot open file " . $hPARM{input} . " : $!\n";

	# CREATION OF AN EDITING INDEX ASSOCIATED WITH THE EXCEL FILE
	open( $hPARM{fo}, ">" . $hPARM{encode}, $hPARM{input} . ".idx" )
		or die "ERROR: Cannot open file " . $hPARM{input} . ".idx" . " : $!\n";

	# DOCUMENT-SPECIFIC INITIALIZATION
	init_Doc();

	my $line = <$fi>;
	$hPARM{csv}->parse($line);
	my @cols = $hPARM{csv}->fields();

	$hPARM{csv}->column_names(@cols);
	while ( $VALS = $hPARM{csv}->getline_hr($fi) ) {

# ED_REFIDDOC,ED_IDLDOC,ED_IDSEQPG,ED_SEQDOC,ED_CPDEST,ED_VILLDEST,ED_IDDEST,ED_NOMDEST,ED_IDEMET,ED_DTEDTION,ED_TYPPROD,ED_PORTADR,ED_ADRLN1,ED_CLEGED1,ED_ADRLN2,ED_CLEGED2,ED_ADRLN3,ED_CLEGED3,ED_ADRLN4,ED_CLEGED4,ED_ADRLN5,ED_CORP,ED_DOCLIB,ED_REFIMP,ED_ADRLN6,ED_SOURCE,ED_OWNER,ED_HOST,ED_IDIDX,ED_CATDOC,ED_CODRUPT,ED_IDLOT,ED_SEQLOT,ED_DTLOT,ED_IDFILIERE,ED_SEQPGDOC,ED_NBPGDOC,ED_POIDSUNIT,ED_NBENC,ED_ENCPDS,ED_BAC_INSERT,ED_TYPED,ED_MODEDI,ED_FORMATP,ED_PGORIEN,ED_FORMFLUX,ED_IDPLI,ED_NBDOCPLI,ED_NUMPGPLI,ED_NBPGPLI,ED_NBFPLI,ED_LISTEREFENC,ED_PDSPLI,ED_TYPOBJ,ED_STATUS,ED_DTPOSTE
		$hIDX{'ED_REFIDDOC'} = oe_ID_LDOC();
		$hIDX{'ED_IDEMET'}   = $VALS->{'ED_IDEMET'};
		$hIDX{'ED_IDDEST'}   = $VALS->{'ED_IDDEST'};
		$hIDX{'ED_NOMDEST'}  = $VALS->{'ED_NOMDEST'};
		$hIDX{'ED_DTLOT'}    = $VALS->{'ED_DTLOT'};
		$hIDX{'ED_DOCLIB'}   = $VALS->{'ED_DOCLIB'};

		prod_Xls_Insert_Val( $VALS->{'ED_IDEMET'} );
		prod_Xls_Insert_Val( $VALS->{'ED_IDDEST'} );
		prod_Xls_Insert_Val( $VALS->{'ED_NOMDEST'} );
		prod_Xls_Insert_Val( $VALS->{'ED_DTLOT'} );
		prod_Xls_Insert_Val( $VALS->{'ED_DOCLIB'} );
		prod_Xls_Edit_Ligne();

		edit_ligne_index();
		track_XLS();
	}

	my $doc_path = "./";
	my $idx_path = "./";
	EDMS_prepare( "sample-excel", oe_ID_LDOC(), $doc_path, $idx_path );
}

sub edit_ligne_index () {
	my @idxcols = map { $$_[0] } @INDEX_COLS[ 0 .. 28 ];
	my @fields;
	foreach my $key (@idxcols) {
		push( @fields, $hIDX{$key} );
	}

	$hPARM{idx}->print( $hPARM{fo}, \@fields );
}

sub init_CSV {
	%hPARM = (

		#		"encode"		=> ":encoding(UTF-8)",
		"encode"     => "",
		"input"      => $ARGV[0],
		"sep_char"   => ',',
		"quote_char" => '"'
	);

	$hPARM{csv} = Text::CSV->new(
		{
			binary     => 1,
			sep_char   => $hPARM{sep_char},
			quote_char => $hPARM{quote_char}
		}
	);
	$hPARM{idx} = Text::CSV->new( { binary => 1, sep_char => ';', eol => "\n", quote_space => 0 } );
}

sub init_XLS {
	###########################################################################
	# EXCEL DOCUMENT CONFIGURATION
	###########################################################################
	#
	# 	OPTIONAL: DEFAULT FORMATTING OF THE EXCEL TABLE COLUMNS
	# 	(AC7 = Alpha Center 7 wide ; Ac7 = Alpha Center Wrap... ; NR7 = Numeric Right...  )
	prod_Xls_Col_Init( 'AC05', 'AC15', 'AL20', 'AC15', 'AC30' );
	#
	###########################################################################
	# 	REQUIRED!
	# 	OPENING AND CONFIGURATION OF THE DOCUMENT
	#	prod_Xls_Init opens an XLS file
	# 		parameter 1 is mandatory (file name)
	#		the following parameters are optional
	###########################################################################
	prod_Xls_Init( "", "Listing Sample CSV" );    #  ,"ENTETE DROIT");

	# DOCUMENT FORMATTING SPECIFIC INITIALIZATIONS
	# PREPARATION OF THE COLUMN HEADERS
	prod_Xls_Insert_Val("ER");
	prod_Xls_Insert_Val("NUMADH");
	prod_Xls_Insert_Val("NOM");
	prod_Xls_Insert_Val("DATE");
	prod_Xls_Insert_Val("DCLIB");

	#COLUMN HEADER OUTPUT (the parameters are optional)
	# 	parameter 1 is the style for the line, 'HEAD' declares the line as a table header
	prod_Xls_Row_Height(32);
	prod_Xls_Edit_Ligne( 'T2', 'HEAD' );

	1;
}

sub init_Doc() {

# BY PUTTING ALL DOCUMENT VARIABLES IN A HASH, I HAVE FEWER VARIABLES AND REINITIALIZE EVERYTHING AT ONCE...
	undef %hIDX;
	undef %hVARS_DOC;
	$hVARS_DOC{LAST_NSECU} = "";

	return 1;
}

sub track_XLS {
	$TRK->track( 'Rejet', 1, $VALS->{'ED_IDDEST'}, $VALS->{'ED_IDEMET'} );
}

main();
1;

#!/usr/bin/perl -w
use oEdtk::Main		0.42; 
use oEdtk::libXls;

#################################################################################
# MAIN BODY OF THE APPLICATION:
#################################################################################

sub run() {
	# OPENING THE STREAMS
	&fXlsOpen("cp_fr_fixe.dat"); # TO BE REPLACED SEE PACKAGE

	# APPLICATION INITIALIZATION AND MAPPING
	&initApp();
	# DOCUMENT-SPECIFIC INITIALIZATION
	&initDoc();

	while (my $ligne=<IN> && $.<2000 ) {
		chomp ($ligne);

		if 		(oe_trt_ref_rec('X',$ligne,0,)){
				# END record processing 

		} else {
			# IF NO RECORD TYPE IS RECOGNIZED
			print STDERR "UNKNOWN LINE: $ligne\n";
		}
		prod_Xls_Edit_Ligne();
	}

1;
}


#################################################################################
# APPLICATION-SPECIFIC FUNCTIONS
#################################################################################
sub initApp{
	# DECLARATIONS OF APPLICATION-SPECIFIC VARIABLES

	# APPLICATION MAPPING 
	oe_rec_motif 	('X', 'A13 A35 A11 A8 A*');
	oe_rec_process	('X', \&trtEnr);

1;
}

sub initDoc {
	###########################################################################
	# EXCEL DOCUMENT CONFIGURATION
	###########################################################################
	#
	# 	OPTIONAL: DEFAULT FORMATTING OF THE EXCEL TABLE COLUMNS 
	# 	(AC7 = Alpha Center 7 wide ; Ac7 = Alpha Center Wrap... ; NR7 = Numeric Right...  ) 
	prod_Xls_Col_Init('AC8', 'AL28.2', 'AC5.5', 'AC8.3', 'AL26.5');
	#
	###########################################################################
	# 	REQUIRED!
	# 	OPENING AND CONFIGURATION OF THE DOCUMENT
	#	prod_Xls_Init opens an XLS file
	# 		parameter 1 is mandatory (file name)
	#		the following parameters are optional
	###########################################################################	
	prod_Xls_Init("oEdtk","LISTE CODE POSTAUX", "FRANCE");

	# DOCUMENT FORMATTING SPECIFIC INITIALIZATIONS
	# PREPARATION OF THE COLUMN HEADERS
	#prod_Xls_Insert_Val("TITLE 1");
	#prod_Xls_Insert_Val("TITLE 2");
	#prod_Xls_Insert_Val("TITLE 3");
	#etc.

	#COLUMN HEADER OUTPUT (the parameters are optional)
	# 	parameter 1 is the style for the line, 'HEAD' declares the line as a table header
	#prod_Xls_Edit_Ligne('T2','HEAD');

1;
}


sub trtEnr() {
	# PREPARATION OF THE RECORD DATA
	prod_Xls_Insert_Val($DATATAB[0]);
	prod_Xls_Insert_Val($DATATAB[1]);
	prod_Xls_Insert_Val($DATATAB[2]);
	prod_Xls_Insert_Val($DATATAB[3]);
	prod_Xls_Insert_Val($DATATAB[4]);
	
	# for the test the headers are on the first line of the file
	if ($.==1) { prod_Xls_Edit_Ligne('T2','HEAD'); }

1;
}

sub fXlsOpen ($){  # TO BE REPLACED SEE PACKAGE
	my $fi =shift;

	open (IN,  "$fi")	or die "failed to open $fi, return code $!\n";
1;
}


#main;
1;

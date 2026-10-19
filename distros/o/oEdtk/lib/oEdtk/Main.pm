package oEdtk::Main;

use strict;
use utf8;
use warnings;
use feature 'state';

use Exporter;
our $VERSION = 2.1126;

our @ISA    = qw(Exporter);
our @EXPORT = qw(
	date2time
	prodEdtk_Current_Rec
	prodEdtk_Previous_Rec
	prodEtk_rec_cdata_join
	recEdtk_erase
	recEdtk_join_tmplte
	recEdtk_post_process
	recEdtk_redefine
	oe_app_usage
	oe_backgrounds_apps
	oe_CAP_sans_accents
	oe_char_xlate
	oe_clean_addr
	oe_clean_addr_line
	oe_close_fo
	oe_compo_link
	oe_corporation_get
	oe_corporation_set
	oe_corporation_tag
	oe_data_build
	oe_date_biggest
	oe_date_smallest
	oe_define_TeX_output
	oe_env_var_completion
	oe_fmt_date
	oe_get_handle_to_input_file
	oe_ID_LDOC
	oe_is_IDLDOC
	oe_iso_country
	oe_list_encodings
	oe_new_ID_LDOC
	oe_new_job
	oe_new_job_input_file
	oe_now_time
	oe_num_sign_x
	oe_num2txt_us
	oe_open_fi_IN
	oe_open_fo_OUT
	oe_options
	oe_params
	oe_print_to_output_file
	oe_process_ref_rec
	oe_rec_motif
	oe_rec_output
	oe_rec_pre_process
	oe_rec_process
	oe_round
	oe_set_sys_date
	oe_simple_job
	oe_to_date
	oe_trimp_space
	oe_trt_ref_rec
	oe_uc_sans_accents
	oe_unique_data_name
	*OUT *IN  @DATATAB $LAST_ENR
	%motifs %ouTags %evalSsTrt
);

use POSIX      qw(mkfifo);
use Date::Calc qw(Add_Delta_Days Delta_Days Date_to_Time Today Gmtime Week_of_Year);
use Encode;
use File::Basename;
use Getopt::Long    qw(GetOptionsFromArray);
use List::MoreUtils qw(uniq);
use List::Util      qw(reduce);
use Math::Round     qw(nearest);
use Sys::Hostname;
use Scalar::Util qw(openhandle);
use Carp         qw(croak);
use Readonly;
use Data::UUID;

use oEdtk;
require oEdtk::Outmngr;
require oEdtk::TexDoc;
use oEdtk::Dict;
use oEdtk::Config qw(config_read);
use oEdtk::Run    qw(oe_status_to_msg oe_compo_run oe_after_compo oe_outmngr_output_run_tex);

#use oEUser::Lib;

#
# CODE - DOC AT THE END
#

# GENERIC METHOD FOR EXTRACTING AND PROCESSING DATA

our @DATATAB;              # the array into which records are distributed
                           # 	rename to OE_DATATAB
our $LAST_ENR     = "";    # WHAT ABOUT LAST_ENR ????
our $CURRENT_REC  = "";    # current record
our $PREVIOUS_REC = "";    # previous record

our %motifs;               #make private
our %ouTags;               #make private
our %evalSsTrt;            #make private

my $_ID_LDOC = '';         # initialize the unique document id (one per run)
my $_IDLDOC_FORMAT;
my $PUSH_VALUE = "";

# Default option values (see oe_options).
Readonly my %DEFAULT_OPTIONS => (
	index      => 0,
	massmail   => 0,
	edms       => 0,
	bpdf       => 0,
	cgi        => 0,
	input_code => 0
);

# [PRIVATE] Default dump mode (0: off, 1: on). Leave it at 0.
# @see _dump()
Readonly::Scalar my $_DEFAULT_OUTPUT_DUMP_MODE => 0;

# [PRIVATE] Default path of the output debug file.
# @see _dump()
Readonly::Scalar my $_DEFAULT_OUTPUT_DUMP_FILE => 'output.rec';

# PLANNED : CONFIGURATION OF OUTPUT SYSTEM
# 		return "\\long\\gdef\\$name\{$value\}";
my ( $TAG_OPEN, $TAG_CLOSE, $TAG_COMMENT );

sub oe_define_TeX_output() {

	# \\long\\gdef\\$name\{$value\}
	# \long\gdef\NUMCONT{000014770}
	# \long\gdef\PRENOM{MIREILLE}\long\gdef\DATE{01/08/2009}\long\gdef\NICY{10}\STARTGAR
	$TAG_OPEN    = "\\";    # a tag opening (open)
	$TAG_CLOSE   = "";      # a tag closing (close)
	$TAG_COMMENT = "%";     # a comment (rem)

	# \long\gdef\xProdApp\}
	1;
}

oe_define_TeX_output();     # default values

################################################################################
## 		GENERIC RECORD HELPERS, USED ELSEWHERE (XLS)
################################################################################

sub oe_rec_motif {    # migrate oe_rec_motif
					  # FUNCTION TO DESCRIBE THE UNPACK PATTERN OF THE RECORD
					  #
					  #  appel :
					  # 	oe_rec_motif ($keyRec, "A2 A10 A15 A10 A15 A*");
	my $keyRec = shift;
	my $motif  = shift;
	$motifs{$keyRec} = $motif;
	1;
}

sub oe_rec_pre_process {    # migrate oe_rec_pre_process
							# FUNCTION TO ATTACH A PRE-PROCESSING TO A RECORD
							#  this processing runs before the record is loaded into DATATAB
							#  the previous record content is always available in DATATAB
							#  the current record type is known in the execution context
							#
							#  appel :
							# 	oe_rec_pre_process ($keyRec, \&fonction);
	my $keyRec      = shift;
	my $refFonction = shift;
	$evalSsTrt{$keyRec}[0] = $refFonction;
	1;
}

sub oe_rec_output {    # migrate oe_rec_output
					   # FUNCTION TO DESCRIBE THE RECORD OUTPUT FORMAT FOR SPRINTF
					   #
					   #  appel :
					   # 	oe_rec_output ($keyRec, "<#GESTION=%s><#PENOCOD=%s><#LICCODC=%s><SK>%s");
	my $keyRec = shift;
	my $format = shift;
	$ouTags{$keyRec} = $format;
	1;
}

sub recEdtk_erase {    # migrate oe_rec_erase
					   # FUNCTION TO REMOVE THE PROCESSING OF A RECORD
					   #
					   #  appel :
					   # 	recEdtk_erase ($keyRec);
	my $keyRec = shift;
	$evalSsTrt{$keyRec}[0] = "";
	$evalSsTrt{$keyRec}[1] = "";
	$evalSsTrt{$keyRec}[2] = "";
	$motifs{$keyRec}       = "";
	$ouTags{$keyRec}       = "-1";
	1;
}

sub recEdtk_redefine {    # migrate oe_rec_redefine
						  # FUNCTION TO REDEFINE THE PROCESSING OF A RECORD
						  #
						  #  appel :
						  # 	recEdtk_redefine ($keyRec, "A2 A10 A15 A10 A15 A*");
	my $keyRec = shift;
	my $motif  = shift;
	recEdtk_erase($keyRec);
	oe_rec_motif( $keyRec, $motif );
	1;
}

sub recEdtk_join_tmplte {    # migrate oe_rec_joined_descriptors
							 # FUNCTION TO COMPLETE THE UNPACK PATTERN DESCRIPTORS OF THE RECORD
							 # AND THE OUTPUT FORMAT IN PARALLEL
							 #
							 #  appel :
							 # 	recEdtk_join_tmplte ("abc", 'A2', '<#tag=%s>');
							 # 	recEdtk_join_tmplte ($keyRec, $motif, $output);

	my $keyRec = shift;
	my $motif  = shift;
	$motif ||= "A*";
	my $output = shift;
	$output ||= "%s";
	$motifs{$keyRec} .= $motif;
	$ouTags{$keyRec} .= $output;
	$ouTags{$keyRec} =~ s/^\-1//
		; # when recEdtk_join_tmplte is used to set ouTags dynamically during oe_trt_ref_rec, the default ouTags value = '-1' (no processing) => remove it so as not to pollute the output
	1;
}

sub oe_rec_process {    # migrate oe_rec_process
						# FUNCTION TO ATTACH A PROCESSING TO A RECORD
						#  this processing runs right after the record is loaded into DATATAB
						#
						#  appel :
						# 	oe_rec_process ($keyRec, \&fonction);
	my $keyRec      = shift;
	my $refFonction = shift;
	$evalSsTrt{$keyRec}[1] = $refFonction;
	1;
}

sub recEdtk_post_process {    # migrate recEdtk_post_process
		# FUNCTION TO ATTACH A POST-PROCESSING TO A RECORD
		#  this processing runs right after the record is reformatted in format_sortie
		#  the record line is known in the execution context, in its "format_sortie" form
		#
		#  appel :
		# 	recEdtk_post_process ($keyRec, \&fonction);
	my $keyRec      = shift;
	my $refFonction = shift;
	$evalSsTrt{$keyRec}[2] = $refFonction;
	1;
}

## no critic (ProhibitSubroutinePrototypes)
sub oe_process_ref_rec ($$\$;$$) {    # migrate oe_process_ref_rec
		# COMBINED ANALYSIS AND PROCESSING OF RECORDS
		#  it wraps the complete analysis and processing of the record (oe_trt_ref_rec)
	 #  one call per key length, in decreasing order (from the strictest key to the least restrictive)
	 #  APPEL :
	 #	oe_process_ref_rec ($offsetKey, $lenKey, $ligne [,$offsetRec, $lenRec]);
	 #  RETURNS: status
	 #
	 #	example 			if 		(oe_process_ref_rec (0, 3, $ligne)){
	 #					} elsif 	(oe_process_ref_rec (0, 2, $ligne)){
	 #						etc.
	my $offsetKey = shift;
	my $lenKey    = shift;
	my $refLigne  = shift;
	my $offsetRec = shift;    # optional
	$offsetRec ||= 0;
	my $lenRec = shift;       # optional
	$lenRec ||= "";

	if ( ${$refLigne} =~ m/^.{$offsetKey}(\w{$lenKey})/s
		&& oe_trt_ref_rec( $1, $refLigne, $offsetRec, $lenRec ) )
	{
		# the record has been identified and processed
		# emit the record
		print OUT ${$refLigne};
		return 1;
	}

	# OTHERWISE THE RECORD WAS NOT RECOGNIZED, THIS IS A FAILURE
	return 0;
}

## no critic (ProhibitSubroutinePrototypes)
sub oe_trt_ref_rec ($\$;$$) {    # migrate oe_trt_ref_rec
		# MAIN RECORD PROCESSING
		# GENERIC METHOD V0.2.1 27/04/2009 10:05:03 (reference passing becomes implicit)
		# THE FUNCTION NEEDS THE RECORD TYPE AND THE REFERENCE TO A DATA LINE
		#  appel :
		#	oe_trt_ref_rec($Rec_ID, $ligne [,$offsetRec,$lenRec]);
		#  returns: status, $Rec_ID
	my $Rec_ID    = shift;
	my $refLigne  = shift;
	my $offsetRec = shift;    # OPTIONAL OFFSET OF DATA TO DROP AT THE START OF THE LINE
	my $lenRec    = shift;    # OPTIONAL LENGTH OF DATA TO PROCESS
							  # DEFAULT VALUES
	$ouTags{$Rec_ID} ||= "-1";
	$motifs{$Rec_ID} ||= "";
	$offsetRec       ||= 0;
	$lenRec          ||= "";

	# IF THE EXTRACTION PATTERN OF THE RECORD TYPE IS UNKNOWN,
	#  AND IF THERE IS NO PRE-PROCESSING ATTACHED TO THE RECORD TYPE,
	#  THEN THE RECORD TYPE IS UNKNOWN
	#
	# THIS CHECK ALLOWS DEFINING A RECORD TYPE DYNAMICALLY BASED ON THE CONTEXT
	#  THAT IS, A RECORD OF TYPE "1" MAY HAVE DIFFERENT CHARACTERISTICS
	#  DEPENDING ON THE PREVIOUSLY PROCESSED RECORD TYPE.
	#  THESE CHARACTERISTICS CAN BE SET AT PRE-PROCESSING TIME.
	#
	if ( $motifs{$Rec_ID} eq "" && !( $evalSsTrt{$Rec_ID}[0] ) ) {
		warn "INFO: oe_trt_ref_rec() > LINE $. REC. >$Rec_ID< (offset $offsetRec) UNKNOWN\n";
		return 0;
	}

	$PREVIOUS_REC = $CURRENT_REC;
	$CURRENT_REC  = $Rec_ID;

	# STEP 0 : EVAL PRE-PROCESSING of $refLigne
	&{ $evalSsTrt{$Rec_ID}[0] }($refLigne) if $evalSsTrt{$Rec_ID}[0];

	# MAKE SURE TO FULLY CLEAR THE READ ARRAY OF THE PREVIOUS RECORD
	undef @DATATAB;

	# OPTIONALLY DROP UNNEEDED DATA (OFFSET AND OUTSIDE USEFUL DATA (lenData))
	${$refLigne} =~ s/^.{$offsetRec}(.{1,$lenRec}).*/$1/ if ( $offsetRec > 0 );

	# SPLIT THE RECORD INTO FIELDS
	@DATATAB = unpack( $motifs{$Rec_ID}, ${$refLigne} )
		or die
		"ERROR: oe_trt_ref_rec() > LINE $. typEnr >$Rec_ID< motif >$motifs{$Rec_ID}< UNKNOWN\n";

	# STEP 1 : EVAL FIELD PROCESSING
	&{ $evalSsTrt{$Rec_ID}[1] } if $evalSsTrt{$Rec_ID}[1];

	# STRUCTURE THE RECORD FOR OUTPUT
	if ( $ouTags{$Rec_ID} ne "-1" ) {
		${$refLigne} = "${TAG_OPEN}a${Rec_ID}${TAG_CLOSE}";
		${$refLigne} .= sprintf( $ouTags{$Rec_ID}, @DATATAB )
			or die "ERROR: oe_trt_ref_rec() > LINE $. typEnr >$Rec_ID< ouTags >$ouTags{$Rec_ID}<\n";
		${$refLigne} .= "${TAG_OPEN}e${Rec_ID}${TAG_CLOSE}\n";
	}
	else {
		${$refLigne} = "";
	}
	$LAST_ENR = $Rec_ID;

	# STEP 2 : EVAL POST-PROCESSING
	&{ $evalSsTrt{$Rec_ID}[2] } if $evalSsTrt{$Rec_ID}[2];

	# OPTIONALLY ADD EXTRA DATA
	${$refLigne} .= $PUSH_VALUE;
	$PUSH_VALUE = "";
	${$refLigne} =~ s/\s{2,}/ /g;    #	CONCATENATION OF BLANKS
									 #$LAST_ENR=$Rec_ID;

	return 1, $Rec_ID;
}

sub prodEtk_rec_cdata_join {    # migrate prodEtk_rec_cdata_join
	$PUSH_VALUE .= shift;
	1;
}

sub prodEdtk_Previous_Rec () {    # migrate oe_previous_rec
	return $PREVIOUS_REC;
}

sub prodEdtk_Current_Rec () {    # migrate oe_current_rec
	return $CURRENT_REC;
}

################################################################################

sub oe_round {

# http://perl.enstimac.fr/allpod/fr-5.6.0/perlfaq4.pod
# http://perl.enstimac.fr/DocFr/perlfaq4.html
# http://www.linux-kheops.com/doc/perl/faq-perl-enstimac/perlfaq4.html
# Perl is not at fault. It is the same as in C. IEEE says we must do it this way. Perl numbers whose absolute value is an integer below 2**31 (on 32-bit machines) will generally behave as mathematical integers. Other numbers are not guaranteed.
	my $value    = shift;
	my $multiple = shift;
	my $decimal;    #=	shift;

	#if (!(defined $decimal)){$decimal = 2;}	# decimal may be 0 (decimal converted to an integer)
	if ( !( defined $multiple ) ) {
		$multiple = .01;
	}               # $multiple may be 0 (decimal converted to an integer)
	if ( $multiple =~ /^0\./ ) {
		$decimal = length($multiple) - 2;
	}
	elsif ( $multiple =~ /^\./ ) {
		$decimal = length($multiple) - 1;
	}
	else {
		$decimal = 0;
	}
	my $motif = "%.0${decimal}f";

	#my $multiple=1/(10**$decimal);
	$value = nearest( $multiple, $value );

	return sprintf( $motif, $value );
}

# Signed-amount digit map. Read in the substitution below, where "$HX_VAL{$1}"
# interpolates as a hash element. Hoisted out of oe_num_sign_x, which rebuilt it
# on every call (17609 on the document path, ~13x the cost of a single lookup).
my %HX_VAL = (
	'p' => 0,
	'q' => 1,
	'r' => 2,
	's' => 3,
	't' => 4,
	'u' => 5,
	'v' => 6,
	'w' => 7,
	'x' => 8,
	'y' => 9,
);

## no critic (ProhibitSubroutinePrototypes)
sub oe_num_sign_x(\$;$) {    # migrate oe_num_sign_x
		# processing of alphanumeric signed amounts
		# receives: a reference to an alphanumeric variable
		#          a number of decimals after the point (optional, 0 by default)

	my ( $refMontant, $decimal ) = @_;
	${$refMontant} ||= "";
	$decimal ||= 0;

	# check the validity of the passed value
	${$refMontant} =~ s/\s+//g;
	if ( ${$refMontant} eq "" || ${$refMontant} eq 0 ) {
		${$refMontant} = 0;
		return 1;
	}
	elsif ( ${$refMontant} =~ /\D{2,}/ ) {
		warn "INFO: value (${$refMontant}) not numeric.\n";
		return -1;
	}

	if ( ${$refMontant} =~ s/(\D{1})$/$HX_VAL{$1}/ ) {

		# a value with an alphanumeric negative sign 213y => -2139
		${$refMontant} = ( ${$refMontant} * (-1) );

		# warn "INFO: SIGNED AMOUNT";
	}
	elsif ( ${$refMontant} =~ /^-{1}/ ) {

		# a value with a negative sign -123456
	}

	${$refMontant} = ${$refMontant} / ( 10**$decimal );

	return ${$refMontant};
}

sub date2time {    # migrate oe_date_to_time
				   # DEPRECATED FUNCTION,
				   # USE THE SPECIALIZED LIBRARY: Date::Calc
	my $date = shift;    # a date in YYYYMMDD format

	my $tmpDate  = "AAAAMMJJ";
	my $decalage = 0;
	my $jours    = -1;
	my $time     = time;
	my ( $sec, $min, $hour, $mday, $mon, $year, $wday, $yday ) = gmtime($time);
	my $nowDate = sprintf( "%4.0f%02.0f%02.0f", $year + 1900, $mon + 1, $mday );

	if ( $nowDate > $date ) {

		# date is older
		$decalage = -1;
	}
	elsif ( $nowDate < $date ) {

		# date is newer
		$decalage = +1;
	}

	while ( $date ne $tmpDate ) {
		$jours++;

		# a day has 86400 seconds
		( $sec, $min, $hour, $mday, $mon, $year, $wday, $yday ) =
			gmtime( $time + ( $decalage * $jours * 86400 ) );
		$tmpDate = sprintf( "%4.0f%02.0f%02.0f", $year + 1900, $mon + 1, $mday );
	}

	return ( $time + ( $decalage * $jours * 86400 ) ), ( $decalage * $jours );
}

sub oe_now_time() {    # migrate oe_now_time
					   # DEPRECATED FUNCTION,
					   # USE THE SPECIALIZED LIBRARY: Date::Calc -> Today

	my $time = time;
	my ( $sec, $min, $hour, $mday, $mon, $year, $wday, $yday ) = gmtime($time);
	$time = sprintf(
		"%4.0f%02.0f%02.0f%02.0f%02.0f%02.0f",
		$year + 1900,
		$mon + 1, $mday, $hour, $min, $sec
	);

	return $time;
}

# ISO COUNTRY DICTIONARY
my $_DICO_COUNTRY;

# ABBREVIATIONS DICTIONARY.
my $_DICO_POST;

# translation dictionary for characters (discouraged, but sometimes needed).
my $_DICO_CHAR;

{
	my $_LAST_ISO = "";

	sub oe_iso_country {

		# returns the country code in country_dico.ini coding or the last known value
		my $country = shift;
		if ( !defined($_DICO_COUNTRY) ) {
			my $cfg = config_read();
			$_DICO_COUNTRY =
				oEdtk::Dict->new( $cfg->{'EDTK_DICO_COUNTRY'}, { section => $cfg->{'EDTK_LANG'} } );
		}
		$_LAST_ISO = $_DICO_COUNTRY->translate($country) if defined($country);
		return $_LAST_ISO;
	}
}

sub oe_char_xlate {    # to migrate into the dictionary?
	my $scalar = shift;

	if ( !defined($_DICO_CHAR) ) {
		my $section = shift || 'DEFAULT';
		my $cfg     = config_read();
		$_DICO_CHAR = oEdtk::Dict->new( $cfg->{'EDTK_DICO_XLAT'}, { section => $section } );
	}
	$scalar = $_DICO_CHAR->substitue($scalar);

	return $scalar;
}

## no critic (ProhibitSubroutinePrototypes)
sub oe_clean_addr_line(\$) {    # migrate oe_clean_addr_line
		# THIS FUNCTION CLEANS ADDRESS LINES TO BUILD THE RECIPIENT ADDRESS BLOCKS
		# it works directly on the variable reference but also returns the resulting string
	my $rLine = shift;

	# default value in case the field is undef
	if ( !defined($$rLine) || length($$rLine) == 0 ) {
		$$rLine = '';
		return $$rLine;
	}

	chomp($$rLine);    # to be sure there is no trailing newline at the end of the field
	oe_trimp_space($rLine);

	$$rLine = oe_char_xlate( $$rLine, 'ADDRESS' );

	# TODO: a regex that replaces everything that is not 0-9, -, degrees or \w with blanks...

# THE NEXT LINE MUST BE ENABLED ONLY AFTER TESTING, FOR NOW HANDLED BY oe_char_xlate
#$$rLine =~ s/\\+/\//g;	# we remove/replace backslashes which are escape characters and which apparently are not counted in the size check (sprintf("%.38s",...)
	$$rLine =~ s/^\s+//
		; # remove consecutive blanks at the start of the string (an oe_trimp_space was done first...) LEFT TRIM
	$$rLine =~ s/\s+$//;    # remove consecutive blanks at the end of the string (...) RIGHT TRIM
	$$rLine =~
		s/^0\s+//;   # remove lone zeros at the start of the string (done last, after the LEFT TRIM)
	$$rLine =~ s/\s+/ /;    # collapse consecutive blanks

	# Use the given dictionary to translate words.
	if ( length($$rLine) > 38 ) {
		if ( !defined($_DICO_POST) ) {
			my $cfg = config_read();
			$_DICO_POST = oEdtk::Dict->new( $cfg->{'EDTK_DICO_POST'} );
		}
		my @words = split( / /, $$rLine );
		$$rLine = join( ' ', map { $_DICO_POST->translate($_) } @words );
	}
	$$rLine = sprintf( "%.38s", $$rLine );    # make sure not to exceed 38 characters per line

	return $$rLine;
}

## no critic (ProhibitSubroutinePrototypes)
sub oe_CAP_sans_accents (\$) {

	# THIS FUNCTION CONVERTS ACCENTED UPPERCASE CHARACTERS INTO NON-ACCENTED UPPERCASE CHARACTERS
	# using localization causes a bug in the "sort" command.
	# We do not rely on the ability to restore the default behavior by escaping
	# (the no locale directive, or when leaving the block enclosing the use locale directive)
	# so as to adopt a standard and simplified operating mode.
	# NB: localization slows sorting down considerably.
	# (cf. Perl documentation about localization: perllocale)
	#
	# the function is called with an implicit reference passing
	#	oe_char_no_accents($chaine);

	my $refChaine = shift;
	${$refChaine} ||= "";
	${$refChaine} =~ s/[ÀÂÄ]/A/g;
	${$refChaine} =~ s/[ÉÈÊË]/E/g;
	${$refChaine} =~ s/[ÌÎÏ]/I/g;
	${$refChaine} =~ s/[ÒÔÖÕ]/O/g;
	${$refChaine} =~ s/[ÚÙÛÜ]/U/g;
	${$refChaine} =~ s/Ç/C/g;

	# the uc command is not included; it can be done before calling oe_CAP_sans_accents
	# - either keep accented lowercase letters, or capitalize everything
	## ${$refChaine}= uc ${$refChaine};

	return ${$refChaine};
}

## no critic (ProhibitSubroutinePrototypes)
sub oe_uc_sans_accents (\$) {    # migrate oe_uc_sans_accents
		# THIS FUNCTION CONVERTS ACCENTED CHARACTERS INTO NON-ACCENTED UPPERCASE CHARACTERS
		# using localization causes a bug in the "sort" command.
		# We do not rely on the ability to restore the default behavior by escaping
		# (the no locale directive, or when leaving the block enclosing the use locale directive)
		# so as to adopt a standard and simplified operating mode.
		# NB: localization slows sorting down considerably.
		# (cf. Perl documentation about localization: perllocale)
		#
		# the function is called with an implicit reference passing
		#	oe_uc_sans_accents($chaine);

	my $refChaine = shift;
	${$refChaine} ||= "";
	${$refChaine} =~ s/[àâä]/a/ig;
	${$refChaine} =~ s/[éèêë]/e/ig;
	${$refChaine} =~ s/[ìîï]/i/ig;
	${$refChaine} =~ s/[òôöõ]/o/ig;
	${$refChaine} =~ s/[úùûü]/u/ig;
	${$refChaine} =~ s/ç/c/ig;
	${$refChaine} = uc ${$refChaine};

	return ${$refChaine};
}

## no critic (ProhibitSubroutinePrototypes)
sub oe_trimp_space(\$) {    # migrate oe_trimp_space
							# REMOVE CONSECUTIVE SPACES (TRAILING BLANK) BY GROUPING
							# the parameter must be a reference, example: oe_trimp_space($chaine)
							# returns the number of removed characters
	my $rChaine = shift;
	${$rChaine} ||= "";
	${$rChaine} =~ s/\s{2,}/ /go;

	return ${$rChaine};
}

sub oe_list_encodings {
	my @list = Encode->encodings();
	warn "INFO: available encodings on this machine are : @list\n";
}

# migrate oe_open_fi_IN
sub oe_open_fi_IN {    # BASIC INPUT FILE HANDLING
	my ( $fi, $enc ) = @_;

	# An explicit encoding wins; otherwise EDTK_OUT_ENCODING from the config.
	# An absent key keeps M behaviour: an open with no encoding layer.
	$enc = oe_config_compo()->{'EDTK_OUT_ENCODING'} unless defined $enc;
	my $mode = $enc ? "<:encoding($enc)" : '<';
	open( IN, $mode, $fi ) or die "ERROR: opening $fi, return code $!\n";    ## no critic (InputOutput::ProhibitBarewordFileHandles)

	1;
}

# migrate oe_open_fo_OUT
sub oe_open_fo_OUT {    # BASIC OUTPUT FILE HANDLING
	my ( $fo, $enc ) = @_;

	$enc = oe_config_compo()->{'EDTK_OUT_ENCODING'} unless defined $enc;
	my $mode = $enc ? ">:encoding($enc)" : '>';
	open( OUT, $mode, $fo ) or die "ERROR: opening $fo - return code $!\n";    ## no critic (InputOutput::ProhibitBarewordFileHandles)

	1;
}

sub oe_close_fo {    # migrate oe_close_fo
	my $f = shift;

	close(OUT) or die "ERROR: closing $f - return code $!\n";
	1;
}

## no critic (ProhibitSubroutinePrototypes)
sub oe_to_date(\$) {    # migrate oe_to_date
						# RECEIVES A REFERENCE TO A DATE IN YYYYMMDD FORMAT
						# FORMATS AS DD/MM/YYYY
	my $refVar = shift;
	${$refVar} ||= "";
	${$refVar} =~ s/(\d{4})(\d{2})(\d{2})(.*)/$3\/$2\/$1/o;

	return ${$refVar};
}

sub oe_fmt_date {    # migrate oe_fmt_date
	my $date = shift;

	die "ERROR: Unexpected date format: \"$date\"\n"
		if $date !~ /^\s*(\d{1,2})\/(\d{1,2})\/(\d{2}|\d{4})\s*$/;

	return sprintf( "%02s/%02s/%s", $1, $2, $3 );
}

# Convert a date in DD/MM/YYYY format to YYYYMMDD format.
sub oe_date_convert {    # oe_date_format
	my $date = shift;

	if ( $date !~ /^\s*(\d{1,2})\/(\d{1,2})\/(\d{4})\s*$/ ) {
		return;
	}
	return sprintf( "%d%02d%02d", $3, $2, $1 );
}

sub oe_date_compare {
	my ( $date1, $date2 ) = @_;

	if ( $date1 eq '' ) {
		$date1 = $date2;
	}

	my $wdate1 = oe_date_convert($date1);
	my $wdate2 = oe_date_convert($date1);

	if ( !defined($wdate1) ) {
		warn "INFO: Unexpected date format: \"$date1\" should be dd/mm/yyyy. Date ignored\n";
		return 1;
	}
	if ( !defined($wdate2) ) {
		warn "INFO: Unexpected date format: \"$date2\" should be dd/mm/yyyy. Date ignored\n";
		return -1;
	}
	return $wdate1 <=> $wdate2;
}

sub oe_date_smallest {
	my ( $date1, $date2 ) = @_;

	if ( oe_date_compare( $date1, $date2 ) <= 0 ) {
		return $date1;
	}
	else {
		return $date2;
	}
}

sub oe_date_biggest {
	my ( $date1, $date2 ) = @_;

	if ( oe_date_compare( $date1, $date2 ) <= 0 ) {
		return $date2;
	}
	else {
		return $date1;
	}
}

## no critic (ProhibitSubroutinePrototypes)
sub oe_num2txt_us(\$) {

	# process amounts in Text format
	# the decimal separator "," is turned into "." for the load commands
	# the thousands separator "." or " " is removed
	# receives: an alphanumeric variable formatted for display
	# 		$value = oe_num2txt_us($value);
	# or by reference
	# 		oe_num2txt_us($value);

	my $refValue = shift;
	${$refValue} ||= "";

	if ( ${$refValue} ) {
		${$refValue} =~ s/\s+//g;             # remove blanks
		${$refValue} =~ s/\.//g;              # remove thousands separators
		${$refValue} =~ s/\,/\./g;            # replace the decimal separator
		${$refValue} =~ s/(.*)(\-)$/$2$1/;    # optionally move the negative sign to the front

	}
	else {
		${$refValue} = 0;
	}

	return ${$refValue};
}

sub oe_include_build {
	my ( $name, $path ) = @_;

	#import oEdtk::TexDoc;

	my $tag = oEdtk::TexDoc->new();
	$tag->include( $name, $path );
	return $tag;
}

sub oe_data_build {    #oe_xdata_build
	my ( $name, $val ) = @_;

	my $tag = oEdtk::TexTag->new( $name, $val );
	return $tag->emit();
}

sub oe_app_usage() {    # migrate oe_app_usage
	my $app = "";
	$0 =~ /([\w-]+[\.plmex]*$)/;
	$1 ? $app = "application.pl" : $app = $1;
	print STDOUT <<"EOF";

 Usage:	$app </source/input/file.dat> [job] [options]
 Usage:	$app --noinputfiles [job] [options]
 options :
		--massmail 	to confirm mass treatment
		--edms		to confirm edms treatment
		--cgi
				these values depend on ED_REFIDDOC config table 
				(example : omgr treatment confirmation)

		--input_code	input caracters encoding
				(ie : --input_code=iso-8859-1)
		--noinputfiles	no data file needed for treatment
		--help		this message

EOF

	# 		--notracking	halt tracking, do not track
	oe_list_encodings();
	exit 1;
}

# XXX Global variable used to remember stuff from oe_new_job() when we
# are in oe_compo_link().  It would be *much* better to keep state in an
# object instance instead.
my $_RUN_PARAMS;

sub oe_new_job {
	@ARGV =
		( @ARGV, @_ );   # optionally override options with the oe_new_job parameters for GetOptions
	my $cfg    = config_read('COMPO');
	my $params = {};

	# DEFAULT OPTION VALUES.
	my %defaults = (

		#		xls	 		=> 0,
		#		tex			=> 0,
		index      => 0,
		massmail   => 0,
		edms       => 0,
		cgi        => 0,
		input_code => 0
	);

	# examples of adding parameters at launch
	# oe_new_job('--index');
	# oe_new_job("--input_code=utf8");

	GetOptions( \%defaults, 'help', 'index', 'massmail', 'edms', 'cgi', 'noinputfiles',
		'input_code=s' );
	while ( my ( $key, $val ) = each(%defaults) ) {
		if ( !defined( $params->{$key} ) ) {
			$params->{$key} = $val;
		}
	}

	if ( $^O ne 'MSWin32' ) {
		$defaults{'fifo'} = 1;
	}
	else {
		$defaults{'fifo'} = 0;
	}

	$params->{'doclib'} = _omngr_doclib();
	$params->{'idldoc'} = oe_ID_LDOC();

	$params->{'outfile'}     = $cfg->{'EDTK_PRGNAME'} . ".txt";         # should be tied to TexMode
	$params->{'output_code'} = $cfg->{'EDTK_OUT_ENCODING'} || 'utf8';
	$params->{'output_code'} = ">:encoding(" . $params->{'output_code'} . ")";
	if ( $params->{'input_code'} ) {
		$params->{'input_code'} = "<:encoding(" . $params->{'input_code'} . ")";
	}
	else {
		$params->{'input_code'} = "<";
	}

	my $fi;
	if ( $defaults{help} ) {
		&oe_app_usage();
		exit 0;
	}
	elsif ( $defaults{noinputfiles} ) {
		$fi = 0;
		warn "INFO: no input file for this treatment\n";
	}
	elsif ( $#ARGV == -1 ) {    # TO KEEP COMPATIBILITY
		&oe_app_usage();
		exit 0;
	}
	else {
		$fi = $ARGV[0];                             # TO KEEP COMPATIBILITY
		open( IN, $params->{'input_code'}, $fi )    ## no critic (InputOutput::ProhibitBarewordFileHandles)
			or die "ERROR: Cannot open \"$fi\" for reading: $!\n";
		warn "INFO: input perl data is $fi (encode \'"
			. $params->{'input_code'}
			. "\' $ARGV[-1])\n";
	}

	# Override default setting if EDTK_COMPO_ASYNC is set in edtk.ini.
	my $async = $cfg->{'EDTK_COMPO_ASYNC'};
	if ( defined($async) && $async =~ /^yes$/i ) {
		$params->{'fifo'} = 1;
	}
	elsif ( defined($async) && $async =~ /^no$/i ) {
		$params->{'fifo'} = 0;
	}

	if ( $params->{'fifo'} && $^O eq 'MSWin32' ) {
		warn "INFO: FIFO mode is not possible under Windows, ignoring.\n";
		$params->{'fifo'} = 0;
	}

	# If we are in FIFO mode and there is a left-over text file, the mkfifo()
	# call would fail.  If we are not in FIFO mode and there's a left-over FIFO,
	# we would hang indefinitely, so make sure to remove this file first.
	unlink( $params->{'outfile'} );

	# Handle options passed in the EDTK_OPTIONS environment variable.
	if ( exists( $ENV{'EDTK_OPTIONS'} ) ) {
		my @opts = split( ',', $ENV{'EDTK_OPTIONS'} );
		foreach my $opt (@opts) {
			$params->{$opt} = 1;
		}
	}

	if ( $params->{'fifo'} ) {
		warn "INFO: Creating FIFO for output data file (" . $params->{'outfile'} . ")\n";
		mkfifo( $params->{'outfile'}, oct('700') ) or die "ERROR: Could not create fifo : $!\n";
		my $pid = oe_compo_run( $cfg->{'EDTK_PRGNAME'}, $params );
		$params->{'pid'} = $pid;
	}

	open( OUT, $params->{'output_code'}, $params->{'outfile'} )    ## no critic (InputOutput::ProhibitBarewordFileHandles)
		or die "ERROR: Cannot open \'" . $params->{'outfile'} . "\' for writing: $!\n";
	warn "INFO: input compo data is "
		. $params->{'outfile'}
		. " (encode \'"
		. $params->{'output_code'} . "\')\n";

	# Remember for later use in oe_compo_link() & oEdtk::Main.
	$_RUN_PARAMS = $params;

	if ( defined $cfg->{'EDTK_COMPO_INCLUDE'} && $cfg->{'EDTK_COMPO_INCLUDE'} =~ /yes/i ) {
		print OUT oe_include_build( $cfg->{'EDTK_PRGNAME'} . "." . $cfg->{'EDTK_EXT_COMPO'},
			'EDTK_DIR_SCRIPT' );
	}
	print OUT oe_data_build( oe_corporation_tag() );
	print OUT oe_data_build( 'xIdLdoc', $params->{'idldoc'} );
	print OUT oe_data_build('xDebFlux');
	print OUT oe_data_build( 'xAppRef', $cfg->{'EDTK_PRGNAME'} );
	print OUT oe_data_build( 'xDOCLIB', $params->{'doclib'} );

	my $env = $cfg->{'EDTK_TYPE_ENV'};
	if ( $env ne 'Production' ) {

		# Generate the 'TEST EDITION' watermark.
		print OUT oe_data_build( 'xWaterM', $cfg->{'EDTK_WATERMARKTEXT'} || ' ' );
		print OUT oe_data_build('xTstApp');
	}
	else {
		# No watermark.
		print OUT oe_data_build('xProdApp');
	}
	print OUT oe_data_build( 'xTYPPROD', substr( $env, 0, 1 ) );
	print OUT oe_data_build( 'xHOST',    hostname() );

	# Do we want to generate an index file?
	if ( $params->{'index'} ) {
		print OUT oe_data_build('xStOmgr');
		print OUT oe_data_build( 'xHost', hostname() );
	}
	print OUT $TAG_COMMENT;
	print OUT "\n";
}

# True when the dissemination-plan URL is configured and carries a non-blank
# value: the one switch that lets a 'call-plan' run reach the service. Sites
# that do not run a dissemination plan leave the key absent, so the call stays
# inert (the mainline behaviour).
sub _dissemination_plan_url_set {
	my $cfg = shift;
	my $url = $cfg->{'DISSEMINATION_PLAN_URL'};
	return ( defined $url && $url =~ /\S/ ) ? 1 : 0;
}

sub oe_compo_link {    # migrate oe_close_files oe_compo_link
					   # IF THE INPUT STREAM HAS LESS THAN 1 LINE (variable $.), EXIT WITH ERROR
					   # if ($. == 0) {
					   #	# INVALID STREAM, STOP
					   #	die 	"ERROR: uncomplete datastream\n $message \n\n";
					   #}

	my @opt = @_;

	my $cfg    = config_read('COMPO');
	my $params = $_RUN_PARAMS;
	$params->{'corp'} = oe_corporation_set();
	if (@opt) {
		foreach (@opt) {
			$_ =~ s/\-+//g;
			$params->{$_} = 1;
		}
	}

	print OUT oe_data_build('xFinFlux');
	close(OUT) or die "ERROR: closing output $!\n";
	if ( $params->{'noinputfiles'} ) {
	}
	else {
		close(IN) or die "ERROR: closing input $!\n";
	}

	if ( $params->{'fifo'} ) {

		# Disable signal handler.
		$SIG{'CHLD'} = 'DEFAULT';
		if ( !defined( $params->{'cldstatus'} ) ) {

			# Wait for the LaTeX process to terminate.
			my $pid = $params->{'pid'};
			warn "INFO: Waiting for the LaTeX process to terminate ($pid)...\n";
			my $kid = waitpid( $pid, 0 );
			if ( $kid <= 0 ) {
				die "ERROR: Could not collect child process status: $!\n";
			}
			$params->{'cldstatus'} = $?;
		}
		my $status = $params->{'cldstatus'};
		if ( $status != 0 ) {
			my $msg = oe_status_to_msg($status);
			die "ERROR: LaTeX process failed: $msg\n";
		}
		warn "INFO: The LaTeX process terminated successfully.\n";
	}
	else {
		# Run the LaTeX process.
		oe_compo_run( $cfg->{'EDTK_PRGNAME'}, $params );
	}
	oe_after_compo( $cfg->{'EDTK_PRGNAME'}, $params );

	# Dissemination plan: only when the caller opted in (and did not veto),
	# and the service URL is configured. The delegate loads oEUser on demand,
	# so a missing companion distribution never breaks the oEdtk load.
	if ( $params->{'call-plan'} && !defined $params->{'nocallplan'} ) {
		if ( _dissemination_plan_url_set($cfg) ) {
			require oEdtk::DisseminationPlan;
			my $app    = $params->{'app-ref'};
			my $id_lot = $params->{'idldoc'};
			defined $app    or croak "ERROR: no 'app-ref' in params\n";
			defined $id_lot or croak "ERROR: no 'idldoc' in params\n";
			oEdtk::DisseminationPlan::idx1_app_idlot( $cfg, $app, $id_lot,
				$params->{'forced-paper'} );
		}
		else {
			warn "INFO: not calling the dissemination plan (DISSEMINATION_PLAN_URL absent)\n";
		}
	}

	return 1;
}

## no critic (ProhibitSubroutinePrototypes)
sub oe_env_var_completion (\$) {

	# expand paths by replacing environment variables with their real values
	# all nesting levels defined in the environment variables are expanded
	# requires the environment variables to be defined beforehand
	my $rValue = shift;
	if ( $^O eq "MSWin32" ) {

		# environment variables may themselves contain variables
		while ( ${$rValue} =~ /\$/g ) {
			${$rValue} =~ s/\$(\w+)/${ENV{$1}}/g;
		}
		${$rValue} =~ s/(\/)/\\/g;

	}
	else {
		# CHECK COMPATIBILITY UNDER *NIX
		while ( ${$rValue} =~ /\$/g ) {
			${$rValue} =~ s/\$(\w+)/${ENV{$1}}/g;
		}
	}
	return ${$rValue};
}

# Maximum length accepted for a forced document id (a 36-char UUID; S70, D1).
use constant IDLDOC_MAX_LEN => 36;

sub oe_ID_LDOC {
	my $force_ID = shift;

	# document batch id: a 36-char UUID by default (S70, D1). A forced id (the
	# -iddoc option, or the witnesses' SETIDLOT) still wins. The id is generated
	# only once per run: several calls in the same instance return the same id.
	# EDTK_IDLDOC_FORMAT=LEGACY (or the alias =old) restores the 16-digit
	# YWWWDHHMMSSPPPP.r format.
	if ( $_ID_LDOC eq '' ) {

		if ( defined $force_ID ) {
			if ( length $force_ID > IDLDOC_MAX_LEN ) {
				die "ERROR: forced ID_LDOC too long (>" . IDLDOC_MAX_LEN . " car) : $force_ID \n";
			}
			$_ID_LDOC = $force_ID;

		}
		elsif ( _idldoc_format() eq 'LEGACY' ) {
			$_ID_LDOC = _idldoc_legacy_new();

		}
		else {
			oe_new_ID_LDOC();

		}

	}

	return $_ID_LDOC;
}

# The mainline (M) 16-digit id YWWWDHHMMSSPPPP.r, kept for
# EDTK_IDLDOC_FORMAT=LEGACY (or its 'old' alias).
sub _idldoc_legacy_new {
	my $time = time;
	my ( $year, $month, $day, $hour, $min, $sec, $doy, $dow, $dst ) = Gmtime($time);
	my ( $week, ) = Week_of_Year( $year, $month, $day );

	my $pid = "$$";
	my $rnd = int( rand(10) );
	if ( length $pid > 5 ) {
		$pid = $pid / ( 10**( ( length $pid ) - 5 ) );
	}

	return sprintf( "%1d%02d%1d%02d%02d%02d%05d%1d",
		$year % 10, $week, $dow, $hour, $min, $sec, $pid, $rnd );
}

# EDTK_IDLDOC_FORMAT: 'UUID' (default) or 'LEGACY' (the 16-digit mainline id).
# 'old' is an accepted spelling of 'LEGACY' (case-insensitive), normalised here
# so oe_ID_LDOC tests a single value. Read once per process: config_read is
# not cached, and oe_ID_LDOC is called from contexts that carry no $cfg
# (Tracking, EDMS, ...).
sub _idldoc_format {
	unless ( defined $_IDLDOC_FORMAT ) {
		my $cfg = eval { config_read('COMPO') } || {};
		my $val = ref $cfg                         ? $cfg->{'EDTK_IDLDOC_FORMAT'} : undef;
		my $fmt = ( defined $val && $val =~ /\S/ ) ? uc($val)                     : 'UUID';
		$fmt            = 'LEGACY' if $fmt eq 'OLD';
		$_IDLDOC_FORMAT = $fmt;
	}
	return $_IDLDOC_FORMAT;
}

# A document batch id (idldoc). Since S70/D1 it is a 36-char UUID; the legacy
# 16-digit YWWWDHHMMSSPPPP.r form is still produced under
# EDTK_IDLDOC_FORMAT=LEGACY (or its 'old' alias). Kept in this module so the
# CLI tools that classify a user-supplied id (see lib/index_Block_refs.pl)
# share one definition.
sub oe_is_IDLDOC {
	my $value = shift;
	return 0 unless defined $value;
	return $value =~ /^[0-9A-Fa-f]{8}(?:-[0-9A-Fa-f]{4}){3}-[0-9A-Fa-f]{12}$/
		|| $value =~ /^\d{16}$/;
}

{
	my $_app_typ_trt;    # batching processing type,
						 # value accessible only through the _app_typ_trt method

	sub _app_typ_trt {

		# designation of the batching processing type (Output Management)
		# if the function is called with a parameter, assign it to $_app_typ_trt
		# if the function is called alone, just return the normalized value
		# by default the value is 'U' for 'undef'
		# THE VALUE CANNOT BE CHANGED DURING PROCESSING, EXCEPT to switch to Test or Debug
		# possible values:
		# - 'M' -> Mass processing with batching
		# - 'G' -> reGrouping processing, batching pending
		# - 'L' -> Local edition processing without batching
		# - 'H' -> homologation processing without batching
		# - 'T' -> test/homologation processing, batching test possible
		# - 'D' -> Debug mode, keep intermediate files
		# - 'U' -> 'undef' processing without batching

		# Run types (Mass/Grouped/Local/Homol/Test/Debug/Undef) handled in 3 groups:
		# - MTD -> do batching
		# - G	-> batching pending
		# - LHU -> do no batching
		# - D   -> does not delete intermediate files
		# - U   -> default mode
		# - H   -> mode tied to the 'Homologation' extension (-V2)

# New run handling based on EDTK_TYPE_ENV:
# EDTK_TYPE_ENV = Production	-> cleanup, if indexed mode: determine the trt from EDTK_REFIDDOC
# EDTK_TYPE_ENV = Integration	-> cleanup, banner, if indexed mode: determine the trt from EDTK_REFIDDOC
# EDTK_TYPE_ENV = Test		-> banner, if indexed mode: determine the trt from EDTK_REFIDDOC
# EDTK_TYPE_ENV = Development	-> cleanup, banner, 'short' processing

		my $xTypTrt = shift || '';
		if ( defined $_app_typ_trt && $xTypTrt !~ /^[TD]/i ) { return $_app_typ_trt; }

		# only the Test and Debug types allow changing $_app_typ_trt if it is already set

		if ( $xTypTrt !~ /^([MGLHTDU])/i ) {
			$_app_typ_trt = 'U';

		}
		elsif ( $xTypTrt =~ /^([MGL])/i ) {
			$_app_typ_trt = $1;

		}
		elsif ( $xTypTrt =~ /^([HTD])/i ) {
			$_app_typ_trt = $1;
		}

		warn
"INFO: OM processing type = $_app_typ_trt (Mass/Grouped/Local/Homol/Test/Debug/Undef)\n";
		return $_app_typ_trt;
	}
}

{
	my $_DOCLIB;    # DCLIB DESIGNATION for batching
					# value accessible only through the _omngr_doclib method

	sub _omngr_doclib {
		if ( defined $_DOCLIB ) { return $_DOCLIB; }

		my $doclib = shift;
		if ( !defined $doclib ) {
			my $cfg = config_read('ENVDESC');
			my $ext = shift || $cfg->{'EDTK_EXT_DEFAULT'};
			$_DOCLIB = "DCLIB_" . oe_ID_LDOC() . "." . $ext;

			#$_DOCLIB =~ s/\./_/;
		}
		else {
			$_DOCLIB = $doclib;
		}

		return $_DOCLIB;
	}
}

#sub user_corp_file_prefixe($;$){
#	my($filename, $directories, $suffix) = fileparse(shift);
#	my $sep = shift || '.';
#	my @prefix = split (/$sep/, $filename);
#	oe_corporation_set ($prefix[0]);
#	# warn "$filename \$prefix[0] $prefix[0] -> ". oe_corporation_set()."\n";
#1;
#}

sub oe_corporation_tag() {
	return ( sprintf( "x%.7s", oe_corporation_set() ) );
}

my $_xCORPOR;
my $_DICT;

sub oe_corporation_get() {
	return $_xCORPOR;
}

sub oe_corporation_set {

	# DICTIONARY USE:
	#	- if the parameter is known in the dictionary => dictionary value
	#	- if the parameter is unknown => default value (edtk.ini / EDTK_CORP)
	#	- if no parameter => last known value
	my $parametre = shift;

	if ( !defined($_DICT) ) {
		my $cfg = config_read();
		$_xCORPOR = $cfg->{'EDTK_CORP'};                                        # Default value
		$_DICT    = oEdtk::Dict->new( $cfg->{'EDTK_DICO'}, { invert => 1 } );
	}

	my $entity;
	if ( defined($parametre) ) {
		$entity = $parametre;
	}
	else {
		$entity = $_xCORPOR;
	}

	$entity = $_DICT->translate( $entity, 1 );

	if ( defined($entity) ) {

		# if the value was found in the dictionary
		$_xCORPOR = $entity;
	}

	# warn "\$entity $entity \$_xCORPOR $_xCORPOR\n";
	return $_xCORPOR;
}

{    # in progress, not operational yet (recovery from the generator)
	my $cpt_sub_call = 0;    # constant variable local to the function
	my %hListeId;

	sub oe_unique_data_name {

# define a unique identifier over n characters
# the first 6 characters of the passed key are extracted
# if the id is already known, take the first 4 and add a 3-digit counter (matches the call sequence)
# if it is still not unique, take the first 3 characters and complete the 3-digit counter with a character
# receives: 	- the total number of characters to return
#		- an identifier
#		- optional: a reference to a counter value (3 numeric)

		my ( $nb_car, $id, $cpt_value ) = @_;
		if ( $nb_car lt 6 ) { $nb_car = 6; }

		if ($cpt_value) { $cpt_sub_call = $cpt_value }
		else            { $cpt_sub_call++ }

		my $debut = $nb_car - 2;
		my $motif = "%-" . $debut . "." . $debut . "s%0.2d";    # "%-4.4s%0.2d"
		warn "$motif / $id\n";
		$id = sprintf( "$motif", $id );
		$id =~ s/\s/x/g;

		if ( exists( $hListeId{$id} ) ) {
			$debut = $nb_car - 3;
			$motif = "%-" . $debut . "." . $debut . "s%0.3d";    # "%-3.3s%0.3d"
			$id    = sprintf( $motif, $id, $cpt_sub_call );

			my $cpt = 97;                                        # for the character "a"
			while ( exists( $hListeId{$id} ) ) {
				$debut = $nb_car - 4;
				$motif = "%-" . $debut . "." . $debut . "s%0.3d";                # "%-3.3s%0.3d"
				$id    = sprintf( $motif, $id, $cpt_sub_call, chr( $cpt++ ) );
				die "ERROR: cannot create a unique key" if ( $cpt >= 123 );

# use Log::Log4perl;
# Log::Log4perl->init("log.conf"); => read log.conf
# $logger = Log::Log4perl->get_logger("");
# $logger->logdie("cannot create a unique key") if ($cpt >= 123);
# $logger->trace("...");  # Log a trace message
# $logger->debug("...");  # Log a debug message
# $logger->info("...");   # Log a info message
# $logger->warn("...");   # Log a warn message	/ $logger->error_warn("..."); (includes the call to warn() )
# $logger->error("...");  # Log a error message	/ $logger->logdie ("..."); (includes the call to die() )
# $logger->fatal("...");  # Log a fatal message
			}
		}
		$hListeId{$id} = 1;
		return $id;
	}
}

{
	my $_backup_date;

	sub oe_set_sys_date {
		my $requested_date = shift;

		my $time = time;
		my ( $year, $month, $day, $hour, $min, $sec, $doy, $dow, $dst ) = Gmtime($time);

		my $commande = sprintf( "date %s", $requested_date );
		warn "INFO: $commande\n";

		eval { system($commande); };

		#		if ($?){
		if ($@) {
			warn "ERROR: command failed $commande : $@\n";
			return -1;
		}

		if ( !defined $_backup_date ) {
			$_backup_date = sprintf( "%02s-%02s-%02s", $day, $month, $year );
		}
		return $_backup_date;
	}

	sub _restore_sys_date {
		oe_set_sys_date($_backup_date) if ( defined $_backup_date );
		1;
	}
}

# Return the handle to the output file, croaking if it was not opened yet.
sub _oe_get_handle_to_output_file {
	my $fh = openhandle(*OUT);
	if ( !defined $fh ) {
		croak
"You tried to use the handle to the output file. However, the output file has not been opened yet!";
	}
	return $fh;
}

# Return the handle to the input file (the file that holds the Infinite flux).
# @note The IN handle should not be accessed directly from outside this module
#       (all the more so as a global variable!).
# @TODO write a function oe_read_from_input_file().
sub oe_get_handle_to_input_file {
	my $fh = openhandle(*IN);
	if ( !defined $fh ) {
		croak
"You tried to use the handle to the input file. However, the input file has not been opened yet!";
	}
	return $fh;
}

# Print a text into the output file.
# @param [string] $in_text text to print.
# @note all actions on the output file should go through an "output adaptor"
#       implemented as a plugin (a class implementing an interface).
sub oe_print_to_output_file {
	my $in_text = shift;
	croak 'in_text undef' if !defined $in_text;
	my $fh = _oe_get_handle_to_output_file();
	return print $fh $in_text;
}

# Print a text into the "output debug file".
# @param [string] $in_text text to print.
# @note the behaviour of this function can be configured through the
#       environment variables listed below:
#       - MNT_OUTPUT_DUMP_MODE: activate or deactivate the recording (0: off, 1: on).
#       - MNT_OUTPUT_DUMP_PATH: the path to the file used to store the recorded data.
#       both environment variables have default values (see
#       $_DEFAULT_OUTPUT_DUMP_MODE and $_DEFAULT_OUTPUT_DUMP_FILE).
sub _dump {
	my ($in_text) = @_;

	my $dump_mode =
		exists $ENV{MNT_OUTPUT_DUMP_MODE} && defined $ENV{MNT_OUTPUT_DUMP_MODE}
		? $ENV{MNT_OUTPUT_DUMP_MODE}
		: $_DEFAULT_OUTPUT_DUMP_MODE;
	if ( !$dump_mode ) {
		return;
	}

	my $dump_path =
		exists $ENV{MNT_OUTPUT_DUMP_PATH} && defined $ENV{MNT_OUTPUT_DUMP_PATH}
		? $ENV{MNT_OUTPUT_DUMP_PATH}
		: $_DEFAULT_OUTPUT_DUMP_FILE;
	use open ':encoding(iso-8859-15)';
	open( my $fd, '>>', $dump_path )
		or die sprintf(
'The module "%s::Main" is configured to record all text written to the output file. Can not open the dump file "%s": %s.',
		__PACKAGE__, $dump_path, $! );
	printf $fd "%s\n", $in_text;
	close($fd)
		or die sprintf(
'The module "%s::Main" is configured to record all text written to the output file. Can not close the dump file "%s": %s.',
		__PACKAGE__, $dump_path, $! );
}

# Dictionary of the applications' backgrounds.
my $_DICO_BACKGROUNDS;

sub oe_backgrounds_apps {
	my ($section) = @_;

	my $cfg = config_read();
	if ( !defined($_DICO_BACKGROUNDS) ) {
		$_DICO_BACKGROUNDS =
			oEdtk::Dict->new( $cfg->{'EDTK_APPS_BACKGROUNDS'}, { section => $section } );
	}
	return $_DICO_BACKGROUNDS->translate( $cfg->{EDTK_PRGNAME} );
}

# Clean up an address line in place to build the recipient address blocks.
# It works on the reference to the variable and also returns the resulting string.
## no critic (ProhibitSubroutinePrototypes)
sub oe_clean_addr(\$) {
	my $rLine = shift;

	# default value when the field is undef
	if ( !defined($$rLine) || length($$rLine) == 0 ) {
		$$rLine = '';
		return $$rLine;
	}

	chomp($$rLine);    # make sure there is no trailing newline
	oe_trimp_space($rLine);

	$$rLine = oe_char_xlate( $$rLine, 'ADDRESS' );

	# TODO: a regular expression turning every non 0-9\-\w character into blanks... XXX

	$$rLine =~ s/^\s+//;                 # left trim: drop leading blanks
	$$rLine =~ s/\s+$//;                 # right trim: drop trailing blanks
	$$rLine =~ s/^0\s+//;                # drop a lone leading zero (after the trims)
	$$rLine =~ s/\s+/ /;                 # collapse consecutive blanks
	$$rLine =~ s/(\s{1}\W{1}){2}/$1/;    # drop a blank followed by a non-alphanumeric
	$$rLine =~ s/\W+$//;                 # drop trailing non-alphanumeric characters

	return $$rLine;
}

# Production type: the first letter of the EDTK_TYPE_ENV configuration value.
sub oe_typ_prod {
	my ($cfg) = @_;
	$cfg //= config_read();
	my $env = $cfg->{'EDTK_TYPE_ENV'} // croak 'Env. var. EDTK_TYPE_ENV undef';
	return substr( $env, 0, 1 );
}

# Create a new "job definition" and, if needed, run asynchronously the process
# that produces the output (pdf) file. When run asynchronously the "job
# definition" is a "FIFO file", otherwise it is a text file (.txt).
# The job file name carries the application name (e.g. "PRACI-AC014.txt") and is
# reachable through the global file handle OUT.
# @param [array] a list of command line options: --help, --index, --edms,
#        --bpdf, --cgi, --noinputfiles, --input_code=s (e.g. utf8).
# @note the input data file (generated by Infinite) is opened and reachable
#       through the global file handle IN.
sub oe_new_job_input_file {
	my $params = oe_params();

	if ( $params->{'input_code'} ) {
		$params->{'input_code'} = "<:encoding(" . $params->{'input_code'} . ")";
	}
	else {
		$params->{'input_code'} = "<";
	}

	my $fi;
	if ( $params->{help} ) {
		oe_app_usage();
		exit 0;
	}
	elsif ( $params->{noinputfiles} ) {
		$fi = 0;
		warn "INFO: no input file for this treatment\n";
	}
	elsif ( !scalar @ARGV ) {    # TO KEEP COMPATIBILITY
		oe_app_usage();
		exit 0;
	}
	else {
		$fi = $ARGV[0];                       # TO KEEP COMPATIBILITY
		$params->{'inputfile'} = $fi;

		open( IN, $params->{input_code}, $fi )    ## no critic (InputOutput::ProhibitBarewordFileHandles)
			or die sprintf( 'Cannot open the input file "%s": %s', $fi, $! );
		warn "INFO: input perl data is $fi (encode '" . $params->{'input_code'} . "' $ARGV[-1])\n";
	}

	return;
}

sub oe_new_job_output_file {
	my $params = oe_params();
	my $cfg    = oe_config_compo();

	$params->{'outfile'}     = $cfg->{'EDTK_PRGNAME'} . ".txt";         # should be tied to TexMode
	$params->{'output_code'} = $cfg->{'EDTK_OUT_ENCODING'} || 'utf8';
	$params->{'output_code'} = ">:encoding(" . $params->{'output_code'} . ")";

	# Override default setting if EDTK_COMPO_ASYNC is set in edtk.ini.

	if (   exists $cfg->{'EDTK_COMPO_ASYNC'}
		&& defined $cfg->{'EDTK_COMPO_ASYNC'}
		&& $cfg->{'EDTK_COMPO_ASYNC'} )
	{
		my $async = $cfg->{'EDTK_COMPO_ASYNC'};
		if ( $async =~ /^yes$/i ) {
			$params->{'fifo'} = 1;
		}
		elsif ( $async =~ /^no$/i ) {
			$params->{'fifo'} = 0;
		}
		else {
			die sprintf
				'Unexpected value for configuration tag EDTK_COMPO_ASYNC: "%s"',
				$async;
		}
	}

	if ( $params->{'fifo'} ) {
		if (   ( exists $cfg->{EDTK_FIFO_MODE} )
			&& ( $cfg->{EDTK_FIFO_MODE} eq 'NONE' ) )
		{
			warn "INFO: Deactivating FIFO MODE, as requested in the configuration";
			$params->{'fifo'} = 0;
		}
		elsif ( $^O eq 'MSWin32' ) {
			warn "INFO: FIFO mode is not possible under Windows, ignoring.\n";
			$params->{'fifo'} = 0;
		}
	}

	# In FIFO mode a left-over text file makes mkfifo() fail; without FIFO mode a
	# left-over FIFO would hang us indefinitely, so remove it first.
	if ( -e $params->{'outfile'} ) {
		unlink( $params->{'outfile'} )
			or die( sprintf 'Cannot remove the file "%s": %s', $params->{'outfile'}, $! );
	}

	# start the LaTeX engine when the FIFO mode is activated.
	if ( $params->{'fifo'} ) {
		mkfifo( $params->{'outfile'}, oct(700) )
			or die
			sprintf( 'ERROR: Could not create fifo in file "%s": %s', $params->{'outfile'}, $! );
		my $pid = oe_compo_run( $cfg->{'EDTK_PRGNAME'}, $params );
		$params->{'pid'} = $pid;
	}

	# create the output file "/path/to/lateX/file.tex".
	_dump( sprintf "\n%%\n%% ==> %s <==\n%%\n%%", $params->{outfile} );
	open( OUT, $params->{output_code}, $params->{outfile} )    ## no critic (InputOutput::ProhibitBarewordFileHandles)
		or die sprintf 'Can not open the output file "%s": %s', $params->{outfile}, $!;
	warn sprintf( 'INFO: input compo data is "%s" (encode is "%s".',
		$params->{'outfile'}, $params->{'output_code'} );
	return;
}

sub oe_watermark {
	my ($cfg) = @_;
	$cfg //= config_read('COMPO');
	return $cfg->{'EDTK_WATERMARKTEXT'} || q{ };               # XXX //?
}

# Getter (no argument) / setter (a hash ref) for the run parameters.
sub oe_params {
	my ($params) = @_;
	state $_RUN_PARAMS;
	if ( defined $params ) {
		$_RUN_PARAMS = $params;
	}
	else {
		return $_RUN_PARAMS;
	}
}

# The COMPO configuration, read once per run.
sub oe_config_compo {
	state $_RUN_CFG = config_read();
	return $_RUN_CFG;
}

sub oe_options {
	my (@args) = @_;
	my $params = oe_params();         # read (getter)
	my $cfg    = oe_config_compo();
	return ( $params, $cfg ) if defined $params;
	$params = {};

	# load all configuration parameters that describe the publication
	# environment: EDTK_BIN_COMPO, EDTK_COMPO, EDTK_COMPO_CMD_PDF...
	my $defaults = {%DEFAULT_OPTIONS};
	GetOptionsFromArray(
		[ @ARGV, @args ], $defaults,      'help',    'index',
		'massmail',       'edms',         'bpdf',    'cgi',
		'noinputfiles',   'input_code=s', 'iddoc=s', 'nocallplan',
		'forced-paper'
	);
	while ( my ( $key, $val ) = each( %{$defaults} ) ) {
		$params->{$key} //= $val;
	}
	$params->{'doclib'} = _omngr_doclib();
	if ( exists $params->{'iddoc'} ) {
		$_ID_LDOC = $params->{'iddoc'};
	}
	$params->{'idldoc'} = oe_ID_LDOC();

	$params->{'type-prod'} = oe_typ_prod($cfg);
	$params->{'HOST-NAME'} = hostname();
	$params->{'app-ref'}   = $cfg->{'EDTK_PRGNAME'};
	if ( $params->{'index'} ) {
		$params->{'activate-lotissement'} = 1;
		$params->{'Host-name'}            = hostname();
	}
	$defaults->{'fifo'} = ( $^O eq 'MSWin32' ) ? 0 : 1;
	my $env = $cfg->{'EDTK_TYPE_ENV'} // croak "Env. var. 'EDTK_TYPE_ENV' undef";
	if ( $env eq 'Production' ) {
		$params->{'type-app'} = 'prod';
	}
	else {
		$params->{'watermark'} = oe_watermark($cfg);
		$params->{'type-app'}  = 'test';
	}

	# handle options passed in the EDTK_OPTIONS environment variable.
	if ( exists( $ENV{'EDTK_OPTIONS'} ) ) {
		my @opts = split( ',', $ENV{'EDTK_OPTIONS'} );
		foreach my $opt (@opts) {
			$params->{$opt} = 1;
		}
	}

	oe_params($params);    # write (setter)
	return ( $params, $cfg );
}

# Historical name kept as an alias of oe_ID_LDOC (same format until S70).
# The true generator: a fresh UUID on every call (fork F semantics, S70/D1).
# oe_ID_LDOC is the memoized entry point; oe_new_ID_LDOC is exported for the
# callers that genuinely want a new id.
sub oe_new_ID_LDOC {
	$_ID_LDOC = Data::UUID->new->create_str();
	return $_ID_LDOC;
}

sub oe_simple_job {
	my (@args) = @_;
	oe_options(@args);
	oe_new_job_input_file();
	oe_new_job_output_file();
	return ( oe_params(), config_read() );
}

END {
	_restore_sys_date;

	# duplicate with oEdtk.pm  :
	#warn "(c) 2005-2020 grechary\@cpan.org - edtk\@free.fr - oEdtk v$VERSION\n";
}

1;

=head1 NAME

oEdtk::Main - core helpers for the oEdtk document pipeline

=head1 SYNOPSIS

    use oEdtk::Main;

    oe_simple_job(@ARGV);            # options, input and output files
    oe_rec_motif($key, $pattern);    # describe a record
    oe_process_ref_rec($off, $len, \$line);

=head1 DESCRIPTION

The central module of the toolkit. It provides the record template engine
(describe a record, match it in a line, unpack and process it), the address,
text, date and number helpers, the input/output file handling, the
document-batch id generation, and the job run lifecycle (option parsing,
FIFO/LaTeX composition, dissemination). The exported globals C<*IN>, C<*OUT>,
C<@DATATAB> and the C<%motifs>, C<%ouTags>, C<%evalSsTrt> hashes carry the run
state.

=head1 FUNCTIONS

=head2 date2time

    date2time($date);

Deprecated: turn a C<YYYYMMDD> date into an epoch time through C<gmtime>.

=head2 prodEdtk_Current_Rec

    my $key = prodEdtk_Current_Rec();

Return the current record identifier.

=head2 prodEdtk_Previous_Rec

    my $key = prodEdtk_Previous_Rec();

Return the previous record identifier.

=head2 prodEtk_rec_cdata_join

    prodEtk_rec_cdata_join($text);

Append C<$text> to the pending push value.

=head2 recEdtk_erase

    recEdtk_erase($key);

Remove every piece of processing registered for the record C<$key>.

=head2 recEdtk_join_tmplte

    recEdtk_join_tmplte($key, $pattern, $output);

Register a record's unpack pattern and output format together.

=head2 recEdtk_post_process

    recEdtk_post_process($key, $code);

Attach the post-reformat processing C<$code> for the record C<$key>.

=head2 recEdtk_redefine

    recEdtk_redefine($key, $pattern);

Reset and redefine the unpack pattern of the record C<$key>.

=head2 oe_app_usage

    oe_app_usage();

Print the application usage and exit.

=head2 oe_backgrounds_apps

    my $set = oe_backgrounds_apps($section);

Look up the application's background set from C<EDTK_APPS_BACKGROUNDS>.

=head2 oe_CAP_sans_accents

    oe_CAP_sans_accents(\$string);

Strip the accents from C<$string> and uppercase it, in place.

=head2 oe_char_xlate

    my $out = oe_char_xlate($string);

Apply the character-translation dictionary to C<$string>.

=head2 oe_clean_addr

    oe_clean_addr(\$string);

A stricter address cleanup (extra trims and C<\W> removal), in place.

=head2 oe_clean_addr_line

    oe_clean_addr_line(\$string);

Clean a 38-character address line (trim, translate, C<EDTK_DICO_POST>), in
place.

=head2 oe_close_fo

    oe_close_fo($fh);

Close the output file handle.

=head2 oe_compo_link

    oe_compo_link(@options);

Close the files, run (or wait for) LaTeX, and run the post-composition step.

=head2 oe_corporation_get

    my $corp = oe_corporation_get();

Return the current corporation.

=head2 oe_corporation_set

    oe_corporation_set($value);

Translate and set the corporation from C<$value>.

=head2 oe_corporation_tag

    my $tag = oe_corporation_tag();

Return the corporation tag.

=head2 oe_data_build

    oe_data_build($name, $value);

Emit a document tag string for C<$name> and C<$value>.

=head2 oe_date_biggest

    my $date = oe_date_biggest($d1, $d2);

Return the later of two C<DD/MM/YYYY> dates.

=head2 oe_date_smallest

    my $date = oe_date_smallest($d1, $d2);

Return the earlier of two C<DD/MM/YYYY> dates.

=head2 oe_define_TeX_output

    oe_define_TeX_output();

Set the output tag delimiters (default backslash, empty, percent).

=head2 oe_env_var_completion

    oe_env_var_completion(\$path);

Expand C<$ENV> references inside the path C<$path>, in place.

=head2 oe_fmt_date

    my $date = oe_fmt_date($date);

Normalise a C<DD/MM/YY> or C<DD/MM/YYYY> date.

=head2 oe_get_handle_to_input_file

    my $fh = oe_get_handle_to_input_file();

Return the input file handle, croaking when it is not open.

=head2 oe_ID_LDOC

    my $id = oe_ID_LDOC($force);

Return the memoised document-batch id, optionally forcing a value.

=head2 oe_is_IDLDOC

    my $ok = oe_is_IDLDOC($value);

Return true when C<$value> is a valid document-batch id.

=head2 oe_iso_country

    my $label = oe_iso_country($country);

Translate a country through the ISO dictionary.

=head2 oe_list_encodings

    oe_list_encodings();

Print the encodings available from C<Encode>.

=head2 oe_new_ID_LDOC

    my $id = oe_new_ID_LDOC();

Generate a fresh document-batch id (a UUID).

=head2 oe_new_job

    oe_new_job();

Legacy job bootstrap: parse the options, open the input, create the output and
emit the header tags.

=head2 oe_new_job_input_file

    oe_new_job_input_file();

Open the input file using the run parameters.

=head2 oe_now_time

    my $stamp = oe_now_time();

Deprecated: return a C<YYYYMMDDHHMMSS> timestamp.

=head2 oe_num_sign_x

    my $value = oe_num_sign_x(\$amount, $decimals);

Decode an alphanumeric signed amount (a trailing C<p>..C<y> letter), in place.

=head2 oe_num2txt_us

    oe_num2txt_us(\$amount);

Normalise a display-formatted amount (comma to dot), in place.

=head2 oe_open_fi_IN

    oe_open_fi_IN($file, $encoding);

Open the input file (C<IN>), optionally with a given encoding.

=head2 oe_open_fo_OUT

    oe_open_fo_OUT($file, $encoding);

Open the output file (C<OUT>), optionally with a given encoding.

=head2 oe_options

    my ($params, $cfg) = oe_options(@args);

Parse the command-line options into the run parameters and return them along
with the configuration.

=head2 oe_params

    my $params = oe_params($params);

Get, or set, the run parameters.

=head2 oe_print_to_output_file

    oe_print_to_output_file($text);

Print C<$text> to the output file.

=head2 oe_process_ref_rec

    oe_process_ref_rec($key_off, $key_len, \$line, $rec_off, $rec_len);

Match a record key in C<$line> and process the referenced record.

=head2 oe_rec_motif

    oe_rec_motif($key, $pattern);

Register the unpack pattern of the record C<$key>.

=head2 oe_rec_output

    oe_rec_output($key, $format);

Register the C<sprintf> output format of the record C<$key>.

=head2 oe_rec_pre_process

    oe_rec_pre_process($key, $code);

Attach the pre-processing C<$code> for the record C<$key>.

=head2 oe_rec_process

    oe_rec_process($key, $code);

Attach the post-load processing C<$code> for the record C<$key>.

=head2 oe_round

    my $value = oe_round($value, $multiple);

Round C<$value> to a multiple, inferring the decimals.

=head2 oe_set_sys_date

    oe_set_sys_date($date);

Set the system date, remembering the original for restoration at exit.

=head2 oe_simple_job

    my ($params, $cfg) = oe_simple_job(@args);

Convenience bootstrap: options, then the input and output files.

=head2 oe_to_date

    oe_to_date(\$date);

Rewrite a C<YYYYMMDD> date as C<DD/MM/YYYY>, in place.

=head2 oe_trimp_space

    oe_trimp_space(\$string);

Collapse consecutive spaces in C<$string>, in place.

=head2 oe_trt_ref_rec

    oe_trt_ref_rec($id, \$line, $rec_off, $rec_len);

The core record processor: pre-process, unpack, process, reformat and
post-process the referenced record.

=head2 oe_uc_sans_accents

    oe_uc_sans_accents(\$string);

Strip the accents from C<$string> and uppercase it, in place.

=head2 oe_unique_data_name

    my $name = oe_unique_data_name($n, $id, $counter);

Generate a unique name of C<$n> characters.

=head1 EXPORTED VARIABLES

=head2 *IN

The input file handle.

=head2 *OUT

The output file handle.

=head2 @DATATAB

The array into which the records are distributed.

=head2 $LAST_ENR

The last processed record marker.

=head2 %motifs

The record-to-unpack-pattern table.

=head2 %ouTags

The record-to-output-tag table.

=head2 %evalSsTrt

The record-to-post-processing table.

=head1 AUTHOR

The oEdtk team.

=cut

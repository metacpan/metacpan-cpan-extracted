package oEdtk::Main;

use strict;
use warnings;

use Exporter;
our $VERSION 	=2.1109;

our @ISA	=	qw(Exporter);
our @EXPORT = 	qw(
			c7Flux
			date2time
			fmt_address
			fmt_address_sender
			fmt_monetary
			prodEdtk_Current_Rec
			prodEdtk_Previous_Rec
			prodEtk_rec_cdata_join
			recEdtk_erase
			recEdtk_join_tmplte
			recEdtk_post_process
			recEdtk_redefine
			toC7date
			oe_app_usage
			oe_CAP_sans_accents
			oe_cdata_table_build
			oe_char_xlate
			oe_clean_addr_line
			oe_close_fo
			oe_compo_link
			oe_compo_set_value
			oe_corporation_get
			oe_corporation_set
			oe_corporation_tag
			oe_csv2data_handles
			oe_data_build
			oe_date_biggest
			oe_date_smallest
			oe_define_TeX_output
			oe_define_Compuset_output
			oe_env_var_completion
			oe_fmt_date
			oe_ID_LDOC
			oe_iso_country
			oe_list_encodings
			oe_new_job
			oe_now_time
			oe_num_sign_x
			oe_num2txt_us
			oe_open_fi_IN
			oe_open_fo_OUT
			oe_outmngr_compo_run
			oe_outmngr_full_run
			oe_outmngr_output_run
			oe_process_ref_rec
			oe_rec_motif
			oe_rec_output
			oe_rec_pre_process
			oe_rec_process
			oe_round
			oe_set_sys_date
			oe_to_date
			oe_trimp_space
			oe_trt_ref_rec
			oe_uc_sans_accents
			oe_unique_data_name
			*OUT *IN  @DATATAB $LAST_ENR
			%motifs %ouTags %evalSsTrt
			);

use POSIX		qw(mkfifo);
use Date::Calc 	qw(Add_Delta_Days Delta_Days Date_to_Time Today Gmtime Week_of_Year);
use Encode;
use File::Basename;
use Getopt::Long;
use List::MoreUtils	qw(uniq);
use List::Util		qw(reduce);
use Math::Round 	qw(nearest);
use Sys::Hostname;

use oEdtk;
require oEdtk::libC7;
require oEdtk::Outmngr;
require oEdtk::TexDoc;
use oEdtk::Dict;
use oEdtk::Config 	qw(config_read);
use oEdtk::Run		qw(oe_status_to_msg oe_compo_run oe_after_compo oe_outmngr_output_run_tex);
#use oEUser::Lib;

#
# CODE - DOC AT THE END
#

# GENERIC METHOD FOR EXTRACTING AND PROCESSING DATA

 our @DATATAB;				# the array into which records are distributed
							# 	rename to OE_DATATAB
 our $LAST_ENR		="";	# WHAT ABOUT LAST_ENR ????
 our $CURRENT_REC	="";	# current record
 our $PREVIOUS_REC	="";	# previous record

 our %motifs;				#make private
 our %ouTags;				#make private
 our %evalSsTrt;			#make private

 my $_ID_LDOC		='';	# initialize the unique document id (one per run)
 my $PUSH_VALUE	="";


 # PLANNED : CONFIGURATION OF OUTPUT SYSTEM
 # 		return "\\long\\gdef\\$name\{$value\}";
 my $TAG_MODE = 'C7';
 my ($TAG_OPEN, $TAG_CLOSE, $TAG_MARKER, $TAG_ASSIGN, $TAG_ASSIGN_CLOS, $TAG_COMMENT, $TAG_L_SET, $TAG_R_SET);

	sub oe_define_TeX_output(){
		$TAG_MODE = 'TEX';
		# \\long\\gdef\\$name\{$value\}
		# \long\gdef\NUMCONT{000014770}
		# \long\gdef\PRENOM{MIREILLE}\long\gdef\DATE{01/08/2009}\long\gdef\NICY{10}\STARTGAR
		$TAG_OPEN	= "\\";				# a tag opening (open)
		$TAG_CLOSE	= "";				# a tag closing (close)
		$TAG_MARKER	= "";				# a tag start marker
		$TAG_ASSIGN	= "long\\gdef\\\{";	# a value assignment marker
		$TAG_ASSIGN_CLOS= "\}"; 		# a value assignment closing marker
		$TAG_COMMENT	= "%";			# a comment (rem)
		$TAG_L_SET	= "";				# variable assignment: left part
		$TAG_R_SET	= "";				# variable assignment: right part

		# \long\gdef\xProdApp\}
	1;
	}

oe_define_TeX_output();		# default values


################################################################################
## 		COMPUSET-SPECIFIC, USED ELSEWHERE (XLS)
################################################################################

	sub oe_rec_motif ($$){		# migrate oe_rec_motif
		# FUNCTION TO DESCRIBE THE UNPACK PATTERN OF THE RECORD
		#
		#  appel :
		# 	oe_rec_motif ($keyRec, "A2 A10 A15 A10 A15 A*");
		my $keyRec=shift;
		my $motif =shift;
		$motifs{$keyRec}=$motif;
	1;
	}

	sub oe_rec_pre_process ($$){		# migrate oe_rec_pre_process
		# FUNCTION TO ATTACH A PRE-PROCESSING TO A RECORD
		#  this processing runs before the record is loaded into DATATAB
		#  the previous record content is always available in DATATAB
		#  the current record type is known in the execution context
		#
		#  appel :
		# 	oe_rec_pre_process ($keyRec, \&fonction);
		my $keyRec=shift;
		my $refFonction=shift;
		$evalSsTrt{$keyRec}[0]=$refFonction;
	1;
	}

	sub oe_rec_output ($$){		# migrate oe_rec_output
		# FUNCTION TO DESCRIBE THE RECORD OUTPUT FORMAT FOR SPRINTF
		#
		#  appel :
		# 	oe_rec_output ($keyRec, "<#GESTION=%s><#PENOCOD=%s><#LICCODC=%s><SK>%s");
		my $keyRec=shift;
		my $format=shift;
		$ouTags{$keyRec}=$format;
	1;
	}


################################################################################
## 		COMPUSET-SPECIFIC, TO BE REMOVED IN THE MEDIUM TERM
################################################################################

sub oe_define_Compuset_output(){
	# <#xAppRef=PRRPC-ADCOMS>
	$TAG_MODE	= 'C7';
	$TAG_OPEN	= '<';		# a tag opening (open)
	$TAG_CLOSE	= '>';		# a tag closing (close)
	$TAG_MARKER	= '#';		# a tag start marker
	$TAG_ASSIGN	= '=';		# a value assignment marker
	$TAG_ASSIGN_CLOS= ''; 		# a value assignment closing marker
	$TAG_COMMENT	= '<SK>';	# a comment (rem)
	$TAG_L_SET	= '<SET>';	# variable assignment: left part
	$TAG_R_SET	= '<EDIT>';	# variable assignment: right part
1;
}


# The newlines are important here, otherwise if you consume too much
# input in Compuset and don't process it right away, you'll get bogus
# errors at character count 16384.

sub fmt_monetary($) {	# cf oe_num2txt_us / oe_compo_set_value
	# DO NOT USE AT ALL ANYMORE!
	my $mnt = shift;

	#$mnt = oe_num2txt_us($mnt);
	$mnt=~s/\s*//g;
	if ($mnt ne 0) {	# fmt_monetary drops zero amounts, which is not a good solution (e.g. INCIMRI) => fix it, but beware of a possible regression on MHN reports
				# we use 'ne' because at this point the amount may be: '1 000.00' or '-120.00' or '63.00-'
		$mnt = oe_compo_set_value($mnt);
	} else {
		# Some lines have optional amounts and we don't want
		# to print 0,00 in that case.
		$mnt = '';
	}
	return $mnt;
}

sub fmt_address(@) {		# migrate c7_oe_fmt_adr
	my @addr = map { oe_clean_addr_line($_) } @_;
	return reduce { "$a<nlIF>$b" } @addr;
}

sub fmt_address_sender(@) {	# migrate c7_oe_fmt_sender_adr
	my $first = shift;
	my $addr = fmt_address(@_);
	return fmt_address($first) . "<nlIF/LT>$addr";
}


sub toC7date(\$) {		# migrate c7_oe_to_date
	# RECEIVES A REFERENCE TO A DATE IN YYYYMMDD FORMAT
	# FORMATS AS <C7J>DD<C7M>MM><C7A>YYYY
	my $refVar  =shift;
	${$refVar}||="";
	${$refVar}=~s/(\d{4})(\d{2})(\d{2})(.*)/\<C7j\>$3\<C7m\>$2\<C7a\>$1/o;

return ${$refVar};
}

sub c7Flux(\$) {		# migrate c7_oe_ref_norm_flux
	# THE "LESS-THAN" AND "GREATER-THAN" SIGNS ARE DELIMITERS RESERVED FOR COMPUSET
	# BUSINESS STREAMS ARE PROCESSED TO REPLACE THESE SIGNS WITH BRACES
	# AT EDITION TIME, COMPUSET RESTORES THESE SIGNS TO GET THE EXPECTED DISPLAY
	#
	# IN THE COMPUSET CONFIGURATION, THE FOLLOWING LINES ARE USED TO RESTORE THE ORIGINAL CHARACTERS:
	# THE CHARACTER { IN THE DATA STREAM IS REPLACED BY THE LESS-THAN SIGN AT COMPOSITION
	#	<TF,{,<,>
	# THE CHARACTER } IN THE DATA STREAM IS REPLACED BY THE GREATER-THAN SIGN AT COMPOSITION
	#	<TF,},>,>
	#
	# the function is called with an implicit reference passing
	#	c7Flux($chaine);

	my $refChaine  =shift;
	${$refChaine}||="";
	${$refChaine}=~s/</{/g;
	${$refChaine}=~s/>/}/g;
1;
}


	sub recEdtk_erase ($){		# migrate oe_rec_erase
		# FUNCTION TO REMOVE THE PROCESSING OF A RECORD
		#
		#  appel :
		# 	recEdtk_erase ($keyRec);
		my $keyRec=shift;
		$evalSsTrt{$keyRec}[0]="";
		$evalSsTrt{$keyRec}[1]="";
		$evalSsTrt{$keyRec}[2]="";
		$motifs{$keyRec}="";
		$ouTags{$keyRec}="-1";
	1;
	}

	sub recEdtk_redefine ($$){		# migrate oe_rec_redefine
		# FUNCTION TO REDEFINE THE PROCESSING OF A RECORD
		#
		#  appel :
		# 	recEdtk_redefine ($keyRec, "A2 A10 A15 A10 A15 A*");
		my $keyRec=shift;
		my $motif =shift;
		recEdtk_erase($keyRec);
		oe_rec_motif($keyRec, $motif);
	1;
	}


	sub recEdtk_join_tmplte ($$$){		# migrate oe_rec_joined_descriptors
		# FUNCTION TO COMPLETE THE UNPACK PATTERN DESCRIPTORS OF THE RECORD
		# AND THE OUTPUT FORMAT IN PARALLEL
		#
		#  appel :
		# 	recEdtk_join_tmplte ("abc", 'A2', '<#tag=%s>');
		# 	recEdtk_join_tmplte ($keyRec, $motif, $output);

		my $keyRec=shift;
		my $motif	=shift;
		$motif	||="A*";
		my $output=shift;
		$output	||="%s";
		$motifs{$keyRec}.=$motif;
		$ouTags{$keyRec}.=$output;
		$ouTags{$keyRec}=~s/^\-1//; # when recEdtk_join_tmplte is used to set ouTags dynamically during oe_trt_ref_rec, the default ouTags value = '-1' (no processing) => remove it so as not to pollute the output
	1;
	}


	sub oe_rec_process ($$){		# migrate oe_rec_process
		# FUNCTION TO ATTACH A PROCESSING TO A RECORD
		#  this processing runs right after the record is loaded into DATATAB
		#
		#  appel :
		# 	oe_rec_process ($keyRec, \&fonction);
		my $keyRec=shift;
		my $refFonction=shift;
		$evalSsTrt{$keyRec}[1]=$refFonction;
	1;
	}

	sub recEdtk_post_process ($$){		# migrate recEdtk_post_process
		# FUNCTION TO ATTACH A POST-PROCESSING TO A RECORD
		#  this processing runs right after the record is reformatted in format_sortie
		#  the record line is known in the execution context, in its "format_sortie" form
		#
		#  appel :
		# 	recEdtk_post_process ($keyRec, \&fonction);
		my $keyRec=shift;
		my $refFonction=shift;
		$evalSsTrt{$keyRec}[2]=$refFonction;
	1;
	}

	sub oe_process_ref_rec ($$\$;$$) {		# migrate oe_process_ref_rec
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
		my $offsetKey	=shift;
		my $lenKey	=shift;
		my $refLigne	=shift;
		my $offsetRec	=shift;	# optional
		$offsetRec	||=0;
		my $lenRec	=shift;	# optional
		$lenRec		||="";

		if (${$refLigne}=~m/^.{$offsetKey}(\w{$lenKey})/s && oe_trt_ref_rec($1,$refLigne,$offsetRec,$lenRec)){
			# the record has been identified and processed
			# emit the record
			print OUT ${$refLigne};
			return 1;
		}
	# OTHERWISE THE RECORD WAS NOT RECOGNIZED, THIS IS A FAILURE
	return 0;
	}

	sub oe_trt_ref_rec ($\$;$$){		# migrate oe_trt_ref_rec
		# MAIN RECORD PROCESSING
		# GENERIC METHOD V0.2.1 27/04/2009 10:05:03 (reference passing becomes implicit)
		# THE FUNCTION NEEDS THE RECORD TYPE AND THE REFERENCE TO A DATA LINE
		#  appel :
		#	oe_trt_ref_rec($Rec_ID, $ligne [,$offsetRec,$lenRec]);
		#  returns: status, $Rec_ID
		my $Rec_ID	=shift;
		my $refLigne	=shift;
		my $offsetRec	=shift;		# OPTIONAL OFFSET OF DATA TO DROP AT THE START OF THE LINE
		my $lenRec	=shift;		# OPTIONAL LENGTH OF DATA TO PROCESS
		# DEFAULT VALUES
		$ouTags{$Rec_ID} 	||="-1";
		$motifs{$Rec_ID} 	||="";
		$offsetRec 		||=0;
		$lenRec			||="";

		# IF THE EXTRACTION PATTERN OF THE RECORD TYPE IS UNKNOWN,
		#  AND IF THERE IS NO PRE-PROCESSING ATTACHED TO THE RECORD TYPE,
		#  THEN THE RECORD TYPE IS UNKNOWN
		#
		# THIS CHECK ALLOWS DEFINING A RECORD TYPE DYNAMICALLY BASED ON THE CONTEXT
		#  THAT IS, A RECORD OF TYPE "1" MAY HAVE DIFFERENT CHARACTERISTICS
		#  DEPENDING ON THE PREVIOUSLY PROCESSED RECORD TYPE.
		#  THESE CHARACTERISTICS CAN BE SET AT PRE-PROCESSING TIME.
		#
		if ($motifs{$Rec_ID} eq "" && !($evalSsTrt{$Rec_ID}[0])) {
			warn "INFO : oe_trt_ref_rec() > LINE $. REC. >$Rec_ID< (offset $offsetRec) UNKNOWN\n";
			return 0;
		}

		$PREVIOUS_REC	=$CURRENT_REC;
		$CURRENT_REC	=$Rec_ID;

		# STEP 0 : EVAL PRE-PROCESSING of $refLigne
		&{$evalSsTrt{$Rec_ID}[0]}($refLigne) if $evalSsTrt{$Rec_ID}[0];

		# MAKE SURE TO FULLY CLEAR THE READ ARRAY OF THE PREVIOUS RECORD
		undef @DATATAB;

		# OPTIONALLY DROP UNNEEDED DATA (OFFSET AND OUTSIDE USEFUL DATA (lenData))
		${$refLigne}=~s/^.{$offsetRec}(.{1,$lenRec}).*/$1/ if ($offsetRec > 0);

		# SPLIT THE RECORD INTO FIELDS
		@DATATAB =unpack ($motifs{$Rec_ID},${$refLigne})
				or die "ERROR: oe_trt_ref_rec() > LINE $. typEnr >$Rec_ID< motif >$motifs{$Rec_ID}< UNKNOWN\n";

		# STEP 1 : EVAL FIELD PROCESSING
		&{$evalSsTrt{$Rec_ID}[1]} if $evalSsTrt{$Rec_ID}[1];

		# STRUCTURE THE RECORD FOR OUTPUT
		if ($ouTags{$Rec_ID} ne "-1"){
			${$refLigne}  ="${TAG_OPEN}a${Rec_ID}${TAG_CLOSE}";
			${$refLigne} .=sprintf ($ouTags{$Rec_ID},@DATATAB)
						or die "ERROR: oe_trt_ref_rec() > LINE $. typEnr >$Rec_ID< ouTags >$ouTags{$Rec_ID}<\n";
			${$refLigne} .="${TAG_OPEN}e${Rec_ID}${TAG_CLOSE}\n";
		} else {
			${$refLigne}="";
		}
		$LAST_ENR=$Rec_ID;

		# STEP 2 : EVAL POST-PROCESSING
		&{$evalSsTrt{$Rec_ID}[2]} if $evalSsTrt{$Rec_ID}[2];

		# OPTIONALLY ADD EXTRA DATA
		${$refLigne} .=$PUSH_VALUE;
		$PUSH_VALUE ="";
		${$refLigne} =~s/\s{2,}/ /g;	#	CONCATENATION OF BLANKS
		#$LAST_ENR=$Rec_ID;

	return 1, $Rec_ID;
	}

	sub prodEtk_rec_cdata_join ($){		# migrate prodEtk_rec_cdata_join
		$PUSH_VALUE .=shift;
	1;
	}

	sub prodEdtk_Previous_Rec () {		# migrate oe_previous_rec
		return $PREVIOUS_REC;
	}

	sub prodEdtk_Current_Rec () {		# migrate oe_current_rec
		return $CURRENT_REC;
	}

################################################################################


sub oe_round ($;$){
	# http://perl.enstimac.fr/allpod/fr-5.6.0/perlfaq4.pod
	# http://perl.enstimac.fr/DocFr/perlfaq4.html
	# http://www.linux-kheops.com/doc/perl/faq-perl-enstimac/perlfaq4.html
	# Perl is not at fault. It is the same as in C. IEEE says we must do it this way. Perl numbers whose absolute value is an integer below 2**31 (on 32-bit machines) will generally behave as mathematical integers. Other numbers are not guaranteed.
	my $value	=	shift;
	my $multiple=	shift;
	my $decimal;#=	shift;

	#if (!(defined $decimal)){$decimal = 2;}	# decimal may be 0 (decimal converted to an integer)
	if (!(defined $multiple)){$multiple = .01;}	# $multiple may be 0 (decimal converted to an integer)
	if ($multiple=~/^0\./){
		$decimal=length($multiple)-2;
	}elsif ($multiple=~/^\./){
		$decimal=length($multiple)-1;
	} else {
		$decimal = 0;
	}
	my $motif	= "%.0${decimal}f";
	#my $multiple=1/(10**$decimal);
	$value = nearest ($multiple, $value);

	return sprintf ($motif, $value);
}

sub oe_num_sign_x(\$;$) {		# migrate oe_num_sign_x
	# processing of alphanumeric signed amounts
	# receives: a reference to an alphanumeric variable
	#          a number of decimals after the point (optional, 0 by default)

	my ($refMontant, $decimal)=@_;
	${$refMontant}	||="";
	$decimal		||=0;

	# check the validity of the passed value
	${$refMontant}=~s/\s+//g;
	if (${$refMontant} eq "" || ${$refMontant} eq 0) {
		${$refMontant} =0;
		return 1;
	} elsif (${$refMontant}=~/\D{2,}/){
		warn "INFO : value (${$refMontant}) not numeric.\n";
		return -1;
	}

	my %hXVal;
	$hXVal{'p'}=0;
	$hXVal{'q'}=1;
	$hXVal{'r'}=2;
	$hXVal{'s'}=3;
	$hXVal{'t'}=4;
	$hXVal{'u'}=5;
	$hXVal{'v'}=6;
	$hXVal{'w'}=7;
	$hXVal{'x'}=8;
	$hXVal{'y'}=9;

	if ( ${$refMontant}=~s/(\D{1})$/$hXVal{$1}/ ) {
		# a value with an alphanumeric negative sign 213y => -2139
		${$refMontant}=(${$refMontant}*(-1));
 		# warn "INFO : SIGNED AMOUNT";
  	} elsif (${$refMontant}=~/^-{1}/){
		# a value with a negative sign -123456
	}

	${$refMontant}=${$refMontant}/(10**$decimal);

return ${$refMontant};
}


sub date2time ($){		# migrate oe_date_to_time
	# DEPRECATED FUNCTION,
	# USE THE SPECIALIZED LIBRARY: Date::Calc
	my $date=shift; # a date in YYYYMMDD format

	my $tmpDate="AAAAMMJJ";
	my $decalage=0;
	my $jours=-1;
	my $time=time;
	my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday) =
		gmtime($time);
	my $nowDate=sprintf ("%4.0f%02.0f%02.0f", $year+1900, $mon+1, $mday);

	if ($nowDate > $date){
		# date is older
		$decalage=-1;
	}elsif ($nowDate < $date){
		# date is newer
		$decalage=+1;
	}

	while ($date ne $tmpDate){
		$jours++;
		# a day has 86400 seconds
		($sec,$min,$hour,$mday,$mon,$year,$wday,$yday) =
			gmtime($time+($decalage*$jours*86400));
		$tmpDate=sprintf ("%4.0f%02.0f%02.0f", $year+1900, $mon+1, $mday);
	}

return ($time+($decalage*$jours*86400)), ($decalage*$jours);
}


sub oe_now_time(){			# migrate oe_now_time
	# DEPRECATED FUNCTION,
	# USE THE SPECIALIZED LIBRARY: Date::Calc -> Today

	my $time =time;
	my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday) =
		gmtime($time);
	$time =sprintf ("%4.0f%02.0f%02.0f%02.0f%02.0f%02.0f", $year+1900, $mon+1, $mday, $hour, $min, $sec);

return $time;
}

# ISO COUNTRY DICTIONARY
my $_DICO_COUNTRY;
# ABBREVIATIONS DICTIONARY.
my $_DICO_POST;
# translation dictionary for characters (discouraged, but sometimes needed).
my $_DICO_CHAR;


{
my $_LAST_ISO ="";

	sub oe_iso_country(;$){
		# returns the country code in country_dico.ini coding or the last known value
		my $country = shift;
		if (!defined($_DICO_COUNTRY))  {
			my $cfg		= config_read();
			$_DICO_COUNTRY	= oEdtk::Dict->new($cfg->{'EDTK_DICO_COUNTRY'}, , { section => $cfg->{'EDTK_LANG'} });
		}
		$_LAST_ISO = $_DICO_COUNTRY->translate($country) if defined ($country);
		return $_LAST_ISO;
	}
}


sub oe_char_xlate($;$){ # to migrate into the dictionary?
		my $scalar = shift;

		if (!defined($_DICO_CHAR))  {
			my $section	= shift || 'DEFAULT';
			my $cfg		= config_read();
			$_DICO_CHAR	= oEdtk::Dict->new($cfg->{'EDTK_DICO_XLAT'}, , { section => $section });
		}
		$scalar = $_DICO_CHAR->substitue($scalar);

	return $scalar;
}


sub oe_clean_addr_line(\$) {	# migrate oe_clean_addr_line
	# THIS FUNCTION CLEANS ADDRESS LINES TO BUILD THE RECIPIENT ADDRESS BLOCKS
	# it works directly on the variable reference but also returns the resulting string
	my $rLine = shift;

	# default value in case the field is undef 
	if (!defined($$rLine) || length($$rLine) == 0) {
		$$rLine = '';
		return $$rLine;
	}

	chomp($$rLine);	# to be sure there is no trailing newline at the end of the field
	oe_trimp_space($rLine);

	$$rLine = oe_char_xlate($$rLine, 'ADDRESS');
	# TODO: a regex that replaces everything that is not 0-9, -, degrees or \w with blanks...

	# THE NEXT LINE MUST BE ENABLED ONLY AFTER TESTING, FOR NOW HANDLED BY oe_char_xlate
	#$$rLine =~ s/\\+/\//g;	# we remove/replace backslashes which are escape characters and which apparently are not counted in the size check (sprintf("%.38s",...) 
	$$rLine =~ s/^\s+//;	# remove consecutive blanks at the start of the string (an oe_trimp_space was done first...) LEFT TRIM
	$$rLine =~ s/\s+$//;	# remove consecutive blanks at the end of the string (...) RIGHT TRIM
	$$rLine =~ s/^0\s+//;	# remove lone zeros at the start of the string (done last, after the LEFT TRIM)
	$$rLine =~ s/\s+/ /;	# collapse consecutive blanks

	# Use the given dictionary to translate words.
	if (length($$rLine) > 38) {
		if (!defined($_DICO_POST))  {
			my $cfg = config_read();
			$_DICO_POST = oEdtk::Dict->new($cfg->{'EDTK_DICO_POST'});
		}
		my @words = split(/ /, $$rLine);
		$$rLine = join(' ', map { $_DICO_POST->translate($_) } @words);
	}
	$$rLine = sprintf("%.38s", $$rLine); # make sure not to exceed 38 characters per line

	# TO AVOID FORCED BLANKS BETWEEN ADDRESS FIELDS (E.G. <PEADNUM>`<PEADBTQ>`<PEVONAT>`<LIBVOIX><NLIF>)
	# add a trailing blank to the field if it contains at least one character
	if ($TAG_MODE eq "C7" && $$rLine =~ /\w+$/) {
		$$rLine .= " ";
	}
	return $$rLine;
}


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

	my $refChaine  =shift;
	${$refChaine}||="";
	${$refChaine}=~s/[ÀÂÄ]/A/g;
	${$refChaine}=~s/[ÉÈÊË]/E/g;
	${$refChaine}=~s/[ÌÎÏ]/I/g;
	${$refChaine}=~s/[ÒÔÖÕ]/O/g;
	${$refChaine}=~s/[ÚÙÛÜ]/U/g;
	${$refChaine}=~s/Ç/C/g;
	# the uc command is not included; it can be done before calling oe_CAP_sans_accents
	# - either keep accented lowercase letters, or capitalize everything
	## ${$refChaine}= uc ${$refChaine};

return ${$refChaine};
}

sub oe_uc_sans_accents (\$) {	# migrate oe_uc_sans_accents
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

	my $refChaine  =shift;
	${$refChaine}||="";
	${$refChaine}=~s/[àâä]/a/ig;
	${$refChaine}=~s/[éèêë]/e/ig;
	${$refChaine}=~s/[ìîï]/i/ig;
	${$refChaine}=~s/[òôöõ]/o/ig;
	${$refChaine}=~s/[úùûü]/u/ig;
	${$refChaine}=~s/ç/c/ig;
	${$refChaine}= uc ${$refChaine};

return ${$refChaine};
}


sub oe_trimp_space(\$) {		# migrate oe_trimp_space
	# REMOVE CONSECUTIVE SPACES (TRAILING BLANK) BY GROUPING
	# the parameter must be a reference, example: oe_trimp_space($chaine)
	# returns the number of removed characters
	my $rChaine  =shift;
	${$rChaine}||="";
	${$rChaine} =~s/\s{2,}/ /go;

return ${$rChaine};
}


sub oe_list_encodings {
	my @list = Encode->encodings();
	warn "INFO : available encodings on this machine are : @list\n";
}

				# migrate oe_open_fi_IN
sub oe_open_fi_IN ($;$){ 		# BASIC INPUT FILE HANDLING
	my $fi =shift;
	open (IN, "$fi")	or die "ERROR: opening $fi, return code $!\n";

1;
}

				# migrate oe_open_fo_OUT
sub oe_open_fo_OUT ($){ 		# BASIC OUTPUT FILE HANDLING
	my $fo =shift;
	open (OUT, "> $fo")	or die "ERROR: opening $fo - return code $!\n";

1;
}


sub oe_close_fo ($) {	# migrate oe_close_fo
	my $f =shift;

	close (OUT) or die "ERROR: closing $f - return code $!\n";
1;
}

sub oe_to_date(\$) {		# migrate oe_to_date
	# RECEIVES A REFERENCE TO A DATE IN YYYYMMDD FORMAT
	# FORMATS AS DD/MM/YYYY
	my $refVar  =shift;
	${$refVar}||="";
	${$refVar}=~s/(\d{4})(\d{2})(\d{2})(.*)/$3\/$2\/$1/o;

return ${$refVar};
}


sub oe_fmt_date($) {		# migrate oe_fmt_date
	my $date = shift;

	die "ERROR: Unexpected date format: \"$date\"\n"
	    if $date !~ /^\s*(\d{1,2})\/(\d{1,2})\/(\d{2}|\d{4})\s*$/;

	return sprintf("%02s/%02s/%s", $1, $2, $3);
}

# Convert a date in DD/MM/YYYY format to YYYYMMDD format.
sub oe_date_convert($) {	# oe_date_format
	my $date = shift;

	if ($date !~ /^\s*(\d{1,2})\/(\d{1,2})\/(\d{4})\s*$/) {
		return undef;
	}
	return sprintf("%d%02d%02d", $3, $2, $1);
}

sub oe_date_compare {
	my ($date1, $date2) = @_;

	if ($date1 eq '') {
		$date1=$date2;
	}

	my $wdate1 = oe_date_convert($date1);
	my $wdate2 = oe_date_convert($date1);

	if (!defined($wdate1)) {
		warn "INFO : Unexpected date format: \"$date1\" should be dd/mm/yyyy. Date ignored\n";
		return 1;
	}
	if (!defined($wdate2)) {
		warn "INFO : Unexpected date format: \"$date2\" should be dd/mm/yyyy. Date ignored\n";
		return -1;
	}
	return $wdate1 <=> $wdate2;
}

sub oe_date_smallest($$) {
	my ($date1, $date2) = @_;

	if (oe_date_compare($date1, $date2) <= 0) {
		return $date1;
	} else {
		return $date2;
	}
}

sub oe_date_biggest($$) {
	my ($date1, $date2) = @_;

	if (oe_date_compare($date1, $date2) <= 0) {
		return $date2;
	} else {
		return $date1;
	}
}


sub oe_num2txt_us(\$) {
	# process amounts in Text format
	# the decimal separator "," is turned into "." for US / C7 load commands
	# the thousands separator "." or " " is removed
	# receives: an alphanumeric variable formatted for display
	# 		$value = oe_num2txt_us($value);
	# or by reference
	# 		oe_num2txt_us($value);

	my $refValue  = shift;
	${$refValue}||="";

	if (${$refValue}){
		${$refValue}=~s/\s+//g;		# remove blanks
		${$refValue}=~s/\.//g;		# remove thousands separators
		${$refValue}=~s/\,/\./g;	# replace the decimal separator
		${$refValue}=~s/(.*)(\-)$/$2$1/;# optionally move the negative sign to the front

	} else {
		${$refValue}=0;
	}

return ${$refValue};
}


# NO LONGER USED IN THE LaTeX CONTEXT
sub oe_compo_set_value ($;$){	# oe_cdata_set
	my ($value, $noedit) = @_;

	# TO REMOVE: SOME NUMBERS ARE ALREADY IN USE
	# -> oe_compo_set_value($value) => oe_compo_set_value(oe_num2txt_us($value))
	my $result = $TAG_L_SET . oe_num2txt_us($value);

	if (!$noedit) {
		$result .= $TAG_R_SET;
	}
	return $result;
}


# NO LONGER USED IN THE LaTeX CONTEXT
sub oe_cdata_table_build($@){	# oe_xdata_table_build
	my $name = shift;
	my @DATATAB = shift;
	my $cdata="";
	for (my $i = 0; $i <= $#DATATAB; $i++) {
		my $elem = sprintf("%.6s%0.2d", $name, $i);
		$cdata .= oe_data_build($elem, $DATATAB[$i] || "");
	}
	#warn "\n";
return $cdata;
}


sub oe_include_build ($$){ # as part of the C7 code cleanup, these calls will need shortening
	my ($name, $path)= @_;
	#import oEdtk::TexDoc;

	my $tag = oEdtk::TexDoc->new();
	$tag->include($name, $path);
	return $tag;
}


# NO LONGER USED IN THE LaTeX CONTEXT
# but used in Main.pm => clean up
sub oe_data_build($;$) {	#oe_xdata_build
	my ($name, $val)= @_;

	if ($TAG_MODE eq 'TEX') {
		my $tag = oEdtk::TexTag->new($name, $val);
		return $tag->emit();
	}

	# FOR COMPUSET
	my $data	= "";
	if 	(defined $val) {
		# if this is a numeric variable
		if ($val =~ /^[\d\.]+$/) {
			$data = $TAG_OPEN . $TAG_MARKER . $name . $TAG_ASSIGN . $TAG_L_SET .
				$val . $TAG_ASSIGN_CLOS . $TAG_CLOSE;
		} else {
			$data = $TAG_OPEN . $TAG_MARKER . $name . $TAG_ASSIGN .
				$val . $TAG_ASSIGN_CLOS . $TAG_CLOSE;
		}
	} elsif	(defined $name) {
		$data = $TAG_OPEN . $name . $TAG_CLOSE;
	}
	return $data;
}


sub oe_app_usage() {		# migrate oe_app_usage
	my $app="";
	$0=~/([\w-]+[\.plmex]*$)/;
	$1 ? $app="application.pl" : $app=$1;
	print STDOUT << "EOF";

 Usage :	$app </source/input/file.dat> [job] [options]
 Usage :	$app --noinputfiles [job] [options]
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


sub oe_new_job(@) {	
	@ARGV = (@ARGV, @_); # optionally override options with the oe_new_job parameters for GetOptions
	my $cfg = config_read('COMPO');
	my $params = {};
	# DEFAULT OPTION VALUES.
	my %defaults = (
#		xls	 		=> 0,
#		tex			=> 0,
		index 		=> 0,
		massmail	=> 0,
		edms 		=> 0,
		cgi			=> 0,
		input_code	=> 0
	);

	# examples of adding parameters at launch 
	# oe_new_job('--index');
	# oe_new_job("--input_code=utf8");

	GetOptions(\%defaults, 'help', 'index', 'massmail', 'edms', 'cgi', 'noinputfiles', 'input_code=s');
	while (my ($key, $val) = each(%defaults)) {
		if (!defined($params->{$key})) {
			$params->{$key} = $val;
		}
	}

	if ($^O ne 'MSWin32') {
		$defaults{'fifo'} = 1;
	} else {
		$defaults{'fifo'} = 0;
	}

	$params->{'doclib'} = _omngr_doclib();
	$params->{'idldoc'} = oe_ID_LDOC();

	$params->{'outfile'} 	= $cfg->{'EDTK_PRGNAME'}.".txt";	# should be tied to TexMode
	$params->{'output_code'}	= $cfg->{'EDTK_OUT_ENCODING'} || 'utf8';
	$params->{'output_code'}	= ">:encoding(". $params->{'output_code'} .")";
	if ($params->{'input_code'}) {
		$params->{'input_code'} = "<:encoding(". $params->{'input_code'} .")";
	} else {
		$params->{'input_code'} = "<";
	}


	my $fi;
	if ($defaults{help}) {
		&oe_app_usage();
		exit 0;
	} elsif ($defaults{noinputfiles}) {
		$fi = 0;	
		warn "INFO : no input file for this treatment\n";
	} elsif ($#ARGV ==-1) {	# TO KEEP COMPATIBILITY
		&oe_app_usage();
		exit 0;
	} else {
		$fi = $ARGV[0];	# TO KEEP COMPATIBILITY
		open(IN, $params->{'input_code'}, $fi)	or die "ERROR: Cannot open \"$fi\" for reading: $!\n";
		warn "INFO : input perl data is $fi (encode \'". $params->{'input_code'} ."\' $ARGV[-1])\n";
	}


	# Override default setting if EDTK_COMPO_ASYNC is set in edtk.ini.
	my $async = $cfg->{'EDTK_COMPO_ASYNC'};
	if (defined($async) && $async =~ /^yes$/i) {
		$params->{'fifo'} = 1;
	} elsif (defined($async) && $async =~ /^no$/i){
		$params->{'fifo'} = 0;
	}

	if ($params->{'fifo'} && $^O eq 'MSWin32') {
		warn "INFO : FIFO mode is not possible under Windows, ignoring.\n";
		$params->{'fifo'} = 0;
	}

	# If we are in FIFO mode and there is a left-over text file, the mkfifo()
	# call would fail.  If we are not in FIFO mode and there's a left-over FIFO,
	# we would hang indefinitely, so make sure to remove this file first.
	unlink($params->{'outfile'});

	# Handle options passed in the EDTK_OPTIONS environment variable.
	if (exists($ENV{'EDTK_OPTIONS'})) {
		my @opts = split(',', $ENV{'EDTK_OPTIONS'});
		foreach my $opt (@opts) {
			$params->{$opt} = 1;
		}
	}

	if ($params->{'fifo'}) {
		warn "INFO : Creating FIFO for output data file (". $params->{'outfile'} .")\n";
		mkfifo($params->{'outfile'}, 0700) or die "ERROR: Could not create fifo : $!\n";
		my $pid = oe_compo_run($cfg->{'EDTK_PRGNAME'}, $params);
		$params->{'pid'} = $pid;
	}

	open(OUT,$params->{'output_code'}, $params->{'outfile'})		or die "ERROR: Cannot open \'". $params->{'outfile'} ."\' for writing: $!\n";
	warn "INFO : input compo data is ".$params->{'outfile'} ." (encode \'". $params->{'output_code'} ."\')\n";

	# Remember for later use in oe_compo_link() & oEdtk::Main.
	$_RUN_PARAMS = $params;

	if (defined $cfg->{'EDTK_COMPO_INCLUDE'} && $cfg->{'EDTK_COMPO_INCLUDE'}=~/yes/i) {
		print OUT oe_include_build($cfg->{'EDTK_PRGNAME'}.".".$cfg->{'EDTK_EXT_COMPO'}, 'EDTK_DIR_SCRIPT');
	}
	print OUT oe_data_build(oe_corporation_tag());
	print OUT oe_data_build('xIdLdoc', $params->{'idldoc'});
	print OUT oe_data_build('xDebFlux');
	print OUT oe_data_build('xAppRef', $cfg->{'EDTK_PRGNAME'});
	print OUT oe_data_build('xDOCLIB', $params->{'doclib'});

	my $env = $cfg->{'EDTK_TYPE_ENV'};
	if ($env ne 'Production') {
		# Generate the 'TEST EDITION' watermark.
		print OUT oe_data_build('xWaterM', $cfg->{'EDTK_WATERMARKTEXT'}||' ');
		print OUT oe_data_build('xTstApp');
	} else {
		# No watermark.
		print OUT oe_data_build('xProdApp');
	}
	print OUT oe_data_build('xTYPPROD', substr($env, 0, 1));
	print OUT oe_data_build('xHOST',	 hostname());

	# Do we want to generate an index file?
	if ($params->{'index'}) {
		print OUT oe_data_build ('xStOmgr');
		print OUT oe_data_build ('xHost', hostname());
	}
	print OUT $TAG_COMMENT;
	print OUT "\n";
}

sub oe_csv2data_handles () {
	undef @DATATAB;
	my $ligne 	= <IN>;
	chomp ($ligne);
	c7Flux($ligne);
	@DATATAB 	= split (/,/, $ligne);
	my $motif	= "";


	# TURN A CSV FILE INTO A DATA FILE
	# THE FIRST LINE DEFINES THE COLUMNS AND THE TAG NAMES
	# a run tag is added at the end of the line = xFLigne
	# finally an end-of-stream tag is added = xFinFlux

	for (my $i=0; $i<=$#DATATAB; $i++){
		$DATATAB[$i] ="vide$i" if ($DATATAB[$i] eq '');
		$DATATAB[$i] =~s/\_//g;

		$motif .= sprintf ('%s%s%.8s%s', $TAG_OPEN, $TAG_MARKER, $DATATAB[$i], $TAG_ASSIGN );
		# my $tag_data =oe_unique_data_name(8, "$DATATAB[$i]", $i);
		# $motif .= sprintf ('%s%s%.8s%s', $TAG_OPEN, $TAG_MARKER, $tag_data, $TAG_ASSIGN);
		$motif .= "%s" . $TAG_ASSIGN_CLOS . $TAG_CLOSE;
	}
	$motif .= $TAG_OPEN . "xFLigne" . $TAG_CLOSE;
	$motif =~s/\s//g;
	# warn $motif . "\n";

	while ($ligne = <IN>) {
		@DATATAB = ();
		chomp ($ligne);
		c7Flux($ligne);
		@DATATAB= split (/,/, $ligne);
		for (my $i=0; $i<=$#DATATAB; $i++){
			if ($DATATAB[$i]=~/^\s*[\d\.\s]+$/){
				$DATATAB[$i] = $TAG_L_SET . $DATATAB[$i];
			}
		}
		$ligne	= sprintf($motif, @DATATAB) || '';
		print OUT $ligne . "\n"; #  if $ligne;
	}

1;
}


sub oe_outmngr_full_run($;$){
	my $input_fdatwork	= shift;
	my $output_format	= shift || "PDF";
	oe_outmngr_compo_run	($input_fdatwork, $output_format);
	oe_outmngr_output_run	();
1;
}

sub oe_outmngr_compo_run ($;$){
	my $input_fdatwork	= shift;
	my $output_format	= shift || "PDF";
	my $xTypTrt		= _app_typ_trt();

	import oEdtk::Outmngr qw(omgr_import);
	import oEdtk::libC7	qw();
	use Fcntl			qw(:flock);
	use File::Copy;

	my $cfg 			= config_read('COMSET');
	my $script_compo	= $cfg->{'EDTK_DIR_SCRIPT'} . "/" . $cfg->{'EDTK_PRGNAME'} . "." . $cfg->{'EDTK_EXT_COMP_OMGR'};
	my $lockfile 		= $cfg->{'EDTK_DOCLIB_LOCK'};
	open(my $lock, '>', $lockfile) or die "ERROR: Cannot open lock file: $!\n";

	warn "INFO : starting compo ($output_format, $script_compo, $input_fdatwork)\n";

	# When Compuset fails with a doclib opened in read-write mode, it corrupts the file,
	# so we have to protect against this...
	my $doclib = _omngr_doclib();
	my $DMG_path = $cfg->{'C7_DCLIB_RW'} . "/$doclib.dmg";

	warn "INFO : Acquiring exclusive lock on $lockfile...\n";
	flock($lock, LOCK_EX) or die "ERROR: Cannot acquire exclusive lock: $!\n";
	warn "INFO : Successfully acquired lock.\n";
	eval {
		if (-f $DMG_path) {
			copy($DMG_path, "$DMG_path.bak") or die "ERROR: Cannot backup \"$DMG_path\": $!\n";
		}
		if (defined $cfg->{'EDTK_TESTDATE'}) { oe_set_sys_date($cfg->{'EDTK_TESTDATE'}) };
		c7_compo ($output_format, $script_compo, $input_fdatwork, "OMGR", $doclib);
		c7_emit  ($output_format, $script_compo, $input_fdatwork, $cfg->{'EDTK_FDATAOUT'}, "OMGR", $doclib);
	};
	if ($@) {
		# There was an error, restore the backup doclib, and re-throw the error.
		copy("$DMG_path.bak", $DMG_path) or warn "INFO : Could not restore the doclib $DMG_path !\n";
		# die $@;
	}
	close($lock);

	my $idx1 	=$cfg->{'EDTK_DIR_OUTMNGR'} . "/" . $cfg->{'EDTK_PRGNAME'} . ".idx1";

	#	warn
	#	"INFO : OM EDTK_PRGNAME = "
	#	. $cfg->{'EDTK_PRGNAME'}
	#	. " EDTK_FTYP_DFLT = "
	#	. $cfg->{'EDTK_FTYP_DFLT'}
	#	. " EDTK_TYP_ENVIRO = "
	#	. $cfg->{'EDTK_TYP_ENVIRO'}
	#	."\n";


	omgr_import	($cfg->{'EDTK_PRGNAME'}, $idx1) if ($xTypTrt =~ /[MGTD]/); # xxxxxx this is where the right application name is needed

	if ($xTypTrt!~/D/) {
		unlink ($idx1);
		unlink ($input_fdatwork);
	}

	print "$cfg->{'EDTK_FDATAOUT'}.$output_format\n";
1;
}


sub oe_outmngr_output_run (;$){
	# the optional parameter sets the processing type to
	# let operations launch the output_run at a regular interval
	my $xTypTrt = _app_typ_trt(shift);

	if ( $xTypTrt !~/[MTD]/) {
		# oe_outmngr_output_run: index_output is only entered for Mass, Debug or batching Test
		warn "INFO : OM processing '$xTypTrt' -> batching suspended\n";
		return 1;
	}

	import oEdtk::Outmngr	qw(omgr_export);
	import oEdtk::libC7 qw ();
	use	Archive::Zip	qw(:ERROR_CODES);
	use	Fcntl		qw(:flock);

	my $cfg 	=config_read('COMSET');

	warn "INFO : starting \@tSsLots =omgr_export\n";
	my @lots = omgr_export();
	my (@tProcessed_Dclib);
	my $lockfile = $cfg->{'EDTK_DOCLIB_LOCK'};
	open(my $lock, '>', $lockfile) or die "ERROR: Cannot open lock file: $!\n";

	foreach (@lots) {
		my ($SsLot, $numpgs, @tDclib) = @$_;

		warn "INFO : Preparation job ticket $cfg->{'EDTK_DIR_OUTMNGR'} $SsLot for compo - tDclib = @tDclib\n";
		my $SsLot_output_txt 	=$cfg->{'EDTK_DIR_OUTMNGR'} . "/" . $SsLot . "." . $cfg->{'EDTK_EXT_WORK'};
		my $SsLot_output_opf 	=$cfg->{'EDTK_DIR_OUTMNGR'} . "/" . $SsLot ; #. "." . $cfg->{'EDTK_EXT_PDF'};
		my $lib_filieres	=$cfg->{'C7_CHAINS_LIB'};

		oe_open_fo_OUT ($SsLot_output_txt);
		oe_open_fi_IN ($cfg->{'EDTK_DIR_OUTMNGR'} . "/" . $SsLot . ".job");
		oe_csv2data_handles ();

		print OUT oe_data_build ("xIniPBAN");

		warn "INFO : Preparation of the index $cfg->{'EDTK_DIR_OUTMNGR'} $SsLot for compo\n";
		oe_open_fi_IN ($cfg->{'EDTK_DIR_OUTMNGR'} . "/" . $SsLot . ".idx");
		oe_csv2data_handles;
		print OUT oe_data_build ("xFinFlux");
		oe_close_fo($SsLot_output_txt);

		warn "INFO : Composition $SsLot in $cfg->{'EDTK_DIR_OUTMNGR'}\n";
		warn "INFO : Acquiring shared lock on $lockfile...\n";
		flock($lock, LOCK_SH) or die "ERROR: Cannot acquire lock: $!\n";
		warn "INFO : Successfully acquired lock.\n";
		eval {
			if (defined $cfg->{'EDTK_TESTDATE'}) { oe_set_sys_date($cfg->{'EDTK_TESTDATE'}) };
			c7_compo ("PDF", $lib_filieres, $SsLot_output_txt, "OMGR", @tDclib);
			c7_emit  ("PDF", $lib_filieres, $SsLot_output_txt, $SsLot_output_opf, "OMGR", @tDclib);
		};
		flock($lock, LOCK_UN);
		die "ERROR: can't unlock $lock : $@" if $@;	# Now that we unlocked, re-throw the error if any.

		close(IN);	# XXX OMG THIS IS A HACK!$#@#@
		warn "INFO : Packaging $cfg->{'EDTK_DIR_OUTMNGR'} $SsLot\n";
		my $zip = Archive::Zip->new();
		$zip->addFile("$cfg->{'EDTK_DIR_OUTMNGR'}/$SsLot.idx", "$SsLot.idx");
		$zip->addFile("$cfg->{'EDTK_DIR_OUTMNGR'}/$SsLot.pdf", "$SsLot.pdf");
		die "ERROR: Could not create zip archive\n"
		    unless $zip->writeToFileNamed("$cfg->{'EDTK_DIR_OUTMNGR'}/$SsLot.zip") == AZ_OK;

		if ($xTypTrt !~/D/) {
			unlink("$cfg->{'EDTK_DIR_OUTMNGR'}/$SsLot.job");
			unlink("$cfg->{'EDTK_DIR_OUTMNGR'}/$SsLot.idx");
			unlink("$cfg->{'EDTK_DIR_OUTMNGR'}/$SsLot.txt");
			unlink("$cfg->{'EDTK_DIR_OUTMNGR'}/$SsLot.pdf");
		}

		@tProcessed_Dclib = uniq(@tProcessed_Dclib, @tDclib);
	}

	if ($xTypTrt !~/D/) {
		while (my $docLib = shift (@tProcessed_Dclib)){
			# warn "INFO : Delete ".$cfg->{'EDTK_DIR_DOCLIB'}."/$docLib";
			unlink($cfg->{'EDTK_DIR_DOCLIB'}."/$docLib");
		}
	}
	close($lock);	# This releases locks.
	warn "INFO : End of oe_outmngr_output_run\n";

	my @zips = map { $cfg->{'EDTK_DIR_OUTMNGR'}."/$$_[0].zip\n" } @lots;
	print @zips;

return 1;
}


sub oe_compo_link (;@){		# migrate oe_close_files oe_compo_link
	# IF THE INPUT STREAM HAS LESS THAN 1 LINE (variable $.), EXIT WITH ERROR
	# if ($. == 0) {
	#	# INVALID STREAM, STOP
	#	die 	"ERROR: uncomplete datastream\n $message \n\n";
	#}

	my @opt=@_;

	if ($TAG_MODE eq 'TEX') {
		my $cfg = config_read('COMPO');
		my $params = $_RUN_PARAMS;
		$params->{'corp'} = oe_corporation_set();
		if (@opt) {
			foreach (@opt){
				$_=~s/\-+//g;
				$params->{$_} = 1;
			}
		}

		print OUT oe_data_build('xFinFlux');
		close(OUT) or die "ERROR: closing output $!\n";
		if ($params->{'noinputfiles'}) {
		} else {
			close(IN)  or die "ERROR: closing input $!\n" ;
		}

		if ($params->{'fifo'}) {
			# Disable signal handler.
			$SIG{'CHLD'} = 'DEFAULT';
			if (!defined($params->{'cldstatus'})) {
				# Wait for the LaTeX process to terminate.
				my $pid = $params->{'pid'};
				warn "INFO : Waiting for the LaTeX process to terminate ($pid)...\n";
				my $kid = waitpid($pid, 0);
				if ($kid <= 0) {
					die "ERROR: Could not collect child process status: $!\n";
				}
				$params->{'cldstatus'} = $?;
			}
			my $status = $params->{'cldstatus'};
			if ($status != 0) {
				my $msg = oe_status_to_msg($status);
				die "ERROR: LaTeX process failed: $msg\n";
			}
			warn "INFO : The LaTeX process terminated successfully.\n";
		} else {
			# Run the LaTeX process.
			oe_compo_run($cfg->{'EDTK_PRGNAME'}, $params);
		}
		oe_after_compo($cfg->{'EDTK_PRGNAME'}, $params);
	}

return 1;
}


sub oe_env_var_completion (\$){
	# expand paths by replacing environment variables with their real values
	# all nesting levels defined in the environment variables are expanded
	# requires the environment variables to be defined beforehand
	my $rValue =shift;
	if ($^O eq "MSWin32"){
		# environment variables may themselves contain variables
		while (${$rValue}=~/\$/g) {
			${$rValue}=~s/\$(\w+)/${ENV{$1}}/g;
		}
		${$rValue}=~s/(\/)/\\/g;

	} else {
		# CHECK COMPATIBILITY UNDER *NIX
		while (${$rValue}=~/\$/g) {
			${$rValue}=~s/\$(\w+)/${ENV{$1}}/g;
		}
	}
return ${$rValue};
}


sub oe_ID_LDOC(;$) {
	# USES THE LIBRARY: Date::Calc
	# document batch id
	# format YWWWDHHMMSSPPPP.r (compuset is limited to 16 digits: 15 integers, 1 decimal) 999999999999999.9
	my $force_ID = shift;

	if ($_ID_LDOC eq '') {		# generate it only once per run: several calls in the same instance return the same id

		if (!defined $force_ID){
			my $time =time;
			my ($year,$month,$day, $hour,$min,$sec, $doy,$dow,$dst)=
				Gmtime($time);
			my ($week,) = Week_of_Year($year,$month,$day);

			my $pid = "$$";
			my $rnd = int(rand(10));
			if (length $pid > 5) {
				$pid = $pid/(10**((length $pid)-5));
			}

			$_ID_LDOC =sprintf ("%1d%02d%1d%02d%02d%02d%05d%1d", $year % 10, $week, $dow, $hour, $min, $sec, $pid, $rnd );

		} else {
			if (length $force_ID > 25) {
				die "ERROR: forced ID_LDOC too long (>25 car) : $force_ID \n";
			}
			$_ID_LDOC = $force_ID;
		}

	}

return $_ID_LDOC;
}


{
 my $_app_typ_trt;	# batching processing type,
 			# value accessible only through the _app_typ_trt method

	sub _app_typ_trt (;$){
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

		my $xTypTrt	= shift || '';
		if (defined $_app_typ_trt && $xTypTrt!~/^[TD]/i) {return $_app_typ_trt ;}
		# only the Test and Debug types allow changing $_app_typ_trt if it is already set

		if ($xTypTrt !~ /^([MGLHTDU])/i){
			$_app_typ_trt='U';

		} elsif ($xTypTrt =~ /^([MGL])/i) {
			$_app_typ_trt=$1;

		} elsif ($xTypTrt =~ /^([HTD])/i) {
			$_app_typ_trt=$1;
		}

	warn "INFO : OM processing type = $_app_typ_trt (Mass/Grouped/Local/Homol/Test/Debug/Undef)\n";
	return $_app_typ_trt;
	}
}

{
 my $_DOCLIB;	# DCLIB DESIGNATION for batching
 			# value accessible only through the _omngr_doclib method

	sub _omngr_doclib (;$$){
		if (defined $_DOCLIB) { return $_DOCLIB ; }

		my $doclib	=shift;
		if (!defined $doclib){
			my $cfg = config_read('ENVDESC');
			my $ext		=shift || $cfg->{'EDTK_EXT_DEFAULT'};
			$_DOCLIB = "DCLIB_" . oe_ID_LDOC() . "." . $ext;
			#$_DOCLIB =~ s/\./_/;
		} else {
			$_DOCLIB=$doclib;
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
	return (sprintf ("x%.7s", oe_corporation_set()) );
}


my $_xCORPOR;
my $_DICT;

sub oe_corporation_get() {
	return $_xCORPOR;
}

	sub oe_corporation_set(;$){
		# DICTIONARY USE:
		#	- if the parameter is known in the dictionary => dictionary value
		#	- if the parameter is unknown => default value (edtk.ini / EDTK_CORP)
		#	- if no parameter => last known value
		my $parametre = shift;

		if (!defined($_DICT)) {
			my $cfg =config_read();
			$_xCORPOR = $cfg->{'EDTK_CORP'};	# Default value
			$_DICT = oEdtk::Dict->new($cfg->{'EDTK_DICO'}, { invert => 1 });
		}

		my $entity;
		if (defined($parametre)) {
			$entity = $parametre;
		} else {
			$entity = $_xCORPOR;
		}

		$entity = $_DICT->translate($entity, 1);

		if (defined ($entity)) {
			# if the value was found in the dictionary
			$_xCORPOR = $entity;
		}

		# warn "\$entity $entity \$_xCORPOR $_xCORPOR\n";
		return $_xCORPOR;
	}



{			# in progress, not operational yet (recovery from the generator)
 my $cpt_sub_call =0; 	# constant variable local to the function
 my %hListeId;

	sub oe_unique_data_name ($$;$) {
		# define a unique identifier over n characters
		# the first 6 characters of the passed key are extracted
		# if the id is already known, take the first 4 and add a 3-digit counter (matches the call sequence)
		# if it is still not unique, take the first 3 characters and complete the 3-digit counter with a character
		# receives: 	- the total number of characters to return
		#		- an identifier
		#		- optional: a reference to a counter value (3 numeric)

		my ($nb_car, $id, $cpt_value) =@_;
		if ($nb_car lt 6) { $nb_car = 6 ; }

		if ($cpt_value) {$cpt_sub_call=$cpt_value} else {$cpt_sub_call++};

		my $debut = $nb_car-2;
		my $motif ="%-" . $debut . "." . $debut . "s%0.2d"; # "%-4.4s%0.2d"
		warn "$motif / $id\n";
		$id	=sprintf ("$motif", $id);
		$id	=~s/\s/x/g;

		if (exists ($hListeId{$id})){
			$debut	= $nb_car-3;
			$motif	="%-" . $debut . "." . $debut . "s%0.3d"; # "%-3.3s%0.3d"
			$id	=sprintf ($motif ,$id, $cpt_sub_call);

			my $cpt	=97;    # for the character "a"
			while (exists ($hListeId{$id})) {
				$debut	= $nb_car-4;
				$motif	="%-" . $debut . "." . $debut . "s%0.3d"; # "%-3.3s%0.3d"
				$id	=sprintf ($motif, $id, $cpt_sub_call, chr($cpt++));
				die "ERROR: cannot create a unique key" if ($cpt >= 123);

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
		$hListeId{$id}=1;
	return $id;
	}
}

{
my $_backup_date ;

	sub oe_set_sys_date($) {
		my $requested_date = shift;

		my $time = time;
		my ($year,$month,$day, $hour,$min,$sec, $doy,$dow,$dst) =
			Gmtime($time);

		my $commande = sprintf ("date %s", $requested_date);
		warn "INFO : $commande\n";

		eval {
			system($commande);
		};

#		if ($?){
		if ($@){
			warn "ERROR: command failed $commande : $@\n";
			return -1;
		}

		if (!defined $_backup_date) {
			$_backup_date = sprintf ("%02s-%02s-%02s", $day, $month, $year);
		}
	return $_backup_date;
	}

	sub _restore_sys_date {
		oe_set_sys_date($_backup_date) if (defined $_backup_date);
	1;
	}
}


END {
	_restore_sys_date;
	# duplicate with oEdtk.pm  :
	#warn "(c) 2005-2020 grechary\@cpan.org - edtk\@free.fr - oEdtk v$VERSION\n";
}

1;

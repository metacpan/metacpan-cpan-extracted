#!/usr/bin/perl

use strict;
use warnings;
use oEdtk;
use oEdtk::Config		qw(config_read get_ini_path);
use oEdtk::DBAdmin		qw(db_connect);
use oEdtk::Messenger	qw(oe_send_mail);


if (@ARGV > 0 or ($ARGV[0] and $ARGV[0] =~/-h/i)) {
	die "Usage: $0 \n\n\tthis will check configuration key in oEdtk.ini setup\n";
}


my $opt = $ARGV[0] || "";
my (@tCheck_access, @tCheck_write, @tCheckMessage);


if ($opt=~/comset/i) {
	# deprecated
	$opt = "COMSET";
	#[COMSET]
	push (@tCheck_access, 'EDTK_DIR_COMSET');
	push (@tCheck_access, 'C7_DCLIB_1');
	push (@tCheck_access, 'C7_DCLIB_2');
	push (@tCheck_write,  'C7_DCLIB_RW');
	push (@tCheck_access, 'C7_MAIN_LIB');
	push (@tCheck_access, 'C7_CHAINS_LIB');
	push (@tCheck_access, 'C7_NULL_CNF');
	push (@tCheck_access, 'C7_PDE_PDF');
	push (@tCheck_access, 'C7_PDE_OMGRPDF');
	push (@tCheck_access, 'C7_CNF_PDF');
	push (@tCheck_access, 'C7_WID_PDF');
}

my $cfg = config_read('MAIL', 'EDTK_DB', 'EDTK_STATS', 'COMPO', $opt);
warn "STARTING CHECK, loading config from " . get_ini_path() ."\n";
warn "\n";

#[DEFAULT]
push (@tCheck_access, 'EDTK_DICO');
#[MAIL]
push (@tCheck_access, 'EDTK_MAIL_REFER');
push (@tCheck_access, 'EDTK_MAIL_OMGR');
#[ENVDESC]
push (@tCheck_write, 'EDTK_DIR_APPTMP');
push (@tCheck_write, 'EDTK_DIR_BASE');
#push (@tCheck_write, 'EDTK_DIR_DATA_IN');
push (@tCheck_write, 'EDTK_DIR_APP');
push (@tCheck_write, 'EDTK_DIR_CONFIG');
#push (@tCheck_write, 'EDTK_DIR_DOCSCRIPT');
push (@tCheck_write, 'EDTK_DIR_LIB');
push (@tCheck_write, 'EDTK_DIR_LOG');
push (@tCheck_write, 'EDTK_DIR_SCRIPT');
push (@tCheck_write, 'EDTK_DIR_EDOCMNGR');
push (@tCheck_write, 'EDTK_DIR_DOCLIB');
push (@tCheck_write, 'EDTK_DIR_OUTMNGR');
push (@tCheck_access, 'EDTK_DIR_TMPLATE');
#push (@tCheck, 'EDTK_FDATAIN=$EDTK_DIR_DATA_IN/$EDTK_PRGNAME
#push (@tCheck, 'EDTK_FDATAOUT=$EDTK_DIR_DATA_IN/$EDTK_PRGNAME
#push (@tCheck, 'EDTK_FDATWORK=$EDTK_DIR_APPTMP/$EDTK_PRGNAME
#push (@tCheck_write, 'EDTK_VCS_LOCATION');
push (@tCheck_access, 'EDTK_BIN_PERL');
#[COMPO]
push (@tCheck_access, 'EDTK_BIN_COMPO');
push (@tCheck_access, 'EDTK_COMPO_LIB');

push (@tCheckMessage, "\nSTART CHECK FROM oEdtk.ini :\n ");
foreach my $element (@tCheck_write){
	my $f_element = sprintf (" %18s ", $element);
	if ($cfg->{$element} eq "") {
		push (@tCheckMessage, "$f_element BAD, NOT DEFINED ($cfg->{$element})\n ");
	} elsif (-w $cfg->{$element}) {
		push (@tCheckMessage, "$f_element good ($cfg->{$element})\n ");
	} else {
		push (@tCheckMessage, "$f_element BAD, NOT WRITABLE ($cfg->{$element})\n ");
	}
}
push (@tCheckMessage, "\n ");

foreach my $element (@tCheck_access){
	my $f_element = sprintf (" %18s ", $element);

	if ($cfg->{$element} eq "") {
		push (@tCheckMessage, "$f_element BAD, NOT DEFINED ($cfg->{$element})\n ");
	} elsif (-e $cfg->{$element}) {
		push (@tCheckMessage, "$f_element good ($cfg->{$element})\n ");
	} else {
		push (@tCheckMessage, "$f_element BAD, DOESN'T EXIST ($cfg->{$element})\n ");
	}
}
push (@tCheckMessage, "\n ");

warn @tCheckMessage;

foreach my $key (keys %{$cfg}) {
	push (@tCheckMessage, " INFO : check key $key = ".$cfg->{$key}."\n ");
}
@tCheckMessage = sort (@tCheckMessage);

# CHECK SENDMAIL
warn "\n\nSTART SENDMAIL CHECK...\n";
my $mail_to=$cfg->{'EDTK_MAIL_TST'};
eval { oe_send_mail( $mail_to, $0, @tCheckMessage); };
if ($@) {
	warn "BAD : sendmail check KO\n";
} else {
	warn "good: sendmail check OK\n\n";
}

# CHECK DB CONNECT
warn "\nSTART CHECK db_connect FROM oEdtk.ini...\n";
warn "\t check DB_BAKUP : \n";
my $dbh1 = db_connect($cfg, 'EDTK_DBI_DSN_BAK') 	or printf " BAD, error connecting EDTK_DBI_DSN_BAK\n";
warn "\n\t check DB_PARAM : \n";
my $dbh2 = db_connect($cfg, 'EDTK_DBI_PARAM') 	or printf " BAD, error connecting EDTK_DBI_PARAM\n";
warn "\n\t check DB_STATS : \n";
my $dbh3 = db_connect($cfg, 'EDTK_DBI_STATS') 	or printf " BAD, error connecting EDTK_DBI_STAT\n";
warn "\n\t check DB_MAIN : \n";
my $dbh4 = db_connect($cfg, 'EDTK_DBI_DSN')		or printf " BAD, error connecting EDTK_DBI_DSN\n";

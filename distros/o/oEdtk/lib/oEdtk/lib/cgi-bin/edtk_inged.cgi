#!/opt/editique/perl/bin/perl
# this line should be modified to point to your perl install

# THIS CGI IS AN INTERFACE TO PUSH DOCUMENT TO edms
use strict;
use warnings;

use CGI;
use File::Basename;
use File::Copy;
use File::Temp		qw(tempdir);
use oEdtk::Config	qw(config_read);
use oEdtk::EDMS	qw(EDMS_edidx_build EDMS_edidx_write EDMS_idx_create_csv EDMS_import EDMS_idldoc_seqpg);
use oEdtk::Main;


my $req 		= CGI->new();
my $error 	= $req->cgi_error;
my $_STATUS	= 400;
my $cfg 		= config_read('EDOCMNGR');


my $check_cgi = uc(basename($0));
if (!defined ($cfg->{$check_cgi}) || ($cfg->{$check_cgi}) !~/yes/i ) { die "ERROR: config said 'application not authorized on this server'\n" }


my $workdir 	= tempdir('edtkXXXXXXX', DIR => $cfg->{'EDTK_DIR_APPTMP'});
my $fh  		= $req->upload('ED_FILENAME');
my %key_param;

$key_param{'ED_FILENAME'}=$req->param('ED_FILENAME') || "";
$key_param{'ED_REFIDDOC'}=$req->param('ED_REFIDDOC') || "";
$key_param{'ED_CORP'}	=$req->param('ED_CORP') || "";
$key_param{'ED_SOURCE'}	=$req->param('ED_SOURCE') || "";
$key_param{'ED_IDDEST'}	=$req->param('ED_IDDEST') || "";
$key_param{'ED_NOMDEST'}	=$req->param('ED_NOMDEST') || "";
$key_param{'ED_IDEMET'}	=$req->param('ED_IDEMET') || "";
$key_param{'ED_OWNER'}	=$req->param('ED_OWNER') || "";
$key_param{'ED_DTEDTION'}=$req->param('ED_DTEDTION') || "";
$key_param{'ED_CORP'}	= oe_corporation_set($key_param{'ED_CORP'}) or die "ERROR: ED_CORP required.\n";
my %headers = (
	-cache_control	=> 'no-cache, no-store',
	-pragma		=> 'no-cache'
);
print $req->header(%headers, -type => 'text/plain');

if (defined $req->param('ED_FILENAME') && $req->param('ED_FILENAME') ne "") {
	eval {
		# Ensure that the directory is readable 
		chmod(0777, $workdir);

		# go to wordir
		chdir($workdir);
	}

} else {
	print $req->header(-status=>$error),
		$req->start_html('400 malformed'),
		$req->h2('400 malformed request : no search key or no user in your doc request'),
		#$req->h2(%key_param);
		#$req->strong($cfg);
	die "400 no search key in your doc request\n";
}

# THIS SCRIPT IS MADE TO TEST edms DIRECT IMPORT
# 1- receive document ready file (pdf, xls, doc...)
# 2- check index keys
# 3- generate EDMS_idldoc_seqpg
# 4- build index
# 5- send doc + index to GED
# 6- return EDMS_idldoc_seqpg


eval {
	EDMS_edidx_build(%key_param);
	EDMS_edidx_write(%key_param);

	copy($fh, $key_param{'EDMS_FILENAME'});
};	

if ($@) {
 	print $req->header(-status=>$_STATUS),
		$req->start_html("$_STATUS Error"),
		$req->h1("$_STATUS Request failed"),
		$req->h2('Preparation request failed, please contact admin'),
		$req->h3($@),
		$req->h4($error);
	die "ERROR: $_STATUS Preparation request failed, please contact admin. Reason is $@";
}

my $index = $key_param{'ED_REFIDDOC'} . "_" . $key_param{'ED_IDLDOC'} . ".idx";
#eval {
	EDMS_import($index, $key_param{'EDMS_FILENAME'} )
	 	or die "ERROR: EDMS_import failed\n";
#}; 


# if ($@) {
# 	print $req->header(-status=>$_STATUS),
# 		$req->start_html("$_STATUS Error"),
# 		$req->h1("$_STATUS Request failed"),
# 		$req->h2('Import request failed, please contact admin'),
# 		$req->h3($@),
# 		$req->h4($error);
# 	die "ERROR: $_STATUS Import request failed, please contact admin. Reason is $@";
# }

# Ensure that the directory is readable once we are finished with it.
#chmod(0777, $workdir);


print EDMS_idldoc_seqpg($key_param{'ED_IDLDOC'}, 1);
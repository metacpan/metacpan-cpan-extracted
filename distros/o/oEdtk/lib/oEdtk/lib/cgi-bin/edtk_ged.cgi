#!/opt/editique/perl/bin/perl
# this line should be modified to point to your perl install

# THIS CGI IS A LINK TO SEEK DOCUMENT IN DOCUBASE RHEAWEB
use strict;
use warnings;

use CGI 'standard';
use File::Basename;
use oEdtk::Config	qw(config_read);
use oEdtk::Main;


my $req 	= CGI->new();
my $error = $req->cgi_error;	# http://fr.wikipedia.org/wiki/Liste_des_codes_HTTP
my $cfg 	= config_read('EDOCMNGR');


my $check_cgi = uc(basename($0));
if (!defined ($cfg->{$check_cgi}) || ($cfg->{$check_cgi}) !~/yes/i ) { die "ERROR: config said 'application not authorized on this server'\n" }


my $redirect_url;


if (defined $req->param('idldocpg') && $req->param('idldocpg') ne "" && defined $req->param('owner') && $req->param('owner') ne "") {
	$redirect_url = sprintf ($cfg->{'EDMS_URL_LOOKUP'}, 
					$req->param('idldocpg'), 
					$req->param('view')	|| '1', 
					$req->param('owner'), 
					$req->param('owner'));
	warn "INFO : eDocs Share lookup url for ". $cfg->{'EDMS_HTML_HOST'} ." owner => ". $req->param('owner') ." server => $redirect_url\n";

} else {
	print $req->header(-status=>400),
		$req->start_html('400 Malformed Request'),
		$req->h1('400 Malformed Request'),
		$req->h2('missing search key or user in your request');
	die "400 malformed request : missing search key or user in your request\n";
}

eval {
	print $req->redirect($redirect_url);
};

if ($@) {
	print $req->header(-status=>400),
		$req->start_html('400 Error'),
		$req->h1('Request failed'),
		$req->h2('Request failed, please contact admin'),
		$req->h3($@);
	die "ERROR: Request failed, please contact admin, reason is $@";
}

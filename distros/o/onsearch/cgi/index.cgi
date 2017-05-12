#!/usr/bin/perl -w

#$Id: index.cgi,v 1.3 2005/07/26 21:46:15 kiesling Exp $

BEGIN { use Config; unshift @INC, ("./lib", "./lib/$Config{archname}"); }

use OnSearch;
use OnSearch::UI;
use OnSearch::Utils;
use OnSearch::AppConfig;
use OnSearch::CGIQuery;
use OnSearch::WebClient;
use Socket;
use Carp;

my $q = new OnSearch::CGIQuery;
$q -> parsequery ();

my $c = OnSearch::AppConfig -> new;

my $server = $ENV{SERVER_NAME};
my $port = $ENV{SERVER_PORT};
my $referer_url = "http://$server:$port/onsearch/admin/admin.shtml";

my $app_dir = $c -> str ('BinDir');

if ($q -> param_value ('idxinterval')) {
    if ($q -> param_value ('idxinterval') ne 
	OnSearch::AppConfig -> str ('IndexInterval')) {
	OnSearch::AppConfig::write_pref ('IndexInterval', 
	 $q -> param_value ('idxinterval'), undef);
      }
}

###
### TO DO Add the ability to rewrite parameters in onsearch.cfg.
### See the comments in AppConfig.pm.
###

###if ($q -> param_value ('digitsonly')) {
###    OnSearch::AppConfig::write_pref ('DigitsOnly', '1', undef);
###} else {
###    OnSearch::AppConfig::write_pref ('DigitsOnly', '0', undef);
###}


###if ($q -> param_value ('backupindexes')) {
###    OnSearch::AppConfig::write_pref ('BackupIndexes', '1', undef);
###} else {
###    OnSearch::AppConfig::write_pref ('BackupIndexes', '0', undef);
###}


if ($q -> param_value ('index_now')) {
    sigwrapper (qw/CHLD/, undef, \&run_onindex);
} 

# OnSearch::WebClient::get_req ($referer_url);
my $ui = OnSearch::UI -> new;
$ui -> header_back -> wprint;


exit 0;


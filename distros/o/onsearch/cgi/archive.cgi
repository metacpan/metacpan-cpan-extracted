#!/usr/bin/perl -w

#$Id: archive.cgi,v 1.5 2005/08/11 06:31:13 kiesling Exp $

BEGIN { use Config; unshift @INC, ("./lib", "./lib/$Config{archname}"); }

use OnSearch;

use OnSearch::AppConfig;
use OnSearch::Base64;
use OnSearch::CGIQuery;
use OnSearch::UI;
use OnSearch::Utils;
use OnSearch::WebLog;
use OnSearch::WebClient;

my $cfg = OnSearch::AppConfig -> new;
my $prefs_val = undef;

my $q = OnSearch::CGIQuery -> new;
$q -> parsequery;

my $ui = OnSearch::UI -> new;

if ($ENV{HTTP_REFERER} =~ /archive\.(shtml|cgi)/) {
    my $req_method = $ENV{REQUEST_METHOD};
    ###
    ### POST means that a file is being uploaded.
    ###
    if ($req_method =~ /POST/) { 
	my ($q, $boundary, $content, @content, $content_length, $cs);
	my ($fname, $content_type, $file, @plugins, $tmpfname, $oldrs);
	($boundary) = ($ENV{CONTENT_TYPE} =~ /boundary=(.*)/i);
	$content_length = $ENV{CONTENT_LENGTH};
	binmode STDIN, ':crlf';
	read STDIN, $content, $content_length;
	@content = split m"--$boundary", $content;
	foreach my $cs (@content) {
	    if ($cs =~ /filename=/is) {
		($fname) = ($cs =~ /filename=\"(.*)\"/);
		($content_type) = ($cs =~ /Content-Type:\s+(\S+)/);
		($file) = ($cs =~ /\015\012\015\012(.*)\015\012/s);
	    }
	}
	$fname = basename ($fname);
	@plugins = $cfg -> lst (qw/PlugIn/);
	if (! scalar grep /$content_type/, @plugins) {
	    $ui -> error_dialog ("Warning\\nOnSearch does not have a plugin " .
				 "for this type of document." ) -> wprint;
	}
	$tmpfname = $fname;
	for (my $ext = 1; -f "uploads/$tmpfname"; $ext++) {
	    $tmpfname = "$fname.$ext";
	}
	
	$oldrs = $/; undef $/;
	open FILE, ">uploads/$tmpfname" or die "$tmpfname: $!\n";
	print FILE $file;
	close FILE;
	$/ = $oldrs if $oldrs;
    } elsif ($req_method =~ /GET/ && $q -> {targeturl}) {
	###
	### Here it means we're indexing a Web page or a Web site.
	###
	my ($yeardate, $proto_name, $server, $port, $path);
	my ($app_uri, $l, @lines, $dirtree, $serverdirname);
	my ($robotspage, $robotsfile, $page, $client_pid);
	$prefs_val = $cfg -> webidx_prefs_val ($q);
	($proto_name, $server, $port, $path) = parse_url ($q->{targeturl});
	unless ($server) {
	    browser_warn ("Could not index URL: " . $q -> {targeturl} .'.');
	    exit 1;
	}
	$webbot = OnSearch::WebBot -> new;
	$serverdirname = (($port == 80) ? "/$server" : "/$server:$port");
	if ($robotspage) {
	    $robotsfile = OnSearch::RobotsDotTxt -> new;
	    $robotsfile -> parse ($robotspage);
	    clf ('notice', 
		 "Web site %s: %s found.", $q -> param_value(qw/targeturl/), 
		 'robots.txt');
	}
	exit 1 if ($robotsfile && 
		   $robotsfile -> is_disallowed ('OnSearch', 
				 $q->param_value (qw/targeturl/)));
	if ($q -> param_value ('targetscope') =~ /site/) {
	    ###
	    ### If returning from the child process, exit immediately.
	    ###
	    if (($client_pid = 
		$webbot -> siteindex ($q -> param_value (qw/targeturl/)))
		== 0) {
		exit $client_pid;
	    }
	} else {
	    ($dirtree) = ($path =~ /(.*)\//);
	    $dirtree = ($dirtree) ? 
		$webbot -> {cachedir} . "$serverdirname$dirtree" : 
		$webbot -> {cachedir} . $serverdirname;
	    $webbot -> mkdirtree ($dirtree, 0755);
	    $page = get_req ($q->{targeturl});
	    if (! $page || $page =~ m|HTTP/1.[01]\s+[45](\d+)|) {
		$page = 'Error requesting page.' unless $page;
		browser_warn ($q->{targeturl} . ": $page");
		exit 1;
	    }
	    $webbot -> cache_page ($page, $q -> param_value (qw/targeturl/));
	}
    }
}

my (@cookies, $key, $val, $prefs);
$prefs = 'defaults';
if (($ENV{HTTP_COOKIE}) && (! $prefs_val)) {
    @cookies = split /\;\s?/, $ENV{HTTP_COOKIE};
    ($val) = grep (/webidx/, @cookies);
    if ($val) {
	($val) = $val =~ /.*?\=(.*)/;
	$prefs = $cfg -> get_prefs ($val);
    }
} elsif ($prefs_val) {
    $prefs = $cfg -> get_prefs ($prefs_val);
}

if (defined ($prefs_val)) {
# Expire cookie in a year.
    my $yeardate = OnSearch::Utils::http_date (31536000);
    $ui -> header_cookie ('OnSearch', 'webidx', $prefs_val,
			  $yeardate) -> wprint;
} else {
    $ui -> header_css ('OnSearch') -> wprint;
}
$ui -> navbar_map -> wprint;
$ui -> javascripts -> wprint;
$ui -> navbar -> wprint;
$ui -> archive_title -> wprint;
$ui -> webindex_form ($prefs) -> wprint;
$ui -> fileindex_form -> wprint;
$ui -> html_footer -> wprint;

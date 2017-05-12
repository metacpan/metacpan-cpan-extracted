#!/usr/bin/perl -w

#$Id: search.cgi,v 1.17 2005/08/16 05:33:49 kiesling Exp $

BEGIN { use Config; unshift @INC, ('./lib', "./lib/$Config{archname}"); }

use OnSearch;

use OnSearch::UI;
use OnSearch::Utils;
use OnSearch::CGIQuery qw/:all/;
use OnSearch::Search;
use OnSearch::AppConfig;
use OnSearch::VFile;
use OnSearch::WebLog;
use OnSearch::Results;
use OnSearch::Regex;
use OnSearch::WebClient;
use OnSearch::URL;
use OnSearch::Base64;

my $logfunc = \&OnSearch::WebLog::clf;

# Parameters - 
# searchterm
# x, y  - coords in the submit button
# matchcase
# matchtype
# pagesize

# FOR TESTING - print the server environment
#my $s;
#foreach (keys %ENV) {$s = $_ . " ". $ENV{$_} . '<BR>'; print $s;}

my $sid = 0;

sub term {
    clf ('warning', "OnSearch: SIGTERM PID $$ child PID $sid");
    # Signal the child process.
    kill ('TERM', $sid);
    unlink ("/tmp/.onsearch.sock.$$") while (-S "/tmp/.onsearch.sock.$$");
#    kill ('KILL', $$);
#    $SIG{TERM} = \&term;
    exit;
}

$SIG{TERM} = \&term;
local $SIG{USR2} = 'IGNORE';

$ENV{PATH} = '/bin:/usr/bin';

my $q = new OnSearch::CGIQuery;
$q -> parsequery ();
$q -> {ppid} = $$;

my $http_referer = $ENV{HTTP_REFERER};
my $document_root = $ENV{DOCUMENT_ROOT};

clean_sids ();
clean_results ();

my $ui = OnSearch::UI -> new;
$ui -> {q} = $q;
$ui -> {searchterm} = $q -> {searchterm};
$ui -> {pagesize} = $q -> {pagesize};
$ui -> {nresults} = $q -> {nresults};
$ui -> {server} = $ENV{SERVER_NAME};
$ui -> {port} = $ENV{SERVER_PORT};
$ui -> {outputfh} = \*STDOUT;

my $cfg = OnSearch::AppConfig -> new;

if (((not $q -> param_value ('searchterm')) or 
     not length ($q -> param_value ('searchterm')))) {
    $ui -> error_dialog ('The Search Term field is empty.') -> wprint;
    exit 1;
}

###
### Parse the search term and determine what kind of match
### the user requested.
###
my @searchwords = split /\W+/, $q -> param_value ('searchterm');
s/\W//g foreach (@searchwords);

###
### If there is only one word, then simply make the match type, "any."
###
if ($#searchwords == 0) { $q -> {matchtype} = 'any'; }

$q -> {displayregex} = display_expr ($q -> param_value ('searchterm'),
				     $q -> param_value ('matchtype'),
				     $q -> param_value ('matchcase'),
				     $q -> param_value ('partword'));
$q -> {regex} = search_expr ($q -> param_value ('searchterm'),
			     $q -> param_value ('matchtype'),
			     $q -> param_value ('matchcase'),
			     $q -> param_value ('partword'));

if ($q -> {matchtype} =~ /all|exact/) {
    $q -> {collateregex} = collate_expr ($q -> param_value ('searchterm'),
					 $q -> param_value ('matchtype'),
					 $q -> param_value ('matchcase'),
					 $q -> param_value ('partword'));
}


###
### Put all the parameters possible into the query object
### before starting the search.  
###

$q -> {context} = $cfg->str (qw/SearchContext/);

if ($q -> param_value ('matchcase') =~ /yes/) {
    $q -> {nmatchcase} = 1;
} else {
    $q -> {nmatchcase} = 0;
}

push @{$q->{searchtermlist}}, @searchwords;

my $OPENTAG = qr'^<file path="(.*?)">';

$server = \&s_write;

###
### Search function templates.
### Prototype:
### &{$q->{sfptr}} (actual_query_object, posting_reference);
### 
if ($q -> param_value ('matchtype') =~ /any/) {
    $q -> {sfptr} = sub { 
	my $q1 = shift;
	my $postbufref = shift;
	&$server ($q1 -> {ppid}, $$postbufref);
	return 1;
    };
} elsif ($q -> param_value ('matchtype') =~ /all/) {
    $q -> {sfptr} = sub { 
	my $q1 = shift;
	my $postbufref = shift;
	my $r;
	if ($r = collate ($q1, $$postbufref)) {
	    &$server ($q1 -> {ppid}, $$postbufref);
	}
	return $r;
    };
} elsif ($q -> param_value ('matchtype') =~ /exact/) {
    $q -> {sfptr} = sub {
	my $q1 = shift;
	my $postbufref = shift;
	my ($r, $r1);
	if ($r = collate ($q1, $$postbufref)) {
	    if ($r1 = text_string_search ($q1, $postbufref)) {
		&$server ($q1 -> {ppid}, $$postbufref);
	    }
	}
	return $r1;
    };
}

if ($cfg -> lst ('ExcludeDir')) {
    my @excdirs = $cfg -> lst ('ExcludeDir');
    push @{$q->{excludedirs}}, @excdirs; 
}

my @tlds;

my %volumes = $cfg -> Volumes ();
my $vol_prefs = 'Default';
if ($ENV{HTTP_COOKIE}) {
    @cookies = split /\;\s?/, $ENV{HTTP_COOKIE};
    ($val) = grep (/onsearchvols/, @cookies);
    if ($val) {
	($val) = $val =~ /.*?\=(.*)/ if $val;
	$vol_prefs = $cfg -> get_prefs ($val);
    }
    my @preflist = split /,/, $vol_prefs;
    foreach my $k (keys %volumes) {
	next unless scalar grep /$k/, @preflist;
	push @tlds, ($volumes{$k});
    }
} else {
    push @tlds, ($volumes{Default});
}

my $extcode_s;
if (($extcode_s = perform_search ($q, \@tlds)) == 0) { exit }

$ui -> {ext} = 0;
my $extcode_r;

if (($extcode_r = $ui -> OnSearch::Results::results ($$)) == 0) {
    exit;
}

sub perform_search {
    my $q = $_[0];
    my $tldref = $_[1];

    ### Must be called after read_config.
    save_sid ($q->{ppid});

    ###
    ### $extpid == 0 if search is completed.
    ###
    my $extpid = $q -> OnSearch::Search::search ($tldref);
    # Returning from the child process, so we go.
    if ($q -> {sid}) { return 0 }

    return $extpid;
}


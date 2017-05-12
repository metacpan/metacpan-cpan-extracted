#!/usr/bin/perl -w

#$Id: results.cgi,v 1.10 2005/07/24 06:56:34 kiesling Exp $

BEGIN { use Config; unshift @INC, ("./lib", "./lib/$Config{archname}"); }

use OnSearch;
use OnSearch::AppConfig;
use OnSearch::CGIQuery;
use OnSearch::Regex;
use OnSearch::Results;
use OnSearch::UI;

###
### Display each page of results.  The results_header () and
### results_footer () subroutines in UI.pm provide the links
### to results.cgi and have the CGI query parameters to restore 
### a session and display the results.
###

my $q = new OnSearch::CGIQuery;
$q -> parsequery ();

my $cfg = OnSearch::AppConfig -> new;

my ($ui, $url);

###
### The restore_session function returns a blessed UI object.
### If it can't retrieve a session, create a new UI object.
###
if (! defined ($ui = OnSearch::UI -> restore_session ($q -> {id}))) {
    $ui = OnSearch::UI->new;
    $ui -> header_css ('OnSearch') -> wprint;
    $ui -> navbar_map -> wprint ($ui -> {o});
    $ui -> javascripts -> wprint ($ui -> {o});
    $ui -> navbar -> wprint ($ui -> {o});
    $ui -> querytitle -> wprint ($ui -> {o});
    $ui -> results_header -> wprint ($ui -> {o});
    browser_warn ('Could not restore the results of session '.$q -> {id}.'.');
    $ui -> results_footer -> wprint;
    exit 1;
}

###
### Copy the search parameters from the search.cgi query, stored 
### with the results, to the results.cgi query object.
###
foreach my $k (qw/searchterm matchcase matchtype display context ppid
	       partword nresults/) {
    $q -> {$k} = $ui -> {q} -> {$k};
}

###
### Regexes aren't saved in with the stored results, so rebuild
### the display regex.
###
$q -> {displayregex} = OnSearch::Regex::display_expr (
      $q->{searchterm}, $q->{matchtype}, $q->{matchcase}, $q->{partword});

$ui -> {q} = $q;

if ($q && $q->{searchterm}) {
    $ui -> header_css ('OnSearch: Results of search "' . 
		       $q->{searchterm} . '"') -> wprint;
} else {
    $ui -> header_css ('OnSearch') -> wprint;
}

$ui -> navbar_map -> wprint ($ui -> {o});
$ui -> javascripts -> wprint ($ui -> {o});
$ui -> navbar -> wprint ($ui -> {o});
$ui -> querytitle -> wprint ($ui -> {o});
###
### Initialize the results queue indexes.
### $ui -> {page}     One less than the CGI parameter formatted by 
###                   results_header () and results_footer ().  
### $ui -> {head}     Number of results element to be displayed.
###

$ui -> {pageno} = $q -> {page};
$ui -> {head} = ($ui -> {pageno} - 1) * $ui -> {pagesize};

$ui -> results_header -> wprint ($ui -> {o});

###
### See the comments in Results.pm
###
sub client_ping {
    my $u = OnSearch::UI->new;
    $u -> {text} = ' ';
    $u -> wprint;
    undef $u;  # Quicker than garbage collection.
    alarm 30;
    $SIG{ALRM} = \&client_ping;
}

alarm 30;
$SIG{ALRM} = \&client_ping;

while (!last_record ($ui)) {

    if(OnSearch::Results::display_result ($ui)) {
	$ui -> {pagenth} += 1;
    }
    ++$ui -> {head};
    last if ((! ($ui->{pagenth} % $ui->{pagesize})) && ($ui->{pagenth} != 0))
}

alarm 0;

$ui -> results_footer -> wprint;
$ui -> html_footer -> wprint;

###
### Actually, last_record () returns true if queue head index is anywhere 
### past the end of the results queue.
###
sub last_record {
    my $ui_obj = shift;
    return ($#{$ui_obj -> {r}} <= ($ui_obj -> {head} - 1));
}

exit 0;

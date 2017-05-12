#!/usr/bin/perl -w

#$Id: main.cgi,v 1.7 2005/08/10 05:29:28 kiesling Exp $

BEGIN { use Config; unshift @INC, ("./lib", "./lib/$Config{archname}",
				   "./lib/$Config{archname}/auto"); }

use OnSearch;

use OnSearch::UI;
use OnSearch::Utils;
use OnSearch::WebLog;
use OnSearch::AppConfig;
use PerlIO::OnSearchIO;

my $ui = OnSearch::UI -> new;
my $cfg = OnSearch::AppConfig -> new;
unless ($cfg -> have_config) {
    $cfg -> read_config ('onsearch.cfg');
    $ui -> header_css -> wprint;
    $ui -> critical_error_form ("Missing \"SearchRoot\" directive<br>in onsearch.cfg") -> wprint;
    exit (1);
}

my (@cookies, $key, $val, $prefs, $vol_prefs);
$prefs = 'defaults';
$vol_prefs = 'Default';
if ($ENV{HTTP_COOKIE}) {
    @cookies = split /\;\s?/, $ENV{HTTP_COOKIE};
    ($val) = grep (/onsearchprefs/, @cookies);
    if ($val) {
	($val) = $val =~ /.*?\=(.*)/ if $val;
	$prefs = $cfg -> get_prefs ($val);
    }
    ($val) = grep (/onsearchvols/, @cookies);
    if ($val) {
	($val) = $val =~ /.*?\=(.*)/ if $val;
	$vol_prefs = $cfg -> get_prefs ($val);
    }
}

$ui -> header_css ('OnSearch') -> wprint;
$ui -> navbar_map -> wprint;
$ui -> javascripts -> wprint;
$ui -> navbar -> wprint;
$ui -> input_form ($prefs, $vol_prefs) -> wprint;
$ui -> html_footer -> wprint;



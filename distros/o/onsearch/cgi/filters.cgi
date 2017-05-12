#!/usr/bin/perl -w

#$Id: filters.cgi,v 1.3 2005/07/20 08:45:27 kiesling Exp $

BEGIN { use Config; unshift @INC, ("./lib", "./lib/$Config{archname}"); }

use OnSearch;
use OnSearch::Base64;
use OnSearch::CGIQuery qw/:all/;
use OnSearch::UI;

my $c = OnSearch::AppConfig -> new;
my @vols_selected;
my %vols = $c -> Volumes ();
my $prefs = 'Default';
my (@cookies, $key, $val);
my $ui_obj = OnSearch::UI -> new;

my $vol_query = new OnSearch::CGIQuery;
$vol_query -> parsequery ();
###
### Delete query instance variables because they won't be 
### needed here.
###
delete $vol_query->{$_}  foreach (qw /pwd regex displayregex context
				  cache ppid sid/);

if ($ENV{HTTP_REFERER} =~ /filters\.(shtml|cgi)/) {
    my %vols_prefs;
    foreach my $k (keys %$vol_query) {
	next if $k =~ /submit\.(x|y)/;
	push @vols_selected, ($k);
    }
    my $val = $c -> vols_prefs_val (\@vols_selected);

    my $yearexpdate = OnSearch::Utils::http_date (31536000);
    $ui_obj -> header_cookie ('OnSearch', 'onsearchvols', $val,
			      $yearexpdate) 
	-> wprint;
} else {
    if ($ENV{HTTP_COOKIE}) {
	@cookies = split /\;\s?/, $ENV{HTTP_COOKIE};
	($val) = grep (/onsearchvols/, @cookies);
	if ($val) {
	    ($val) = $val =~ /.*?\=(.*)/ if $val;
	    $prefs = $c -> get_prefs ($val);
	    @vols_selected = split /,/, $prefs;
	}
    }
    $ui_obj -> header_css ('OnSearch') -> wprint;
}

$ui_obj -> navbar_map -> wprint;
$ui_obj -> javascripts -> wprint;
$ui_obj -> navbar -> wprint;

$ui_obj -> volume_form (\%vols, \@vols_selected) -> wprint;

exit 0;

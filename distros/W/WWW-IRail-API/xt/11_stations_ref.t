#!/usr/bin/perl
use strict;
use warnings;
use Test::More;
use Test::Deep;
use Data::Dumper;
use JSON::XS;
use WWW::IRail::API qw/irail/;
use WWW::IRail::API::Client::LWP;
use LWP::UserAgent;
use FindBin qw/$Bin/;

my $irail_0 = new WWW::IRail::API;

## check reference data #################################################################################

my $js;

if (-f "$Bin/data/stationlist.js") {
    # wget http://www.railtime.be/website/StationDataScript.ashx -O stationlist.js
    # open, slurp & assign, close 
    { open my $fh, '<', "$Bin/data/stationlist.js"; local $/ = undef; $js = <$fh>; close $fh; }
} else {
    my $ua = new LWP::UserAgent;
    my $re = $ua->get("http://www.railtime.be/website/StationDataScript.ashx");
    die "could not get http://www.railtime.be/website/StationDataScript.ashx, status line: ".$re->status_line unless $re->is_success;

    $js = $re->decoded_content();
}

$js =~ s/[\r\n]//g;                                 # remove newlines
$js =~ s/^var dataItems = //;                       # remove assignment
$js =~ s/;$//;                                      # remove end of statement
$js =~ s/"//g;                                      # remove all double quotes
$js =~ s/([a-z'][\w\d\s\-'_\(\)\.\/]*)/"$1"/gi;     # quote all identifiers and non numeric values
my $json_string = $js;                              # js is munged to JSON now

my $station_list = decode_json($json_string);

# map to a handy structure
my %stations; for (@$station_list) { $stations{$_->{i}}{lc $_->{l}} = $_->{d}; }

## [NL] test ###########################################################################################
                                                                                                       
my $stations_8 = $irail_0->lookup_stations(lang => 'nl');
foreach my $id (keys %stations) {
    my $name = $stations{$id}{'nl'};
    next unless $name;

    # broaden the match
    (my $lesser_name = $name) =~ s/[\ \-]//g;
    ok((grep { /^$lesser_name$/ } map { s/[\ \-]//g; $_; } (@$stations_8)), "station named '$name' [NL] should exist");
}

## [FR] test ###########################################################################################
my $stations_9 = $irail_0->lookup_stations(lang => 'fr');
foreach my $id (keys %stations) {
    my $name = $stations{$id}{'fr'};
    next unless $name;

    # broaden the match
    (my $lesser_name = $name) =~ s/[\ \-]//g;
    ok((grep { /^$lesser_name$/ } map { s/[\ \-]//g; $_; } (@$stations_9)), "station named '$name' [FR] should exist");
}

## [EN] test ###########################################################################################
my $stations_10 = $irail_0->lookup_stations(lang => 'en');
foreach my $id (keys %stations) {
    my $name = $stations{$id}{'en'};
    next unless $name;

    # broaden the match
    (my $lesser_name = $name) =~ s/[\ \-]//g;                                                                                  
    ok((grep { /^$lesser_name$/ } map { s/[\ \-]//g; $_; } (@$stations_10)), "station named '$name' [EN] should exist");
}

## [DE] test ###########################################################################################
my $stations_11 = $irail_0->lookup_stations(lang => 'de');
foreach my $id (keys %stations) {
    my $name = $stations{$id}{'de'};
    next unless $name;

    # broaden the match
    my $lesser_name = $name;
    $lesser_name =~ s/\s*\(.*?\)\s*//g; # de version uses BRUSSEL (BRUXELLES)-OUEST, convert to BRUSSEL-OUEST
    $lesser_name =~ s/[\ \-]//g;
    ok((grep { /^$lesser_name$/ } map { s/[\ \-]//g; $_; } (@$stations_11)), "station named '$name' [DE] should exist");
}




done_testing();

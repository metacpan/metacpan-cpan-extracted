#!/usr/bin/perl
use Data::Dumper;
use JSON::XS;
use LWP::UserAgent;

###############################################################################
## Station Data Dumper - copyright (c) 2010 Tim Esselens - license: Perl
###############################################################################

my $ua = new LWP::UserAgent;
my $url = 'http://www.railtime.be/website/StationDataScript.ashx';
my $re = $ua->get($url);

die "could not get $url, status line: ".$re->status_line unless $re->is_success;

my $js = $re->decoded_content();

$js =~ s/[\r\n]//g;                                 # remove newlines
$js =~ s/^var dataItems = //;                       # remove assignment
$js =~ s/;$//;                                      # remove end of statement
$js =~ s/"//g;                                      # remove all double quotes
$js =~ s/([a-z'][\w\d\s\-'_\(\)\.\/]*)/"$1"/gi;     # requote ident & non nums
my $json_string = $js;                              # js is munged to JSON now

# decode the json_strong
my $station_list = decode_json($json_string);

# map to a handy structure
my %stations; for (@$station_list) { $stations{$_->{i}}{lc $_->{l}} = $_->{d}; }

# print Dumper(\%stations); for debugging

# print the station list, give FR priority 
foreach my $id (sort { $a <=> $b } keys %stations) {
    my ($name) = map { $_->{fr} || $_->{en} || $_->{de} || $_->{nl} } $stations{$id};
    print join ";", ("BE.NMBS.".$id , $name, $xpos, $ypos);
    print "\n";
}

# print the station list, give NL priority 
# foreach my $id (sort { $a <=> $b } keys %stations) {
#     my ($name) = map { $_->{nl} || $_->{en} || $_->{de} || $_->{fr} } $stations{$id};
#     print join ";", ("BE.NMBS.".$id , $name, $xpos, $ypos);
#     print "\n";
# }

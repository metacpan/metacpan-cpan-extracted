#!perl

use 5.006;

use strict;
use warnings;
use lib '../../lib/';

use Storable qw(nstore);

use Ticketmaster::API;

my $real_api_key  = 'realAPIkey';
my $save_api_key  = 'testAPIkey';
my $method = 'GET';
my $path_template = 'discovery/%s/venues/341396.json';
my %parameters = (
);

my $recording_name = 'GET_' . sprintf($path_template, 'v1') . "?apikey=$save_api_key";
foreach my $key (sort {$a cmp $b} keys %parameters) {
    $recording_name .= '_' . $key . '_' . $parameters{$key};
}
$recording_name =~ s/[=?&\/]/_/g;

die("record.pl needs to be run within the recordings directory") unless $0 eq 'record.pl';
die("recording already exists: $recording_name\n") if -e $recording_name;

my $obj = Ticketmaster::API->new(api_key => $real_api_key);
my $res = $obj->get_data(method => $method, path_template => $path_template);

nstore $res, $recording_name;

print "$recording_name populated\n";

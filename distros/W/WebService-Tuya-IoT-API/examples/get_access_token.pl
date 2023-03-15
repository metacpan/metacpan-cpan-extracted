#!/usr/bin/perl
use strict;
use warnings;
use Getopt::Std;
use WebService::Tuya::IoT::API;

my $syntax         = "$0 -i client_id -s client_secret\n";
my $opt            = {};
getopts('ds:i:', $opt);
my $debug          = $opt->{'d'};
my $client_id      = $opt->{'i'} or die($syntax);
my $client_secret  = $opt->{'s'} or die($syntax);

my $ws             = WebService::Tuya::IoT::API->new(client_id=>$client_id, client_secret=>$client_secret) or die;
my $access_token   = $ws->access_token or die;

print "Access Token: $access_token\n";

if ($debug) {
  require Data::Dumper;
  print Data::Dumper::Dumper($ws);
}

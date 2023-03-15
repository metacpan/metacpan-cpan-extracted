#!/usr/bin/perl
use strict;
use warnings;
use Data::Dumper qw{Dumper};
use Getopt::Std;
use WebService::Tuya::IoT::API;
$Data::Dumper::Indent  = 1; #smaller index
$Data::Dumper::Terse   = 1; #remove $VAR1 header

my $syntax         = "$0 -i client_id -s client_secret deviceid [...]\n";
my $opt            = {};
getopts('ds:i:', $opt);
my $debug          = $opt->{'d'};
my $client_id      = $opt->{'i'} or die($syntax);
my $client_secret  = $opt->{'s'} or die($syntax);

my $ws             = WebService::Tuya::IoT::API->new(client_id=>$client_id, client_secret=>$client_secret) or die;

foreach my $deviceid (@ARGV) {
  my $r = $ws->device_status($deviceid);
  print Dumper($r);
}

if ($debug) {
  print Data::Dumper::Dumper($ws);
}

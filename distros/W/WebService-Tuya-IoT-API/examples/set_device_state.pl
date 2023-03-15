#!/usr/bin/perl
use strict;
use warnings;
use Data::Dumper qw{Dumper};
use Getopt::Std;
use WebService::Tuya::IoT::API;

my $syntax         = "$0 [-d] -i client_id -s client_secret deviceid switch [on|off]\n";
my $opt            = {};
getopts('ds:i:', $opt);
my $debug          = $opt->{'d'};
my $client_id      = $opt->{'i'} or die($syntax);
my $client_secret  = $opt->{'s'} or die($syntax);

my $deviceid       = shift or die($syntax);
my $switch         = shift or die($syntax);
my $state          = shift;
my $ws             = WebService::Tuya::IoT::API->new(client_id=>$client_id, client_secret=>$client_secret, _debug=>($debug ? 2 : 0)) or die;

print_state($ws => $deviceid);

if (defined($state) and $state =~ m/\Aon|off|1|0\Z/i) {
  my $state_boolean  = $state =~ m/\A(on|1)\Z/i ? \1 : \0; #note scalar references
  my $response       = $ws->device_command_code_value($deviceid, $switch, $state_boolean);
  my $success        = $response->{'success'};
  if ($debug) {
    local $Data::Dumper::Indent  = 1; #smaller index
    local $Data::Dumper::Terse   = 1; #remove $VAR1 header
    print Dumper($response);
  }
  printf "Device: %s, Switch: %s, State: %s, Success: %s\n", $deviceid, $switch, ($$state_boolean ? 'on' : 'off'), ($success ? 'yes' : 'no');

  print_state($ws => $deviceid);
} else {
  die($syntax);
}

sub print_state {
  my $ws       = shift or die;
  my $deviceid = shift or die;
  my $response = $ws->device_status($deviceid);

  if ($debug) {
    local $Data::Dumper::Indent  = 1; #smaller index
    local $Data::Dumper::Terse   = 1; #remove $VAR1 header
    print Dumper($response);
  }

  my $results_aref = $response->{'result'};
  my $value;
  my @codes        = ();
  foreach my $result_href (@$results_aref) {
    my $code = $result_href->{'code'};
    push @codes, $code;
    if ($code eq $switch) {
      $value = $result_href->{'value'};
    }
  }
  if (defined $value) {
    printf "Device: %s, Switch: %s, State: %s\n", $deviceid, $switch, ($value ? 'on' : 'off');
  } else {
    printf qq{Error: switch "%s" not found on device. try: %s\n}, $switch, join(", ", map {qq{"$_"}} @codes);
  }
}

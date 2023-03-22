use strict;
use warnings;
use Data::Dumper qw{Dumper};
use Time::HiRes qw{sleep};
use List::Util qw{first};

use Test::More tests => 1 + 6;
BEGIN { use_ok('WebService::Tuya::IoT::API') };

my $client_id     = $ENV{'TUYA_CLIENT_ID'};
my $client_secret = $ENV{'TUYA_CLIENT_SECRET'};
my $deviceid      = $ENV{'TUYA_DEVICEID'};
my $code          = $ENV{'TUYA_CODE'} || 'switch_1';
my $skip          = not ($client_id and $client_secret and $deviceid);

SKIP: {
  skip "ENV TUYA_CLIENT_ID, TUYA_CLIENT_SECRET and TUYA_DEVICEID must be set", 6 if $skip;
  my $ws    = WebService::Tuya::IoT::API->new(client_id=>$client_id, client_secret=>$client_secret);
  my $token = $ws->access_token;
  diag("Token: $token");
  like($token, qr/\A[a-f0-9]+\Z/);

  my $reset;
  if ($ws->device_status_code_value($deviceid, $code)) {
    $ws->device_command_code_value($deviceid, $code, \0);
    $reset = \1;
  }

  my $value = $ws->device_status_code_value($deviceid, $code);
  my $state = $value ? 'on' : 'off';
  diag("Device: $deviceid, Code: $code, Value: $state");

  {
    my $set   = $ws->device_command_code_value($deviceid, $code, \1);
    ok($set->{'success'}, 'set on success');
    diag(Dumper($set));
    sleep 0.1;
    my $value = $ws->device_status_code_value($deviceid, $code);
    my $state = $value ? 'on' : 'off';
    diag("Device: $deviceid, Code: $code, Value: $state");
    ok($value, 'set on value');
  }
  {
    my $set   = $ws->device_command_code_value($deviceid, $code, \0);
    ok($set->{'success'}, 'set off success');
    diag(Dumper($set));
    sleep 0.1;
    my $value = $ws->device_status_code_value($deviceid, $code);
    my $state = $value ? 'on' : 'off';
    diag("Device: $deviceid, Code: $code, Value: $state");
    ok(!$value, 'set off value');
  }

  if (defined $reset) {
    my $set   = $ws->device_command_code_value($deviceid, $code, $reset);
    diag(Dumper($set));
    ok($set->{'success'}, 'set start success');
  } else {
    ok(1);
  }
}

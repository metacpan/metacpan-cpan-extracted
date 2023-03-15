use strict;
use warnings;
use Data::Dumper qw{Dumper};
require Time::HiRes;

sub millis {1000*Time::HiRes::time()};

use Test::More tests => 1 + 1+4*7;
BEGIN { use_ok('WebService::Tuya::IoT::API') };

my $client_id     = $ENV{'TUYA_CLIENT_ID'};
my $client_secret = $ENV{'TUYA_CLIENT_SECRET'};
my $deviceid      = $ENV{'TUYA_DEVICEID'};
my $skip          = not ($client_id and $client_secret and $deviceid);

SKIP: {
  skip "ENV TUYA_CLIENT_ID, TUYA_CLIENT_SECRET and TUYA_DEVICE must be set", 1+4*7 if $skip;
  my $ws    = WebService::Tuya::IoT::API->new(client_id=>$client_id, client_secret=>$client_secret);
  my $token = $ws->access_token;
  diag("Token: $token");
  like($token, qr/\A[a-f0-9]+\Z/);
  {
    my $start = millis();
    my $res = $ws->device_status($deviceid);
    diag(Dumper({device_status=>$res}));
    isa_ok($res, 'HASH', 'device_status');
    ok($res->{'success'});
    ok($res->{'t'} >= $start);
    ok($res->{'t'} <= millis());
  }
  {
    my $start = millis();
    my $res = $ws->device_information($deviceid);
    diag(Dumper({device_information=>$res}));
    isa_ok($res, 'HASH', 'device_information');
    ok($res->{'success'});
    ok($res->{'t'} >= $start);
    ok($res->{'t'} <= millis());
  }
  {
    my $start = millis();
    my $res = $ws->device_freeze_state($deviceid);
    diag(Dumper({device_freeze_state=>$res}));
    isa_ok($res, 'HASH', 'device_freeze_state');
    ok($res->{'success'});
    ok($res->{'t'} >= $start);
    ok($res->{'t'} <= millis());
  }
  {
    my $start = millis();
    my $res = $ws->device_factory_infos($deviceid);
    diag(Dumper({device_factory_infos=>$res}));
    isa_ok($res, 'HASH', 'device_factory_infos');
    ok($res->{'success'});
    ok($res->{'t'} >= $start);
    ok($res->{'t'} <= millis());
  }
  {
    my $start = millis();
    my $res = $ws->device_specification($deviceid);
    diag(Dumper({device_specification=>$res}));
    isa_ok($res, 'HASH', 'device_specification');
    ok($res->{'success'});
    ok($res->{'t'} >= $start);
    ok($res->{'t'} <= millis());
  }
  {
    my $start = millis();
    my $res = $ws->device_protocol($deviceid);
    diag(Dumper({device_protocol=>$res}));
    isa_ok($res, 'HASH', 'device_protocol');
    ok($res->{'success'});
    ok($res->{'t'} >= $start);
    ok($res->{'t'} <= millis());
  }
  {
    my $start = millis();
    my $res = $ws->device_properties($deviceid);
    diag(Dumper({device_properties=>$res}));
    isa_ok($res, 'HASH', 'device_properties');
    ok($res->{'success'});
    ok($res->{'t'} >= $start);
    ok($res->{'t'} <= millis());
  }
}

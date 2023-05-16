use strict;
use warnings;
use Data::Dumper qw{Dumper};
use Test::More tests => 4;
BEGIN { use_ok('WebService::Whistle::Pet::Tracker::API') };

my $email         = $ENV{'WHISTLE_EMAIL'};
my $password      = $ENV{'WHISTLE_PASSWORD'};
my $device_serial = $ENV{'WHISTLE_DEVICE_SERIAL'};
my $skip          = not ($email and $password and $device_serial);

SKIP: {
  skip 'Environment WHISTLE_EMAIL and WHISTLE_PASSWORD and WHISTLE_DEVICE_SERIAL not set', 3 if $skip;
  my $ws     = WebService::Whistle::Pet::Tracker::API->new(email=>$email, password=>$password);
  my $device = $ws->device($device_serial);
  diag(Dumper($device));
  isa_ok($device, 'HASH', 'device');
  like($device->{'battery_level'}, qr/\A([1-9]|[1-9][0-9]|100)\Z/);
  is($device->{'serial_number'}, $device_serial, '$device_serial');
}

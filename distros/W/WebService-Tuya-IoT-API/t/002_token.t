use strict;
use warnings;

use Test::More tests => 2;
BEGIN { use_ok('WebService::Tuya::IoT::API') };

my $client_id     = $ENV{'TUYA_CLIENT_ID'};
my $client_secret = $ENV{'TUYA_CLIENT_SECRET'};
my $skip          = not ($client_id and $client_secret);

SKIP: {
  skip "ENV TUYA_CLIENT_ID and TUYA_CLIENT_SECRET must be set", 1 if $skip;
  my $ws    = WebService::Tuya::IoT::API->new(client_id=>$client_id, client_secret=>$client_secret);
  my $token = $ws->access_token;
  diag("Token: $token");
  like($token, qr/\A[a-f0-9]+\Z/);
}

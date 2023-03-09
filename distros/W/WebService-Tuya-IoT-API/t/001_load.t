use strict;
use warnings;

use Test::More tests => 12;
BEGIN { use_ok('WebService::Tuya::IoT::API') };

{
  my $ws = WebService::Tuya::IoT::API->new(client_id=>'123abc', client_secret=>'xyz456');
  isa_ok($ws, 'WebService::Tuya::IoT::API');
  can_ok($ws, 'new');
  can_ok($ws, 'http_hostname');
  can_ok($ws, 'api_version');
  can_ok($ws, 'api');
  can_ok($ws, 'client_id');
  can_ok($ws, 'client_secret');
  is($ws->client_id, '123abc', 'client_id');
  is($ws->client_id('123abcxxx'), '123abcxxx', 'client_id');
  is($ws->client_secret, 'xyz456', 'client_secret');
  is($ws->client_secret('xyz456xxx'), 'xyz456xxx', 'client_secret');
}




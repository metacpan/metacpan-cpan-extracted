use strict;
use Test::More 0.98;
use WWW::FBX::API;

ok (
fbx_api_method( t_api_version => ( description => <<'',
Get API version.

  path => 'api_version',
  method => 'GET',
  params => [],
  required => [],
))
, "fbx_api_method"
);

done_testing;


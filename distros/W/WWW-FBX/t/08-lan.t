use strict;
use Test::More 0.98;
use WWW::FBX;

plan skip_all => "FBX_APP_ID, FBX_APP_NAME, FBX_APP_VERSION, FBX_TRACK_ID, FBX_APP_TOKEN not all set"
    unless $ENV{FBX_APP_ID} and $ENV{FBX_APP_NAME} and $ENV{FBX_APP_VERSION} and $ENV{FBX_TRACK_ID} and $ENV{FBX_APP_TOKEN};

my $fbx;
my $res;
my $net;
my $id;

eval {
  $fbx = WWW::FBX->new (
    app_id => $ENV{FBX_APP_ID},
    app_name => $ENV{FBX_APP_NAME},
    app_version => $ENV{FBX_APP_VERSION},
    device_name => $ENV{FBX_TRACK_ID},
    track_id => $ENV{FBX_TRACK_ID},
    app_token => $ENV{FBX_APP_TOKEN},
  );

  isa_ok $fbx, "WWW::FBX", "lan";
  ok( $res = $fbx->lan_config, "lan config"); #diag explain $res;
  ok( $res = $fbx->lan_browser_interfaces, "lan browser interfaces");
  $net = $res->[0]->{name};
  ok( $res = $fbx->list_hosts( $net ), "lan browser interfaces pub"); #diag explain $res;
  $id = $res->[0]->{id};
  ok( $res = $fbx->list_hosts("$net/$id"), "get host information"); #diag explain $res;

  if ($ENV{FBX_FULL_TESTS}) {
    ok( $res = $fbx->upd_host("$net/$id", { id => $id , host_type => "networking_device" }), "update host information"); #diag explain $res;
    ok( $res = $fbx->upd_lan_config( {mode=>"router"} ), "update lan config"); #diag explain $res;
    ok( $res = $fbx->wol_host( $net, {mac => "B8:27:EB:73:8C:4E"} )||1, "send wol"); #diag explain $res;
  }
};

if ( my $err = $@ ) {
    diag "HTTP Response Code: ", $err->code, "\n",
         "HTTP Message......: ", $err->message, "\n",
         "API Error.........: ", $err->error, "\n",
         "Error Code........: ", $err->fbx_error_code, "\n",
}


done_testing;


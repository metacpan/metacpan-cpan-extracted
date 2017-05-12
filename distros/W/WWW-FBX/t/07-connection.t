use strict;
use Test::More 0.98;
use WWW::FBX;

plan skip_all => "FBX_APP_ID, FBX_APP_NAME, FBX_APP_VERSION, FBX_TRACK_ID, FBX_APP_TOKEN not all set" 
    unless $ENV{FBX_APP_ID} and $ENV{FBX_APP_NAME} and $ENV{FBX_APP_VERSION} and $ENV{FBX_TRACK_ID} and $ENV{FBX_APP_TOKEN};

my $fbx;
my $res;

diag "Sleeping 1s to avoid 503 error on invalid token" && sleep 1;

eval { 
  $fbx = WWW::FBX->new ( 
    app_id => $ENV{FBX_APP_ID},
    app_name => $ENV{FBX_APP_NAME},
    app_version => $ENV{FBX_APP_VERSION},
    device_name => $ENV{FBX_TRACK_ID},
    track_id => $ENV{FBX_TRACK_ID},
    app_token => $ENV{FBX_APP_TOKEN},
  );
  
  isa_ok $fbx, "WWW::FBX", "connection";
  ok( $res = $fbx->connection, "connection"); #diag explain $res;
  ok( $res = $fbx->connection_config, "connection config"); #diag explain $res;
  ok($fbx->connection_ipv6_config, "connection ipv6 config");
  ok($fbx->connection_xdsl, "connection xdsl");
  ok($fbx->connection_ftth, "connection ftth");
  if ($ENV{FBX_FULL_TESTS}) { 
    ok( $res = $fbx->upd_connection({ping=>\1}), "update connection config"); #diag explain $res; 
    ok( $res = $fbx->upd_ipv6_config({ipv6_enabled=>\0}), "update connection ipv6 config"); #diag explain $res; 
    ok($res = $fbx->connection_dyndns("noip/status"), "connection dyndns noip"); #diag explain $res; 
    ok($res = $fbx->upd_connection_dyndns("noip/status", {enabled=>\0}), "connection dyndns noip"); #diag explain $res;
  }
};

if ( my $err = $@ ) {
    diag "HTTP Response Code: ", $err->code, "\n",
         "HTTP Message......: ", $err->message, "\n",
         "API Error.........: ", $err->error, "\n",
         "Error Code........: ", $err->fbx_error_code, "\n",
}


done_testing;


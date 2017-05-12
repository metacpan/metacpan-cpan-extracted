use strict;
use Test::More 0.98;
use WWW::FBX;

plan skip_all => "FBX_APP_ID, FBX_APP_NAME, FBX_APP_VERSION, FBX_TRACK_ID, FBX_APP_TOKEN not all set" 
    unless $ENV{FBX_APP_ID} and $ENV{FBX_APP_NAME} and $ENV{FBX_APP_VERSION} and $ENV{FBX_TRACK_ID} and $ENV{FBX_APP_TOKEN};

my $fbx;
my $res;

eval { 
  $fbx = WWW::FBX->new ( 
    app_id => $ENV{FBX_APP_ID},
    app_name => $ENV{FBX_APP_NAME},
    app_version => $ENV{FBX_APP_VERSION},
    device_name => $ENV{FBX_TRACK_ID},
    track_id => $ENV{FBX_TRACK_ID},
    app_token => $ENV{FBX_APP_TOKEN},
  );
  
  isa_ok $fbx, "WWW::FBX", "nat";
  ok($fbx->fw_dmz, "fw dmz");
  ok($fbx->fw_redir, "fw all redir");
  ok( $res = $fbx->fw_redir(1), "fw redir"); #diag explain $res;
  ok( $res = $fbx->fw_incoming, "fw all incoming"); #diag explain $res;
  ok( $res = $fbx->fw_incoming("bittorrent-main"), "fw incoming"); diag explain $res;
};

if ( my $err = $@ ) {
    diag "HTTP Response Code: ", $err->code, "\n",
         "HTTP Message......: ", $err->message, "\n",
         "API Error.........: ", $err->error, "\n",
         "Error Code........: ", $err->fbx_error_code, "\n",
}


done_testing;


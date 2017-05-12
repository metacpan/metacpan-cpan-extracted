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
  
  isa_ok $fbx, "WWW::FBX", "wifi";
  ok($fbx->wifi_config, "wifi config");
  ok( $res = $fbx->wifi_ap, "wifi all ap");
  ok( $res = $fbx->wifi_ap(0), "wifi ap");
  ok( $res = $fbx->wifi_ap("0/allowed_channel_comb"), "wifi ap allowed combination");
  ok( $res = $fbx->wifi_ap("0/stations"), "wifi ap connected stations"); diag "connected stations: ", join( ', ', map($_->{hostname},@$res) );
  ok( $res = $fbx->wifi_ap("0/neighbors"), "wifi ap neighbors"); #diag explain $res;
  ok( $res = $fbx->wifi_ap("0/channel_usage"), "wifi ap channel usage"); #diag explain $res;
  ok( $res = $fbx->wifi_bss, "wifi bss"); #diag explain $res;
  ok( $res = $fbx->wifi_bss( $res->[0]{id} )); #diag explain $res;
  ok($fbx->wifi_planning, "wifi planning");
  ok($fbx->wifi_mac_filter, "wifi mac filter");
};

if ( my $err = $@ ) {
    diag "HTTP Response Code: ", $err->code, "\n",
         "HTTP Message......: ", $err->message, "\n",
         "API Error.........: ", $err->error, "\n",
         "Error Code........: ", $err->fbx_error_code, "\n",
}


done_testing;


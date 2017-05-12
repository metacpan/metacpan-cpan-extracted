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
  
  isa_ok $fbx, "WWW::FBX", "fs";
  ok($fbx->fs_tasks, "fs tasks");
#  ok($fbx->fs_tasks(12), "fs task");
#  ok($fbx->del_task(12), "del fs task");
#  ok($fbx->upd_task(12, state=>"paused"}), "update fs task");
  ok($res = $fbx->list_files("Disque dur/"), "list files");
#  ok($res = $fbx->file_info("Disque dur/Photos/Sydney/DSCF4323.JPG"), "file info");
#  ok($res = $fbx->download_file("Disque dur/Photos/cyril/DSCF4322.JPG"), "download RAW file not JSON!");
};

if ( my $err = $@ ) {
    diag "HTTP Response Code: ", $err->code, "\n",
         "HTTP Message......: ", $err->message, "\n",
         "API Error.........: ", $err->error, "\n",
         "Error Code........: ", $err->fbx_error_code, "\n",
}


done_testing;


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
 
  isa_ok $fbx, "WWW::FBX", "download";
  $fbx->downloads;
  $fbx->downloads_config;
  $fbx->downloads_stats;
  $fbx->downloads_feeds;

  if ($ENV{FBX_FULL_TESTS}) { 
    my $id;
    my $id2;
    my $id_file;
    my $max_dl_tasks;

    ok($res = $fbx->downloads_config);
    $max_dl_tasks = $res->{max_downloading_tasks};
    $res = $fbx->get_download_task;
    ok($res = $fbx->add_download_task( { download_url => "http://cdimage.debian.org/debian-cd/current/arm64/bt-cd/debian-8.4.0-arm64-CD-1.iso.torrent"} ));
    $res = $fbx->upd_downloads_config({max_downloading_tasks => $max_dl_tasks});
    $res = $fbx->upd_downloads_throttle( "schedule" );
    $res = $fbx->get_download_task;
    $id = $res->[0]{id}; #diag("id is $id");
    $res = $fbx->del_download_task( $id );
    $res = $fbx->add_download_task_file( {download_file => [ "$ENV{HOME}/debian-8.4.0-arm64-netinst.iso.torrent" ] });
    $id2 = $res->{id}; #diag("id is $id");
    ok($res = $fbx->get_download_task( $id2 ));
    $res = $fbx->get_download_task( "$id2/log" );
    $fbx->upd_download_task( $id2, { io_priority => "high" } );
    ok($res = $fbx->get_download_task("$id2/files") );
    $id_file = $res->[0]{id}; #diag "id file is $id_file";
    ok($res = $fbx->change_prio_download_file( "$id2/files/$id_file", { priority=>"high"} )||1);
    ok($res = $fbx->get_download_task( "$id2/trackers"));
    ok($res = $fbx->get_download_task( "$id2/peers")||1);
    $fbx->del_download_task( "$id2/erase" );
    $res = $fbx->get_download_task; $fbx->del_download_task( $_->{id} . "/erase" ) for @{$res};

    $res = $fbx->downloads_feeds;
    ok($res = $fbx->add_feed( "http://www.esa.int/rssfeed/Our_Activities/Space_News" ));
    $id = $res->{id}; 
    $fbx->upd_feed( $id , {auto_download=> \1} );
    sleep 1;
    ok($res = $fbx->downloads_feeds("$id/items"));
    $id_file = $res->[0]{id}; #diag "id file is $id_file";
#    $fbx->refresh_feed( "$id/fetch" );
    $fbx->refresh_feeds;
    $fbx->downloads_feeds("$id/items");
    $fbx->upd_feed("$id/items/$id_file");
    $fbx->download_feed_item("$id/items/$id_file/download");
    $fbx->mark_all_read( "$id/items/mark_all_as_read" );
    $fbx->del_feed( $id );
    $res = $fbx->get_download_task; $fbx->del_download_task( $_->{id} . "/erase" ) for @{$res};
    
    ok( $res = $fbx->download_file( "Disque dur/Photos/cyril/DSCF4322.JPG" ));
    ok( $res = $fbx->mkdir({parent=>"/Disque dur", dirname =>"testdir"})|| 1);
    ok( $res = $fbx->upload_auth( {upload_name => "DSCF4322.JPG", dirname => "/Disque dur/testdir/"} ));
    ok( $res = $fbx->upload_file( {id=> $res->{id}, filename=>"DSCF4322.JPG"})||1);
    ok( $res = $fbx->rm( {files=>[ "/Disque dur/testdir/DSCF4322.JPG" ]} ));
    ok( $res = $fbx->upload_file( {filename => "DSCF4322.JPG", dirname => "/Disque dur/testdir/"} )||1);
    ok( $res = $fbx->rm( {files=>[ "/Disque dur/testdir/" ]} ));
    unlink "DSCF4322.JPG";
  }

};

if ( my $err = $@ ) {
    diag "HTTP Response Code: ", $err->code, "\n",
         "HTTP Message......: ", $err->message, "\n",
         "API Error.........: ", $err->error, "\n",
         "Error Code........: ", $err->fbx_error_code, "\n",
}


done_testing;


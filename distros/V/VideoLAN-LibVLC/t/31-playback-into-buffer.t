use strict;
use warnings;
use Test::More;
use FindBin;
use Time::HiRes 'sleep';
use File::Spec::Functions 'catdir';
use Scalar::Util 'weaken';
use Devel::Peek;
my $datadir= catdir($FindBin::Bin, 'data');

use_ok('VideoLAN::LibVLC::MediaPlayer') || BAIL_OUT;

my $vlc= new_ok( 'VideoLAN::LibVLC', [], 'init libvlc' );
$vlc->log(sub { note $_[0]->{message}; }, { level => 1 });

#subtest player_pic_refcnt => \&test_player_pic_refcnt;
#sub test_player_pic_refcnt {
#	my $player= new_ok( 'VideoLAN::LibVLC::MediaPlayer', [ libvlc => $vlc ], 'player instance' );
#	my $picture= new_ok( 'VideoLAN::LibVLC::Picture', [{ chroma => "RGBA", width => 256, height => 256, pitch => 4*256, lines => 4*256 }], 'picture instance' );
#	$player->queue_picture($picture);
#	weaken($picture);
#	ok( $picture, 'picture not freed' );
#	my $picture2= $player->remove_picture($picture);
#	ok( $picture, 'picture still not freed' );
#	weaken($picture2);
#	is( $picture, undef, 'picture freed' )
#		or diag Devel::Peek::Dump($picture), Devel::Peek::Dump($picture2);
#	weaken($player);
#	is( $player, undef, 'player freed' )
#		or diag Devel::Peek::Dump($player);
#	
#	$player= new_ok( 'VideoLAN::LibVLC::MediaPlayer', [ libvlc => $vlc, video_format => { chroma => "RGBA", width => 256, height => 256, pitch => 4*256, lines => 4*256 } ], 'player instance' );
#	$player->trace_pictures;
#	$player->queue_new_picture();
#	undef $player; # no way to test other than view logs.
#	
#	done_testing;
#}

#subtest custom_framesize => \&test_custom_framesize;
sub test_custom_framesize {
	my $player= new_ok( 'VideoLAN::LibVLC::MediaPlayer', [ libvlc => $vlc ], 'player instance' );
	1 while $vlc->callback_dispatch;

	my $pic;
	$player->trace_pictures(1) if $ENV{DEBUG};
	$player->set_video_callbacks(display => sub { $pic= $_[1]{picture}; });
	$player->set_video_format(chroma => 'RGBA', width => 64, height => 64, pitch => 64*4);
	$player->queue_new_picture(id => $_) for 0..7;
	$player->media(catdir($datadir, 'NASA-solar-flares-2017-04-02.mp4'));
	1 while $vlc->callback_dispatch;

	ok( $player->play, 'play' );
	for (my $i= 0; !$pic && $i < 100; $i++) {
		sleep .05;
		1 while $vlc->callback_dispatch;
	}
	ok( $pic, 'received picture from display callback' );
	$player->stop;
	for (my $i= 0; $player->is_playing && $i < 100; $i++) {
		sleep .05;
		1 while $vlc->callback_dispatch;
	}
	weaken($pic);
	sleep .05;
	is( $pic, undef, 'pic got freed' )
		or diag Devel::Peek::Dump($pic);
	weaken($player);
	is( $player, undef, 'player got freed' )
		or diag Devel::Peek::Dump($player);
	done_testing;
}

subtest native_framesize => \&test_native_framesize;
sub test_native_framesize {
	my $player= new_ok( 'VideoLAN::LibVLC::MediaPlayer', [ libvlc => $vlc ], 'player instance' );
	1 while $vlc->callback_dispatch;

	my ($next_pic_id, $pic, $ready, $done);
	$player->trace_pictures(1) if $ENV{DEBUG};
	$player->set_video_callbacks(
		display => sub { $pic= $_[1]{picture}; },
		format => sub {
			my ($p, $event)= @_;
			diag explain $event if $ENV{DEBUG};
			$p->set_video_format(%$event, chroma => 'RGBA', alloc_count => 8);
		},
		lock => sub {
			my ($p, $event)= @_;
			$p->queue_new_picture(id => ++$next_pic_id) while $p->queued_picture_count < 8;
		},
		cleanup => sub { ++$done },
	);
	$player->media(catdir($datadir, 'NASA-solar-flares-2017-04-02.mp4'));
	1 while $vlc->callback_dispatch;
	ok( $player->play, 'play' );
	my $timeout= time + 15;
	while (time < $timeout && !$pic) {
		sleep .01;
		1 while $vlc->callback_dispatch;
	}
	ok( $pic, 'received picture from display callback' );
	is( $pic->held_by_vlc, 0, 'pic not held by vlc' );
	ok( eval { $player->queue_picture($pic); 1 }, 'push picture' );
	is( $pic->held_by_vlc, 1, 'pic held by vlc again' );
	$player->stop;
	$timeout= time + 10;
	while (time < $timeout && (!$done || $player->is_playing)) {
		sleep .01;
		# player can run out of pictures if we don't re-queue them, which isn't really
		# a problem but displays warnings on STDERR.  Re-queue pictures to prevent
		# underrun.
		while ($vlc->callback_dispatch) {
			$player->queue_picture($pic) unless $pic->held_by_vlc;
		}
	}
	ok( $done, 'got cleanup event' );
	weaken($player);
	is( $player, undef, 'player got freed' )
		or diag Devel::Peek::Dump($player);
	weaken($pic);
	is( $pic, undef, 'pic got freed' )
		or diag Devel::Peek::Dump($pic);
	done_testing;
}

done_testing;

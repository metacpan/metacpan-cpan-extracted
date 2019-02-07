use strict;
use warnings;
use Test::More;
use FindBin;
use Time::HiRes 'sleep';
use File::Spec::Functions 'catdir';
my $datadir= catdir($FindBin::Bin, 'data');

use_ok('VideoLAN::LibVLC::MediaPlayer') || BAIL_OUT;

# wrap with function to help free vars in correct order
sub test {
	my $vlc= new_ok( 'VideoLAN::LibVLC', [], 'init libvlc' );
	$vlc->log(sub { note $_[0]->{message}; }, { level => 0 });

	my $player= new_ok( 'VideoLAN::LibVLC::MediaPlayer', [ libvlc => $vlc ], 'player instance' );
	1 while $vlc->callback_dispatch;

	$player->media(catdir($datadir, 'NASA-solar-flares-2017-04-02.mp4'));
	1 while $vlc->callback_dispatch;

	is( $player->time, undef, 'time = undef' );
	is( $player->position, undef, 'position = undef' );
	ok( $player->play, 'play' );
	for (my $i= 0; !$player->is_playing && $i < 10; $i++) {
		sleep .5;
		1 while $vlc->callback_dispatch;
	}
	sleep .5;
	$player->pause;
	1 while $vlc->callback_dispatch;
	is( $player->will_play, 1, 'will_play = 1' );
	ok( $player->time > 0, 'time > 0' );
	ok( $player->position > 0, 'position > 0' );

	$player->time(0.5);
	is( $player->time, 0.5, 'time = 0.5' );
	ok( $player->position < 0.5, 'position < 0.5' );

	$player->position(0);
	is( $player->time, 0, 'time = 0' );
	is( $player->position, 0, 'position = 0' );

	$player->stop;
	1 while $vlc->callback_dispatch;
}
test();

done_testing;

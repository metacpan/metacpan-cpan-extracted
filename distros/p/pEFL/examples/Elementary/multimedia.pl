# Based on the multimedia tutorial code
# see https://www.enlightenment.org/develop/legacy/tutorial/multimedia_tutorial
#
#! /usr/bin/perl
use strict;
use warnings;

use pEFL::Evas;
use pEFL::Elm;
use pEFL::Emotion;

my $file = "PATH_TO_VIDEO_FILE";

my $info = 0;

pEFL::Elm::init($#ARGV, \@ARGV);

my $win = pEFL::Elm::Win->util_standard_add("main", "Multimedia Tutorial");
$win->show();

pEFL::Elm::policy_set(ELM_POLICY_QUIT, ELM_POLICY_QUIT_LAST_WINDOW_CLOSED);
$win->autodel_set(1);

my $nav = pEFL::Elm::Naviframe->add($win);
$nav->size_hint_weight_set(EVAS_HINT_EXPAND,EVAS_HINT_EXPAND);
$win->resize_object_add($nav);
$nav->show();


my $video = pEFL::Elm::Video->add($win);
$video->size_hint_weight_set(EVAS_HINT_EXPAND,EVAS_HINT_EXPAND);
$video->file_set($file);
$video->play();
$video->show();

my $player = pEFL::Elm::Player->add($win);
$player->size_hint_weight_set(EVAS_HINT_EXPAND,EVAS_HINT_EXPAND);
$player->content_set($video);
$player->smart_callback_add("info,clicked",\&_player_info_cb,$video);
$player->show();

my $it = $nav->item_push("Video",undef,undef,$player,undef);
$it->title_enabled_set(0,0);

$win->resize(800,600);

pEFL::Elm::run();

pEFL::Elm::shutdown();

sub _player_info_cb {
	my ($video, $obj, $event_info) = @_;
	
	my $emotion = $video->emotion_get();
	$info = 1;
	
	my $table = pEFL::Elm::Table->add($obj);
	$table->padding_set(8,8);
	$table->size_hint_weight_set(EVAS_HINT_EXPAND,EVAS_HINT_EXPAND);
	$table->show();
	
	# display the playing status in label
	my $label = pEFL::Elm::Label->add($table);
	$label->show();
	_player_info_status_update($label,$emotion,undef);
	$table->pack($label,0,0,2,1);
	$emotion->smart_callback_add("playback_finished", \&_player_info_status_update,$label);
	
	# * get the file name and location
	# set the file label
	my $flabel = pEFL::Elm::Label->add($table);
	$flabel->text_set("File:");
	$flabel->show();
	$table->pack($flabel,0,1,1,1);
	
	# set the file name label
	my $fname = $emotion->file_get();
	my $fnlabel = pEFL::Elm::Label->add($table);
	$fnlabel->text_set($fname);
	$fnlabel->show();
	$table->pack($fnlabel,1,1,1,1);
	
	# TODO: PATH LABEL
	
	# * get video position and duration
	# set time label
	my $tlabel = pEFL::Elm::Label->add($table);
	$tlabel->text_set("Time:");
	$tlabel->show();
	$table->pack($tlabel,0,3,1,1);
	
	# set position-duration label
	my $pdlabel = pEFL::Elm::Label->add($table);
	my $position = $video->play_position_get();
	my $duration = $video->play_length_get();
	
	my $psec = $position % 60;
	my $pmin = $position / 60;
	my $phour = $position / 3600;
	my $dsec = $duration % 60;
	my $dmin = $duration / 60;
	my $dhour = $duration / 3600;
	
	$pdlabel->text_set(sprintf("%02d:%02d:%02d / %02d:%02d:%02d", $phour,$pmin,$psec,$dhour,$dmin,$dsec));
	$table->pack($pdlabel,1,3,1,1);
	$pdlabel->show();
	
	$emotion->smart_callback_add("position_update",\&_player_info_time_update,$pdlabel);
	$emotion->smart_callback_add("length_change",\&_player_info_time_update,$pdlabel);
	
	# get the video dimensions
	my $dlabel = pEFL::Elm::Label->add($table);
	$dlabel->text_set("Size: ");
	$dlabel->show();
	$table->pack($dlabel, 0,4,1,1);
	
	my $dimlabel = pEFL::Elm::Label->add($table);
	my ($w,$h) = $emotion->size_get();
	$dimlabel->text_set("$w x $h");
	$dimlabel->show();
	$table->pack($dimlabel,1,4,1,1);
	
	# push info in a seperate naviframe item
	my $it = $nav->item_push("Information",undef,undef,$table,undef);
	$it->pop_cb_set(\&_player_info_del_cb, undef)
	
}

sub _player_info_status_update {
	my ($label, $emotion, $event_info) = @_;
	
	# switch on main item
	if (!$info) {
		print "Deletint playback finished event\n";
		$emotion->smart_callback_del("playback_finished", \&_player_info_status_update);
		return;
	}
	
	# update
	my $position = $emotion->position_get();
	my $duration = $emotion->play_length_get();
	
	if ($emotion->play_get()) {
		$label->text_set("<b>Playing</b>");
	}
	elsif ($position < $duration) {
		$label->text_set("<b>Paused</b>");
	}
	else {
		$label->text_set("<b>Ended</b>");
	}
	
}

sub _player_info_time_update {
	my ($label, $emotion, $event_info) = @_;
	
	# switch on main item
	if (!$info) {
		$emotion->smart_callback_del("position_update",\&_player_info_time_update);
		$emotion->smart_callback_del("length_change",\&_player_info_time_update);
		return;
	}
	else {
	# update
		my $position = $emotion->position_get();
		my $duration = $emotion->play_length_get();
	
		my $psec = $position % 60;
		my $pmin = $position / 60;
		my $phour = $position / 3600;
		my $dsec = $duration % 60;
		my $dmin = $duration / 60;
		my $dhour = $duration / 3600;
	
		$label->text_set(sprintf("%02d:%02d:%02d / %02d:%02d:%02d", $phour,$pmin,$psec,$dhour,$dmin,$dsec));
	}
}

sub _player_info_del_cb {
	my ($data, $it) = @_;

	$info = 0;
	return 1;
}

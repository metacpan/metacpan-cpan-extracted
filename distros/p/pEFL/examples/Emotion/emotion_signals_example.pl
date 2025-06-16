# Based on the multimedia tutorial code
# see https://www.enlightenment.org/develop/legacy/tutorial/multimedia_tutorial
#
#! /usr/bin/perl
use strict;
use warnings;

use pEFL::Ecore;
use pEFL::Ecore::Evas;
use pEFL::Evas;
use pEFL::Emotion;

my $width = 320;
my $height = 240;

my $filename = $ARGV[0];

if ( !$filename ) {
	print "At least one argument is necessary: Usage:\n\t $0 <filename> [module_name] \n";
	exit;
}

my $module = $ARGV[1] || undef;

if (!pEFL::Ecore::Evas::init()) {
	die "Initialization of Ecore Evas did not work\n";
}

# this will give you a window with an Evas canvas under the first
# engine available
my $ee = pEFL::Ecore::Evas->new(undef,10,10,$width,$height,undef);

if (!$ee) {
	warn "Requires at least one Evas engine built and linked to ecore-evas for this example to run properly.\n";	
	pEFL::Ecore::Evas::shutdown();
}

$ee->show();

# the canvas pointer, de facto
my $e = $ee->evas_get();

# adding a background to this example
my $bg = pEFL::Evas::Rectangle->add($e);
$bg->name_set("our dear rectangle");
$bg->color_set(255,255,255,255); # white bg
$bg->move(0,0); # at canvas origin
$bg->resize($width,$height); # covers full canvas
$bg->show();

# creating the emotion object
my $em = _create_emotion_object($e);
$em->file_set($filename);
$em->move(0,0);
$em->resize($width,$height);
$em->show();

$em->play_set(1);

pEFL::Ecore::Mainloop::begin();

$ee->free();
pEFL::Ecore::Evas::shutdown();

sub _create_emotion_object {
	my ($e) = @_;
	
	my $em = pEFL::Emotion::Object->add($e);
	if (!$em->init($module)) {
		warn "Emotion: $module could not be initialized\n";
	}
	
	# show display info after creation
	_display_info($em);
	
	# set up emotion callbacks
	$em->smart_callback_add("playback_started",\&_playback_started_cb,undef);
	$em->smart_callback_add("playback_finished",\&_playback_finished_cb,undef);
	$em->smart_callback_add("open_done",\&_open_done_cb,undef);
	$em->smart_callback_add("position_update",\&_position_update_cb,undef);
	$em->smart_callback_add("frame_decode",\&_frame_decode_cb,undef);
	$em->smart_callback_add("decode_stop",\&_decode_stop_cb,undef);
	$em->smart_callback_add("frame_resize",\&_frame_resize_cb,undef);
	
	return $em;
}

sub _display_info {
	my ($obj) = @_;
	print "playing: " . $obj->play_get() . "\n";
	print "meta title: " . $obj->meta_info_get(EMOTION_META_INFO_TRACK_TITLE) . "\n";
	printf("seek position: %.3f\n", $obj->position_get());
	printf("play length: %.3f\n", $obj->play_length_get());
	printf("is seekable: %d\n", $obj->seekable_get());

	my ($w,$h) = $obj->size_get();
	printf("video geometry: %d x %d\n", $w, $h);
	printf("video width / height ratio: %.3f\n", $obj->ratio_get());
	print "\n";
}

sub _playback_started_cb {
	my ($data, $obj, $ev) = @_;
	print ">>> Emotion object started playback\n";
	_display_info($obj);
}

sub _playback_finished_cb {
	my ($data, $obj, $ev) = @_;
	print ">>> Emotion object finished playback.\n";
	_display_info($obj);
}

sub _open_done_cb {
	my ($data, $obj, $ev) = @_;
	print ">>> Emotion object open done.\n";
	_display_info($obj);
}

sub _position_update_cb {
	my ($data, $obj, $ev) = @_;
	print ">>> Emotion object first position update.\n";
	$obj->smart_callback_del("position_update",\&_position_update_cb);
	_display_info($obj);
}

sub _frame_decode_cb {
	my ($data, $obj, $ev) = @_;
	print ">>> Emotion object first frame decode.\n";
	$obj->smart_callback_del("frame_decode",\&_frame_decode_cb);
	_display_info($obj);
}

sub _decode_stop_cb {
	my ($data, $obj, $ev) = @_;
	print ">>> Emotion object decode stop.\n";
	_display_info($obj);
}

sub _frame_resize_cb {
	my ($data, $obj, $ev) = @_;
	print ">>> Emotion object frame resize.\n";
	_display_info($obj);
}
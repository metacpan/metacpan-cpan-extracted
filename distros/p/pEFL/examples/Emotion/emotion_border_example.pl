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

my $bg; my $em;

my @filenames;

foreach my $f (@ARGV) {
	push @filenames, $f;
}

if ( $#filenames < 0 ) {
	print "One argument is necessary: Usage:\n\t $0 <filename>\n";
}

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

$ee->callback_resize_set(\&_canvas_resize_cb);

$ee->show();

# the canvas pointer, de facto
my $e = $ee->evas_get();

# adding a background to this example
$bg = pEFL::Evas::Rectangle->add($e);
$bg->name_set("our dear rectangle");
$bg->color_set(255,255,255,255); # white bg
$bg->move(0,0); # at canvas origin
$bg->resize($width,$height); # covers full canvas
$bg->show();

# creating the emotion object
$em = _create_emotion_object($e);
$em->file_set(shift @filenames);
$em->move(0,0);
$em->resize($width,$height);
$em->show();

# CALLBACKS
$em->smart_callback_add("frame_decode",\&_frame_decode_cb,undef);
$em->smart_callback_add("length_changed",\&_length_change_cb,undef);
$em->smart_callback_add("position_update",\&_position_update_cb,undef);
$em->smart_callback_add("progress_change",\&_progress_change_cb,undef);
$em->smart_callback_add("frame_resize",\&_frame_resize_cb,undef);

$bg->event_callback_add(EVAS_CALLBACK_KEY_DOWN, \&_on_key_down, $em);
$bg->focus_set(1);

$em->play_set(1);

pEFL::Ecore::Mainloop::begin();

$ee->free();
pEFL::Ecore::Evas::shutdown();

sub _create_emotion_object {
	my ($e) = @_;
	
	my $em = pEFL::Emotion::Object->add($e);
	$em->init("generic");
	
	# cb
	$em->smart_callback_add("playback_started",\&_playback_started_cb,undef);
	
	return $em;
}

sub _playback_started_cb {
	my ($data, $obj, $ev) = @_;
	
	print "Emotion object started playback\n";
}

sub _playback_stopped_cb {
	my ($data, $obj, $ev) = @_;
	
	print "Emotion playback stopped\n";
	$obj->play_set(0);
	$obj->position_set(0);
}

sub _on_key_down {
	my ($em, $e, $o, $event_info) = @_;
	
	my $ev = pEFL::ev_info2obj($event_info, "pEFL::Evas::Event::KeyDown");
	my $key = $ev->key();
	
	if ($key eq "Return") {
		$em->play_set(1);
	}
	elsif ($key eq "space") {
		$em->play_set(0);
	}
	elsif ($key eq "Escape") {
		pEFL::Ecore::Mainloop::quit();
	}
	elsif ($key eq "n") {
		my $file = shift @filenames;
		if ($file) {
			warn "playing next file: $file\n";
			$em->file_set($file);
		}
		else {
			warn "No file more in queue\n";
		}
	}
	elsif ($key eq "b") {
		$em->border_set(0,0,50,50);
	}
	elsif ($key eq "0") {
		$em->keep_aspect_set(EMOTION_ASPECT_KEEP_NONE);
	}
	elsif ($key eq "w") {
		$em->keep_aspect_set(EMOTION_ASPECT_KEEP_WIDTH);
	}
	elsif ($key eq "h") {
		$em->keep_aspect_set(EMOTION_ASPECT_KEEP_HEIGHT);
	}
	elsif ($key eq "2") {
		$em->keep_aspect_set(EMOTION_ASPECT_KEEP_BOTH);
	}
	elsif ($key eq "c") {
		$em->keep_aspect_set(EMOTION_ASPECT_CROP);
	}
	else {
		warn "unhandled key \n";
	}
}

sub _frame_decode_cb {
	#warn "smartcb: frame_decode\n"
}

sub length_change_cb {
	my ($data, $obj, $ev) = @_;
	my $length = $obj->play_length_get();
	printf("smartcb:length_change: %.3f\n",$length); 
}

sub _position_update_cb {
	my ($data, $obj, $ev) = @_;
	printf("smart_cb: position_update: %.3f\n", $obj->position_get());
}

sub _frame_resize_cb {
	my ($data, $obj, $ev) = @_;
	my ($w, $h) = $obj->size_get();
	warn "smartcb: frame_resize: $w x $h\n";
}

sub progress_change_cb {
	my ($data, $obj, $ev) = @_;
	printf("smartcb:progress_change: %.3f, %s\n",$obj->progress_status_get, $obj->progress_info_get); 
}

sub _canvas_resize_cb {
	my ($ee) = @_;
	
	my ($x, $y, $w, $h) = $ee->geometry_get();
	
	$bg->resize($w,$h);
	$em->resize($w-20,$h-20);
}
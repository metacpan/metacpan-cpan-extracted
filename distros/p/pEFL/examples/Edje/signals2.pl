#! /usr/bin/perl
use strict;
use warnings;

use pEFL;
use pEFL::Ecore;
use pEFL::Ecore::Evas;
use pEFL::Evas;
use pEFL::Edje;

my $width = 700;
my $height = 700;
my $walk = 10;
my $edje_file = "./signalsBubble.edj";


if (!pEFL::Ecore::Evas::init()) {
	die "Could not init Ecore Evas\n";
}

if (! pEFL::Edje::init()) {
	pEFL::Ecore::Evas::shutdown();
	die "Could not init Edje\n";
}

my $ee = pEFL::Ecore::Evas->new(undef,0,0,$width,$height,undef);

if (!$ee) {
	pEFL::Ecore::Edje::shutdown();
	pEFL::Ecore::Evas::shutdown();	
	die "Could not create Ecore Evas.\n";
}

$ee->callback_delete_request_set(\&on_delete);
$ee->title_set("Edje animations and signals");

my $evas = $ee->evas_get();

my $bg = pEFL::Evas::Rectangle->add($evas);
$bg->color_set(255,255,255,255); # White
$bg->move(0,0); # origin
$bg->resize($width,$height); # cover the window
$bg->show();
$ee->object_associate($bg, ECORE_EVAS_OBJECT_ASSOCIATE_BASE);
$bg->focus_set(1);

my $edje_obj = pEFL::Edje::Object->add($evas);

if (!$edje_obj->file_set($edje_file,"image_group")) {
	my $err = $edje_obj->load_error_get();
	my $errstr = pEFL::Edje::load_error_str($err);
	
	warn "Could not load the edje file: $errstr\n";
	pEFL::Ecore::Edje::shutdown();
	pEFL::Ecore::Evas::shutdown();
}

$edje_obj->signal_callback_add("mouse,move","part_image",\&_on_mouse_over,$evas);

$edje_obj->move(50,50);
$edje_obj->resize(63,63);
$edje_obj->show();

$ee->show();

pEFL::Ecore::Mainloop::begin();

$ee->free();
pEFL::Ecore::Evas::shutdown();
pEFL::Edje::shutdown();

sub on_delete {
	pEFL::Ecore::Mainloop::quit();
}

sub _on_mouse_over {
	my ($evas, $edje_object,$emission,$source) = @_;
	
	my ($x,$y) = $edje_obj->geometry_get();
	my ($mouseX, $mouseY) = $evas->pointer_output_xy_get();
	
	if ((rand() % 2) == 0) {
		$x += (($mouseX - $x) + ($x / 4 + $mouseY / 2));
	}
	else {
		$x -= (($mouseX - $x) + ($x / 4 + $mouseY / 2));
	}
	
	if ((rand() % 2) == 0) {
		$y += (($mouseY - $y) + ($y / 4 + $mouseX / 2));
	}
	else {
		$y -= (($mouseY - $y) + ($y / 4 + $mouseX / 2));
	}
	
	if ($x > $width) {
		$x = $width;
	}
	elsif ($x < 0 ) {
		$x = 0;
	}
	
	if ($y > $height) {
		$y = $height;
	}
	elsif ($y < 0 ) {
		$y = 0;
	}
	
	print "Moving object to - $x, $y\n";
	
	$edje_obj->move($x,$y);
	
}




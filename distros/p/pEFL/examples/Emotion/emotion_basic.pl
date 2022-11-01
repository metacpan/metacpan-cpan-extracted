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

if (!$filename) {
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
my $em = pEFL::Emotion::Object->add($e);
$em->init(undef);

# cb
$em->smart_callback_add("playback_started",\&_playback_started_cb,undef);

$em->move(0,0);
$em->resize($width,$height);
$em->show();

$em->file_set($filename);

$em->play_set(1);

pEFL::Ecore::Mainloop::begin();

$ee->free();
pEFL::Ecore::Evas::shutdown();

sub _playback_started_cb {
	my ($data, $obj, $ev) = @_;
	
	print "Emotion object started playback\n";
}


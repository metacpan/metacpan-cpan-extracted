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
my $edje_file = "./basic2.edj";


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
$ee->title_set("Edje show image");

my $evas = $ee->evas_get();

my $bg = pEFL::Evas::Rectangle->add($evas);
$bg->color_set(255,255,255,255); # White
$bg->move(0,0); # otigin
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
	
$edje_obj->move(50,50);
$edje_obj->resize(64,64);
$edje_obj->show();

$bg->event_callback_add(EVAS_CALLBACK_KEY_DOWN,\&_on_keydown,$edje_obj);

$ee->show();

print_commands();

pEFL::Ecore::Mainloop::begin();

$ee->free();
pEFL::Ecore::Evas::shutdown();
pEFL::Edje::shutdown();

sub on_delete {
	pEFL::Ecore::Mainloop::quit();
}

sub print_commands {
	print "commands are:\nEsc - Exit\nUp - move image up\nDown - move image down\n" .
    	"Right - move image to right\nLeft - move image to left\n";
}
sub _on_keydown {
	my ($edje_obj, $evas,$o,$einfo) = @_;
	
	my $e = pEFL::ev_info2obj($einfo, "pEFL::Ecore::Event::Key");
	my $keyname = $e->keyname();
	
	my ($x,$y) = $edje_obj->geometry_get();
	
	if ($keyname eq "h") {
		print_commands();
	}
	elsif ($keyname eq "Down") {
		$y += $walk;
	}
	elsif ($keyname eq "Up") {
		$y -= $walk;
	}
	elsif ($keyname eq "Right") {
		$x += $walk;
	}
	elsif ($keyname eq "Left") {
		$x -= $walk;
	}
	elsif ($keyname eq "Escape") {
		pEFL::Ecore::Mainloop::quit();
	}
	else {
		print "Unhandled key\n";
		print_commands();
	}
	
	$edje_obj->move($x,$y);
	
}




#! /usr/bin/perl
use strict;
use warnings;

use pEFL;
use pEFL::Ecore;
use pEFL::Ecore::Evas;
use pEFL::Evas;
use pEFL::Edje;

my $width = 320;
my $height = 240;

if (!pEFL::Ecore::Evas::init()) {
	die "Could not init Ecore Evas\n";
}

if (! pEFL::Edje::init()) {
	pEFL::Ecore::Evas::shutdown();
	die "Could not init Edje\n";
}

my $window = pEFL::Ecore::Evas->new(undef,0,0,$width,$height,undef);

if (!$window) {
	pEFL::Ecore::Edje::shutdown();
	pEFL::Ecore::Evas::shutdown();
	die "Could not create window.\n";
}

my $canvas = $window->evas_get();

my $edje = create_my_group($canvas,"");

if (!$edje) {
	pEFL::Ecore::Edje::shutdown();
	pEFL::Ecore::Evas::shutdown();
	exit -2;
}

$window->show();

pEFL::Ecore::Mainloop::begin();

$edje->del();
$window->free();
pEFL::Edje::shutdown();
pEFL::Ecore::Evas::shutdown();

exit 0;

sub create_my_group {
	my ($canvas,$text) = @_;
	
	my $edje = pEFL::Edje::Object->add($canvas);
	
	if (!$edje) {
		my $err = $edje_obj->load_error_get();
		my $errstr = pEFL::Edje::load_error_str($err);
		warn "Could not create edje object: $errstr\n";
		return undef;
	}
	
	if (!$edje->file_set("./example.edj","my_group")) {
		my $err = $edje_obj->load_error_get();
		my $errstr = pEFL::Edje::load_error_str($err);
		warn "Could not load 'my_group' from example.edj: $errstr\n";
		$edje->del();
		return undef;
	}
	
	$edje->move(0,0);
	$edje->resize($width,$height);
	$edje->show();
	
	return $edje;
}
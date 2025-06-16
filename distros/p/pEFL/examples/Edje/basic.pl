#! /usr/bin/perl
use strict;
use warnings;

use pEFL;
use pEFL::Ecore;
use pEFL::Ecore::Evas;
use pEFL::Evas;
use pEFL::Edje;

my $width = 300;
my $height = 300;
my $edje_file = "./basic.edj";
my $img_file = "./red.png";

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
$ee->title_set("Edje Basic Example");

my $evas = $ee->evas_get();

my $bg = pEFL::Evas::Rectangle->add($evas);
$bg->color_set(255,255,255,255); # White
$bg->move(0,0); # origin
$bg->resize($width,$height); # cover the window
$bg->show();
$ee->object_associate($bg, ECORE_EVAS_OBJECT_ASSOCIATE_BASE);

$bg->focus_set(1);

my $edje_obj = pEFL::Edje::Object->add($evas);

if (!$edje_obj->file_set($edje_file,"unexistent_group")) {
	# TODO: Implement EdjeError
	my $err = $edje_obj->load_error_get();
	my $errstr = pEFL::Edje::load_error_str($err);
	
	warn "Could not load unexistant_group from basic.edj: $errstr\n";
}

if (!$edje_obj->file_set($edje_file,"example_group")) {
	# TODO: Implement EdjeError
	my $err = $edje_obj->load_error_get();
	my $errstr = pEFL::Edje::load_error_str($err);
	
	warn "Could not load unexistant_group from basic.edj: $errstr\n";
	$edje_obj->del();
	pEFL::Ecore::Edje::shutdown();
	pEFL::Ecore::Evas::shutdown();
	
}

print "Loaded Edje object bound to group 'example_group' from " .
	"file basic.edj with success\n";
	
$edje_obj->move(20,20);
$edje_obj->resize($width-40,$height-40);
$edje_obj->show();

$bg->event_callback_add(EVAS_CALLBACK_KEY_DOWN,\&_on_keydown,$edje_obj);

# this is a border around the Edje object above, here just to
# emphasize its geometry
my $border = pEFL::Evas::Image->add($evas);
$border->filled_set(1);
$border->file_set($img_file,undef);
$border->border_set(2,2,2,2);
$border->border_center_fill_set(EVAS_BORDER_FILL_NONE);

$border->resize($width-40+4,$height-40+4);
$border->move(20-2,20-2);
$border->show();

# TODO
print "'example_data' data field in group 'example_group' has" .
	"the value " . $edje_obj->data_get("example_data") . "\n";

print "Testing if 'part_one' exists?\n";
$edje_obj->part_exists("part_one") ? print "yes!\n" : print "no\n";

my ($x,$y,$w,$h) = $edje_obj->part_geometry_get("part_one");
print "The geometry of that part is: x = $x, y = $y, w = $w, h = $h \n";

my $evas_obj = $edje_obj->part_object_get("part_one");
my ($r,$g,$b,$a) = $evas_obj->color_get();
print "That part's color components are is: r = $r, g = $g, b = $b, a = $a \n";

($w,$h) = $edje_obj->size_max_get();
print "The Edje object's max. size is: w = $w, h = $h \n";

($w,$h) = $edje_obj->size_min_get();
print "The Edje object's min. size is: w = $w, h = $h \n";

($w,$h) = $edje_obj->size_min_calc();
print "The Edje object's min. size reported by min. size " .
	"calculation is: w = $w, h = $h \n";

($w,$h) = $edje_obj->size_min_restricted_calc(500,500);
print "The Edje object's min. size reported by *restricted* min. size " .
	"calculation is: w = $w, h = $h \n";
	
($x,$y,$w,$h) = $edje_obj->parts_extends_calc();
print "The Edje object's *extended* geometry is: x = $x, y = $y, w = $w, h = $h \n";

$ee->show();

print_commands();

pEFL::Ecore::Mainloop::begin();

#$edje->del();
$ee->free();
pEFL::Ecore::Evas::shutdown();
pEFL::Edje::shutdown();

sub on_delete {
	pEFL::Ecore::Mainloop::quit();
}

sub print_commands {
	print "commands are:\n" .
		"\ts - change Edje's global scaling factor\n" .
		"\tr - change center rectangle's scaling factor\n" .
		"\tEsc - exit\n" .
		"\th - print help\n";
}

sub _on_keydown {
	my ($edje_obj, $evas,$o,$einfo) = @_;
	
	my $e = pEFL::ev_info2obj($einfo, "pEFL::Ecore::Event::Key");
	my $keyname = $e->keyname();
	
	if ($keyname eq "h") {
		print_commands();
	}
	elsif ($keyname eq "s") {
		my $scale = pEFL::Edje::scale_get();
		
		print "got scale $scale\n";
			
		$scale = $scale == 1.0 ? 2.0 : 1.0;
		
		pEFL::Edje::scale_set($scale);
		
		print "Setting global scaling factor to $scale\n";	
		
		return;
	}
	elsif ($keyname eq "r") {
		my $scale = $edje_obj->scale_get();
		
		print "got scale $scale\n";
		
		if ($scale == 0) {
			$scale = 1.0;
		} 
		elsif ($scale == 1.0) {
			$scale = 2.0;
		}
		else {
			$scale = 0;
		}
		
		$edje_obj->scale_set($scale);
		
		print "Setting center rectangle's scaling factor to $scale\n";	
		
		return;
	}
	elsif ($keyname eq "Escape") {
		pEFL::Ecore::Mainloop::quit();
	}
	else {
		print "Unhandled key\n";
		print_commands();
	}
	
}




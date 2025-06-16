#! /usr/bin/perl
use strict;
use warnings;

use pEFL;
use pEFL::Ecore;
use pEFL::Ecore::Evas;
use pEFL::Evas;
use pEFL::Edje;
use pEFL::Edje::Message::IntSet;
use pEFL::Edje::Message::String;
use pEFL::Edje::Message::StringSet;
use pEFL::Edje::Message::FloatSet;

my $width = 300;
my $height = 300;
my $right_rect_show = 1;
my $msg_color = 1;
my $msg_text = 2;
my $img_file = "./red.png";
my $edje_file = "./signals-messages.edj";


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
$ee->title_set("Edje Signals and Messages Example");

my $evas = $ee->evas_get();

my $bg = pEFL::Evas::Rectangle->add($evas);
$bg->color_set(255,255,255,255); # White bg
$bg->move(0,0); # at canvas' origin
$bg->resize($width,$height); # covers full canvas
$bg->show();
$bg->focus_set(1);
$ee->object_associate($bg, ECORE_EVAS_OBJECT_ASSOCIATE_BASE);

my $edje_obj = pEFL::Edje::Object->add($evas);

if (!$edje_obj->file_set($edje_file,"example_group")) {
	my $err = $edje_obj->load_error_get();
	my $errstr = pEFL::Edje::load_error_str($err);
	
	warn "Could not load 'example_group' from signals-messages.edj: $errstr\n";
	pEFL::Ecore::Edje::shutdown();
	pEFL::Ecore::Evas::shutdown();
}

$edje_obj->signal_callback_add("mouse,wheel,*","part_left",\&on_mouse_wheel,undef);
$edje_obj->signal_callback_add("mouse,over", "part_right", \&on_mouse_over,undef);
#$edje_obj->message_handler_set(\&_message_handle, undef);

$edje_obj->move(20,20);
$edje_obj->resize($width-40,$height-40);
$edje_obj->show();

#$bg->event_callback_add(EVAS_CALLBACK_KEY_DOWN, \&_on_keydown, $edje_obj);

# this is a border around the Edje object above, here just to
# emphasize its geometry
my $border = pEFL::Evas::Image->add($evas);
$border->filled_set(1);
$border->file_set($img_file,undef);
$border->border_set(2,2,2,2);
$border->border_center_fill_set(EVAS_BORDER_FILL_NONE);

$border->resize($width-40+4,$height-40+4);
$border->move(20-2,20-2);
$border->repeat_events_set(1);
$border->show();

print_commands();

$ee->show();

pEFL::Ecore::Mainloop::begin();

$ee->free();
pEFL::Ecore::Evas::shutdown();
pEFL::Edje::shutdown();

sub on_delete {
	pEFL::Ecore::Mainloop::quit();
}

sub on_mouse_wheel {
	my ($evas, $edje_object,$emission,$source) = @_;
	
	_sig_print($emission, $source);	
}
	
sub on_mouse_over {
	my ($evas, $edje_object,$emission,$source) = @_;

	_sig_print($emission,$source);
	
	my @vals = ( rand(256) % 256, rand(256) % 256, rand(256) % 256);
	my $msg = pEFL::Edje::Message::IntSet->new(@vals);
	
	my @colors = $msg->val();
	print "RGB @colors\n";
	
	my @str = ("Hello", "World", "from Perl");
	my $str_msg = pEFL::Edje::Message::StringSet->new(@str);
	my @strings = $str_msg->str();
	print "STRINGS @strings\n";
		
	my $dm = pEFL::Edje::Message::FloatSet->new(0.7,0.12,12.3,1222.3,123,45,48,49.5);
	my @doubles = $dm->val();
	print "DOUBLES @doubles\n";
	
	#my $sstr_msg = pEFL::Edje::Message::String->new("Hello World");
	#my $s = $sstr_msg->str();
	#print "STRING $s\n";
	
	$edje_obj->message_send(EDJE_MESSAGE_INT_SET,$msg_color,$msg);
}

sub _sig_print {
	my ($emission, $source) = @_;
	
	print "Signal $emission coming from part $source\n";
}
sub print_commands {
	print "commands are:\n" .
		"\tt - toggle right rectangle's visibility\n" .
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
	elsif ($keyname eq "t") {
		$right_rect_show = $right_rect_show ? 0 : 1;
		
		my $signal = $right_rect_show ? "part_right,show" : "part_right,hide";
		print "Emitting $signal\n";
		$edje_obj->signal_emit($signal,"");
	}
	elsif ($keyname eq "Escape") {
		pEFL::Ecore::Mainloop::quit();
	}
	else {
		print "Unhandled key\n";
		print_commands();
	}
}

sub _message_handle {
	my ($data,$obj,$type,$id,$msg) = @_;
	
	return if ($type != EDJE_MESSAGE_STRING);
	return if ($id != $msg_text);
	
	print "String message received " . $msg->str . "\n";
}
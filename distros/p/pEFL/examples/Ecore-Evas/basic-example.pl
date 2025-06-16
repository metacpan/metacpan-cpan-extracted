#! /usr/bin/perl
use strict;
use warnings;

use pEFL;
use pEFL::Ecore;
use pEFL::Ecore::Evas;
use pEFL::Evas;

if (pEFL::Ecore::Evas::init() <= 0) {
    exit 1;
}

# TODO: Enginges
my $ee = pEFL::Ecore::Evas->new( undef, 0,0,200,200,undef);
$ee->title_set("Ecore Evas basics Example");
$ee->show();

$ee->callback_delete_request_set(\&on_delete);
$ee->callback_show_set(\&on_show);
$ee->callback_hide_set(\&on_show);

my $canvas = $ee->evas_get();

my $bg = pEFL::Evas::Rectangle->add($canvas);
$bg->color_set(0,0,255,255);
$bg->resize(200,200);
$bg->show();

$bg->event_callback_add(EVAS_CALLBACK_MOUSE_DOWN, \&on_click, 123);
$bg->event_callback_add(EVAS_CALLBACK_MOUSE_UP, \&on_mouse_up, 123);
$bg->event_callback_add(EVAS_CALLBACK_MOUSE_MOVE, \&on_mouse_move, 123);

$ee->object_associate($bg,0);

pEFL::Ecore::Mainloop::begin();
$ee->free();
pEFL::Ecore::Evas::shutdown();

sub on_delete {
    my ($ee) = @_;
    pEFL::Ecore::Mainloop::quit();
}

sub on_show {
    my ($ee) = @_;
    my $canvas = $ee->evas_get();
    my ($w,$h) = $canvas->output_size_get();
    print "Showing/Hiding $w $h \n";
}

sub on_click {
	my ($data, $evas, $bg, $ev) = @_;
	print "\nMOUSE DOWN EVENT\n";
	my $pev = pEFL::ev_info2obj( $ev, "pEFL::Evas::Event::MouseDown");
	
	my $output = $pev->output();
	print "OUTPUT: $output->{x} $output->{y}\n";
	my $canvas = $pev->canvas();
	print "CANVAS: $canvas->{x} $canvas->{y}\n";
	my $button = $pev->button();
	print "BUTTON $button\n";
	
	my $mod = $pev->modifiers();
	# Control ist Str :-)
	my $control_set = $mod->key_modifier_is_set("Control");
	print "CONTROL_SET? $control_set\n";
	
	my $locks = $pev->locks();
	# Control ist Str :-)
	my $lock_set = $locks->key_lock_is_set("Caps_Lock");
	print "LOCK_SET? $lock_set\n";
	
	my $flags = $pev->flags();
	print "FLAGS $flags\n";
	
	my $ev_flags = $pev->event_flags();
	print "EVENT FLAGS $ev_flags\n";
	
	return 1;
	# TODO: event_src??? 
}

sub on_mouse_up {
	my ($data, $evas, $bg, $ev) = @_;
	print "\nMOUSE UP EVENT\n";
	my $pev = pEFL::ev_info2obj( $ev, "pEFL::Evas::Event::MouseUp");
	
	my $output = $pev->output();
	print "OUTPUT: $output->{x} $output->{y}\n";
	my $canvas = $pev->canvas();
	print "CANVAS: $canvas->{x} $canvas->{y}\n";
	my $button = $pev->button();
	print "BUTTON $button\n";
	
	my $mod = $pev->modifiers();
	# Control ist Str :-)
	my $control_set = $mod->key_modifier_is_set("Control");
	print "CONTROL_SET? $control_set\n";
	
	my $locks = $pev->locks();
	# Control ist Str :-)
	my $lock_set = $locks->key_lock_is_set("Caps_Lock");
	print "LOCK_SET? $lock_set\n";
	
	my $flags = $pev->flags();
	print "FLAGS $flags\n";
	
	my $ev_flags = $pev->event_flags();
	print "EVENT FLAGS $ev_flags\n";
	
	return 1;
	# TODO: event_src??? 
}

sub on_mouse_move {
	my ($data, $evas, $bg, $ev) = @_;
	print "\nMOUSE MOVE EVENT\n";
	my $pev = pEFL::ev_info2obj( $ev, "pEFL::Evas::Event::MouseMove");
	
	my $prev = $pev->prev();
	print "PREVIOUS POSITION\n";
	print "OUTPUT: $prev->{output}->{x} $prev->{output}->{y}\n";
	print "CANVAS: $prev->{canvas}->{x} $prev->{canvas}->{y}\n";
	
	my $cur = $pev->cur();
	print "CURRENT POSITION\n";
	print "OUTPUT: $cur->{output}->{x} $cur->{output}->{y}\n";
	print "CANVAS: $cur->{canvas}->{x} $cur->{canvas}->{y}\n";
	
	my $buttons = $pev->buttons();
	print "BUTTON $buttons\n";
	
	my $mod = $pev->modifiers();
	# Control ist Str :-)
	my $control_set = $mod->key_modifier_is_set("Control");
	print "CONTROL_SET $control_set\n";
	
	my $locks = $pev->locks();
	# Control ist Str :-)
	my $lock_set = $locks->key_lock_is_set("Caps_Lock");
	print "LOCK_SET $lock_set\n";
	
	my $ev_flags = $pev->event_flags();
	print "EVENT FLAGS $ev_flags\n";
	
	return 1;
	# TODO: event_src??? 
}

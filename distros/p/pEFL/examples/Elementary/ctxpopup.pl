#! /usr/bin/perl
use strict;
use warnings;

use pEFL::Evas;
use pEFL::Elm;

my $list_mouse_down = 0;

pEFL::Elm::init($#ARGV, \@ARGV);

pEFL::Elm::policy_set(ELM_POLICY_QUIT, ELM_POLICY_QUIT_LAST_WINDOW_CLOSED);

my $win = pEFL::Elm::Win->util_standard_add("hello", "Hello, World!");
$win->smart_callback_add("delete,request", \&_win_del, undef);
$win->autodel_set(1);

my $list = pEFL::Elm::List->add($win);
$list->event_callback_add(EVAS_CALLBACK_MOUSE_DOWN, \&_list_mouse_down);
$list->event_callback_add(EVAS_CALLBACK_MOUSE_UP, \&_list_mouse_up);
$list->size_hint_weight_set(EVAS_HINT_EXPAND, EVAS_HINT_EXPAND);
$win->resize_object_add($list);
$list->mode_set(ELM_LIST_COMPRESS);

$list->item_append("Ctxpopup with icons and labels", undef, undef, \&_list_item_cb, undef);

$list->item_append("Ctxpopup with icons only", undef, undef, \&_list_item_cb2, undef);

$list->show();
$list->go();

$win->resize(200,300);
$win->show();

pEFL::Elm::run();
pEFL::Elm::shutdown();

sub _dismissed_cb {
	my ($data, $obj, $ev) = @_;
	$obj->del();
}

sub _ctxpopup_item_cb {
	my ($data, $obj, $evinfo) = @_;
	my $selected = pEFL::ev_info2obj($evinfo, "pEFL::Elm::CtxpopupItem");
	print "ctxpopup item selected: " . $selected->text_get() . "\n";
}

sub item_new {
	my ($ctxpopup, $label, $icon) = @_;
	
	my $ic = pEFL::Elm::Icon->add($ctxpopup);
	$ic->standard_set($icon);
	$ic->resizable_set(0,0);
	
	return $ctxpopup->item_append($label, $ic, \&_ctxpopup_item_cb, undef);
}

sub _list_item_cb {
	my ($data, $obj, $ev_info) = @_;
	
	return if ($list_mouse_down > 0);
	
	my $ctxpopup = pEFL::Elm::Ctxpopup->add($obj);
	$ctxpopup->smart_callback_add("dismissed", \&_dismissed_cb, undef);
	
	item_new($ctxpopup, "Go to home folder", "home");
	item_new($ctxpopup, "Save file", "file");
   	item_new($ctxpopup, "Delete file", "delete");
   	my $it = item_new($ctxpopup, "Navigate to folder", "folder");
   	$it->disabled_set(1);
   	item_new($ctxpopup,"Edit entry", "edit");
   	my $it2 = item_new($ctxpopup,"Set date and time", "clock");
   	$it2->disabled_set(1);
   	
   	my $canvas = $obj->evas_get();
   	my ($x, $y) = $canvas->pointer_canvas_xy_get();
   	$ctxpopup->move($x,$y);
   	$ctxpopup->show();
   	
   	my $selected = pEFL::ev_info2obj($ev_info, "pEFL::Elm::ListItem");
   	$selected->selected_set(0);
}

sub _list_item_cb2 {
	my ($data, $obj, $ev_info) = @_;
	
	return if ($list_mouse_down > 0);
	
	my $ctxpopup = pEFL::Elm::Ctxpopup->add($obj);
	$ctxpopup->smart_callback_add("dismissed", \&_dismissed_cb, undef);
	
	item_new($ctxpopup,undef, "home");
	item_new($ctxpopup,undef, "file");
   	item_new($ctxpopup,undef, "delete");
   	item_new($ctxpopup,undef, "folder");
   	my $it = item_new($ctxpopup,undef, "edit");
   	$it->disabled_set(1);
   	my $it2 = item_new($ctxpopup,undef, "clock");
   	$it2->disabled_set(1);
   	
   	my $canvas = $obj->evas_get();
   	my ($x, $y) = $canvas->pointer_canvas_xy_get();
   	$ctxpopup->move($x,$y);
   	$ctxpopup->show();
   	
   	my $selected = pEFL::ev_info2obj($ev_info, "pEFL::Elm::ListItem");
   	$selected->selected_set(0);
}

sub _list_mouse_down {
	$list_mouse_down++
}

sub _list_mouse_up {
	$list_mouse_down--
}

sub _win_del {
	$list_mouse_down = 0;
}

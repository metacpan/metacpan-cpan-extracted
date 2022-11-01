#! /usr/bin/perl
use strict;
use warnings;

use pEFL::Evas;
use pEFL::Elm;

pEFL::Elm::init($#ARGV, \@ARGV);

pEFL::Elm::policy_set(ELM_POLICY_QUIT, ELM_POLICY_QUIT_LAST_WINDOW_CLOSED);

my $win = pEFL::Elm::Win->util_standard_add("Main", "Hello, World");

$win->autodel_set(1);

my $bg = pEFL::Elm::Bg->add($win);
$bg->size_hint_weight_set(EVAS_HINT_EXPAND, EVAS_HINT_EXPAND);
$bg->size_hint_align_set(EVAS_HINT_FILL, EVAS_HINT_FILL);
$win->resize_object_add($bg);
$bg->show();

my $bx = pEFL::Elm::Box->add($win);
$bx->size_hint_weight_set(EVAS_HINT_EXPAND, EVAS_HINT_EXPAND);
$win->resize_object_add($bx);
$bx->show();

my $combobox = pEFL::Elm::Combobox->add($win);
$combobox->size_hint_weight_set(EVAS_HINT_EXPAND,0);
$combobox->size_hint_align_set(EVAS_HINT_FILL,0);
$combobox->part_text_set("guide", "A simple list");
$bx->pack_end($combobox);
$combobox->show();

my $itc = pEFL::Elm::GenlistItemClass->new();
$itc->item_style("default");
$itc->text_get(\&_text_get);
$itc->state_get(\&_state_get);
# TODO: filter_get functionality not yet implemented
#$itc->filter_get(\&_filter_get);

my $i;
for ($i=0;$i< 10; $i++) {
	$combobox->item_append($itc,$i,undef,ELM_GENLIST_ITEM_NONE,undef,$i*10);
}

$combobox->smart_callback_add("clicked",\&_combobox_clicked_cb, undef);
$combobox->smart_callback_add("selected",\&_combobox_selected_cb, undef);
$combobox->smart_callback_add("dismissed",\&_combobox_dismissed_cb, undef);
$combobox->smart_callback_add("expanded",\&_combobox_expanded_cb, undef);
$combobox->smart_callback_add("item,pressed",\&_combobox_item_pressed_cb, undef);

$win->resize(300,500);
$win->show();


pEFL::Elm::run();

pEFL::Elm::shutdown();

sub del_cb {
}

sub _state_get {
    my ($data, $obj, $part) = @_;
    return 0;
}

sub _text_get {
    my ($data, $obj, $part) = @_;
 	return "Item # $data";
}

# TODO: Not implemented yet :-S
sub _filter_get {
	
}

sub _combobox_clicked_cb {
	my ($data,$obj,$event_info) = @_;
}

sub _combobox_selected_cb {
	my ($data,$obj,$event_info) = @_;
	my $item = pEFL::ev_info2obj($event_info, "ElmGenlistItemPtr");
	print "'selected' callback is called. (selected item : " . $item->text_get . ")\n";
}

sub _combobox_dismissed_cb {
	my ($data,$obj,$event_info) = @_;
}

sub _combobox_expanded_cb {
	my ($data,$obj,$event_info) = @_;
}

sub _combobox_item_pressed_cb {
	my ($data,$obj,$event_info) = @_;
	my $item = pEFL::ev_info2obj($event_info, "ElmGenlistItemPtr");
	my $text = $item->text_get();
	print "'item,pressed' callback is called. (selected item : $text)\n";
	$obj->text_set($text);
	$obj->hover_end();
}

sub _select_item {
    my ($data, $obj, $evInfo) = @_;
    my @arr = $obj->selected_items_get_pv();
    foreach my $item (@arr) {
        $item->del();
    }
    
}

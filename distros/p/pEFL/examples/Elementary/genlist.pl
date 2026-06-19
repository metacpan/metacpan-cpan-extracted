#! /usr/bin/perl
use strict;
use warnings;

use pEFL::Evas;
use pEFL::Elm;

pEFL::Elm::init($#ARGV, \@ARGV);

pEFL::Elm::policy_set(ELM_POLICY_QUIT, ELM_POLICY_QUIT_LAST_WINDOW_CLOSED);

my $win = pEFL::Elm::Win->util_standard_add("Main", "Hello, World");

$win->autodel_set(1);

$win->resize(400,400);

$win->smart_callback_add("delete,request",sub {print "Exiting \n"}, undef);


# Genlist
my $list = pEFL::Elm::Genlist->new($win);

$list->multi_select_set(1);
my $itc = pEFL::Elm::GenlistItemClass->new();
$itc->item_style("default");
$itc->text_get(\&_text_get);
$itc->content_get(\&_content_get);
$itc->del(\&del_cb);

my $item1 = $list->item_append($itc,123,undef,ELM_GENLIST_ITEM_NONE(),\&_select_item,123);

my $item2 = $list->item_prepend($itc,567,undef,ELM_GENLIST_ITEM_NONE(),undef,undef);
$list->insert_before($itc,111,undef,$item1,ELM_GENLIST_ITEM_NONE,undef,undef);
$list->insert_after($itc,444,undef,$item1,ELM_GENLIST_ITEM_NONE,undef,undef);
$list->item_prepend($itc,"000",undef,ELM_GENLIST_ITEM_NONE,undef,undef);

$list->size_hint_weight_set(EVAS_HINT_EXPAND,EVAS_HINT_EXPAND);
$win->resize_object_add($list);

my $i; 
for ($i= 1; $i < 11; $i++) {
	$list->item_append($itc,$i,undef,ELM_GENLIST_ITEM_NONE,undef,undef);
}

$list->show();

$win->show();


pEFL::Elm::run();

pEFL::Elm::shutdown();

sub del_cb {
	print "Delete item\n";
}

sub _text_get {
    my ($data, $obj, $part) = @_;
    return "Entry $data";
}

sub _content_get {
    my ($data, $obj, $part) = @_;
 	my $type = $obj->widget_type_get();
    my $icon = pEFL::Elm::Icon->add($obj);
    if ($part eq "elm.swallow.icon") {
        $icon->standard_set("clock");
    }
    $icon->size_hint_aspect_set(0.5, 1, 1);
    return $icon;
}

sub _select_item {
    my ($data, $obj, $evInfo) = @_;
    my @arr = $obj->selected_items_get_pv();
    foreach my $item (@arr) {
        $item->del();
    }
    
}

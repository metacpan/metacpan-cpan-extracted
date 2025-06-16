#! /usr/bin/perl
use strict;
use warnings;

use pEFL::Evas;
use pEFL::Elm;

pEFL::Elm::init($#ARGV, \@ARGV);

my $win = pEFL::Elm::Win->util_standard_add("hello", "Hello, World!");
$win->autodel_set(1);
pEFL::Elm::policy_set(ELM_POLICY_QUIT, ELM_POLICY_QUIT_LAST_WINDOW_CLOSED);

# TODO: rect

my $hoversel = pEFL::Elm::Hoversel->add($win);
$hoversel->hover_parent_set($win);
$hoversel->horizontal_set(0);
$hoversel->text_set("Add an item to Hoversel");
# elm_object_part_content_set(hoversel, "icon", rect);
$hoversel->item_add("Print items", undef, ELM_ICON_NONE, \&_print_items, 123);
$hoversel->item_add("Option 2", "home", ELM_ICON_STANDARD, undef, undef);
$hoversel->smart_callback_add("clicked", \&_add_item, undef);

$hoversel->resize(180, 30);
$hoversel->move(10, 10);
$hoversel->show();

$win->resize(200,300);
$win->show();

pEFL::Elm::run();
pEFL::Elm::shutdown();

sub _print_items {
    my ($data,$obj,$event_info) = @_;
    my @items = $obj->items_get_pv();
    foreach my $item (@items) {
    	print "Item with text " . $item->text_get() . "\n";
    }
}

sub _add_item {
    print "Add an item to Hoversel clicked. The example must be completed :-S :-D \n";
}

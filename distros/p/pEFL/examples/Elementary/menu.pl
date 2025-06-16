# Based on the Menu example under
# https://www.enlightenment.org/develop/legacy/api/c/start#tutorial_menu.html
#
#! /usr/bin/perl
use strict;
use warnings;

use pEFL::Evas;
use pEFL::Elm;

pEFL::Elm::init($#ARGV, \@ARGV);

my $win = pEFL::Elm::Win->util_standard_add("menu", "Menu");
$win->autodel_set(1);
pEFL::Elm::policy_set(ELM_POLICY_QUIT, ELM_POLICY_QUIT_LAST_WINDOW_CLOSED);

my $rect = pEFL::Evas::Rectangle->add($win->evas_get());
$win->resize_object_add($rect);
$rect->size_hint_min_set(0,0);
$rect->color_set(0,0,0,0);
$rect->show();

my $menu = pEFL::Elm::Menu->add($win);
$menu->item_add(undef, undef, "first item", \&select, 123);
my $menu_it = $menu->item_add(undef, "mail-reply-all","second item", undef,undef);

$menu->item_add($menu_it,"object-rotate-left","menu 1",undef,undef);
my $button = pEFL::Elm::Button->add($win);
$button->text_set("button - delete items");
my $menu_it1 = $menu->item_add($menu_it, undef,undef, undef, undef, undef);
$menu_it1->part_content_set("default", $button);
$button->smart_callback_add("clicked", \&_del_it, $menu);
$menu->item_separator_add($menu_it);
$menu->item_add($menu_it, undef, "third item", undef, undef);
$menu->item_add($menu_it, undef, "fourth item", undef, undef);
$menu->item_add($menu_it, "window-new", "sub menu", undef, undef);

my $menu_it2 = $menu->item_add(undef, undef, "third item", undef, undef);
$menu_it->disabled_set(1);

$rect->event_callback_add(EVAS_CALLBACK_MOUSE_DOWN,\&show,$menu);
#$menu->show();

$win->resize(250,350);
$win->show();

pEFL::Elm::run();
pEFL::Elm::shutdown();

sub _del_it {
    print "DEL CLICKED\n";
}

sub show {
    my ($menu, $evas,$obj, $evinfo) = @_;
    my $ev = pEFL::ev_info2obj($evinfo, "pEFL::Evas::Event::MouseDown");
    my $canvas = $ev->canvas();
    $menu->move($canvas->{x},$canvas->{y});
    $menu->show();
}

sub select {
    my ($data2,$e,$f ) = @_; print "SELECT $data2\n";
}

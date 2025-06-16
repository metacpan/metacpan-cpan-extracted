# Based on the Panes Tutorial
# see https://www.enlightenment.org/develop/legacy/tutorial/panes_tutorial
#
#! /usr/bin/perl
use strict;
use warnings;

use pEFL::Elm;
use pEFL::Evas;

my $size;

pEFL::Elm::init($#ARGV, \@ARGV);

pEFL::Elm::policy_set(ELM_POLICY_QUIT, ELM_POLICY_QUIT_LAST_WINDOW_CLOSED);

my $win = pEFL::Elm::Win->util_standard_add("hello", "Hello, World!");
$win->autodel_set(1);

# win 400x400
$win->resize(400,400);

my $panes = pEFL::Elm::Panes->add($win);
$panes->size_hint_weight_set(EVAS_HINT_EXPAND, EVAS_HINT_EXPAND);
$win->resize_object_add($panes);
$panes->show();

my $panes_h = pEFL::Elm::Panes->add($win);
$panes_h->horizontal_set(1);
$panes->part_content_set("left",$panes_h);

# Create a button object
my $bt = pEFL::Elm::Button->add($win);
$bt->text_set("Right");
$bt->size_hint_weight_set(EVAS_HINT_EXPAND,EVAS_HINT_EXPAND);
$bt->size_hint_align_set(EVAS_HINT_FILL, EVAS_HINT_FILL);
$bt->show();

$panes->part_content_set("right",$bt);

# Create an "Up" button
my $bt2 = pEFL::Elm::Button->add($win);
$bt2->text_set("Up");
$bt2->size_hint_weight_set(EVAS_HINT_EXPAND,EVAS_HINT_EXPAND);
$bt2->size_hint_align_set(EVAS_HINT_FILL, EVAS_HINT_FILL);
$bt2->show();

$panes_h->part_content_set("left",$bt2);

# Create a "Down" button
my $bt3 = pEFL::Elm::Button->add($win);
$bt3->text_set("Down");
$bt3->size_hint_weight_set(EVAS_HINT_EXPAND,EVAS_HINT_EXPAND);
$bt3->size_hint_align_set(EVAS_HINT_FILL, EVAS_HINT_FILL);
$bt3->show();

$panes_h->part_content_set("right",$bt3);

# Set the proportion of the panes to 80%
$panes->content_left_size_set(0.8);
$panes_h->content_left_size_set(0.8);

# panes callbacks
$panes->smart_callback_add("clicked", \&_clicked_cb, $panes);
$panes->smart_callback_add("press", \&_press_cb, $panes);
$panes->smart_callback_add("unpress", \&_unpress_cb, $panes);
$panes->smart_callback_add("clicked,double", \&_clicked_double_cb, $panes);

# panes_h callbacks
$panes_h->smart_callback_add("clicked", \&_clicked_cb, $panes_h);
$panes_h->smart_callback_add("press", \&_press_cb, $panes_h);
$panes_h->smart_callback_add("unpress", \&_unpress_cb, $panes_h);
$panes_h->smart_callback_add("clicked,double", \&_clicked_double_cb, $panes_h);

$win->show();

pEFL::Elm::run();

pEFL::Elm::shutdown();

sub _clicked_cb {
    print "Clicked\n";
}

sub _press_cb {
    print "Pressed\n";
}

sub _unpress_cb {
    print "Unpressed\n";
}

sub _clicked_double_cb {
    my ($data, $obj, $event_info) = @_;

    my $tmp_size = $obj->content_left_size_get();
    if ($tmp_size > 0) {
        $obj->content_left_size_set(0.0);
        print "Double clicked, hidden\n";
    }
    else {
        $obj->content_left_size_set($size);
        print "Double clicked, hidden\n";
    }
    $size = $tmp_size;
}

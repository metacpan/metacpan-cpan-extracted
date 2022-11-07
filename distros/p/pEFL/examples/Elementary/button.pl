# Based on the Basic tutorial code Basic Button
# see https://www.enlightenment.org/develop/legacy/tutorial/basic_tutorial
#
#! /usr/bin/perl
use strict;
use warnings;

use pEFL::Elm;
use pEFL::Evas;

my $count = 0;

pEFL::Elm::init($#ARGV, \@ARGV);

pEFL::Elm::policy_set(ELM_POLICY_QUIT, ELM_POLICY_QUIT_LAST_WINDOW_CLOSED);
my $win = pEFL::Elm::Win->util_standard_add("hello", "Hello, World!");
$win->autodel_set(1);

# win 400x400
$win->resize(400,400);

# basic tutorial code
# basic text button
my $button_text = pEFL::Elm::Button->new($win);

$button_text->text_set("Click me");

# how a container object should resize a given child within its area
$button_text->size_hint_weight_set(EVAS_HINT_EXPAND,EVAS_HINT_EXPAND);

# how to align an object
$button_text->size_hint_align_set(EVAS_HINT_FILL, 0.5);

$button_text->resize(100,30);
$button_text->show();

# Basic icon button
my $button_icon = pEFL::Elm::Button->add($win);
my $icon = pEFL::Elm::Icon->add($win);

# set the image file and the button as an icon
$icon->file_set("icon.png",undef);
$button_icon->part_content_set("icon",$icon);

$button_icon->size_hint_weight_set(1,1);
$button_icon->size_hint_align_set(-1, 0.5);

$button_icon->resize(100,30);
$button_icon->move(110,0);
$button_icon->show();

# Icon and text button
my $button_icon_text = pEFL::Elm::Button->add($win);
my $icon2 = pEFL::Elm::Icon->add($win);

# set the image file and the button as an icon
$icon2->file_set("icon.png",undef);
$button_icon_text->part_content_set("icon",$icon2);
$button_icon_text->text_set("Press me");

$button_icon_text->size_hint_weight_set(1,1);
$button_icon_text->size_hint_align_set(-1, 0.5);

$button_icon_text->resize(100,30);
$button_icon_text->move(210,0);
$button_icon_text->show();

# Click event
$button_text->smart_callback_add("clicked", \&_button_click_cb, undef);

# Press event
$button_icon->smart_callback_add("pressed", \&_button_press_cb, undef);
# Unpress event
$button_icon->smart_callback_add("unpressed", \&_button_unpress_cb, undef);

# Get whether the autorepeat feature is enabled.
$button_icon_text->autorepeat_set(1);
# Set the initial timeout before the autorepeat event is generated.
$button_icon_text->autorepeat_initial_timeout_set(1.0);
# gap between two callbacks
$button_icon_text->autorepeat_gap_timeout_set(0.5);
# "repeated": the user pressed the button without releasing it
$button_icon_text->smart_callback_add("repeated", \&_button_repeat_cb, undef);

$win->show();

pEFL::Elm::run();
pEFL::Elm::shutdown();

sub _button_click_cb {
	my ($data, $button, $event_info) = @_;
	print "Clicked\n";
	$button->text_set("Clicked!");
}

sub _button_press_cb {
	my ($data, $button, $event_info) = @_;
	 $button->text_set("Pressed!");
}

sub _button_unpress_cb {
	my ($data,$button, $event_info) = @_;
	$button->text_set("Unpressed!");
}

sub _button_repeat_cb {
	my ($data, $button, $event_info) = @_;
	$count++;
	$button->text_set("Repeat $count!");
}

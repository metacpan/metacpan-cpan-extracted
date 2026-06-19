# Based on the Popup Tutorial
# see https://www.enlightenment.org/develop/legacy/tutorial/popup_tutorial
#
#! /usr/bin/perl
use strict;
use warnings;

use pEFL::Elm;

my $size;

pEFL::Elm::init($#ARGV, \@ARGV);

pEFL::Elm::policy_set(ELM_POLICY_QUIT, ELM_POLICY_QUIT_LAST_WINDOW_CLOSED);

my $win = pEFL::Elm::Win->util_standard_add("hello", "Hello, World!");
$win->autodel_set(1);

# win 400x400
$win->resize(400,400);

my $btn = pEFL::Elm::Button->add($win);
$btn->text_set("popup");
$btn->resize(100,50);
$btn->move(150,150);
$btn->show();
$btn->smart_callback_add("clicked", \&_btn_click_cb,$win);

$win->show();

pEFL::Elm::run();

pEFL::Elm::shutdown();

sub _popup_close_cb {
	my ($popup, $obj, $evinfo) = @_;
	
	$popup->del();
}

sub _btn_click_cb {
	my ($data, $obj, $evinfo) = @_;
	
	# Add an elm popup
	my $popup = pEFL::Elm::Popup->add($data);
	$popup->text_set("This popup has content area and action area set, action area has one button Close");
	
	# popup buttons
	my $btn = pEFL::Elm::Button->add($popup);
	$btn->text_set("Close");
	$popup->part_content_set("button1",$btn);
	$btn->smart_callback_add("clicked",\&_popup_close_cb,$popup);
	
	# popup show should be called after adding all the contents and the buttons
    # of popup to set the focus into popup's contents correctly.
	$popup->show();
}
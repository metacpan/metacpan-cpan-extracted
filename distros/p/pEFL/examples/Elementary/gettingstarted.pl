# Based on the Getting started example
# see https://www.enlightenment.org/develop/efl/start
#
#! /usr/bin/perl
use strict;
use warnings;

use pEFL::Elm;

pEFL::Elm::init($#ARGV, \@ARGV);

pEFL::Elm::policy_set(ELM_POLICY_QUIT, ELM_POLICY_QUIT_LAST_WINDOW_CLOSED);

my $win = pEFL::Elm::Win->util_standard_add("hello", "Hello");
$win->smart_callback_add("delete,request",\&on_done, undef);

my $box = pEFL::Elm::Box->add($win);
$box->horizontal_set(1);
$win->resize_object_add($box);
$box->show();

my $lab = pEFL::Elm::Label->add($win);
$lab->text_set("Hello out there, World\n");
$box->pack_end($lab);
$lab->show();

my $btn = pEFL::Elm::Button->add($win);
$btn->text_set("OK");
$box->pack_end($btn);
$btn->show();
$btn->smart_callback_add("clicked", \&on_done, undef);

$win->show();

pEFL::Elm::run();

pEFL::Elm::shutdown();

sub on_done {
    print "Exiting \n";
    pEFL::Elm::exit();
}

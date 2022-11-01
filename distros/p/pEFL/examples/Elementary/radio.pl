#! /usr/bin/perl
use strict;
use warnings;

use pEFL::Elm;

pEFL::Elm::init($#ARGV, \@ARGV);

pEFL::Elm::policy_set(ELM_POLICY_QUIT, ELM_POLICY_QUIT_LAST_WINDOW_CLOSED);

my $win = pEFL::Elm::Win->util_standard_add("Radio", "Radio Example");
$win->autodel_set(1);

# win 400x400
$win->resize(400,400);

my $box = pEFL::Elm::Box->add($win);
$box->show();

my $radio = pEFL::Elm::Radio->add($box);
$radio->text_set("Radio 1");
$radio->state_value_set(1);
$radio->show();
$box->pack_end($radio);

my $radio2 = pEFL::Elm::Radio->add($box);
$radio2->text_set("Radio 2");
$radio2->state_value_set(2);
$radio2->show();
$box->pack_end($radio2);

$radio2->group_add($radio);

my $radio3 = pEFL::Elm::Radio->add($box);
$radio3->text_set("Radio 3");
$radio3->state_value_set(3);
$radio3->show();
$box->pack_end($radio3);
$radio3->group_add($radio);

$radio->value_set(2);

$win->show();

pEFL::Elm::run();

#print "Exiting ...\n";
pEFL::Elm::shutdown();

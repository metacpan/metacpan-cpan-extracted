# Based on the Basic tutorial code
# see https://www.enlightenment.org/develop/legacy/tutorial/basic_tutorial
#
#! /usr/bin/perl
use strict;
use warnings;

use pEFL::Elm;

pEFL::Elm::init($#ARGV, \@ARGV);

pEFL::Elm::policy_set(ELM_POLICY_QUIT, ELM_POLICY_QUIT_LAST_WINDOW_CLOSED);

my $win = pEFL::Elm::Win->util_standard_add("Main", "Hello, World");
$win->autodel_set(1);
# win 400x400
$win->resize(400,400);

$win->smart_callback_add("delete,request",sub {print "Exiting \n"}, undef);

$win->show();

pEFL::Elm::run();

pEFL::Elm::shutdown();

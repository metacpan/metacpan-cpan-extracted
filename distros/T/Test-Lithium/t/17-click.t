#!/usr/bin/perl

use strict;
use warnings;
use Test::More;
use t::common;

my $site = start_depends;

start_webdriver sel_conf(site => $site);

{
	# Test getting and setting input values
	isnt_visible "div#_div_test_a";
	click "a#_test_a";
	until_visible "div#_div_test_a";
	is text("div#_div_test_a"), "You clicked on the link! Good on you";
}

stop_depends;
done_testing;

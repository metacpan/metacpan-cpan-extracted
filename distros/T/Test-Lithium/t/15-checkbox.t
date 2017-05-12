#!/usr/bin/perl

use strict;
use warnings;
use Test::More;
use t::common;


my $site = start_depends;

start_webdriver sel_conf(site => $site);

{
	# Test checking and unchecking checkboxes
	resize() if is_phantom;   # Set the screen size to 1920x1080
	maximize(); # Make sure its been maxed, redundent given how phantom works

	check("input[type='checkbox']");
	uncheck("input[type='checkbox']");
}

stop_depends;
done_testing;

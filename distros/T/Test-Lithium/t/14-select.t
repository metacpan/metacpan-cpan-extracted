#!/usr/bin/perl

use strict;
use warnings;
use Test::More;
use Test::Deep qw/!set !any/;
use t::common;


my $site = start_depends;

start_webdriver sel_conf(site => $site);

{
	# Test getting and selecting dropdown options
	resize() if is_phantom; # Set the screen size to 1920x1080
	maximize(); # Make sure its been maxed, redundent given how phantom works

	is_visible("select");
	cmp_bag([dropdown_options("select")],
		['Label 1','Label 2','Label 3'],
		"Ensuring the labels/text is correct for dropdown with default method");
	cmp_bag([dropdown_options("select", data => "value")],
		['val 1','val 2','val 3'],
		"Ensuring the values are correct for the dropdown with value method");
	cmp_bag([dropdown_options("select", data => "label")],
		['Label 1','Label 2','Label 3'],
		"Ensuring the labels/text is correct for dropdown with label method");

	is(value("select"), 'val 1', "Defaults to first value");
	dropdown("select", "Label 3");
	is(value("select"), "val 3", "Ensuring select by label gets third value");
	dropdown("select", "val 2", method => "value");
	is(value("select"), 'val 2', "Ensure picking by value");
	dropdown("select", "Label 1", method => "label");
	is(value("select"), "val 1", "Ensuring select by label gets third value");
}

stop_depends;
done_testing;

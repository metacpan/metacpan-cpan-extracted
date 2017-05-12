#!/usr/bin/perl

use strict;
use warnings;
use Test::More;
use t::common;


my $site = start_depends;

start_webdriver sel_conf(site => $site);

resize() if is_phantom;   # Set the screen size to 1920x1080
maximize(); # Make sure its been maxed, redundent given how phantom works

subtest "Getting and Setting input values", sub {
	# Test getting and setting input values
	is(value("input._value"), "val 1", "Check for prefilled input value");
	is(attribute("input._placeholder", 'placeholder'), "test?", "Esure getting other attributes work");

	type("input._placeholder", "TEST TEXT", "Set text in input value");
	is(value("input._placeholder"), "TEST TEXT", "Ensure typed text matches");
};

subtest "value() sanity checking", sub {
	is value("div#get_val input.empty"), '',
		"Empty element returns empty string for value()";
	is value("div#get_val input.whitespace"), ' ',
		"Whitespace only element returns correct string for value()";
	is value("div#get_val input.full"), "myVal",
		"value() returns correct string when data is present";
};

stop_depends;
done_testing;

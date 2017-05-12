#!/usr/bin/perl

use strict;
use warnings;
use Test::More;
use t::common;

my $site = start_depends;

start_webdriver sel_conf(site => $site);

subtest "Basic text checking on /" => sub {
	# Test getting and setting input values
	resize() if is_phantom;   # Set the screen size to 1920x1080
	maximize(); # Make sure its been maxed, redundent given how phantom works
	is(text("p#test_text"), "Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor"
		." incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation"
		." ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit"
		." in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat"
		." non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.");
};

subtest "text() sanity checking", sub {
	visit '/';
	is text("div#get_text p.empty"), '',
		"Empty element returns empty string for text()";
	is text("div#get_text p.whitespace"), ' ',
		"Whitespace only element returns correct string for text()";
	is text("div#get_text p.full"), "There's data in them thar P tags",
		"text() returns correct string when data is present";
};

subtest "More advanced counter testing on /p_tag" => sub {
	# Test getting and setting input values
	visit '/p_tag';
	is(text('p'), "this is text and some more and now the end", "Getting text by p tag");
	is(text('.p_test'), "this is text and some more and now the end", "Getting text by class only");
	click "#_adder";
	is(text('.p_test'), "this is text 1 and now the end", "Getting text by class after updating it");
	click "#_creator";
	is(text('._p_'),
		"New text begins Spanner Text Speak for those that cannot",
		"Ensure new p tag has the entire text");
};

subtest "Html text on /p_tag" => sub {
	# Test getting and setting input values
	visit '/p_tag';
	click "#_creator";
	is(html('._p_'),
		'New text begins <span id="_span_man">Spanner Text </span>Speak for those that cannot',
		"Ensure new p tag has the entire text");
};

subtest "html() sanity checking", sub {
	visit '/';
	is html("div#get_html div.empty"), '',
		"Empty element returns empty string for html()";
	is html("div#get_html div.full"), "<div>&nbsp;</div>",
		"html() returns correct string when data is present";
};

stop_depends;
done_testing;

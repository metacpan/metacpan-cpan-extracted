#!/usr/bin/perl

use strict;
use warnings;
use Test::More;
use t::common;

plan skip_all => "Selenium has not implemented /frame support"
	unless is_phantom;

my $site = start_depends;

start_webdriver sel_conf(site => $site);

{ # Simple context switch
	visit "/iframe";
	isnt_present("#i0-0", "This should fail without context switching");
	focus_frame('#main-0', "Focusing frame to 0");
	is(text('#i0-0'), "Hello there", "Found text of frame");
	focus_frame("default", "Reseting to main frame/window");
}

{ # do some more, with nesting
	visit "/iframe";
	isnt_present("#i0-0", "This should fail without context switching");
	focus_frame('#main-0', "Focusing frame to 0");
	is(text('#i0-0'), "Hello there", "Get the text of the first nested frame");
	focus_frame('#i0-1', "Focusing frame to 2");
	is(text('#i2-0'), "Goodday Sir", "Get the text of the second nested frame");
	focus_frame("default", "Reseting to main frame/window");
}

{ # travese parent to go to siblings
	visit "/iframe";
	is_present("#main-1", "If we focus on a frame the siblings are findable");
	focus_frame('#main-0', "Focusing frame to 0");
	isnt_present("#main-1", "If we focus on a frame the siblings are findable");
	focus_frame("default", "Reseting to main frame/window");
}

{ # travese parent to go to siblings
	visit "/iframe";
	focus_frame('#main-1', "Focus the frame to the first iframe");
	is(text('#texter'), 'placeholder', 'Initial div text');
	click('form.click_test button');
	click('div#btn-div');
	is(text('#texter'), 'New Text', 'Clicked text changed');
	is(text('#btn-div-txt'), 'New Div Text', 'Div text changed');
	focus_frame("default", "Reseting to main frame/window");
	# verify the js works
	visit '/iframe1';
	click('form.click_test button');
	click('#btn-div');
	is(text('#texter'), 'New Text', 'Clicked text changed');
	is(text('#btn-div-txt'), 'New Div Text', 'Div text changed');

}

{ # Dynamically load an iframe and verify its location
	visit "/frame_location";
	my ($x, $y) = location 'div#loader', 200, 200;
	location "#frame", $x, $y;
	focus_frame('#frame', "Focus the frame to the first iframe");

	is(text('#texter'), 'placeholder', 'Initial div text');
	click('form.click_test button');
	click('div#btn-div');

	is(text('#texter'), 'New Text', 'Clicked text changed');
	is(text('#btn-div-txt'), 'New Div Text', 'Div text changed');
	focus_frame("default", "Reseting to main frame/window");
}

stop_depends;
done_testing;

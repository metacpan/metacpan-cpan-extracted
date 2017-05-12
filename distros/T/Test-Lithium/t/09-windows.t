#!/usr/bin/perl

use strict;
use warnings;
use Test::More;
use t::common;


my $site = start_depends;


# Check to make sure visit works
{
	start_webdriver sel_conf(site => $site);
	is address_bar(), "$site", "The address bar should be: $site";
	visit '/test3';
	is address_bar(), "${site}test3", "The address bar should be: ${site}test3";
	is title(), 'webdriver test 3', "Ensure the title is correct";
	stop_webdriver;
}

# Slowness is from waiting for the page to load everytime window_titles is called
{
	start_webdriver sel_conf(site => $site);
	click "a#_test2";
	my $titles = window_titles;
	is $titles->[-1], "webdriver test 2",   "webdriver 2 should be the last window";
	click "a#_test3";
	$titles = window_titles;
	is $titles->[-1], "webdriver test 3", "webdriver 3 should be the last window";
	stop_webdriver;
}

# yes this was an issue and yes this helped me solve it
{
	start_webdriver sel_conf(site => $site);
	strict_window_updates;
	click "a#_test1";
	click "a#_test2";
	click "a#_test3";
	my $titles = window_titles;
	is $titles->[1], "webdriver test",  "test 1 should be the second window";
	is $titles->[2], "webdriver test 2",   "test 2 should be the third window";
	is $titles->[3], "webdriver test 3", "test 3 should be the last window";
	stop_webdriver
}

{
	start_webdriver sel_conf(site => $site);
	click "a#_test1";
	click "a#_test2";
	click "a#_test3";
	my $titles = window_titles;
	new_window("http://www.google.com");
	$titles = window_titles;
	is $titles->[-1], "Google", "google should now be the last window";
	stop_webdriver;
}
{
	start_webdriver sel_conf(site => $site);
	strict_window_updates;
	click "a#_test1";
	click "a#_test2";
	click "a#_test3";
	new_window("http://www.google.com");
	my $titles = window_titles;
	is $titles->[1], "webdriver test", "test 1 should be the second window";
	is $titles->[-1], "Google", "google should now be the last window";
	stop_webdriver;
}

{
	start_webdriver sel_conf(site => $site);
	click "a#_test1";
	click "a#_test2";
	click "a#_test3";
	new_window("http://www.google.com", 'google', "Auto select the last window", 5 );
	like title, qr/google/i, 'Auto select last window opened';
	stop_webdriver;
}

stop_depends;
done_testing;

#!/usr/bin/perl

use strict;
use warnings;
use Test::More;
use t::common;
use Time::HiRes;
use Data::Dumper;

plan skip_all => "Timing/alarming tests don't work well with automated testing outside of phantom"
	unless is_phantom;

my $site = start_depends;

start_webdriver sel_conf(site => $site);

# Slowness is from waiting for the page to load everytime window_titles is called
{
	my $tim = time;
	isnt_present("div#DNE", "Should come back immediately on missing element on isnt_present");
	$tim = time - $tim;
	ok( $tim <= 1, "Time taken should be more than 1 seconds");
	is_present "#_that_guy";
	click "#_murder";
	$tim = time;
	until_not_present("#_that_guy", 7, "Wait until that guy is deleted");
	$tim = time - $tim;
	note("Time taken is: $tim (s)");
	ok( $tim >= 2 && $tim <=3, "Time taken should be atleast 2 seconds");
	$tim = time;
	isnt_visible "#_div_test_a", "Div isn't visible yet";
	$tim = time - $tim;
	ok( $tim <= 1, "Time taken should be more than 1 seconds");
	click "#_test_a";
	$tim = time;
	until_visible "#_div_test_a", 3, "Div should be visible after 2 seconds, and timeout is 4";
	$tim = time - $tim;
	ok( $tim >= 2 && $tim <= 4, "Time should be between 2 and 4 seconds");
	note("Time take was: $tim (s)");
	click "#_test_a";
	$tim = time;
	until_not_visible "#_div_test_a", 3, "Div should be invisble after 2 seconds";
	$tim = time - $tim;
	ok( $tim >= 2 && $tim <= 4, "Time should be between 2 and 4 seconds");
	note("Time take was: $tim (s)");
}

stop_depends;
done_testing;

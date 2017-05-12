#!/usr/bin/perl

use strict;
use warnings;
use Test::More;
use t::common;

my $site = start_depends;

start_webdriver sel_conf(site => $site);

{
	# Test getting and setting input values
	my $exists = runjs("return (function is_frameworked () {
		try {
			if (typeof(window) !== 'undefined') {
				return 1;
			} else {
				return 0;
			}
		} catch(err) {
				return 0;
		}
	})();", "Running simulation of freeze tester");
	ok($exists, "The window var should exist");
}

stop_depends;
done_testing;

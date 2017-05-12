#!/usr/bin/perl

use strict;
use warnings;
use Test::More;
use t::common;

plan skip_all => "We only test UA changes against phantom" unless is_phantom;

my $site = start_depends;

# Test defaults
{
	start_webdriver sel_conf(site => $site);
	like(runjs("return navigator.userAgent;"),
		qr/^Mozilla\/5\.0\s+\(Unknown; Linux x86_64\)\s+AppleWebKit\/\d+\.\d+\s+\(KHTML,\s+like\s+Gecko\)\s+PhantomJS\/\d\.\d\.\d\s+Safari\/\d+\.\d+$/,
		"Ensure the default user-agent for phantom is phantom");
	stop_webdriver();
}


# Be able to set UA to Firefox
{
	start_webdriver sel_conf(site => $site, ua => 'linux firefox');
	is(runjs("return navigator.userAgent;"),
		"Mozilla/5.0 (X11; Linux x86_64; rv:29.0) Gecko/20100101 Firefox/29.0",
		"Ensure the default user-agent is settable to Firefox");

	stop_webdriver();
}


# Be able to set UA to Chrome
{
	start_webdriver sel_conf(site => $site, ua => 'linux chrome');
	is(runjs("return navigator.userAgent;"),
		"Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/31.0.1650.26 Safari/537.36",
		"Ensure the default user-agent is settable to Firefox");

	stop_webdriver();
}


# Be able to set UA to Android
{
	start_webdriver sel_conf(site => $site, ua => 'android default');
	is(runjs("return navigator.userAgent;"),
		"Mozilla/5.0 (Linux; U; Android 4.0.3; de-de; Galaxy S II Build/GRJ22) AppleWebKit/534.30 (KHTML, like Gecko) Version/4.0 Mobile Safari/534.30",
		"Ensure the default user-agent is settable to an Android UA");

	stop_webdriver();
}


# Be able to set UA to Android Firefox
{
	start_webdriver sel_conf(site => $site, ua => 'android firefox');
	is(runjs("return navigator.userAgent;"),
		"Mozilla/5.0 (Android; Mobile; rv:29.0) Gecko/29.0 Firefox/29.0",
		"Ensure the default user-agent is settable to an Android UA");

	stop_webdriver();
}


# Be able to set UA to Iphone
{
	start_webdriver sel_conf(site => $site, ua => 'apple iphone');
	is(runjs("return navigator.userAgent;"),
		"Mozilla/5.0 (iPhone; U; CPU iPhone OS 4_2_1 like Mac OS X; da-dk) AppleWebKit/533.17.9 (KHTML, like Gecko) Version/5.0.2 Mobile/8C148 Safari/6533.18.5",
		"Ensure the default user-agent is settable to an Iphone UA");

	stop_webdriver();
}


# Be able to set UA to ipad
{
	start_webdriver sel_conf(site => $site, ua => 'Apple Ipad');
	is(runjs("return navigator.userAgent;"),
		"Mozilla/5.0 (iPad; CPU OS 6_0 like Mac OS X) AppleWebKit/536.26 (KHTML, like Gecko) Version/6.0 Mobile/10A5355d Safari/8536.25",
		"Ensure the default user-agent is settable to an Ipad UA");

	stop_webdriver();
}


# Default to phantom on bad ua
{
	start_webdriver sel_conf(site => $site, ua => 'bad');
	like(runjs("return navigator.userAgent;"),
		qr/^Mozilla\/5\.0\s+\(Unknown; Linux x86_64\)\s+AppleWebKit\/\d+\.\d+\s+\(KHTML,\s+like\s+Gecko\)\s+PhantomJS\/\d\.\d\.\d\s+Safari\/\d+\.\d+$/,
		"Ensure the default user-agent is settable to phantom on bad ua");

	stop_webdriver();
}


# Set ua should stay same on target="_blank"
{
	start_webdriver sel_conf(site => $site, ua => 'Linux - Firefox');
	is(runjs("return navigator.userAgent;"),
		"Mozilla/5.0 (X11; Linux x86_64; rv:29.0) Gecko/20100101 Firefox/29.0",
		"Ensure the user-agent is firefox");
	click('a#_test2');
	focus_window(title => "webdriver test 2");

	my $ua = runjs("return navigator.userAgent;");
	TODO: {
		local $TODO = "Bug in ghostdriver see:"
			." https://github.com/detro/ghostdriver/issues/273"
			." for more information";
		is($ua, "Mozilla/5.0 (X11; Linux x86_64; rv:29.0) Gecko/20100101 Firefox/29.0",
			"Ensure new window user-agent is firefox on target='_blank'");
	}
	stop_webdriver();
}


# Set ua should stay same on new_window creation
{
	start_webdriver sel_conf(site => $site, ua => 'Linux - Firefox');
	is(runjs("return navigator.userAgent;"),
		"Mozilla/5.0 (X11; Linux x86_64; rv:29.0) Gecko/20100101 Firefox/29.0",
		"Ensure the user-agent is firefox");
	new_window("http://www.google.com");
	focus_window(title => "google");

	my $ua = runjs("return navigator.userAgent;");
	TODO: {
		local $TODO = "Bug in ghostdriver see:"
			." https://github.com/detro/ghostdriver/issues/273"
			." for more information";
		is($ua, "Mozilla/5.0 (X11; Linux x86_64; rv:29.0) Gecko/20100101 Firefox/29.0",
			"Ensure new window user-agent is firefox on framework new_window call");
	}
	stop_webdriver();
}


stop_depends;
done_testing;

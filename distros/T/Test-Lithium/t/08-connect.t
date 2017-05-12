use strict;
use warnings;
use Test::More;
use t::common;


my $site = start_depends;

start_webdriver sel_conf(site => $site);
sleep 1;
is(title(), "webdriver test",
	"Ensure title is correct to ensure we are on the right page");

stop_depends;
done_testing;

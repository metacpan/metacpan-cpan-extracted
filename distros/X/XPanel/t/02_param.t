#!/usr/bin/perl -w

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 3;

require XPanel;
ok(1);

my $xpanel = new XPanel();
ok($xpanel);

ok($xpanel->{'language'} eq 'en-US');

exit(0);
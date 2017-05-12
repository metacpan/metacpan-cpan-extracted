#!/usr/bin/perl

# Simple example for using Nicola Worthington's WWW::Comic module to fetch
# the latest XKCD comic from www.xkcd.org
#
# $Id: example.pl 328 2008-04-04 23:15:10Z davidp $

use strict;
use WWW::Comic;


my $wc = new WWW::Comic;

my $strip_url = $wc->strip_url( comic => 'xkcd' );

print "Strip is at $strip_url\n";

my $filename = $wc->mirror_strip( comic => 'xkcd' );

print "Saved to $filename\n";


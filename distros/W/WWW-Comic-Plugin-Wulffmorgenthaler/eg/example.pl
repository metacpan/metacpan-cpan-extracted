#!/usr/bin/perl

# Simple example for using Nicola Worthington's WWW::Comic module to fetch
# the latest Wulffmorgenthaler comic from www.wulffmorgenthaler.com
#
# $Id: example.pl 430 2008-08-25 22:24:11Z davidp $

use strict;
use WWW::Comic;


my $wc = new WWW::Comic;

my $strip_url = $wc->strip_url( comic => 'wulffmorgenthaler' );

print "Strip is at $strip_url\n";

my $filename = $wc->mirror_strip( comic => 'wulffmorgenthaler' );

print "Saved to $filename\n";


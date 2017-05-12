#!/usr/bin/perl

# Simple example for using Nicola Worthington's WWW::Comic module to fetch
# the latest f8d comic from www.f8d.org
#
# $Id: example.pl 339 2008-05-09 23:35:59Z davidp $

use strict;
use WWW::Comic;


my $wc = new WWW::Comic;

my $strip_url = $wc->strip_url( comic => 'f8d' );

print "Strip is at $strip_url\n";

my $filename = $wc->mirror_strip( comic => 'f8d' );

print "Saved to $filename\n";


#!/usr/bin/perl

# Simple example for using Nicola Worthington's WWW::Comic module to fetch
# the latest Cyanide and Happiness strip
#
# $Id: example.pl 326 2008-04-04 22:28:44Z davidp $

use strict;
use WWW::Comic;


my $wc = new WWW::Comic;

my $strip_url = $wc->strip_url( comic => 'cyanideandhappiness' );

print "Strip is at $strip_url\n";

my $filename = $wc->mirror_strip( comic => 'cyanideandhappiness' );

print "Saved to $filename\n";


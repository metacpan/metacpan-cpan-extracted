#!/usr/bin/perl

# Simple example for using Nicola Worthington's WWW::Comic module to fetch
# the latest LeastICouldDo comic from www.leasticoulddo.com
#
# $Id: example.pl 384 2008-06-26 14:11:47Z davidp $

use strict;
use WWW::Comic;


my $wc = new WWW::Comic;

my $strip_url = $wc->strip_url( comic => 'licd' );

print "Strip is at $strip_url\n";

my $filename = $wc->mirror_strip( comic => 'leasticoulddo' );

print "Saved to $filename\n";


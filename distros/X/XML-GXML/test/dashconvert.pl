#!/usr/bin/perl

# GXML test suite - dashconvert.pl
# by Josh Carter <josh@multipart-mixed.com>
#
# Checks to make sure dash conversion is working. Should take "--" and
# make them into XML em-dashes.

use strict;
use XML::GXML;

my $xml = '<basetag>hi there -- this has a dash</basetag>';

print "before:\n";
print $xml;

print "\nafter with dashconvert:\n";
my $gxml = new XML::GXML({'dashConvert' => 'on'});
print $gxml->Process($xml);

print "\nafter without dashconvert:\n";
$gxml = new XML::GXML();
print $gxml->Process($xml);

print "\n";

exit;


#!/usr/bin/perl

# GXML test suite - collector.pl
# by Josh Carter <josh@multipart-mixed.com>
#
# Tests the AttributeCollector class by collecting stuff from
# collector.xml test file. It should collect the name and quest of
# each "collectme" element, and store these in a hash by the name tag
# of each element.

use strict;
use XML::GXML;

my $collector = new XML::GXML::AttributeCollector('collectme', 'name', 
											 ['quest', 'color']);

$collector->CollectFromFile('collector.xml');

foreach my $item (keys %$collector)
{
	next if $item =~ /^_/; # skip private vars

	print "$item:\n";
	print "- quest: " . $collector->{$item}->{'quest'} . "\n";
	print "- color: " . $collector->{$item}->{'color'} . "\n";
}

$collector->Clear();

print "\ndone!\n";

exit;

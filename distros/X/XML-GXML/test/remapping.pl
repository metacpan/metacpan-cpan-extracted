#!/usr/bin/perl

# GXML test suite - remapping.pl
# by Josh Carter <josh@multipart-mixed.com>
#
# Tests remappings. "thing" tags should get mapped into "remapped."

use strict;
use XML::GXML;

my $xml = '<basetag><thing name="hi">hi there</thing></basetag>';
my %remappings = ( 'thing' => 'remapped' );

my $gxml = new XML::GXML({'remappings' => \%remappings});

print "before:\n";
print $xml;
print "\nafter:\n";
print $gxml->Process($xml);
print "\n";

exit;

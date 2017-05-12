#!/usr/bin/perl -w

# GXML test suite - callbacks.pl
# by Josh Carter <josh@multipart-mixed.com>
#
# Installs start and end callbacks for a tag, and prints messages
# saying the callbacks have been hit.

use strict;
use XML::GXML;

# test code
my $xml = '<basetag><thing name="hi">hi there</thing></basetag>';

# assemble callback hash
my %callbacks = ( 'start:thing' => \&thingStart,
				  'end:thing'   => \&thingEnd);

my $gxml = new XML::GXML({'callbacks' => \%callbacks});

# run our test
print "before:\n";
print $xml;
print "\nafter:\n";
print $gxml->Process($xml);
print "\n";

exit;

### callbacks below

sub thingStart
{
	my $rParams = shift;

	print "-- callback saw start tag\n";
}

sub thingEnd
{
	my $rParams = shift;

	print "-- callback saw end tag\n";
}


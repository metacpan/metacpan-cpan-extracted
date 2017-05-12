#!/usr/bin/perl -w

# GXML test suite - callbacks2.pl
# by Josh Carter <josh@multipart-mixed.com>
#
# Tests the end tag return system by returning 'discard' after it's
# seen three 'thing' entities.

use strict;
use XML::GXML;

# assemble callback hash
my %callbacks = ( 'end:thing'   => \&OnlyTakeThree);

my $gxml = new XML::GXML({'callbacks' => \%callbacks});

# run our test
print "\nafter:\n";
print $gxml->ProcessFile('callbacks2.xml');
print "\n";

exit;

### callbacks below

sub OnlyTakeThree
{
	if (XML::GXML::NumAttributes('thing') > 3)
	{ return ['discard']; }
}


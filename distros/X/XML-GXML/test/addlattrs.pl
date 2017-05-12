#!/usr/bin/perl

# GXML test suite - addlattrs.pl
# by Josh Carter <josh@multipart-mixed.com>
#
# Tests the dynamic attributes feature

use strict;
use XML::GXML;

my $file = 'addlattrs.xml';

my $gxml = new XML::GXML({'addlAttrs' => \&Boberize});

print "\nafter:\n";
print $gxml->ProcessFile($file);
print "\n";

exit;

sub Boberize
{
	my $attr = shift;

	if ($attr eq 'name')
	{ return 'Bob'; }
}


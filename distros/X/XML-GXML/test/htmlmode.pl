#!/usr/bin/perl -w

# GXML test suite - htmlmode.pl
# by Josh Carter <josh@multipart-mixed.com>
#
# Runs the stuff in "htmlmode.xml" test file. This demonstrates some
# differences between normal and HTML modes.

use strict;
use XML::GXML;

my $gxml = new XML::GXML();

print "\nwithout HTML mode (normal):\n";
print $gxml->ProcessFile('htmlmode.xml');
print "\n";
undef $gxml;

$gxml = new XML::GXML({'html' => 'on'});

print "\nwith HTML mode:\n";
print $gxml->ProcessFile('htmlmode.xml');
print "\n";

exit;


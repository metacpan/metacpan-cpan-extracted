#!/usr/bin/perl -w

# GXML test suite - varprocessors.pl
# by Josh Carter <josh@multipart-mixed.com>
#
# This demonstrates applying post-processors to variables.

use strict;
use XML::GXML;

my $gxml = new XML::GXML();
print "With no variable processing:\n";
print $gxml->Process('<p name="Bob the Man">%%%name%%%</p>');
print "\n";

print "Now in uppercase:\n";
print $gxml->Process('<p name="Bob the Man">%%%name-UPPERCASE%%%</p>');
print "\n";

print "Now in lowercase:\n";
print $gxml->Process('<p name="Bob the Man">%%%name-LOWERCASE%%%</p>');
print "\n";

print "Now with basic URL encoding:\n";
print $gxml->Process('<p name="Bob the Man">%%%name-URLENCODED%%%</p>');
print "\n";


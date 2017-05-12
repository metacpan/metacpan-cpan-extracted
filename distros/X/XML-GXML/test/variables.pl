#!/usr/bin/perl

# GXML test suite - variables.pl
# by Josh Carter <josh@multipart-mixed.com>
#
# Runs the stuff in "variables.xml" test file. This exercises the
# variable scoping mechanism

use strict;
use XML::GXML;

my $file = 'variables.xml';

my $gxml = new XML::GXML();

print "\nafter:\n";
print $gxml->ProcessFile($file);
print "\n";

exit;


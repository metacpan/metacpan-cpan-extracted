#!/usr/bin/perl

# GXML test suite - commands.pl
# by Josh Carter <josh@multipart-mixed.com>
#
# Runs the commands in "commands.xml" test file. This exercises the
# foreach, ifequals, and ifexists commands.

use strict;
use XML::GXML;

my $file = 'commands.xml';

my $gxml = new XML::GXML();

print "\nafter:\n";
print $gxml->ProcessFile($file);
print "\n";

exit;


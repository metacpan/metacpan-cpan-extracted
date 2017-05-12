#!/usr/bin/perl

use WWW::URLToys;
use strict;

my @list;

print "\nURLToys Test\nVersion: ";
ut_exec_command('version',\@list);

print "If this printed the URLToys version on the previous line, URLToys is installed.\n\n";

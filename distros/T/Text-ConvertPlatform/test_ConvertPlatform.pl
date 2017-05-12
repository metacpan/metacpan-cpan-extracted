#!/usr/local/bin/perl -w

# This is a basic(perl) example of how one can use Text::ConvertPlatform.

# USAGE
# ls *.html | test_ConvertPlatform.pl

use strict;
use Text::ConvertPlatform;

my $philip = new Text::ConvertPlatform;

while (<>) {

	chop;
	$philip->filename("$_");	# file that is to be worked on
	# $philip->convert_to("mac");	# set conversion mode - dos, mac, or unix 
	# not needed if converting to unix
	$philip->process_file;	# change FILENAME to new format
	$philip->replace_file;	# overwrite FILENAME with NEWCONTENTS
	$philip->backup_file;	# create a copy of FILENAME with a .bak extension
	# print $philip->oldcontents;	# print original contents of FILENAME
	# print $philip->newcontents;	# print results of the processed file

	}

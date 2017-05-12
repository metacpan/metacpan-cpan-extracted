#!/usr/bin/perl

use XML::Directory::SAX;
use MyHandler;
use MyErrorHandler;
use strict;

(@ARGV == 1 ) || die ("Usage: dir2xml_sax.pl path\n\n");

my $path = shift;

my $h = MyHandler->new();
my $e = MyErrorHandler->new();

my $dir = XML::Directory::SAX->new(
				  Handler => $h, 
				  ErrorHandler => $e,
				  details => 3,
				  depth => 10,
				 );

my $rc  = $dir->parse_dir($path);

exit 0;

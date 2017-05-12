#!/usr/bin/perl

use XML::Directory::String;
use strict;

(@ARGV == 1 ) || die ("Usage: dir2xml_rdf.pl path\n\n");

my $path = shift;

my $dir = new XML::Directory::String($path,2,5);
$dir->enable_rdf('index.n3');
#$dir->error_treatment('warn');

my $rc  = $dir->parse;
my $xml = $dir->get_arrayref;

foreach (@$xml) {
    print "$_\n";
}

exit 0;



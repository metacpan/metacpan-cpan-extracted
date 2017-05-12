#!/usr/bin/perl
use XML::DT ;
my $filename = "ex7.xml";;

# Test the name()
# tests the starts_with and the contains

%handler=(
	  '-inputenc' => 'ISO-8859-1',
     '//*[not(contains(name(),"c"))]' => sub{print "$c\n";toxml},
);
pathdt($filename,%handler);
print "\n";

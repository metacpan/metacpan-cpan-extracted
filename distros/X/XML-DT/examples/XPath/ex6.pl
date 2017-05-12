#!/usr/bin/perl
use XML::DT ;
my $filename = "ex6.xml";;

# Test comparasion of atribute with string...
# tests the normalize-space function

%handler=(
	  '-inputenc' => 'ISO-8859-1',
     '//*[normalize-space(@id) = "a"]' => sub{print "$c\n";toxml},
);
pathdt($filename,%handler);
print "\n";

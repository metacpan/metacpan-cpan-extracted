#!/usr/bin/perl
use XML::DT ;
my $filename = "ex8.xml";;

# tests number comparasion and string-length function


%handler=(
	  '-inputenc' => 'ISO-8859-1',
	  '//*[string-length(name())&lt;2]' => sub{
	    print "$c\n";toxml
	  },
	 );
pathdt($filename,%handler);
print "\n";

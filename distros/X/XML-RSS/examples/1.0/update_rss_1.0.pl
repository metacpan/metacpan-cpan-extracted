#!/usr/bin/perl -w
# this script adds a new item to an existing rss file and
# updates the channel date and publisher

use XML::RSS;

# create a new instance of the XML::RSS
my $rss = XML::RSS->new;

# parse the local file
$rss->parsefile("rss1.0.rdf");

# add a new item to the file
$rss->add_item(
   title       => "QScheme 0.2.2",
   link        => "http://freshmeat.net/news/1999/06/21/930003829.html",
   description => "Really fast, small and easy to interface Scheme interpreter",
   dc => {
     subject  => "X11/Utilities",
     creator  => "David Allen (s2mdalle at titan.vcu.edu)",
   },
 );

# update the dublin core information for the channel
$rss->channel(dc => {
		 date => "2000-01-01T12:00+00:00",
		 publisher => "Jonathan Eisenzopf (eisen\@xif.com)"
		    }
             );

# print the new rss file as a string. We could also save it
to a file with the save() routine.
print $rss->as_string;

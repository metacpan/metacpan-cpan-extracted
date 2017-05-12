#!/usr/bin/perl -w
# create_rss.pl
# creates and prints RSS 0.9 file

use strict;
use warnings;

use XML::RSS;

my $rss = XML::RSS->new(version => '0.9');
$rss->channel(title => "freshmeat.net",
	      link  => "http://freshmeat.net",
	      description => "the one-stop-shop for all your Linux software needs"
	      );

$rss->image(title => "freshmeat.net",
	    url => "http://freshmeat.net/images/fm.mini.jpg",
	    link => "http://freshmeat.net"
	    );

$rss->add_item(title => "GTKeyboard 0.85",
	       link  => "http://freshmeat.net/news/1999/06/21/930003829.html"
	       );

$rss->add_item(title => "Spruce 0.4.7b",
	       link  => "http://freshmeat.net/news/1999/06/21/930003816.html"
	       );

$rss->textinput(title => "quick finder",
		description => "Use the text input below to search freshmeat",
		name => "query",
		link => "http://core.freshmeat.net/search.php3"
		);

print $rss->as_string;

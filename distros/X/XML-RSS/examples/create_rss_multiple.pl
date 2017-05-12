#!/usr/bin/perl
# create_rss.pl
# creates multiple instances of XML::RSS

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

my $rss2 = XML::RSS->new(version => '0.9');
$rss2->channel(title => "perlxml.com",
	      link  => "http://perlxml.com"
	      );

$rss2->add_item(title => "dada",
		link  => "foo"
		);
print "\n\nTitle2: ",$rss2->channel('title'),"\n";
print $rss2->items->[0]->{'title'},"\n";


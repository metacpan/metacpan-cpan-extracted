#!/usr/bin/env perl

1;

__END__

=head1 NAME

XML::TreePuller::CookBook::Intro - Various ways to work with an Atom feed

=head1 ABOUT

Atom documents are simple and small - they fit into RAM and don't have many
nested elements. Processing them is straight forward and a good place to
start learning. 

=head2 Atom Format

An Atom feed looks like this:

  <?xml version="1.0" encoding="utf-8"?>
 
  <feed xmlns="http://www.w3.org/2005/Atom">
 
  	<title>Example Feed</title>
  	<subtitle>A subtitle.</subtitle>
  	<link href="http://example.org/feed/" rel="self" />
  	<link href="http://example.org/" />
  	<id>urn:uuid:60a76c80-d399-11d9-b91C-0003939e0af6</id>
  	<updated>2003-12-13T18:30:02Z</updated>
  	<author>
  		<name>John Doe</name>
  		<email>johndoe@example.com</email>
  	</author>
 
  	<entry>
  		<title>Atom-Powered Robots Run Amok</title>
  		<link href="http://example.org/2003/12/13/atom03" />
  		<link rel="alternate" type="text/html" href="http://example.org/2003/12/13/atom03.html"/>
  		<link rel="edit" href="http://example.org/2003/12/13/atom03/edit"/>
  		<id>urn:uuid:1225c695-cfb8-4ebb-aaaa-80da344efa6a</id>
  		<updated>2003-12-13T18:30:02Z</updated>
  		<summary>Some text.</summary>
  	</entry>
 
  </feed>

=head1 PROGRAMS

=head2 Feed summaries

Lets say you have 10 Atom feeds you are interested in subscribing to but
you want to see what they have to offer as a summary; Perl to the rescue!
The following script generates a report of an arbitrary number of Atom feeds 
off the Internet fetching them directly from a URL or a file. The format 
of the report is like this:

  Feed: Example Feed
    * Atom-Powered Robots Run Amok
    
(that sure does sound like an interesting feed)

  #!/usr/bin/env perl
  
  use strict;
  use warnings;
  
  use XML::TreePuller;
  
  foreach (@ARGV) {
  	my $root = XML::TreePuller->parse(location => $_);
	my $title = $root->xpath('/feed/title')->text;
  	
  	print "Feed: $title\n";

	foreach ($root->xpath('/feed/entry/title')) {  	
  		print "  * ", $_->text, "\n";
  	}
  	
  	print "\n\n\n";
  }

=head2 Linking to entries

Given an Atom feed what is the easiest way to build an HTML list of hyperlinks to the entries that
are specified in it? We need to get the title which is stored in a single element and the hyperlink
to the entry; there are multiple link elements and we only want one - the one with "rel" attribute
value of "alternate". XPath makes quick work of this.

  #!/usr/bin/env perl

  use strict;
  use warnings;
  
  use XML::TreePuller;
  
  my $root = XML::TreePuller->parse(location => shift(@ARGV));
  
  print "<ul>\n";
  
  foreach($root->xpath('/feed/entry')) {
  	my $title = $_->xpath('//title')->text;
  	#there are many link elements but we only want one of them
  	my $to = $_->xpath("//link[\@rel='alternate']")->attribute('href');
  
  	print "  <li><a href=\"$to\">$title</a></li>\n";
  }
  
  print "</ul>\n";


=head1 COPYRIGHT 

The ATOM example XML document was taken from Wikipedia at the
following URL: http://en.wikipedia.org/w/index.php?title=Atom_(standard)&oldid=353180236
and is available under the Creative Commons Attribution ShareAlike license

All other content is copyright Tyler Riddle; see the README for licensing terms. 

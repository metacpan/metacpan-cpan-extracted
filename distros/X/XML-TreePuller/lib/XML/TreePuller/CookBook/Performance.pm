1;

__END__

=head1 NAME

XML::TreePuller::CookBook::Performance - Increasing the rate of data through XML::TreePuller

=head1 ABOUT

Wikipedia (and MediaWiki) dump files present interesting parsing challenges -
they are not of a high complexity but they do get to be very large; the
English Wikipedia dump file is around 24 gigabytes and the dump file that
has all of the revisions ever made is estimated to be around 1.5 terabytes 
(or larger). We'll cover parsing the Wikipedia dump files in faster
and faster ways. 

=head2 Wikipedia dump format

The dump file looks a little something like this:

  <mediawiki version="0.4">
    <siteinfo>
      <sitename>Wikipedia</sitename>
      <namespaces>
        <namespace key="0"/>
        <namespace key="1">Talk</namespace>
      </namespaces>
    </siteinfo>
    <page>
      <title>Perl</title>
      <revision>
        <contributor>
          <username>A Random Monger</username>
        </contributor>
        <text>A nifty little language if I do say so myself!</text>
      </revision>
    </page>
    <!-- 24 gigabytes more of XML goes here>
    <page>
      <title>C</title>
      <revision>
        <contributor>
          <username>A Random Monger</username>
        </contributor>
        <text>Faster and even more dangerous.</text>
      </revision>
    </page>
  </mediawiki>
  
=head1 PROGRAMS

=head2 Print out a report from the dump file

Lets build a report from the dump file: it'll contain the version
of the dump file, the site name, and the list of page titles. 

The most important thing to keep in mind with big dump files is that they are to
large to fit the entire document into RAM. Because of this we need to have 
XML::TreePuller break the document up into chunks that will fit. We also want to 
access the version attribute on the root node but with out having the entire
document read into memory.  

  #!/usr/bin/env perl

  use strict;
  use warnings;
  
  use XML::TreePuller;
  
  my $xml = XML::TreePuller->new(location => shift(@ARGV));

  #read the mediawiki element but stop short
  #of reading in a subelement 
  $xml->iterate_at('/mediawiki' => 'short');
  $xml->iterate_at('/mediawiki/siteinfo/sitename' => 'subtree');
  $xml->iterate_at('/mediawiki/page' => 'subtree');

  print "Dump version: ", $xml->next->attribute('version'), "\n";
  print "Sitename: ", $xml->next->text, "\n";
  
  while($_ = $xml->next) {
  	#note that the root element is page, not mediawiki
  	print '  * ', $_->xpath('/page/title')->text, "\n";
  }
  
=head2 Print page titles and text

Because the English Wikipedia dump files are so large parsing them has been
turned into a shoot-out to gauge the speed of various XML processing systems.
The shoot-out is to print all the page titles and contents to STDOUT. This
example processes the XML input of the simple English Wikipedia at 3.45 MiB/sec. 

  use strict;
  use warnings;

  use XML::TreePuller;

  binmode(STDOUT, ':utf8');

  my $xml = XML::TreePuller->new(location => shift(@ARGV));

  $xml->iterate_at('/mediawiki/page', 'subtree');

  while(defined(my $e = $xml->next)) {
  	my $t = $e->xpath('/page');
	
  	print 'Title: ', $e->xpath('/page/title')->text, "\n";
  	print $e->xpath('/page/revision/text')->text;
  } 
  
=head2 Print page titles and text but faster

The previous example does not really use any of the features of
XPath that warrant the additional processing overhead of involving
it in our code. We can replace the xpath() calls with get_elements()
which has less features but is faster. This code processes the XML
input at 6.68 MiB/sec. 

  use strict;
  use warnings;

  use XML::TreePuller;

  binmode(STDOUT, ':utf8');

  my $xml = XML::TreePuller->new(location => shift(@ARGV));

  $xml->iterate_at('/mediawiki/page', 'subtree');

  while(defined(my $e = $xml->next)) {
  	my $t = $e->xpath('/page');
	
  	print 'Title: ', $e->get_elements('title')->text, "\n";
  	print $e->get_elements('revision/text')->text;
  } 
  
=head2 Print page titles and text - also faster

There is one more way to solve this particular problem: we can ask
the engine to iterate on both page title and text elements. This
example runs at 7.9 MiB/sec.

  use strict;
  use warnings;

  use XML::TreePuller;

  binmode(STDOUT, ':utf8');

  my $xml = XML::TreePuller->new(location => shift(@ARGV));

  $xml->iterate_at('/mediawiki/page/title', 'subtree');
  $xml->iterate_at('/mediawiki/page/revision/text', 'subtree');

  while(defined(my $e = $xml->next)) {
  	print 'Title: ', $e->text, "\n";
  	print $xml->next->text, "\n";
  } 


=head1 COPYRIGHT 

All content is copyright Tyler Riddle; see the README for licensing terms. 
  

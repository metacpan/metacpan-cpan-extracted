use strict;
use Test::More;

use constant RSS_VERSION       		=> "2.0";
use constant RSS_ENCLOSURE_URL      	=> qq(http://www.scripting.com/mp3s/weatherReportSuite.mp3);
use constant RSS_ENCLOSURE_LENGTH      	=> qq(12216320);
use constant RSS_ENCLOSURE_TYPE      	=> qq(audio/mpeg);

use constant RSS_DOCUMENT      		=> qq(<?xml version="1.0"?>
<rss version="2.0">
 <channel>
  <title>Example 2.0 Channel with Enclosure sub-element of Item</title>
  <link>http://example.com/</link>
  <description>To lead by example</description>
  <language>en-us</language>
  <copyright>All content Public Domain, except comments which remains copyright the author</copyright> 
  <managingEditor>editor\@example.com</managingEditor> 
  <webMaster>webmaster\@example.com</webMaster>
  <docs>http://backend.userland.com/rss</docs>
  <category  domain="http://www.dmoz.org">Reference/Libraries/Library_and_Information_Science/Technical_Services/Cataloguing/Metadata/RDF/Applications/RSS/</category>
  <generator>The Superest Dooperest RSS Generator</generator>
  <lastBuildDate>Mon, 02 Sep 2002 03:19:17 GMT</lastBuildDate>
  <ttl>60</ttl>

  <item>
   <title>News for September the Second</title>
   <link>http://example.com/2002/09/02</link>
   <description>other things happened today</description>
   <comments>http://example.com/2002/09/02/comments.html</comments>
   <author>joeuser\@example.com</author>
   <pubDate>Mon, 02 Sep 2002 03:19:00 GMT</pubDate>
   <guid isPermaLink="true">http://example.com/2002/09/02</guid>
   <enclosure url="http://www.scripting.com/mp3s/weatherReportSuite.mp3" length="12216320" type="audio/mpeg" />
  </item>


 </channel>
</rss>);

plan tests => 8;

use_ok("XML::RSS::LibXML");

my $xml = XML::RSS::LibXML->new();
isa_ok($xml,"XML::RSS::LibXML");

eval { $xml->parse(RSS_DOCUMENT); };
is($@,'',"Parsed RSS feed");

cmp_ok($xml->{'_internal'}->{'version'},"eq",RSS_VERSION,"Is RSS version ".RSS_VERSION);
cmp_ok(ref($xml->{items}),"eq","ARRAY","\$xml->{items} is an ARRAY ref");


if($xml->{items} && ref($xml->{items}) eq 'ARRAY'){
    my $item = shift @{$xml->{items}};

    if($item->{enclosure}){

	my $encl = $item->{enclosure};

	cmp_ok($encl->{'url'},"eq",RSS_ENCLOSURE_URL, "ENCLOSURE URL is ".RSS_ENCLOSURE_URL);
	cmp_ok($encl->{'length'},"eq",RSS_ENCLOSURE_LENGTH, "ENCLOSURE URL is ".RSS_ENCLOSURE_LENGTH);
	cmp_ok($encl->{'type'},"eq",RSS_ENCLOSURE_TYPE, "ENCLOSURE URL is ".RSS_ENCLOSURE_TYPE);
    
    }else{
	
	ok(0,"Parsing Enclosure element, sub-element of Item");
    }

    
}




__END__

=head1 NAME

enclosures2.t - tests for parsing RSS 2.0 data with XML::RSS::LibXML.pm

=head1 SYNOPSIS

 use Test::Harness qw (runtests);
 runtests (./XML-RSS/t/*.t);

=head1 DESCRIPTION

Tests for parsing RSS 2.0 data with XML::RSS::LibXML.pm

L<http://rt.cpan.org/Ticket/Display.html?id=21740>

=head1 AUTHOR

Aaron Straup Cope

=head1 SEE ALSO

http://backend.userland.com/rss2

=cut

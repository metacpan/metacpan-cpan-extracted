use strict;
use Test::More;

use constant RSS_VERSION       => "2.0";
use constant RSS_CHANNEL_TITLE => "Example 2.0 Channel";

use constant RSS_DOCUMENT      => qq(<?xml version="1.0"?>
<rss version="2.0">
 <channel>
  <title>Example 2.0 Channel</title>
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
   <enclosure url="http://example.com/test.mp3" length="5352283" type="audio/mpeg" />
  </item>

 </channel>
</rss>);

plan tests => 6;

use_ok("XML::RSS::LibXML");

my $xml = XML::RSS::LibXML->new();
isa_ok($xml,"XML::RSS::LibXML");

eval { $xml->parse(RSS_DOCUMENT); };
is($@,'',"Parsed RSS feed");

# XXX We can't compare hash structures here, because we have a 
# XML::RSS::LibXML::MagicElement type here.
# is_deeply($xml->{items}->[0]->{enclosure}, { url => "http://example.com/test.mp3", length => "5352283", type => "audio/mpeg" }, "got enclosure");

my $e = $xml->{items}->[0]->{enclosure};
is($e->{url}, "http://example.com/test.mp3", "enclosure url");
is($e->{length}, "5352283", "enclosure length");
is($e->{type}, "audio/mpeg", "enclosure type");

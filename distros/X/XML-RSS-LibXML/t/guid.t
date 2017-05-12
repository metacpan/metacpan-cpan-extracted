# This is to test the following bug:
# https://rt.cpan.org/Ticket/Display.html?id=24742

use strict;

use Test::More tests => 1;

use XML::RSS::LibXML;

{
    my $rss_text = qq(<?xml version="1.0" encoding="utf-8"?>
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

    my $xml = XML::RSS::LibXML->new();

    $xml->parse($rss_text);

    # TEST
    ok (
        (index($xml->as_string(), q{<guid isPermaLink="true">http://example.com/2002/09/02</guid>}) >= 0), 
        "Checking for correct guid"
    );
}

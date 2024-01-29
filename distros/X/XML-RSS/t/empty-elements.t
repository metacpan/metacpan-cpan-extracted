use strict;
use warnings;

use Test::More tests => 4;

use XML::RSS ();

my $RSS_DOCUMENT = qq(<?xml version="1.0"?>
<rss version="2.0">
 <channel>
  <title>Example 2.0 Channel</title>
  <link>http://example.com/</link>
  <description>To lead by example</description>
  <language>en-us</language>
  <managingEditor>editor\@example.com</managingEditor>
  <webMaster>webmaster\@example.com</webMaster>
  <docs>http://backend.userland.com/rss</docs>
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
   <!-- a custom element which is allowed to be empty -->
   <custom name="seeds" value="100" />
   <guid isPermaLink="true">http://example.com/2002/09/02</guid>
   <enclosure url="http://example.com/test.mp3" length="5352283" type="audio/mpeg" />
  </item>

 </channel>
</rss>);


{
    my $xml = XML::RSS->new();

    # TEST
    isa_ok($xml, "XML::RSS");

    eval { $xml->parse($RSS_DOCUMENT); };

    # TEST
    is($@, '', "Parsed RSS feed");

}

{
    my $xml = XML::RSS->new;

    eval { $xml->parse($RSS_DOCUMENT, {allow_empty => ['custom']}) };

    # TEST
    is($@, '', "Parsed RSS feed for with option to allow empty 'custom' elements");

    # TEST
    is_deeply(
        $xml->{items}->[0]->{custom},
        {name => "seeds", value => "100"},
        "returned custom empty element and its attributes"
    );

}

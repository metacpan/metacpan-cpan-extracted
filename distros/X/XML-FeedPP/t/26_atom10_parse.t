# ----------------------------------------------------------------
    use strict;
    use Test::More tests => 23;
    BEGIN { use_ok('XML::FeedPP') };
# ----------------------------------------------------------------
#	Sample Atom 1.0 sources from http://www.ietf.org/rfc/rfc4287
# ----------------------------------------------------------------
{
	my $sample = <<'EOT';
   <?xml version="1.0" encoding="utf-8"?>
   <feed xmlns="http://www.w3.org/2005/Atom">

     <title>Example Feed</title>
     <link href="http://example.org/"/>
     <updated>2003-12-13T18:30:02Z</updated>
     <author>
       <name>John Doe</name>
     </author>
     <id>urn:uuid:60a76c80-d399-11d9-b93C-0003939e0af6</id>

     <entry>
       <title>Atom-Powered Robots Run Amok</title>
       <link href="http://example.org/2003/12/13/atom03"/>
       <id>urn:uuid:1225c695-cfb8-4ebb-aaaa-80da344efa6a</id>
       <updated>2003-12-13T18:30:02Z</updated>
       <summary>Some text.</summary>
     </entry>

   </feed>
EOT
	my $feed = XML::FeedPP->new( $sample );
	ok( $feed->isa( 'XML::FeedPP::Atom::Atom10' ), 'XML::FeedPP::Atom::Atom10' );
	is( $feed->title, 'Example Feed', 'feed title' );
	is( $feed->link, 'http://example.org/', 'feed link' );
	is( $feed->pubDate, '2003-12-13T18:30:02Z', 'feed pubDate' );
#	is( $feed->author, 'John Doe', 'feed author' );
#	is( $feed->guid, 'urn:uuid:60a76c80-d399-11d9-b93C-0003939e0af6', 'feed guid' );

	my @entry = $feed->get_item;
	is( scalar(@entry), 1, 'feed get_item' );
	my $item = shift @entry;
	is( $item->title, 'Atom-Powered Robots Run Amok', 'item title' );
	is( $item->link, 'http://example.org/2003/12/13/atom03', 'item link' );
	is( $item->guid, 'urn:uuid:1225c695-cfb8-4ebb-aaaa-80da344efa6a', 'item guid' );
	is( $item->pubDate, '2003-12-13T18:30:02Z', 'item pubDate' );
	is( $item->description, 'Some text.', 'item description' );
}
# ----------------------------------------------------------------
{
	my $sample = <<'EOT';
   <?xml version="1.0" encoding="utf-8"?>
   <feed xmlns="http://www.w3.org/2005/Atom">
     <title type="text">dive into mark</title>
     <subtitle type="html">
       A &lt;em&gt;lot&lt;/em&gt; of effort
       went into making this effortless
     </subtitle>
     <updated>2005-07-31T12:29:29Z</updated>
     <id>tag:example.org,2003:3</id>
     <link rel="alternate" type="text/html"
      hreflang="en" href="http://example.org/"/>
     <link rel="self" type="application/atom+xml"
      href="http://example.org/feed.atom"/>
     <rights>Copyright (c) 2003, Mark Pilgrim</rights>
     <generator uri="http://www.example.com/" version="1.0">
       Example Toolkit
     </generator>
     <entry>
       <title>Atom draft-07 snapshot</title>
       <link rel="alternate" type="text/html"
        href="http://example.org/2005/04/02/atom"/>
       <link rel="enclosure" type="audio/mpeg" length="1337"
        href="http://example.org/audio/ph34r_my_podcast.mp3"/>
       <id>tag:example.org,2003:3.2397</id>
       <updated>2005-07-31T12:29:29Z</updated>
       <published>2003-12-13T08:29:29-04:00</published>
       <author>
         <name>Mark Pilgrim</name>
         <uri>http://example.org/</uri>
         <email>f8dy@example.com</email>
       </author>
       <contributor>
         <name>Sam Ruby</name>
       </contributor>
       <contributor>
         <name>Joe Gregorio</name>
       </contributor>
       <content type="xhtml" xml:lang="en"
        xml:base="http://diveintomark.org/">
         <div xmlns="http://www.w3.org/1999/xhtml">
           <p><i>[Update: The Atom draft is finished.]</i></p>
         </div>
       </content>
     </entry>
   </feed>
EOT

	my $feed = XML::FeedPP->new( $sample );
	ok( $feed->isa( 'XML::FeedPP::Atom::Atom10' ), 'XML::FeedPP::Atom::Atom10' );
	is( $feed->title, 'dive into mark', 'feed title' );
	like( $feed->description, qr/effortless/, 'feed description' );

my $desc = $feed->description;
print "[$desc]\n";

	is( $feed->pubDate, '2005-07-31T12:29:29Z', 'feed pubDate' );
#	is( $feed->guid, 'tag:example.org,2003:3', 'feed guid' );
	is( $feed->link, 'http://example.org/', 'feed link' );
	is( $feed->copyright, 'Copyright (c) 2003, Mark Pilgrim', 'feed copyright' );

	my @entry = $feed->get_item;
	is( scalar(@entry), 1, 'feed get_item' );
	my $item = shift @entry;
	is( $item->title, 'Atom draft-07 snapshot', 'item title' );
	is( $item->link, 'http://example.org/2005/04/02/atom', 'item link' );
	is( $item->guid, 'tag:example.org,2003:3.2397', 'item guid' );
	is( $item->pubDate, '2005-07-31T12:29:29Z', 'item pubDate' );
	is( $item->author, 'Mark Pilgrim', 'item author' );

$desc = $item->description;
print "[$desc]\n";
use Data::Dumper;
print Dumper($desc);

}
# ----------------------------------------------------------------
;1;
# ----------------------------------------------------------------

# ----------------------------------------------------------------
    use strict;
    use Test::More tests => 22;
    BEGIN { use_ok('XML::FeedPP') };
# ----------------------------------------------------------------
#	Sample Atom 0.3 sources from 
#	http://www.mnot.net/drafts/draft-nottingham-atom-format-02.html
#	http://www.kanzaki.com/memo/2004/01/29-1
# ----------------------------------------------------------------
{
	my $sample = <<'EOT';
		<?xml version="1.0" encoding="utf-8"?>
		<feed version="0.3" xmlns="http://purl.org/atom/ns#">
		  <title>dive into mark</title>
		  <link rel="alternate" type="text/html" 
		   href="http://diveintomark.org/"/>
		  <modified>2003-12-13T18:30:02Z</modified>
		  <author>
		    <name>Mark Pilgrim</name>
		  </author>
		  <entry>
		    <title>Atom 0.3 snapshot</title>
		    <link rel="alternate" type="text/html" 
		     href="http://diveintomark.org/2003/12/13/atom03"/>
		    <id>tag:diveintomark.org,2003:3.2397</id>
		    <issued>2003-12-13T08:29:29-04:00</issued>
		    <modified>2003-12-13T18:30:02Z</modified>
		  </entry>
		</feed>
EOT
	my $feed = XML::FeedPP->new( $sample );
	ok( $feed->isa( 'XML::FeedPP::Atom::Atom03' ), 'XML::FeedPP::Atom::Atom03' );
	is( $feed->title, 'dive into mark', 'feed title' );
	is( $feed->link, 'http://diveintomark.org/', 'feed link' );
	is( $feed->pubDate, '2003-12-13T18:30:02Z', 'feed pubDate' );

	my @entry = $feed->get_item;
	is( scalar(@entry), 1, 'feed get_item' );
	my $item = shift @entry;
	is( $item->title, 'Atom 0.3 snapshot', 'item title' );
	is( $item->link, 'http://diveintomark.org/2003/12/13/atom03', 'item link' );
	is( $item->guid, 'tag:diveintomark.org,2003:3.2397', 'item guid' );
	is( $item->pubDate, '2003-12-13T18:30:02Z', 'item pubDate' );
}
# ----------------------------------------------------------------
{
	my $sample = <<'EOT';
		<!DOCTYPE feed SYSTEM
		  "http://intertwingly.net/stories/2003/08/10/atom.dtd">
		<feed
		  xmlns="http://purl.org/atom/"
		  xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#">
		 <title>The Web KANZAKI - Japan, music and computer</title>
		 <tagline>Talking about Contrabass and Semantic Web</tagline>
		 <link rel="alternate" href="http://www.kanzaki.com"/>
		 <modified>2004-01-28</modified>
		 <entry>
		  <title>Contrabass Stories</title>
		  <link rel="alternate" href="http://www.kanzaki.com/bass/"/>
		  <id>tag:kanzaki.com/bass/</id>
		  <author>
		   <name>Masahide Kanzaki</name>
		  </author>
		  <issued>1995-12-15</issued>
		  <modified>2004-01-28T10:00:00Z</modified>
		  <summary>Some talks on Contrabas and its music</summary>
		 </entry>
		</feed>
EOT
	my $feed = XML::FeedPP->new( $sample );
	ok( $feed->isa( 'XML::FeedPP::Atom::Atom03' ), 'XML::FeedPP::Atom::Atom03' );
	is( $feed->title, 'The Web KANZAKI - Japan, music and computer', 'feed title' );
	is( $feed->description, 'Talking about Contrabass and Semantic Web', 'feed description' );
	is( $feed->link, 'http://www.kanzaki.com', 'feed link' );
	is( $feed->pubDate, '2004-01-28', 'feed pubDate' );

	my @entry = $feed->get_item;
	is( scalar(@entry), 1, 'feed get_item' );
	my $item = shift @entry;
	is( $item->title, 'Contrabass Stories', 'item title' );
	is( $item->link, 'http://www.kanzaki.com/bass/', 'item link' );
	is( $item->guid, 'tag:kanzaki.com/bass/', 'item guid' );
	is( $item->author, 'Masahide Kanzaki', 'item author' );
	is( $item->pubDate, '2004-01-28T10:00:00Z', 'item pubDate' );
	is( $item->description, 'Some talks on Contrabas and its music', 'item description' );
}
# ----------------------------------------------------------------
;1;
# ----------------------------------------------------------------

use strict;
use XML::Builder;
use Test::More tests => 1;

my $xb = XML::Builder->new;
my $a = $xb->ns( 'http://www.w3.org/2005/Atom' => '' );

my $hb = XML::Builder->new;
my $h = $hb->ns( 'http://www.w3.org/1999/xhtml' => '' );

chomp( my $expected = << '' );
<?xml version="1.0" encoding="us-ascii"?>
<feed xmlns="http://www.w3.org/2005/Atom">
 <title>dive into mark</title>
 <subtitle type="html">a &lt;em&gt;lot&lt;/em&gt; of effort went into making this effortless</subtitle>
 <updated>2005-07-31T12:29:29Z</updated>
 <id>tag:example.org,2003:3</id>
 <link href="http://example.org/" hreflang="en" rel="alternate" type="text/html"/>
 <link href="http://example.org/feed.atom" rel="self" type="application/atom+xml"/>
 <rights>Copyright (c) 2003, Mark Pilgrim</rights>
 <generator uri="http://www.example.com/" version="1.0">Example Toolkit</generator>
 <entry>
  <title>Atom draft-07 snapshot</title>
  <link href="http://example.org/2005/04/02/atom" rel="alternate" type="text/html"/>
  <link href="http://example.org/audio/ph34r_my_podcast.mp3" length="1337" rel="enclosure" type="audio/mpeg"/>
  <id>tag:example.org,2003:3.2397</id>
  <updated>2005-07-31T12:29:29Z</updated>
  <published>2003-12-13T08:29:29-04:00</published>
  <author><name>Mark Pilgrim</name><uri>http://example.org/</uri><email>f8dy@example.com</email></author>
  <contributor><name>Sam Ruby</name></contributor>
  <contributor><name>Joe Gregorio</name></contributor>
  <content type="xhtml" xml:base="http://diveintomark.org/" xml:lang="en"><div xmlns="http://www.w3.org/1999/xhtml"><p><i>[Update: The Atom draft is finished.]</i></p></div></content>
 </entry>
</feed>

my $result = $xb->document(
	$a->feed(
		map {; "\n ", $_ }
		$a->title( 'dive into mark' ),
		$a->subtitle( { type => 'html' }, 'a <em>lot</em> of effort went into making this effortless' ),
		$a->updated( '2005-07-31T12:29:29Z' ),
		$a->id( 'tag:example.org,2003:3' ),
		$a->link( { rel => 'alternate', type => 'text/html', hreflang => 'en', href => 'http://example.org/' } ),
		$a->link( { rel => 'self', type => 'application/atom+xml', href => 'http://example.org/feed.atom' } ),
		$a->rights( 'Copyright (c) 2003, Mark Pilgrim' ),
		$a->generator( { uri => 'http://www.example.com/', version => '1.0' }, 'Example Toolkit' ),
		$a->entry(
			map {; "\n  ", $_ }
			$a->title( 'Atom draft-07 snapshot' ),
			$a->link( { rel => 'alternate', type => 'text/html', href => 'http://example.org/2005/04/02/atom' } ),
			$a->link( { rel => 'enclosure', type => 'audio/mpeg', length => 1337, href => 'http://example.org/audio/ph34r_my_podcast.mp3' } ),
			$a->id( 'tag:example.org,2003:3.2397' ),
			$a->updated( '2005-07-31T12:29:29Z' ),
			$a->published( '2003-12-13T08:29:29-04:00' ),
			$a->author(
				$a->name( 'Mark Pilgrim' ),
				$a->uri( 'http://example.org/' ),
				$a->email( 'f8dy@example.com' ),
			),
			$a->contributor->foreach(
				$a->name( 'Sam Ruby' ),
				$a->name( 'Joe Gregorio' ),
			),
			$a->content( { type => 'xhtml', 'xml:lang' => 'en', 'xml:base' => 'http://diveintomark.org/' },
				$hb->root( $h->div( $h->p( $h->i( '[Update: The Atom draft is finished.]' ) ) ) ),
			)->append( "\n " ),
		)->append( "\n" ),
	),
);

is $result, $expected, 'example Atom feed';

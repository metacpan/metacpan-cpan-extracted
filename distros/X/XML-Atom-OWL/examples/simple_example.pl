use lib "lib";
use XML::Atom::OWL;
use JSON;

my $atom = <<ATOM;
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
	 <title property="dc:title" xmlns:dc="http://example.com/dc#">Atom draft-07 snapshot</title>
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
  <entry>
	<id>http://example.net/id/2</id>
	<content type="image/jpeg" src="data:text/html;base64,PCFET0NUWVBFIEhUTUwgUFVCTElDICItLy9XM0MvL0RURCBIVE1MIDQuMC8vRU4iPg0KPGh0bWwgbGFuZz0iZW4iPg0KIDxoZWFkPg0KICA8dGl0bGU%2BVGVzdDwvdGl0bGU%2BDQogIDxzdHlsZSB0eXBlPSJ0ZXh0L2NzcyI%2BDQogIDwvc3R5bGU%2BDQogPC9oZWFkPg0KIDxib2R5Pg0KICA8cD48L3A%2BDQogPC9ib2R5Pg0KPC9odG1sPg0K" />
  </entry>
</feed>
ATOM

my $awol = XML::Atom::OWL->new($atom, 'http://example.net/')->consume;
print to_json($awol->graph->as_hashref, {pretty=>1,canonical=>1});

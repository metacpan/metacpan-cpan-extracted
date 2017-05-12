#!/usr/bin/perl

use lib "../XML-Atom-OWL/lib";
use lib "lib";
use RDF::TrineShortcuts;
use RDF::RDFa::Parser;
use XML::Atom::FromOWL;

my $atom = <<ATOM;
<feed xmlns="http://www.w3.org/2005/Atom"
	xmlns:as="http://activitystrea.ms/spec/1.0/"
	xmlns:hnews="http://ontologi.es/hnews#"
	xmlns:thr="http://purl.org/syndication/thread/1.0">
  <title type="text">dive into mark</title>
  <subtitle type="html">
	 A &lt;em&gt;lot&lt;/em&gt; of effort
	 went into making this effortless
  </subtitle>
  <updated>2005-07-31T12:29:29Z</updated>
  <id>tag:example.org,2003:3</id>
  <logo>http://example.net/logo.jpeg</logo>
  <link rel="alternate" type="text/html"
	hreflang="en" href="http://example.org/"/>
  <link rel="self" type="application/atom+xml"
	href="http://example.org/feed.atom"/>
  <rights>Copyright (c) 2003, Mark Pilgrim</rights>
  <generator uri="http://www.example.com/" version="1.0">
	 Example Toolkit
  </generator>
  <entry xml:lang="en-US">
	 <title property="dc:title" xmlns:dc="http://example.com/dc#">Atom draft-07 snapshot</title>
	 <link rel="alternate" type="text/html"
	  href="http://example.org/2005/04/02/atom"/>
	 <link rel="enclosure" type="audio/mpeg" length="1337"
	  href="http://example.org/audio/ph34r_my_podcast.mp3"/>
    <category term="technology" label="Technology" scheme="http://example.com/categories/" />
	 <id>tag:example.org,2003:3.2397</id>
	 <updated>2005-07-31T12:29:29Z</updated>
	 <published>2003-12-13T08:29:29-04:00</published>
	 <meta property="hnews:dateline-literal" content="Dateline Literal" xml:lang="en-GB" />
	 <meta rel="hnews:source-org" href="http://dbpedia.org/resource/IANA" />
	 <author>
		<name>Mark Pilgrim</name>
		<uri>http://example.org/</uri>
		<email>f8dy\@example.com</email>
	 </author>
	 <as:verb>post</as:verb>
	 <as:object>
	   <id>foo:bar:baz</id>
	   <title>Foo Bar Baz</title>
	   <as:object-type>note</as:object-type>
	 </as:object>
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
	<thr:total>9</thr:total>
	<thr:in-reply-to source="foo" href="bar" ref="baz" />
	<content type="image/jpeg" src="data:text/html;base64,PCFET0NUWVBFIEhUTUwgUFVCTElDICItLy9XM0MvL0RURCBIVE1MIDQuMC8vRU4iPg0KPGh0bWwgbGFuZz0iZW4iPg0KIDxoZWFkPg0KICA8dGl0bGU%2BVGVzdDwvdGl0bGU%2BDQogIDxzdHlsZSB0eXBlPSJ0ZXh0L2NzcyI%2BDQogIDwvc3R5bGU%2BDQogPC9oZWFkPg0KIDxib2R5Pg0KICA8cD48L3A%2BDQogPC9ib2R5Pg0KPC9odG1sPg0K" />
  </entry>
</feed>
ATOM

my $cfg   = RDF::RDFa::Parser::Config->new('atom', '1.1', atom_parser=>1);
my $awol  = RDF::RDFa::Parser->new($atom, 'http://example.net/', $cfg)->consume;
my $model = $awol->graph;

my $exporter = XML::Atom::FromOWL->new();
print $_->as_xml foreach $exporter->export_feeds($model);
print rdf_string($model => 'Turtle');


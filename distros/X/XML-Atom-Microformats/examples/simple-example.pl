#!/usr/bin/perl

use 5.010;
use strict;
use utf8;

use JSON;
use RDF::Trine;
use XML::Atom::Microformats;

my $xml = <<XML;
<feed xmlns="http://www.w3.org/2005/Atom">
	<entry>
		<id>http://example.com/id/1</id>
		<content type="text/html">
			&lt;p class="vcard">&lt;span class="fn">Alice&lt;/span>&lt;/p>
		</content>
		<link rel="self" href="http://example.com/article/1" />
		<link rel="profile" href="http://ufs.cc/x/hcard" />
	</entry>
	<entry xml:base="http://bob.com/">
		<foo property=":fooble">lala</foo>
		<id>http://example.com/id/2</id>
		<content type="text/html">
			&lt;p class="vcard">&lt;a href="/foo" class="fn url">Bob&lt;/a>&lt;/p>
		</content>
		<link rel="self" href="http://example.com/article/2" />
	</entry>
</feed>
XML

my $xamf = XML::Atom::Microformats->new_feed($xml, "http://example.net/");
#$xamf->assume_all_profiles;
print $xamf->json(pretty=>1,canonical=>1);

my $s = RDF::Trine::Serializer::NQuads->new;
print $s->serialize_model_to_string($xamf->model(atomowl=>1));

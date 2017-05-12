use Test::More tests => 5;
BEGIN { use_ok('XML::Atom::Microformats') };

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

ok(
	my $model1 = XML::Atom::Microformats->new_feed($xml, "http://example.net/")->model,
	"Was able to build a model",
	);

ok(
	my $model2 = XML::Atom::Microformats->new_feed($xml, "http://example.net/")->assume_profile('hCard')->model,
	"Was able to build a model, assuming hCard profile",
	);

is(
	$model1->count_statements(
		undef,
		RDF::Trine::Node::Resource->new('http://www.w3.org/1999/02/22-rdf-syntax-ns#type'),
		RDF::Trine::Node::Resource->new('http://www.w3.org/2006/vcard/ns#VCard'),
		),
	1,
	"When not assuming profiles, only an explicitly profiled hCard is found."
	);

is(
	$model2->count_statements(
		undef,
		RDF::Trine::Node::Resource->new('http://www.w3.org/1999/02/22-rdf-syntax-ns#type'),
		RDF::Trine::Node::Resource->new('http://www.w3.org/2006/vcard/ns#VCard'),
		),
	2,
	"When assuming hCard profile, both hCards are found."
	);
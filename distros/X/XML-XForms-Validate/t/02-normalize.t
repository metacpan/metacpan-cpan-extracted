
use Test::More tests => 13;
BEGIN { use_ok('XML::XForms::Validate', 'normalize') };

my $parser = new XML::LibXML(ext_ent_handler => sub { die });
$parser->validation(0);
$parser->load_ext_dtd(0);
$parser->expand_xinclude(0);
$parser->expand_entities(0);
$parser->clean_namespaces(0);
$parser->no_network(1);

sub x($) { $parser->parse_string($_[0]) }
sub _($) { $_[0]->toStringC14N }

is(normalize("String"), "String", "string pass-through");

is(_ normalize(x "<a/>"), "<a></a>", "basic operation");

is_deeply(
	{ map { ref($_)?_($_):$_ } %{normalize({ '' => x '<a/>', 'b' => x '<b/>'})} },
	{ '' => '<a></a>', 'b' => '<b></b>' },
	"hash normalization"
);

is(_ normalize(x '<a><?xml-stylesheet blah?></a>'), '<a></a>', 'PI stripping');

is(_ normalize(x '<a><!--xml-stylesheet blah--></a>'), '<a></a>', 'comment stripping');

is(_ normalize(x '<a><![CDATA[<>"&]]></a>'), '<a>&lt;&gt;"&amp;</a>', 'CDATA section conversion');

is(
	_ normalize(x '<a><include xmlns="http://www.w3.org/2001/XInclude" href="MANIFEST" parse="text"/></a>'), 
	'<a></a>',
	"XInclude stripping"
);

is(
	normalize(x "<a b='1' a='2'/>\n")->documentElement->toString(),
	'<a a="2" b="1"/>',
	"C14N"
);

is(_ normalize(x '<a xmlns="" xmlns:foo="urn:foo"/>'), '<a></a>', 'namespace stripping');

is(_ normalize(x '<a xmlns="urn:foo"/>'), '<a xmlns="urn:foo"></a>', 'namspace keeping');

is(_ normalize(x '<a xmlns:x="urn:foo" x:a="1"/>'), '<a xmlns:x="urn:foo" x:a="1"></a>', 'attr namspace keeping');

is(_ normalize(x '<a xmlns:foo="urn:foo"/>', 1), '<a xmlns:foo="urn:foo"></a>', 'extra namspace keeping');


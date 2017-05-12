
use Test::More tests => 11;
use constant INVALID => "XML DATA INVALID]]>--\"\"''&<>";
BEGIN { use_ok('XML::XForms::Validate') };

my $v = new XML::XForms::Validate(
	xforms => \'<model xmlns="http://www.w3.org/2002/xforms"><submission id="s1"/></model>',
);

isa_ok($v, 'XML::XForms::Validate');

my $parser = $v->{parser};
sub chk($) {
	my $val = eval { $parser->parse_string($_[0])->toStringC14N };
	return INVALID if $@;
	return $val;
}

is(chk("<a/>"), "<a></a>", "basic parser operation");

is(chk("<a>&;</a>"), INVALID, "non-well-formed XML");

is(chk('<!DOCTYPE doc [ <!ENTITY x "foo"> ]><a>&x;</a>'), "<a>foo</a>", "internal entities");

is(chk('<!DOCTYPE doc [ <!ATTLIST a a CDATA "foo"> ]><a/>'), "<a></a>", "DTD ignore");

is(chk('<!DOCTYPE doc [ <!ENTITY x SYSTEM "/dev/null"> ]><a>&x;</a>'), INVALID, "no external entities 1");

is(chk('<!DOCTYPE doc [ <!ENTITY % x SYSTEM "/dev/null"> %x; ]><a/>'), INVALID, "no external entities 2");

is(chk('<!DOCTYPE a [ <!ELEMENT a (b)> ]><a><c/></a>'), '<a><c></c></a>', 'no validation');

is(chk('<!DOCTYPE html
PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN"
"http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd"><a/>'), '<a></a>', "no external DTD retrieval");

is(
	chk('<a><include xmlns="http://www.w3.org/2001/XInclude" href="MANIFEST" parse="text"/></a>'),
	'<a><include xmlns="http://www.w3.org/2001/XInclude" href="MANIFEST" parse="text"></include></a>',
	"no XInclude"
);

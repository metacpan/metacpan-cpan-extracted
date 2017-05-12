
use Test::More tests => 4;
BEGIN { use_ok('XML::XForms::Validate') };

my $v;
sub _($) {
	return $v->normalize($_[0]->{''})->toStringC14N if ref($_[0]);
	return $_[0];
}

my $doc = <<'EOX';
<doc xmlns:xf='http://www.w3.org/2002/xforms' xmlns:xsi='http://www.w3.org/2001/XMLSchema-instance'>
	<xf:model id="a">
		<xf:submission id="def"/>
		<xf:instance id="i1">
			<data xsi:noNamespaceSchemaLocation="t/abc.xsd">
				<a>123</a>
				<b>bbB</b>
				<c><d>f</d></c>
			</data>
		</xf:instance>
	</xf:model>
	<xf:input ref="a"/>
	<xf:input ref="b"/>
	<xf:input ref="c"/>
	<xf:input ref="c/d"/>
</doc>
EOX

$v = new XML::XForms::Validate(xforms => \$doc);
isa_ok($v, 'XML::XForms::Validate');

is(_ $v->validate(input => \'<data xsi:noNamespaceSchemaLocation="t/abc.xsd" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
				<a>123</a>
				<b>bbB</b>
				<c><d>f</d></c>
			</data>'),
	'<data xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:noNamespaceSchemaLocation="t/abc.xsd">
				<a>123</a>
				<b>bbB</b>
				<c><d>f</d></c>
			</data>',
	'successful validation'
);

is(_ $v->validate(input => \'<data xsi:noNamespaceSchemaLocation="t/abc.xsd" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
				<a>123a</a>
				<b>bbB</b>
				<c><d>f</d></c>
			</data>'),
	"Schema validation failed for instance \"i1\": Element 'a': '123a' is not a valid value of the atomic type 'xs:integer'.\n",
	'type error'
);

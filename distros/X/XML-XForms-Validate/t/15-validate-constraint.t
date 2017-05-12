
use Test::More tests => 5;
BEGIN { use_ok('XML::XForms::Validate') };

my $v;
sub _($) {
	return $v->normalize($_[0]->{''})->toStringC14N if ref($_[0]);
	return $_[0];
}

my $doc = <<'EOX';
<doc xmlns:xf='http://www.w3.org/2002/xforms'>
	<xf:model id="modela">
		<xf:submission id="sub1"/>
		<xf:instance>
<data>
	<frobozz><a/></frobozz>
	<gna>123</gna>
	<yip>aaa</yip>
	<foo>
		<bar blub="2">1</bar>
		<baz blech="4">2</baz>
		<baz>3</baz>
	</foo>
	<wib>5</wib>
	<yadda/>
</data>
		</xf:instance>
		<xf:bind nodeset="frobozz" constraint=". > 0">
			<xf:bind nodeset="a" constraint="/data/yadda + //@blub > 967" id="a"/>
		</xf:bind>
		<xf:bind nodeset="foo/bar/@blub" constraint="true()" id="d"/>
		<xf:bind nodeset="yadda" calculate="42*23"/>
	</xf:model>
	<xf:input ref="wib"/>
	<xf:input ref="frobozz"/>
	<xf:input ref="frobozz/text()[2]"/>
	<xf:input bind="a"/>
	<xf:input bind="d"/>
</doc>
EOX

my $result = '<data>
	<frobozz><a></a>2</frobozz>
	<gna>123</gna>
	<yip>aaa</yip>
	<foo>
		<bar blub="3">1</bar>
		<baz blech="4">2</baz>
		<baz>3</baz>
	</foo>
	<wib>5</wib>
	<yadda>966</yadda>
</data>';

$v = new XML::XForms::Validate(xforms => \$doc);
isa_ok($v, 'XML::XForms::Validate');

is(_ $v->validate(input => \$result),
	$result,
	'constraint basics'
);

is(_ $v->validate(input => \'<data>
	<frobozz><a></a>2</frobozz>
	<gna>123</gna>
	<yip>aaa</yip>
	<foo>
		<bar blub="1">1</bar>
		<baz blech="4">2</baz>
		<baz>3</baz>
	</foo>
	<wib>5</wib>
	<yadda>966</yadda>
</data>'),
	'Constraint error for /data/frobozz/a (/data/yadda + //@blub > 967)',
	'constraint using foreign data'
);

is(_ $v->validate(input => \'<data>
	<frobozz><a></a></frobozz>
	<gna>123</gna>
	<yip>aaa</yip>
	<foo>
		<bar blub="3">1</bar>
		<baz blech="4">2</baz>
		<baz>3</baz>
	</foo>
	<wib>5</wib>
	<yadda>966</yadda>
</data>'),
	'Constraint error for /data/frobozz (. > 0)',
	'constraint on node itself'
);
